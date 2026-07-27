import { resolve } from "node:path";
import { readJson, sha256File } from "./lib/atomic.mjs";
import { resolveRunDir, resolveSceneDir } from "./lib/paths.mjs";
import { loadOutputProfile } from "./lib/config.mjs";
import { validateSceneMedia } from "./lib/media.mjs";
import { loadManifest } from "./lib/manifest.mjs";
import { runProcess } from "./lib/process.mjs";
import { parseArgs, requiredOption, option, printJson, failCli } from "./lib/cli.mjs";

export async function validateSceneOutput({ root, runDir, sceneId, mediaOnly = false }) {
  const rootResolved = resolve(root);
  const runDirResolved = resolveRunDir(rootResolved, runDir);
  const sceneDir = resolveSceneDir(runDirResolved, sceneId);
  const outputProfile = await loadOutputProfile(rootResolved);
  const manifest = await loadManifest(runDirResolved);
  const scene = manifest.scenes?.find((s) => s.id === sceneId);
  if (!scene) throw new Error(`Scene ${sceneId} not found in manifest`);

  const errors = [];

  // HyperFrames deterministic checks (skip if mediaOnly)
  if (!mediaOnly) {
    const checks = [
      { cmd: ["lint", ".", "--json"], label: "lint" },
      { cmd: ["validate", ".", "--json"], label: "validate" },
      { cmd: ["inspect", ".", "--json", "--strict"], label: "inspect" },
    ];

    for (const check of checks) {
      try {
        const result = await runProcess("npx", ["--no-install", "hyperframes", ...check.cmd], {
          cwd: sceneDir, timeoutMs: 60_000,
        });
        if (result.code !== 0) {
          errors.push({ code: `HF_${check.label.toUpperCase()}`, detail: result.stderr.trim() || result.stdout.trim() });
        }
      } catch (e) {
        errors.push({ code: `HF_${check.label.toUpperCase()}`, detail: e.message });
      }
    }
  }

  // Media check
  const mp4Path = resolve(sceneDir, `${sceneId}.mp4`);
  let mediaOk = false;
  let mediaMeta = {};

  try {
    const mediaResult = await validateSceneMedia({
      mediaPath: mp4Path,
      expectedWidth: outputProfile.width,
      expectedHeight: outputProfile.height,
      expectedFps: outputProfile.fps,
      expectedFrames: scene.frame_count,
    });

    if (!mediaResult.ok) {
      errors.push(...mediaResult.errors);
    } else {
      mediaOk = true;
    }
    mediaMeta = mediaResult.meta;
  } catch (e) {
    errors.push({ code: "MEDIA_PROBE", detail: e.message });
  }

  return {
    ok: errors.length === 0,
    errors,
    media_ok: mediaOk,
    media: mediaMeta,
  };
}

async function main() {
  const { options } = parseArgs();
  const runArg = requiredOption(options, "run");
  const sceneId = requiredOption(options, "scene");
  const mediaOnly = options["media-only"] !== undefined;

  const result = await validateSceneOutput({
    root: ".", runDir: runArg, sceneId, mediaOnly,
  });
  printJson(result);
  if (!result.ok) process.exit(1);
}

const isMain = process.argv[1] && (process.argv[1].endsWith("validate-outputs.mjs") || process.argv[1].endsWith("validate-outputs"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
