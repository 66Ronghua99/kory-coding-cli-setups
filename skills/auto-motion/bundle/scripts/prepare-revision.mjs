import { mkdir, copyFile, writeFile, readFile } from "node:fs/promises";
import { resolve, relative } from "node:path";
import { readJson, writeJsonAtomic, sha256File } from "./lib/atomic.mjs";
import { resolveRunDir, resolveSceneDir } from "./lib/paths.mjs";
import { loadManifest, writeManifest, transitionScene } from "./lib/manifest.mjs";
import { parseArgs, requiredOption, option, printJson, failCli } from "./lib/cli.mjs";

export async function prepareRevision({ root, runDir, sceneIds, feedback }) {
  const rootResolved = resolve(root);
  const runDirResolved = resolveRunDir(rootResolved, runDir);
  const manifest = await loadManifest(runDirResolved);

  const archiveBase = resolve(runDirResolved, "revisions");

  for (const sceneId of sceneIds) {
    const scene = manifest.scenes.find((s) => s.id === sceneId);
    if (!scene) throw new Error(`Scene ${sceneId} not found`);

    const currentRev = scene.revision ?? 1;
    const revDir = resolve(archiveBase, `v${String(currentRev).padStart(3, "0")}`, sceneId);
    await mkdir(revDir, { recursive: true });

    const sceneDir = resolveSceneDir(runDirResolved, sceneId);

    // Archive current version
    const filesToArchive = ["scene-plan.json", "scene-context.md", "index.html", "status.json"];
    for (const f of filesToArchive) {
      try {
        await copyFile(resolve(sceneDir, f), resolve(revDir, f));
      } catch {
        // file may not exist
      }
    }

    // Archive MP4 if present
    const mp4Path = resolve(sceneDir, `${sceneId}.mp4`);
    try {
      await copyFile(mp4Path, resolve(revDir, `${sceneId}.mp4`));
    } catch {
      // MP4 may not exist
    }

    // Archive validation if present
    try {
      await copyFile(resolve(sceneDir, "validation.json"), resolve(revDir, "validation.json"));
    } catch {
      // may not exist
    }

    // Write feedback
    await writeFile(resolve(revDir, "feedback.md"), feedback, "utf8");

    // Update manifest
    transitionScene(manifest, sceneId, "planned");
    scene.revision = currentRev + 1;
    scene.artifact_path = null;
    scene.artifact_sha256 = null;
    scene.validation_path = null;
    scene.validation_sha256 = null;
    scene.validation_ok = null;
    scene.failure_class = null;
    scene.failure_code = null;
    scene.failure_summary = null;
  }

  await writeManifest(runDirResolved, manifest);

  return {
    revised: sceneIds,
    revision: sceneIds.map((id) => manifest.scenes.find((s) => s.id === id).revision),
  };
}

async function main() {
  const { options, positionals } = parseArgs();
  const runArg = requiredOption(options, "run");
  const sceneIdsStr = positionals[0] || option(options, "scenes");
  const feedbackFile = option(options, "feedback-file");

  if (!sceneIdsStr) {
    failCli(new Error("Scene IDs required"));
    return;
  }

  const sceneIds = sceneIdsStr.split(",").map((s) => s.trim());
  const feedback = feedbackFile ? await readFile(feedbackFile, "utf8") : "Review feedback";

  const result = await prepareRevision({ root: ".", runDir: runArg, sceneIds, feedback });
  printJson(result);
}

const isMain = process.argv[1] && (process.argv[1].endsWith("prepare-revision.mjs") || process.argv[1].endsWith("prepare-revision"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
