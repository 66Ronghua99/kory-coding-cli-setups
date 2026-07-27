import { mkdir, copyFile, readFile, writeFile } from "node:fs/promises";
import { resolve, relative, basename } from "node:path";
import { createHash } from "node:crypto";
import { readJson, writeJsonAtomic, sha256Json } from "./lib/atomic.mjs";
import { resolveRunDir, resolveSceneDir } from "./lib/paths.mjs";
import { loadOutputProfile } from "./lib/config.mjs";
import { compileSceneContext } from "./compile-scene-context.mjs";
import { validateContract } from "./lib/contracts.mjs";
import { frameAtMs } from "./parse-srt.mjs";

const ROOT = resolve(".");

export async function prepareRun({ root, runDir, sceneIds, preserveComposition = false }) {
  const rootResolved = resolve(root);
  const runDirResolved = resolveRunDir(rootResolved, runDir);
  const scenesDir = resolve(runDirResolved, "scenes");

  const outputProfile = await loadOutputProfile(rootResolved);
  const profileHash = sha256Json(outputProfile);

  const existingManifest = await readJson(resolve(runDirResolved, "scene-manifest.json")).catch(() => null);
  const existingScenes = existingManifest?.scenes ?? [];

  const runInput = await readJson(resolve(runDirResolved, "transcription.json"));
  const visualBible = await readJson(resolve(runDirResolved, "visual-bible.json"));
  const visualBibleHash = sha256Json(visualBible);

  const assetsIndex = await readJson(resolve(runDirResolved, "assets", "index.json")).catch(() => ({ schema_version: 1, assets: [] }));
  const assetsHash = sha256Json(assetsIndex);

  const prefsSnap = await readFile(resolve(runDirResolved, "preferences.snapshot.yml"), "utf8");
  const prefsHash = createHash("sha256").update(prefsSnap).digest("hex");

  const catalog = JSON.parse(await readFile(resolve(rootResolved, ".omp", "skills", "hyperframes-motion", "catalog.json"), "utf8"));
  const originMs = runInput.timeline_origin_ms;
  const { fps } = outputProfile;

  const templateDir = resolve(rootResolved, "templates", "scene");
  const templateHtml = await readFile(resolve(templateDir, "index.html"), "utf8");
  const vendorGsapPath = resolve(rootResolved, "node_modules", "gsap", "dist", "gsap.min.js");

  const scenes = [];

  for (const sceneId of (sceneIds ?? [])) {
    const sceneDir = resolveSceneDir(runDirResolved, sceneId);
    await mkdir(sceneDir, { recursive: true });

    const plan = await readJson(resolve(sceneDir, "scene-plan.json"));
    const durationMs = plan.end_ms - plan.start_ms;
    const durationSec = (durationMs / 1000).toFixed(2);

    // Compute frame values
    const startFrame = frameAtMs(plan.start_ms, originMs, fps);
    const endFrame = frameAtMs(plan.end_ms, originMs, fps);
    const frameCount = endFrame - startFrame;

    // Derive category from blueprint
    const blueprint = plan.recipe_refs[0];
    const categoryRef = catalog.blueprints[blueprint] ?? "";

    const existing = existingScenes.find((s) => s.id === sceneId);

    if (!preserveComposition) {
      const html = templateHtml
        .replace(/__WIDTH__/g, String(outputProfile.width))
        .replace(/__HEIGHT__/g, String(outputProfile.height))
        .replace(/__DURATION_SECONDS__/g, durationSec);
      await writeFile(resolve(sceneDir, "index.html"), html, "utf8");
      await copyFile(resolve(templateDir, "hyperframes.json"), resolve(sceneDir, "hyperframes.json"));
    }

    await mkdir(resolve(sceneDir, "vendor"), { recursive: true });
    await copyFile(vendorGsapPath, resolve(sceneDir, "vendor", "gsap.min.js"));

    const { contextHash } = await compileSceneContext({ root: rootResolved, runDir: runDirResolved, sceneId });

    const planStr = JSON.stringify(plan);
    const packetHash = createHash("sha256").update(planStr).digest("hex");

    const status = {
      schema_version: 1,
      scene_id: sceneId,
      reported_status: "building",
      artifact_path: null,
      error_code: null,
      error_summary: null,
      updated_at: new Date().toISOString(),
    };
    await writeJsonAtomic(resolve(sceneDir, "status.json"), status);

    scenes.push({
      id: sceneId,
      start_frame: startFrame,
      end_frame: endFrame,
      frame_count: frameCount,
      category_ref: categoryRef,
      packet_sha256: packetHash,
      context_sha256: contextHash,
      model_selector: "deepseek/deepseek-v4-pro",
      task_id: null,
      session_id: null,
      status: "planned",
      repair_attempts: existing?.repair_attempts ?? 0,
      revision: existing?.revision ?? 1,
      status_path: `scenes/${sceneId}/status.json`,
      artifact_path: null,
      artifact_sha256: null,
      validation_path: null,
      validation_sha256: null,
      validation_ok: null,
      failure_class: null,
      failure_code: null,
      failure_summary: null,
    });
  }

  const manifest = {
    schema_version: 1,
    run_id: basename(runDirResolved),
    created_at: existingManifest?.created_at ?? new Date().toISOString(),
    input_path: runInput.source_path,
    input_sha256: runInput.source_sha256,
    visual_bible_sha256: visualBibleHash,
    output_profile: outputProfile,
    output_profile_sha256: profileHash,
    preferences_snapshot_sha256: prefsHash,
    assets_index_sha256: assetsHash,
    status: "planning",
    assembly_status: "pending",
    publication_status: "pending",
    final_path: null,
    final_sha256: null,
    scenes,
  };

  await validateContract(rootResolved, "scene-manifest", manifest);
  await writeJsonAtomic(resolve(runDirResolved, "scene-manifest.json"), manifest);

  return manifest;
}

async function main() {
  const { parseArgs, requiredOption, option, printJson, failCli } = await import("./lib/cli.mjs");
  const { options, positionals } = parseArgs();
  const runArg = requiredOption(options, "run");
  const sceneIdsStr = positionals[0] || option(options, "scenes");
  const preserveComposition = options["preserve-composition"] !== undefined;

  if (!sceneIdsStr) {
    failCli(new Error("Scene IDs required as positional argument or --scenes"));
    return;
  }

  const sceneIds = sceneIdsStr.split(",").map((s) => s.trim());
  const result = await prepareRun({ root: ROOT, runDir: runArg, sceneIds, preserveComposition });
  printJson(result);
}

const isMain = process.argv[1] && (process.argv[1].endsWith("prepare-run.mjs") || process.argv[1].endsWith("prepare-run"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
