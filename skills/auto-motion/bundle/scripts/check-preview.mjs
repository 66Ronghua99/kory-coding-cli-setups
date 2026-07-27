import { resolve } from "node:path";
import { readFile } from "node:fs/promises";
import { readJson } from "./lib/atomic.mjs";
import { resolveRunDir, resolveSceneDir } from "./lib/paths.mjs";
import { runProcess } from "./lib/process.mjs";
import { parseArgs, requiredOption, option, printJson, failCli } from "./lib/cli.mjs";

async function findFreePort() {
  const net = await import("node:net");
  return new Promise((resolvePort, reject) => {
    const server = net.createServer();
    server.listen(0, "127.0.0.1", () => {
      const port = server.address().port;
      server.close(() => resolvePort(port));
    });
    server.on("error", reject);
  });
}

export async function checkPreview({ root, runDir, sceneId, initialOnly = false }) {
  const rootResolved = resolve(root);
  const runDirResolved = resolveRunDir(rootResolved, runDir);
  const sceneDir = resolveSceneDir(runDirResolved, sceneId);

  // Check if this is a repair (skip preview for repairs when initialOnly)
  if (initialOnly) {
    try {
      const manifest = await readJson(resolve(runDirResolved, "scene-manifest.json"));
      const scene = manifest.scenes?.find((s) => s.id === sceneId);
      if (scene && scene.repair_attempts > 0) {
        return { ok: true, skipped: true, reason: "repair_attempts > 0" };
      }
    } catch {
      // manifest doesn't exist yet — proceed
    }
  }

  const port = await findFreePort();

  let preview;
  try {
    // Start preview
    preview = await runProcess("npx", [
      "--no-install", "hyperframes", "preview", ".",
      "--background", "--no-open", `--port`, String(port),
    ], { cwd: sceneDir, timeoutMs: 30_000 });

    // Verify preview is running
    const status = await runProcess("npx", [
      "--no-install", "hyperframes", "preview", ".", "--status",
    ], { cwd: sceneDir, timeoutMs: 10_000, check: true });

    return { ok: true, skipped: false, port };
  } finally {
    // Always stop preview
    try {
      await runProcess("npx", [
        "--no-install", "hyperframes", "preview", ".", "--stop",
      ], { cwd: sceneDir, timeoutMs: 10_000 });
    } catch {
      // best effort teardown
    }
  }
}

async function main() {
  const { options } = parseArgs();
  const runArg = requiredOption(options, "run");
  const sceneId = requiredOption(options, "scene");
  const initialOnly = options["initial-only"] !== undefined;

  try {
    const result = await checkPreview({ root: ".", runDir: runArg, sceneId, initialOnly });
    printJson(result);
  } catch (e) {
    failCli(e);
  }
}

const isMain = process.argv[1] && (process.argv[1].endsWith("check-preview.mjs") || process.argv[1].endsWith("check-preview"));
if (isMain) {
  main();
}
