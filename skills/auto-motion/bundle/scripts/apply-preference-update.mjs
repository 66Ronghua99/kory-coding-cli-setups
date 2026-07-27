import { mkdir, writeFile, readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { readJson, writeJsonAtomic, writeTextAtomic } from "./lib/atomic.mjs";
import { resolveRunDir, defaultHomeDir } from "./lib/paths.mjs";
import { parseArgs, requiredOption, option, printJson, failCli } from "./lib/cli.mjs";
import YAML from "yaml";
import { validateContract } from "./lib/contracts.mjs";

async function loadYamlFile(path) {
  try {
    return YAML.parse(await readFile(path, "utf8")) ?? { version: 1, items: {} };
  } catch {
    return { version: 1, items: {} };
  }
}

function setNested(obj, key, value) {
  const parts = key.split(".");
  let current = obj;
  for (let i = 0; i < parts.length - 1; i++) {
    if (!current[parts[i]] || typeof current[parts[i]] !== "object") {
      current[parts[i]] = {};
    }
    current = current[parts[i]];
  }
  const changed = current[parts[parts.length - 1]] !== value;
  current[parts[parts.length - 1]] = value;
  return changed;
}

function removeNested(obj, key) {
  const parts = key.split(".");
  let current = obj;
  for (let i = 0; i < parts.length - 1; i++) {
    if (!current[parts[i]]) return false;
    current = current[parts[i]];
  }
  const existed = parts[parts.length - 1] in current;
  delete current[parts[parts.length - 1]];
  return existed;
}

export async function applyPreferenceUpdate({ root, runDir, updatePath, homeDir }) {
  const rootResolved = resolve(root);
  const runDirResolved = resolveRunDir(rootResolved, runDir);
  const hd = homeDir ?? defaultHomeDir();

  // Gate: accepted-feedback.json must exist
  try {
    const accepted = await readJson(resolve(runDirResolved, "accepted-feedback.json"));
    if (!accepted.accepted) throw new Error("Feedback not accepted");
  } catch (e) {
    if (e.message === "Feedback not accepted") throw e;
    throw new Error("No accepted-feedback.json found. Preferences require explicit acceptance.");
  }

  const update = await readJson(updatePath);
  await validateContract(rootResolved, "preference-update", update);

  const globalPath = resolve(hd, ".omp", "agent", "auto-motion", "preferences.yml");
  const projectPath = resolve(rootResolved, ".omp", "auto-motion", "preferences.yml");

  const globalPrefs = await loadYamlFile(globalPath);
  const projectPrefs = await loadYamlFile(projectPath);

  const globalChanges = [];
  const projectChanges = [];

  // Apply global set
  if (update.global?.set) {
    for (const [key, value] of Object.entries(update.global.set)) {
      if (setNested(globalPrefs.items ?? (globalPrefs.items = {}), key, value)) {
        globalChanges.push(`set ${key}=${JSON.stringify(value)}`);
      }
    }
  }

  // Apply global remove
  if (update.global?.remove) {
    for (const key of update.global.remove) {
      if (removeNested(globalPrefs.items ?? (globalPrefs.items = {}), key)) {
        globalChanges.push(`remove ${key}`);
      }
    }
  }

  // Apply project set
  if (update.project?.set) {
    for (const [key, value] of Object.entries(update.project.set)) {
      if (setNested(projectPrefs.items ?? (projectPrefs.items = {}), key, value)) {
        projectChanges.push(`set ${key}=${JSON.stringify(value)}`);
      }
    }
  }

  // Apply project remove
  if (update.project?.remove) {
    for (const key of update.project.remove) {
      if (removeNested(projectPrefs.items ?? (projectPrefs.items = {}), key)) {
        projectChanges.push(`remove ${key}`);
      }
    }
  }

  // Write global (only if there are changes)
  if (globalChanges.length > 0) {
    await mkdir(resolve(hd, ".omp", "agent", "auto-motion"), { recursive: true });
    await writeFile(globalPath, YAML.stringify(globalPrefs), "utf8");
  }

  // Write project (only if there are changes)
  if (projectChanges.length > 0) {
    await writeFile(projectPath, YAML.stringify(projectPrefs), "utf8");
  }

  // Store run_only
  const runOnly = update.run_only ?? [];
  if (runOnly.length > 0) {
    const feedbackDir = resolve(runDirResolved, "feedback");
    await mkdir(feedbackDir, { recursive: true });
    await writeJsonAtomic(resolve(feedbackDir, "preferences.json"), {
      schema_version: 1,
      instructions: runOnly,
    });
  }

  return {
    global_changes: globalChanges,
    project_changes: projectChanges,
    run_only: runOnly,
  };
}

async function main() {
  const { options } = parseArgs();
  const runArg = requiredOption(options, "run");
  const updatePath = requiredOption(options, "update");
  const homeDir = option(options, "home-dir");

  const result = await applyPreferenceUpdate({
    root: ".", runDir: runArg, updatePath, homeDir,
  });
  printJson(result);
}

const isMain = process.argv[1] && (process.argv[1].endsWith("apply-preference-update.mjs") || process.argv[1].endsWith("apply-preference-update"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
