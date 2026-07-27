import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { readJson } from "./atomic.mjs";
import { writeJsonAtomic } from "./atomic.mjs";

const ALLOWED_TRANSITIONS = {
  planned: ["dispatched"],
  dispatched: ["building", "failed"],
  building: ["validating", "failed"],
  validating: ["passed", "repairable", "failed"],
  repairable: ["dispatched", "failed"],
  passed: ["planned"],
  failed: ["planned"],
};

export async function loadManifest(runDir) {
  return readJson(resolve(runDir, "scene-manifest.json"));
}

export async function writeManifest(runDir, manifest) {
  await writeJsonAtomic(resolve(runDir, "scene-manifest.json"), manifest);
}

export function transitionScene(manifest, sceneId, nextState, patch = {}) {
  const scene = manifest.scenes.find((s) => s.id === sceneId);
  if (!scene) throw new Error(`Scene not found: ${sceneId}`);

  const allowed = ALLOWED_TRANSITIONS[scene.status];
  if (!allowed || !allowed.includes(nextState)) {
    throw new Error(`Invalid transition: ${scene.status} -> ${nextState} for ${sceneId}`);
  }

  // Increment repair_attempts on repairable -> dispatched
  if (scene.status === "repairable" && nextState === "dispatched") {
    scene.repair_attempts = (scene.repair_attempts ?? 0) + 1;
  }

  scene.status = nextState;
  Object.assign(scene, patch);

  return scene;
}

export function updateRunStatus(manifest, newStatus) {
  manifest.status = newStatus;
}
