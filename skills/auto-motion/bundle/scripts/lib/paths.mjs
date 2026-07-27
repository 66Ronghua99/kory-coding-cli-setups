import { isAbsolute, relative, resolve, sep, normalize, join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { homedir } from "node:os";

function assertInside(base, candidate, label) {
  const root = resolve(base);
  const target = resolve(candidate);
  const rel = relative(root, target);
  if (rel === "" || (!rel.startsWith(`..${sep}`) && rel !== ".." && !isAbsolute(rel))) return target;
  throw new Error(`${label} is outside allowed root: ${candidate}`);
}

export function resolveInside(base, candidate, label = "Path") {
  if (typeof candidate !== "string" || candidate.length === 0) throw new Error(`${label} is empty`);
  if (isAbsolute(candidate)) throw new Error(`${label} must be relative: ${candidate}`);
  if (candidate.split(/[\\/]+/).includes("..")) throw new Error(`${label} contains traversal: ${candidate}`);
  return assertInside(base, join(base, candidate), label);
}

export function validateSceneId(sceneId) {
  if (!/^scene-\d{3}$/.test(sceneId)) throw new Error(`Invalid scene ID: ${sceneId}`);
  return sceneId;
}

export function resolveRunDir(root, runArg) {
  if (typeof runArg !== "string" || runArg.length === 0) throw new Error("Run directory is empty");
  const rootResolved = resolve(root);
  const runsRoot = resolve(rootResolved, "runs");
  const candidate = isAbsolute(runArg)
    ? resolve(runArg)
    : runArg === "runs" || runArg.startsWith(`runs${sep}`) || runArg.startsWith("runs/")
      ? resolve(rootResolved, runArg)
      : resolve(runsRoot, runArg);
  assertInside(runsRoot, candidate, "Run directory");
  if (relative(runsRoot, candidate).split(sep).includes("..")) throw new Error(`Invalid run path: ${runArg}`);
  return candidate;
}

export function resolveSceneDir(runDir, sceneId) {
  validateSceneId(sceneId);
  return assertInside(resolve(runDir, "scenes"), resolve(runDir, "scenes", sceneId), "Scene directory");
}

export function relativePosix(root, target) {
  const value = relative(resolve(root), resolve(target)).split(sep).join("/");
  if (value === "" || value.startsWith("../") || value === "..") throw new Error(`Path is outside root: ${target}`);
  return value;
}

export function resolveSkillUri(root, uri) {
  if (typeof uri !== "string" || !uri.startsWith("skill://")) throw new Error(`Unsupported skill URI: ${uri}`);
  const body = uri.slice("skill://".length);
  const slash = body.indexOf("/");
  const skill = slash < 0 ? body : body.slice(0, slash);
  const rest = slash < 0 ? "SKILL.md" : body.slice(slash + 1);
  if (!/^[A-Za-z0-9][A-Za-z0-9_-]*$/.test(skill)) throw new Error(`Invalid skill name: ${skill}`);
  return resolveInside(resolve(root, ".omp", "skills", skill), rest, `Skill reference ${uri}`);
}

export function projectRootFrom(fileUrl) {
  return resolve(dirname(fileURLToPath(fileUrl)), "..", "..");
}

export function defaultHomeDir() {
  return homedir();
}

export { assertInside };
