import { resolve } from "node:path";
import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { readJson, sha256Json, sha256File } from "./lib/atomic.mjs";
import { resolveRunDir } from "./lib/paths.mjs";
import { loadOutputProfile } from "./lib/config.mjs";
import { loadManifest } from "./lib/manifest.mjs";
import { probeMedia } from "./lib/media.mjs";
import { parseArgs, requiredOption, printJson, failCli } from "./lib/cli.mjs";

/**
 * Plan resume work: determine which scenes to reuse, rebuild, or reassemble.
 *
 * Invalidation matrix:
 * - input changed → reject run (must create new run)
 * - Visual Bible/profile changed → rebuild every scene
 * - packet/context/referenced asset changed → rebuild only affected scene
 * - artifact missing/hash/probe bad → rebuild only affected scene
 * - all scenes valid, no final → reassemble only
 * - all scenes and final valid → no work
 */
export async function planResume({ root, runDir }) {
  const rootResolved = resolve(root);
  const runDirResolved = resolveRunDir(rootResolved, runDir);

  const manifest = await loadManifest(runDirResolved);
  const outputProfile = await loadOutputProfile(rootResolved);

  // Check input hasn't changed
  const runInput = await readJson(resolve(runDirResolved, "transcription.json"));
  const currentInputHash = runInput.source_sha256;
  if (currentInputHash !== manifest.input_sha256) {
    throw new Error("INPUT_CHANGED_CREATE_NEW_RUN: Transcript hash differs. Create a new run instead of resuming.");
  }

  // Check Visual Bible and profile
  let vbChanged = false;
  try {
    const vb = await readJson(resolve(runDirResolved, "visual-bible.json"));
    const vbHash = sha256Json(vb);
    if (vbHash !== manifest.visual_bible_sha256) vbChanged = true;
  } catch {
    vbChanged = true;
  }

  const profileHash = sha256Json(outputProfile);
  if (profileHash !== manifest.output_profile_sha256) vbChanged = true;

  if (vbChanged) {
    // Rebuild everything
    return {
      reuse: [],
      rebuild: manifest.scenes.map((s) => s.id),
      reassemble: true,
      reasons: Object.fromEntries(manifest.scenes.map((s) => [s.id, ["Visual Bible or profile changed"]])),
    };
  }

  // Asset index check
  let assetsHash = manifest.assets_index_sha256;
  try {
    const assetsIndex = await readJson(resolve(runDirResolved, "assets", "index.json"));
    assetsHash = sha256Json(assetsIndex);
  } catch {
    // assets missing, but we don't rebuild for that — individual asset checks catch it
  }

  const reuse = [];
  const rebuild = [];
  const reasons = {};

  for (const scene of manifest.scenes) {
    const sceneReasons = [];
    const sceneDir = resolve(runDirResolved, "scenes", scene.id);

    // Check packet hash (scene plan)
    try {
      const plan = await readJson(resolve(sceneDir, "scene-plan.json"));
      const planHash = sha256Json(plan);
      if (planHash !== scene.packet_sha256) {
        sceneReasons.push("Scene plan (packet) changed");
      }
    } catch {
      sceneReasons.push("Scene plan missing");
    }

    // Check context hash
    try {
      const ctx = await readFile(resolve(sceneDir, "scene-context.md"), "utf8");
      const ctxHash = createHash("sha256").update(ctx).digest("hex");
      if (ctxHash !== scene.context_sha256) {
        sceneReasons.push("Context changed");
      }
    } catch {
      sceneReasons.push("Context missing");
    }

    // Check artifact
    if (scene.artifact_path) {
      try {
        const artPath = resolve(runDirResolved, scene.artifact_path);
        const artHash = await sha256File(artPath);
        if (artHash !== scene.artifact_sha256) {
          sceneReasons.push("Artifact hash changed");
        }

        // Probe media
        const info = await probeMedia(artPath);
        if (info.width !== outputProfile.width || info.height !== outputProfile.height) {
          sceneReasons.push("Media dimensions changed");
        }
      } catch {
        sceneReasons.push("Artifact missing or unreadable");
      }
    } else {
      sceneReasons.push("No artifact path");
    }

    // Check validation
    if (!scene.validation_ok) {
      sceneReasons.push("Validation not OK");
    }

    if (sceneReasons.length > 0) {
      rebuild.push(scene.id);
      reasons[scene.id] = sceneReasons;
    } else {
      reuse.push(scene.id);
    }
  }

  // Determine reassemble
  const allValid = rebuild.length === 0;
  let reassemble = false;
  if (allValid) {
    const finalPath = resolve(rootResolved, manifest.final_path ?? "");
    try {
      const finalHash = await sha256File(finalPath);
      if (finalHash !== manifest.final_sha256) {
        reassemble = true;
      }
    } catch {
      reassemble = true; // final missing
    }
  }

  return { reuse, rebuild, reassemble, reasons };
}

async function main() {
  const { options } = parseArgs();
  const runArg = requiredOption(options, "run");

  const result = await planResume({ root: ".", runDir: runArg });
  printJson(result);
}

const isMain = process.argv[1] && (process.argv[1].endsWith("plan-resume.mjs") || process.argv[1].endsWith("plan-resume"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
