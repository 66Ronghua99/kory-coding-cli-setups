import { readFile, writeFile, mkdir } from "node:fs/promises";
import { resolve, relative } from "node:path";
import { createHash } from "node:crypto";
import { readJson, sha256Json, sha256File } from "./lib/atomic.mjs";
import { resolveRunDir } from "./lib/paths.mjs";
import { loadOutputProfile, loadWorkflowConfig } from "./lib/config.mjs";

/**
 * Compile a scene's context document from its plan, transcript, visual bible, and catalog.
 */
export async function compileSceneContext({ root, runDir, sceneId }) {
  const rootResolved = resolve(root);
  const runDirResolved = resolve(runDir);
  const scenesDir = resolve(runDirResolved, "scenes");
  const sceneDir = resolve(scenesDir, sceneId);

  // Load inputs
  const plan = await readJson(resolve(sceneDir, "scene-plan.json"));
  const transcript = await readJson(resolve(runDirResolved, "transcription.json"));
  const visualBible = await readJson(resolve(runDirResolved, "visual-bible.json"));
  const outputProfile = await loadOutputProfile(rootResolved);
  const workflow = await loadWorkflowConfig(rootResolved);
  const catalog = JSON.parse(await readFile(resolve(rootResolved, ".omp", "skills", "hyperframes-motion", "catalog.json"), "utf8"));

  // Resolve recipes
  const [blueprint, rule] = plan.recipe_refs;
  const categoryRef = catalog.blueprints[blueprint] ?? null;

  // Get adjacent context cues
  const { adjacent_context_cues } = workflow;
  const cueIds = plan.subtitle_ids;
  const allCues = transcript.cues;
  const firstCueId = cueIds[0];
  const lastCueId = cueIds[cueIds.length - 1];
  const firstCueIndex = allCues.findIndex((c) => c.id === firstCueId);
  const lastCueIndex = allCues.findIndex((c) => c.id === lastCueId);

  // Build adjacent cue context
  const contextStart = Math.max(0, firstCueIndex - adjacent_context_cues);
  const contextEnd = Math.min(allCues.length - 1, lastCueIndex + adjacent_context_cues);
  const contextCues = allCues.slice(contextStart, contextEnd + 1);

  // Build timing section
  const sceneDurationMs = plan.end_ms - plan.start_ms;
  const sceneDurationSec = (sceneDurationMs / 1000).toFixed(2);

  // Build assets section
  const assetsIndex = await readJson(resolve(runDirResolved, "assets", "index.json")).catch(() => ({ schema_version: 1, assets: [] }));
  const sceneAssets = (plan.assets ?? []).map((aid) => {
    const entry = assetsIndex.assets?.find((a) => a.id === aid);
    return entry ? `- **${aid}**: \`${entry.path}\` (${entry.media_type}, SHA-256: ${entry.sha256})` : `- **${aid}**: unresolved`;
  }).join("\n");

  // Build allowed skill references
  const allowedRefs = [blueprint];
  if (rule) allowedRefs.push(rule);
  if (categoryRef) allowedRefs.push(categoryRef);
  // Always include core references
  allowedRefs.push("skill://hyperframes-motion/adapters/gsap.md");
  const allowedSection = allowedRefs.map((r) => `- ${r}`).join("\n");

  // Build commands section
  const commands = [
    `(cd ${relative(rootResolved, sceneDir)} && npx --no-install hyperframes lint . --json)`,
    `(cd ${relative(rootResolved, sceneDir)} && npx --no-install hyperframes validate . --json)`,
    `(cd ${relative(rootResolved, sceneDir)} && npx --no-install hyperframes inspect . --json --strict)`,
    `node scripts/check-preview.mjs --run runs/${relative(runDirResolved, resolve(rootResolved, "runs"))} --scene ${sceneId} --initial-only`,
    `(cd ${relative(rootResolved, sceneDir)} && npx --no-install hyperframes render . --workers 1 --quality high --output ${sceneId}.mp4)`,
    `node scripts/validate-outputs.mjs --run runs/${relative(runDirResolved, resolve(rootResolved, "runs"))} --scene ${sceneId}`,
  ].join("\n");

  // Build the context document
  const context = `# Scene Execution Contract

## Timing
- Scene: ${sceneId}
- Start: ${plan.start_ms}ms
- End: ${plan.end_ms}ms
- Duration: ${sceneDurationSec}s (${sceneDurationMs}ms)
- Frame count: output profile ${outputProfile.width}x${outputProfile.height} @ ${outputProfile.fps}fps

## Copy Context
${contextCues.map((c) => `${c.id}: [${c.start_ms}-${c.end_ms}ms] ${c.text}` + (cueIds.includes(c.id) ? " ← this scene" : " ← adjacent context")).join("\n")}

## Visual Bible
Full story: ${visualBible.full_story_summary}
Canvas: ${outputProfile.width}x${outputProfile.height}, background ${visualBible.canvas.background}
Palette: primary=${visualBible.palette.primary}, accent=${visualBible.palette.accent}, text=${visualBible.palette.text}, surface=${visualBible.palette.surface}
Typography: heading=${visualBible.typography.heading_font}, body=${visualBible.typography.body_font}, fallback=${visualBible.typography.fallback_fonts.join(", ")}
Layout: grid=${visualBible.layout.grid}, margins=[${visualBible.layout.margins.top},${visualBible.layout.margins.right},${visualBible.layout.margins.bottom},${visualBible.layout.margins.left}], density=${visualBible.layout.density}, hierarchy=${visualBible.layout.hierarchy}
Motion: easing=${visualBible.motion.easing}, density=${visualBible.motion.density}, entry=${visualBible.motion.entry}, exit=${visualBible.motion.exit}, transition=${visualBible.motion.transition_family}
Asset treatment: images=${visualBible.asset_treatment.images}, icons=${visualBible.asset_treatment.icons}, logos=${visualBible.asset_treatment.logos}, code=${visualBible.asset_treatment.code}
Forbidden patterns: ${visualBible.forbidden_patterns.join(", ")}
Scene goal: ${plan.goal}
Scene visual: ${plan.visual}
Beats:
${plan.beats.map((b) => `  - ${b.at_ms}ms: ${b.action}`).join("\n")}
Selected blueprint: ${blueprint}
${rule ? `Selected rule: ${rule}` : "No rule selected"}
Derived category: ${categoryRef ?? "unknown"}

## Assets
${sceneAssets || "(none)"}

## Allowed Skill References
${allowedSection}

## Commands
${commands}

## Result Contract
Write self-report to ${sceneId}/status.json before and after building.
Yield: mode, status (passed|repairable|failed), summary, scene_id, artifact_path, validation_path, error_code, error_summary.
`;

  await mkdir(sceneDir, { recursive: true });
  await writeFile(resolve(sceneDir, "scene-context.md"), context, "utf8");

  const contextHash = createHash("sha256").update(context).digest("hex");

  return { context, contextHash };
}

async function main() {
  const { parseArgs, requiredOption, printJson, failCli } = await import("./lib/cli.mjs");
  const { options } = parseArgs();
  const runArg = requiredOption(options, "run");
  const sceneId = requiredOption(options, "scene");
  const root = resolve(".");
  const runDir = resolveRunDir(root, runArg);

  const { contextHash } = await compileSceneContext({ root, runDir, sceneId });
  printJson({ scene_id: sceneId, context_sha256: contextHash });
}

const isMain = process.argv[1] && (process.argv[1].endsWith("compile-scene-context.mjs") || process.argv[1].endsWith("compile-scene-context"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
