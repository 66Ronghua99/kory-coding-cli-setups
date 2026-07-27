import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { createHash } from "node:crypto";
import { readJson, sha256Json } from "./lib/atomic.mjs";
import { resolveRunDir, resolveSceneDir } from "./lib/paths.mjs";
import { loadOutputProfile } from "./lib/config.mjs";
import { parseArgs, requiredOption, printJson, failCli } from "./lib/cli.mjs";

export async function loadSceneContext({ root, runId, sceneId }) {
  const rootResolved = resolve(root);
  const runDir = resolveRunDir(rootResolved, runId);
  const sceneDir = resolveSceneDir(runDir, sceneId);

  // Read context file
  const context = await readFile(resolve(sceneDir, "scene-context.md"), "utf8");

  // Recompute and verify hash
  const plan = await readJson(resolve(sceneDir, "scene-plan.json"));
  const outputProfile = await loadOutputProfile(rootResolved);
  const catalog = JSON.parse(await readFile(resolve(rootResolved, ".omp", "skills", "hyperframes-motion", "catalog.json"), "utf8"));
  const assetsIndex = await readJson(resolve(runDir, "assets", "index.json")).catch(() => ({ schema_version: 1, assets: [] }));
  const visualBible = await readJson(resolve(runDir, "visual-bible.json"));

  const planHash = sha256Json(plan);
  const profileHash = sha256Json(outputProfile);
  const assetsHash = sha256Json(assetsIndex);
  const vbHash = sha256Json(visualBible);
  const catalogHash = sha256Json(catalog);

  const contextHash = createHash("sha256").update(context).digest("hex");

  const manifest = await readJson(resolve(runDir, "scene-manifest.json"));
  const sceneManifest = manifest.scenes?.find((s) => s.id === sceneId);

  if (sceneManifest && sceneManifest.context_sha256 !== contextHash) {
    throw new Error(`Context hash mismatch for ${sceneId}: stored=${sceneManifest.context_sha256}, computed=${contextHash}. The context may have been modified.`);
  }

  // Print the context
  process.stdout.write(context);

  return {
    sceneId,
    contextHash,
    planHash,
    profileHash,
    assetsHash,
    vbHash,
    catalogHash,
  };
}

async function main() {
  const { options } = parseArgs();
  const runId = requiredOption(options, "run");
  const sceneId = requiredOption(options, "scene");

  // Don't print JSON — just output the context. The caller expects the markdown.
  await loadSceneContext({ root: ".", runId, sceneId });
}

const isMain = process.argv[1] && (process.argv[1].endsWith("load-scene-context.mjs") || process.argv[1].endsWith("load-scene-context"));
if (isMain) {
  main().catch((e) => {
    process.stderr.write(`${e.message}\n`);
    process.exit(1);
  });
}
