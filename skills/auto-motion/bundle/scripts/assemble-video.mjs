import { mkdir, copyFile, writeFile, readFile, rename, open } from "node:fs/promises";
import { resolve, dirname, relative } from "node:path";
import { createHash } from "node:crypto";
import { readJson, sha256File, writeJsonAtomic } from "./lib/atomic.mjs";
import { resolveRunDir } from "./lib/paths.mjs";
import { loadOutputProfile } from "./lib/config.mjs";
import { loadManifest, writeManifest, updateRunStatus } from "./lib/manifest.mjs";
import { runProcess } from "./lib/process.mjs";
import { validateSceneMedia } from "./lib/media.mjs";
import { parseArgs, requiredOption, printJson, failCli } from "./lib/cli.mjs";

export async function assembleVideo({ root, runDir }) {
  const rootResolved = resolve(root);
  const runDirResolved = resolveRunDir(rootResolved, runDir);
  const manifest = await loadManifest(runDirResolved);
  const outputProfile = await loadOutputProfile(rootResolved);

  // Gate: all scenes must be passed
  const allPassed = manifest.scenes.every((s) => s.status === "passed");
  if (!allPassed) {
    const failed = manifest.scenes.filter((s) => s.status !== "passed").map((s) => s.id);
    throw new Error(`Not all scenes passed. Failed scenes: ${failed.join(", ")}`);
  }

  // Gate: all scenes must have artifact paths
  for (const scene of manifest.scenes) {
    if (!scene.artifact_path) {
      throw new Error(`Scene ${scene.id} has no artifact`);
    }
  }

  // Compute total frames
  const totalFrames = manifest.scenes.reduce((sum, s) => sum + s.frame_count, 0);

  // Create concat list
  const assemblyDir = resolve(runDirResolved, ".assembly");
  await mkdir(assemblyDir, { recursive: true });
  const concatPath = resolve(assemblyDir, "concat.txt");

  const entries = [];
  for (const scene of manifest.scenes) {
    const artPath = resolve(runDirResolved, scene.artifact_path);
    entries.push(`file '${artPath}'`);
  }
  await writeFile(concatPath, entries.join("\n") + "\n", "utf8");

  updateRunStatus(manifest, "assembling");
  manifest.assembly_status = "pending";
  await writeManifest(runDirResolved, manifest);

  // Run FFmpeg concat
  const tmpMp4 = resolve(runDirResolved, "final.tmp.mp4");
  const scaleFilter = `scale=${outputProfile.width}:${outputProfile.height}:flags=lanczos`;
  const fpsFilter = `fps=${outputProfile.fps}`;

  await runProcess("ffmpeg", [
    "-f", "concat", "-safe", "0", "-i", concatPath,
    "-an", "-vf", `${scaleFilter},${fpsFilter}`,
    "-frames:v", String(totalFrames),
    "-c:v", "libx264", "-pix_fmt", "yuv420p",
    "-crf", "18", "-preset", "medium", "-movflags", "+faststart",
    tmpMp4,
  ], { timeoutMs: 300_000, check: true });

  // Validate the assembled file
  const validResult = await validateSceneMedia({
    mediaPath: tmpMp4,
    expectedWidth: outputProfile.width,
    expectedHeight: outputProfile.height,
    expectedFps: outputProfile.fps,
    expectedFrames: totalFrames,
  });

  if (!validResult.ok) {
    manifest.assembly_status = "failed";
    await writeManifest(runDirResolved, manifest);
    throw new Error(`Assembly validation failed: ${JSON.stringify(validResult.errors)}`);
  }

  // Move to run final
  const runFinal = resolve(runDirResolved, "final.mp4");
  await rename(tmpMp4, runFinal);

  // Atomic publication: copy to sibling temp, fsync, rename
  const publishPath = resolve(rootResolved, outputProfile.publish);
  const publishDir = dirname(publishPath);
  await mkdir(publishDir, { recursive: true });
  const publishTmp = resolve(publishDir, `.${outputProfile.publish}.${process.pid}.tmp`);

  await copyFile(runFinal, publishTmp);
  // fsync the parent directory
  const dirFd = await open(publishDir, "r");
  await dirFd.sync();
  await dirFd.close();
  await rename(publishTmp, publishPath);

  // Generate review map
  const reviewMap = {
    schema_version: 1,
    run_id: manifest.run_id,
    total_frames: totalFrames,
    scenes: manifest.scenes.map((s) => ({
      scene_id: s.id,
      start_frame: s.start_frame,
      end_frame: s.end_frame,
      start_ms: 0, // Will be populated by caller from transcript
      end_ms: 0,
      subtitle_ids: [], // populated by caller
      revision: s.revision,
      artifact_path: s.artifact_path,
      artifact_sha256: s.artifact_sha256,
    })),
  };
  await writeJsonAtomic(resolve(runDirResolved, "review-map.json"), reviewMap);

  const finalHash = await sha256File(runFinal);

  manifest.assembly_status = "passed";
  manifest.publication_status = "passed";
  manifest.final_path = outputProfile.publish;
  manifest.final_sha256 = finalHash;
  updateRunStatus(manifest, "published");

  await writeManifest(runDirResolved, manifest);

  return {
    run_final: relative(rootResolved, runFinal),
    published_final: outputProfile.publish,
    review_map: "review-map.json",
    total_frames: totalFrames,
    final_sha256: finalHash,
  };
}

async function main() {
  const { options } = parseArgs();
  const runArg = requiredOption(options, "run");
  const result = await assembleVideo({ root: ".", runDir: runArg });
  printJson(result);
}

const isMain = process.argv[1] && (process.argv[1].endsWith("assemble-video.mjs") || process.argv[1].endsWith("assemble-video"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
