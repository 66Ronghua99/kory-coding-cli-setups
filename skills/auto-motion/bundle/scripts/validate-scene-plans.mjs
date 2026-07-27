import { resolve } from "node:path";
import { readFile } from "node:fs/promises";
import { readJson, sha256Json } from "./lib/atomic.mjs";
import { resolveRunDir, resolveSceneDir } from "./lib/paths.mjs";
import { loadOutputProfile } from "./lib/config.mjs";
import { parseArgs, option, requiredOption, printJson, failCli } from "./lib/cli.mjs";

import { frameAtMs } from "./parse-srt.mjs";

export { frameAtMs };

/**
 * Validate scene plans against a parsed transcript.
 *
 * @param {object} opts
 * @param {string} opts.root
 * @param {object} opts.transcript - parsed transcript JSON
 * @param {Array} opts.plans - array of scene plan objects
 * @param {object} opts.outputProfile
 * @param {object} opts.assetsIndex
 * @param {boolean} opts.requireResolvedAssets
 * @returns {object} validation result
 */
export async function validateScenePlans({ root, transcript, plans, outputProfile, assetsIndex, requireResolvedAssets }) {
  const catalogPath = resolve(root, ".omp", "skills", "hyperframes-motion", "catalog.json");
  const catalog = JSON.parse(await readFile(catalogPath, "utf8"));

  const { fps } = outputProfile;
  const originMs = transcript.timeline_origin_ms;
  const endMs = transcript.timeline_end_ms;
  const cues = transcript.cues;

  const totalFrames = frameAtMs(endMs, originMs, fps);
  const errors = [];
  const assetIds = [];

  // Build cue lookup
  const cueMap = new Map(cues.map((c) => [c.id, c]));

  const scenes = [];
  let nextExpectedCueIndex = 0;

  for (let i = 0; i < plans.length; i++) {
    const plan = plans[i];
    const sceneErrors = [];
    const sceneId = plan.id;

    // Validate recipe_refs
    const [blueprint, rule] = plan.recipe_refs;
    if (!catalog.blueprints[blueprint]) {
      sceneErrors.push(`Unknown blueprint: ${blueprint}`);
    }
    if (rule && !rule.startsWith("skill://hyperframes-motion/rules/")) {
      sceneErrors.push(`Second recipe must be a rule: ${rule}`);
    }

    // Derive category
    let categoryRef = null;
    if (catalog.blueprints[blueprint]) {
      categoryRef = catalog.blueprints[blueprint];
    }

    // Validate subtitle_ids are consecutive from the expected position
    const firstCueId = plan.subtitle_ids[0];
    const expectedFirstCueId = cues[nextExpectedCueIndex]?.id;
    if (firstCueId !== expectedFirstCueId) {
      sceneErrors.push(`Expected first cue ${expectedFirstCueId}, got ${firstCueId}`);
    }

    // All subtitle_ids must exist and be consecutive
    for (let j = 0; j < plan.subtitle_ids.length; j++) {
      const sid = plan.subtitle_ids[j];
      if (!cueMap.has(sid)) {
        sceneErrors.push(`Unknown subtitle ID: ${sid}`);
      }
      if (j > 0 && sid !== plan.subtitle_ids[j - 1] + 1) {
        sceneErrors.push(`Non-consecutive subtitle IDs: ${plan.subtitle_ids[j - 1]} -> ${sid}`);
      }
    }

    // start_ms must equal the first cue's start
    const firstCue = cueMap.get(firstCueId);
    if (firstCue && plan.start_ms !== firstCue.start_ms) {
      sceneErrors.push(`start_ms ${plan.start_ms} doesn't match cue ${firstCueId} start ${firstCue.start_ms}`);
    }

    // Non-final scene: end_ms must equal next scene's first cue start
    if (i < plans.length - 1) {
      const nextPlan = plans[i + 1];
      const nextFirstCueId = nextPlan.subtitle_ids[0];
      const nextFirstCue = cueMap.get(nextFirstCueId);
      if (nextFirstCue && plan.end_ms !== nextFirstCue.start_ms) {
        sceneErrors.push(`end_ms ${plan.end_ms} must equal next scene start ${nextFirstCue.start_ms}`);
      }
    } else {
      // Final scene: end_ms must equal the final cue's end
      const lastCue = cues[cues.length - 1];
      if (plan.end_ms !== lastCue.end_ms) {
        sceneErrors.push(`Final scene end_ms ${plan.end_ms} must equal last cue end ${lastCue.end_ms}`);
      }
    }

    // Validate beats: ordered, in range, and at_ms < scene duration (not equal)
    const sceneDuration = plan.end_ms - plan.start_ms;
    for (let j = 0; j < plan.beats.length; j++) {
      if (j > 0 && plan.beats[j].at_ms < plan.beats[j - 1].at_ms) {
        sceneErrors.push(`Beats not ordered: beat ${j} at ${plan.beats[j].at_ms}ms < beat ${j - 1} at ${plan.beats[j - 1].at_ms}ms`);
      }
      if (plan.beats[j].at_ms < 0) {
        sceneErrors.push(`Beat ${j} at_ms ${plan.beats[j].at_ms} is negative`);
      }
      if (plan.beats[j].at_ms >= sceneDuration) {
        sceneErrors.push(`Beat ${j} at_ms ${plan.beats[j].at_ms} >= scene duration ${sceneDuration}`);
      }
    }

    // Track declared assets
    for (const aid of plan.assets) {
      if (!assetIds.includes(aid)) assetIds.push(aid);
    }

    // Assets must be syntactic IDs
    for (const aid of plan.assets) {
      if (!/^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/.test(aid)) {
        sceneErrors.push(`Invalid asset ID syntax: ${aid}`);
      }
    }

    // Check gaps: every gap between consecutive scenes should be 0
    nextExpectedCueIndex += plan.subtitle_ids.length;

    // Compute frames
    const startFrame = frameAtMs(plan.start_ms, originMs, fps);
    const endFrame = frameAtMs(plan.end_ms, originMs, fps);
    const frameCount = endFrame - startFrame;

    if (frameCount <= 0) {
      sceneErrors.push(`Non-positive frame count: ${frameCount}`);
    }

    if (sceneErrors.length > 0) {
      errors.push({ scene: sceneId, errors: sceneErrors });
    }

    scenes.push({
      id: sceneId,
      start_frame: startFrame,
      end_frame: endFrame,
      frame_count: frameCount,
      category_ref: categoryRef,
    });
  }

  // Check all cues are covered
  if (nextExpectedCueIndex !== cues.length) {
    errors.push({ scene: null, errors: [`Not all cues covered: expected ${cues.length}, covered ${nextExpectedCueIndex}`] });
  }

  // Asset resolution
  if (requireResolvedAssets) {
    const resolvedIds = new Set((assetsIndex?.assets ?? []).map((a) => a.id));
    for (const aid of assetIds) {
      if (!resolvedIds.has(aid)) {
        errors.push({ scene: null, errors: [`Unresolved asset: ${aid}`] });
      }
    }
  }

  if (errors.length > 0) {
    const errorMsg = errors.map((e) => `${e.scene ?? "global"}: ${e.errors.join("; ")}`).join("\n");
    throw new Error(`Scene plan validation failed:\n${errorMsg}`);
  }

  return {
    origin_ms: originMs,
    end_ms: endMs,
    total_frames: totalFrames,
    asset_ids: assetIds,
    scenes,
  };
}

