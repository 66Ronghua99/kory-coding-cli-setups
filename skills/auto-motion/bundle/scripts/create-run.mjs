import { mkdir, copyFile, writeFile, readFile } from "node:fs/promises";
import { resolve, relative, dirname } from "node:path";
import { createHash } from "node:crypto";
import { parseArgs, requiredOption, option, printJson, failCli } from "./lib/cli.mjs";
import { resolveRunDir, resolveInside, defaultHomeDir } from "./lib/paths.mjs";
import { loadPreferences, loadYamlFile } from "./lib/config.mjs";
import { sha256File, sha256Json, writeJsonAtomic, writeTextAtomic, readJson } from "./lib/atomic.mjs";

async function mergePreferences(globalItems, projectItems, defaults) {
  return { ...defaults, ...globalItems, ...projectItems };
}

export async function createRun({ root, inputPath, runId = null, homeDir = null }) {
  const rootResolved = resolve(root);
  const hd = homeDir ?? defaultHomeDir();
  const inputResolved = resolve(rootResolved, inputPath);

  // Hash the input
  const inputSha256 = await sha256File(inputResolved);
  const inputFirst8 = inputSha256.slice(0, 8);

  // Generate run ID if not provided
  const dateStr = new Date().toISOString().replace(/[-:]/g, "").replace(/\..+/, "Z");
  const actualRunId = runId ?? `run-${dateStr}-${inputFirst8}`;

  // Build run directory path
  const runsRoot = resolve(rootResolved, "runs");
  const runDir = resolve(runsRoot, actualRunId);

  // Reject existing directory
  try {
    await readFile(resolve(runDir, "scene-manifest.json"));
    throw new Error(`Run already exists: ${actualRunId}`);
  } catch (e) {
    if (e.message.startsWith("Run already exists")) throw e;
    // Directory doesn't exist or is empty — proceed
  }

  await mkdir(runDir, { recursive: true });
  await mkdir(resolve(runDir, "scenes"), { recursive: true });
  await mkdir(resolve(runDir, "assets", "files"), { recursive: true });
  await mkdir(resolve(runDir, "feedback"), { recursive: true });

  // Copy input transcript
  const inputRel = relative(rootResolved, inputResolved);
  const transcriptDest = resolve(runDir, "transcription.json");
  // The transcript will be parsed by parse-srt; for now just note the input
  const inputText = await readFile(inputResolved, "utf8");
  const srtHash = createHash("sha256").update(inputText).digest("hex");

  // Snapshot preferences
  const globalPrefsPath = resolve(hd, ".omp", "agent", "auto-motion", "preferences.yml");
  let globalPrefs;
  try {
    globalPrefs = await loadYamlFile(globalPrefsPath);
  } catch {
    globalPrefs = { version: 1, items: {} };
  }
  if (!globalPrefs) globalPrefs = { version: 1, items: {} };

  const projectPrefs = await loadPreferences(rootResolved);
  const globalItems = globalPrefs.items ?? {};
  const projectItems = projectPrefs.items ?? {};
  const effective = { ...globalItems, ...projectItems };

  const snapshot = {
    version: 1,
    captured_at: new Date().toISOString(),
    global: globalItems,
    global_sha256: sha256Json(globalItems),
    project: projectItems,
    project_sha256: sha256Json(projectItems),
    effective: effective,
    effective_sha256: sha256Json(effective),
  };
  await writeTextAtomic(resolve(runDir, "preferences.snapshot.yml"),
    `version: 1\ncaptured_at: ${snapshot.captured_at}\n` +
    `global_sha256: ${snapshot.global_sha256}\n` +
    `project_sha256: ${snapshot.project_sha256}\n` +
    `effective_sha256: ${snapshot.effective_sha256}\n`
  );

  // Write empty asset index
  await writeJsonAtomic(resolve(runDir, "assets", "index.json"), {
    schema_version: 1,
    assets: [],
  });

  return {
    run_id: actualRunId,
    run_dir: relative(rootResolved, runDir),
    input_path: inputRel,
    input_sha256: srtHash,
  };
}

async function main() {
  const { options } = parseArgs();
  const inputPath = requiredOption(options, "input");
  const runId = option(options, "run-id");
  const homeDir = option(options, "home-dir");
  const root = resolve(".");

  const result = await createRun({ root, inputPath, runId, homeDir });
  printJson(result);
}

const isMain = process.argv[1] && (process.argv[1].endsWith("create-run.mjs") || process.argv[1].endsWith("create-run"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
