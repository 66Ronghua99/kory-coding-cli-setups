import { resolve } from "node:path";
import { readJson, sha256File, writeJsonAtomic } from "./lib/atomic.mjs";
import { resolveRunDir, resolveSceneDir } from "./lib/paths.mjs";
import { loadOutputProfile, loadWorkflowConfig } from "./lib/config.mjs";
import { loadManifest, writeManifest, transitionScene, updateRunStatus } from "./lib/manifest.mjs";
import { validateSceneOutput } from "./validate-outputs.mjs";
import { parseArgs, requiredOption, option, printJson, failCli } from "./lib/cli.mjs";

export async function recordSceneResult({ root, runDir, result }) {
  const rootResolved = resolve(root);
  const runDirResolved = resolveRunDir(rootResolved, runDir);
  const manifest = await loadManifest(runDirResolved);
  const workflow = await loadWorkflowConfig(rootResolved);

  const { mode, status: reportedStatus, scene_id, artifact_path, error_code, error_summary, task_id, session_id, model_selector } = result;

  if (mode === "model-smoke") {
    // Model smoke — just record evidence, no manifest changes
    return { recorded: true, mode: "model-smoke" };
  }

  if (!scene_id) throw new Error("scene_id required in scene mode");
  const scene = manifest.scenes.find((s) => s.id === scene_id);
  if (!scene) throw new Error(`Scene ${scene_id} not in manifest`);

  // Update metadata
  if (task_id) scene.task_id = task_id;
  if (session_id) scene.session_id = session_id;
  if (model_selector) scene.model_selector = model_selector;

  // Classify failure
  const providerErrors = ["PROVIDER", "AUTHENTICATION", "QUOTA", "CAPACITY", "NETWORK", "RATE_LIMIT"];
  let failureClass = null;
  if (reportedStatus === "failed" || reportedStatus === "repairable") {
    if (error_code && providerErrors.some((p) => error_code.toUpperCase().includes(p))) {
      failureClass = "provider";
    } else if (error_code) {
      failureClass = "technical";
    }
  }

  // Run deterministic validation
  if (artifact_path) {
    const validResult = await validateSceneOutput({
      root: rootResolved, runDir, sceneId: scene_id, mediaOnly: false,
    });

    const sceneDir = resolveSceneDir(runDirResolved, scene_id);
    const validationPath = `scenes/${scene_id}/validation.json`;
    await writeJsonAtomic(resolve(runDirResolved, validationPath), validResult);

    scene.validation_path = validationPath;
    scene.validation_ok = validResult.ok;

    if (validResult.ok) {
      const artifactHash = await sha256File(resolve(runDirResolved, artifact_path));
      scene.artifact_sha256 = artifactHash;
      scene.artifact_path = artifact_path;

      transitionScene(manifest, scene_id, "passed");
    } else if (failureClass === "provider") {
      scene.failure_class = failureClass;
      scene.failure_code = error_code ?? "PROVIDER_FAILURE";
      scene.failure_summary = error_summary ?? "Provider failure";
      transitionScene(manifest, scene_id, "failed");
      updateRunStatus(manifest, "paused");
    } else {
      scene.failure_class = failureClass;
      scene.failure_code = error_code;
      scene.failure_summary = error_summary;

      const maxRepairs = workflow.max_repairs_per_scene ?? 2;
      if ((scene.repair_attempts ?? 0) < maxRepairs) {
        transitionScene(manifest, scene_id, "repairable");
      } else {
        transitionScene(manifest, scene_id, "failed");
      }
    }
  } else {
    // No artifact produced
    if (failureClass === "provider") {
      scene.failure_class = failureClass;
      scene.failure_code = error_code ?? "PROVIDER_FAILURE";
      scene.failure_summary = error_summary ?? "Provider failure";
      transitionScene(manifest, scene_id, "failed");
      updateRunStatus(manifest, "paused");
    } else {
      scene.failure_class = failureClass ?? "technical";
      scene.failure_code = error_code;
      scene.failure_summary = error_summary;

      const maxRepairs = workflow.max_repairs_per_scene ?? 2;
      if ((scene.repair_attempts ?? 0) < maxRepairs) {
        transitionScene(manifest, scene_id, "repairable");
      } else {
        transitionScene(manifest, scene_id, "failed");
      }
    }
  }

  // Update run status
  const allPassed = manifest.scenes.every((s) => s.status === "passed");
  const anyFailed = manifest.scenes.some((s) => s.status === "failed");
  const anyBuilding = manifest.scenes.some((s) => ["planned", "dispatched", "building", "validating", "repairable"].includes(s.status));

  if (allPassed && !anyBuilding) {
    updateRunStatus(manifest, "ready");
  } else if (!anyBuilding && anyFailed) {
    // Some failed, some passed — leave as building for manual review or use plan-resume
    if (manifest.status !== "paused") {
      updateRunStatus(manifest, "ready");
    }
  } else {
    updateRunStatus(manifest, "building");
  }

  await writeManifest(runDirResolved, manifest);

  return {
    recorded: true,
    scene_id,
    new_status: scene.status,
  };
}

async function main() {
  const { options } = parseArgs();
  const runArg = requiredOption(options, "run");
  const resultFile = requiredOption(options, "result-file");

  const result = JSON.parse(await (await import("node:fs/promises")).readFile(resultFile, "utf8"));
  const output = await recordSceneResult({ root: ".", runDir: runArg, result });
  printJson(output);
}

const isMain = process.argv[1] && (process.argv[1].endsWith("record-scene-result.mjs") || process.argv[1].endsWith("record-scene-result"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