async function main() {
  const { options } = parseArgs();
  const runArg = requiredOption(options, "run");
  const allowUnresolved = options["allow-unresolved-assets"] !== undefined;
  const root = resolve(".");

  const runDir = resolveRunDir(root, runArg);

  // Load transcript
  const transcript = await readJson(resolve(runDir, "transcription.json"));

  // Load output profile
  const outputProfile = await loadOutputProfile(root);

  // Load all scene plans
  const scenesDir = resolve(runDir, "scenes");
  const { readdir, stat } = await import("node:fs/promises");
  const entries = await readdir(scenesDir);
  const plans = [];
  for (const entry of entries.sort()) {
    const dirPath = resolve(scenesDir, entry);
    try {
      const s = await stat(resolve(dirPath, "scene-plan.json"));
      if (!s.isFile()) continue;
      plans.push(await readJson(resolve(dirPath, "scene-plan.json")));
    } catch {
      // skip entries without scene-plan.json
    }
  }

  // Load assets index for resolved validation
  let assetsIndex = null;
  if (!allowUnresolved) {
    try {
      assetsIndex = await readJson(resolve(runDir, "assets", "index.json"));
    } catch {
      assetsIndex = { schema_version: 1, assets: [] };
    }
  }

  const result = await validateScenePlans({
    root,
    transcript,
    plans,
    outputProfile,
    assetsIndex,
    requireResolvedAssets: !allowUnresolved,
  });

  printJson(result);
}

const isMain = process.argv[1] && (process.argv[1].endsWith("validate-scene-plans.mjs") || process.argv[1].endsWith("validate-scene-plans"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
