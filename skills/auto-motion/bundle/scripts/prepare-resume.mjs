import { resolve } from "node:path";
import { readJson, writeJsonAtomic } from "./lib/atomic.mjs";
import { resolveRunDir } from "./lib/paths.mjs";
import { loadManifest, writeManifest, transitionScene, updateRunStatus } from "./lib/manifest.mjs";
import { planResume } from "./plan-resume.mjs";
import { prepareRun } from "./prepare-run.mjs";
import { parseArgs, requiredOption, printJson, failCli } from "./lib/cli.mjs";

export async function prepareResume({ root, runDir }) {
  const rootResolved = resolve(root);
  const runDirResolved = resolveRunDir(rootResolved, runDir);

  const plan = await planResume({ root: rootResolved, runDir });
  await writeJsonAtomic(resolve(runDirResolved, "resume-plan.json"), plan);

  const manifest = await loadManifest(runDirResolved);

  if (plan.rebuild.length === 0 && !plan.reassemble) {
    return { resumed: false, reason: "all_scenes_valid" };
  }

  if (plan.rebuild.length === 0 && plan.reassemble) {
    updateRunStatus(manifest, "assembling");
    await writeManifest(runDirResolved, manifest);
    return { resumed: true, rebuild: [], reassemble_only: true };
  }

  if (plan.rebuild.length > 0) {
    await prepareRun({
      root: rootResolved, runDir,
      sceneIds: plan.rebuild, preserveComposition: true,
    });

    for (const sceneId of plan.rebuild) {
      const scene = manifest.scenes.find((s) => s.id === sceneId);
      if (scene) {
        scene.artifact_path = null;
        scene.artifact_sha256 = null;
        scene.validation_path = null;
        scene.validation_sha256 = null;
        scene.validation_ok = null;
        scene.failure_class = null;
        scene.failure_code = null;
        scene.failure_summary = null;
        transitionScene(manifest, sceneId, "planned");
      }
    }
  }

  updateRunStatus(manifest, "building");
  await writeManifest(runDirResolved, manifest);

  return {
    resumed: true, rebuild: plan.rebuild, reuse: plan.reuse,
    reassemble: plan.reassemble || plan.rebuild.length > 0, reasons: plan.reasons,
  };
}

async function main() {
  const { options } = parseArgs();
  const runArg = requiredOption(options, "run");
  const result = await prepareResume({ root: ".", runDir: runArg });
  printJson(result);
}

const isMain = process.argv[1] && (process.argv[1].endsWith("prepare-resume.mjs") || process.argv[1].endsWith("prepare-resume"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
