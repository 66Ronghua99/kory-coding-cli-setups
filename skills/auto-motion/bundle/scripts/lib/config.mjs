import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import YAML from "yaml";
import { readJson, sha256Json } from "./atomic.mjs";
import { resolveInside } from "./paths.mjs";

export async function loadYamlFile(filePath) {
  try {
    return YAML.parse(await readFile(filePath, "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") return undefined;
    throw error;
  }
}

export async function loadWorkflowConfig(root) {
  const raw = await loadYamlFile(resolve(root, ".omp", "auto-motion", "workflow.yml"));
  if (!raw) throw new Error("Workflow config not found");
  return {
    max_repairs_per_scene: raw.max_repairs_per_scene ?? 2,
    adjacent_context_cues: raw.adjacent_context_cues ?? 1,
  };
}

export async function loadOutputProfile(root) {
  const raw = await loadYamlFile(resolve(root, ".omp", "auto-motion", "output-profile.yml"));
  if (!raw) throw new Error("Output profile not found");
  return {
    width: raw.width ?? 1080,
    height: raw.height ?? 1440,
    fps: raw.fps ?? 30,
    audio: raw.audio ?? "none",
    publish: raw.publish ?? "final.mp4",
  };
}

export async function loadPreferences(root) {
  const raw = await loadYamlFile(resolve(root, ".omp", "auto-motion", "preferences.yml"));
  return raw ?? { version: 1, items: {} };
}

export async function loadOmpConfig(root) {
  const raw = await loadYamlFile(resolve(root, ".omp", "config.yml"));
  if (!raw) throw new Error("OMP config not found");
  return raw;
}

export async function loadOmpModelConfig(root, profileName) {
  const path = resolve(root, ".omp", "model-profiles", `${profileName}.yml`);
  const raw = await loadYamlFile(path);
  if (!raw) throw new Error(`Model profile not found: ${profileName}`);
  return raw;
}
