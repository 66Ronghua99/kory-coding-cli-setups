import { execFileSync } from "node:child_process";
import { readFile, access, readdir } from "node:fs/promises";
import { resolve } from "node:path";
import { commandExists } from "./lib/process.mjs";
import { parseArgs, option, printJson } from "./lib/cli.mjs";
import { readJson } from "./lib/atomic.mjs";
import { checkSkillGraph } from "./check-skill-graph.mjs";

export async function preflight({ root, ompBin = "omp", sceneModel = null }) {
  const rootResolved = resolve(root);
  const checks = [];
  const warnings = [];
  const errors = [];

  function check(name, ok, detail = "") {
    checks.push({ name, ok, detail });
    if (!ok) errors.push(name);
  }

  function warn(name, ok, detail = "") {
    if (!ok) warnings.push({ name, detail });
  }

  // Node major >= 22
  const nodeMajor = parseInt(process.version.slice(1).split(".")[0], 10);
  check("node>=22", nodeMajor >= 22, `node ${process.version}`);

  // FFmpeg
  const ffmpegOk = await commandExists("ffmpeg");
  check("ffmpeg", ffmpegOk, ffmpegOk ? "found" : "not found");

  // FFprobe
  const ffprobeOk = await commandExists("ffprobe");
  check("ffprobe", ffprobeOk, ffprobeOk ? "found" : "not found");

  // HyperFrames
  try {
    const hfResult = execFileSync("npx", ["--no-install", "hyperframes", "doctor", "--json"], {
      cwd: rootResolved, timeout: 60_000, encoding: "utf8",
    });
    const hf = JSON.parse(hfResult);
    check("hyperframes-doctor", hf.ok === true, `version=${hf.version ?? "?"}`);
  } catch (e) {
    check("hyperframes-doctor", false, e.message);
  }

  // transcription.srt readable
  try {
    await readFile(resolve(rootResolved, "transcription.srt"));
    check("transcription.srt", true, "readable");
  } catch {
    check("transcription.srt", false, "not readable");
  }

  // runs/ writable
  try {
    await access(resolve(rootResolved, "runs"));
    check("runs-writable", true);
  } catch {
    try {
      const { mkdir } = await import("node:fs/promises");
      await mkdir(resolve(rootResolved, "runs"), { recursive: true });
      check("runs-writable", true, "created");
    } catch (e) {
      check("runs-writable", false, e.message);
    }
  }

  // Schemas, config, skills, catalog
  try {
    const graphResult = await checkSkillGraph(rootResolved);
    check("skill-graph", graphResult.ok, `${graphResult.skills.length} skills, ${graphResult.agents.length} agents, ${graphResult.references} refs`);
  } catch (e) {
    check("skill-graph", false, e.message);
  }

  // OMP executable
  try {
    execFileSync(ompBin, ["--version"], { timeout: 10_000 });
    check("omp-executable", true, ompBin);
  } catch {
    check("omp-executable", false, `${ompBin} not found`);
  }

  // DEEPSEEK_API_KEY
  const dsKey = process.env.DEEPSEEK_API_KEY;
  check("DEEPSEEK_API_KEY", !!dsKey, dsKey ? "present" : "missing");

  // MINIMAX_API_KEY
  const mmKey = process.env.MINIMAX_API_KEY;
  const activeProfile = sceneModel ?? process.env.ACTIVE_SCENE_MODEL ?? "";
  if (activeProfile && activeProfile.toLowerCase().includes("minimax")) {
    check("MINIMAX_API_KEY", !!mmKey, mmKey ? "present" : "missing");
  } else if (!mmKey) {
    warn("MINIMAX_API_KEY", false, "missing — generated-image sourcing disabled");
  }

  // OMP model catalog
  try {
    const ompResult = execFileSync(ompBin, ["model", "list", "--json"], {
      timeout: 15_000, encoding: "utf8",
    });
    const models = JSON.parse(ompResult);
    const requiredModels = ["deepseek/deepseek-v4-pro", "deepseek/deepseek-v4-flash"];
    for (const m of requiredModels) {
      const found = Array.isArray(models) ? models.some((x) => x.id === m) : (models[m] !== undefined);
      check(`model:${m}`, found, found ? "available" : "not found");
    }
  } catch (e) {
    check("model-catalog", false, e.message);
  }

  const ok = errors.length === 0;

  return { ok, checks, warnings, errors };
}

async function main() {
  const { options } = parseArgs();
  const ompBin = option(options, "omp-bin", "omp");
  const sceneModel = option(options, "scene-model");

  const result = await preflight({ root: ".", ompBin, sceneModel });
  printJson(result);
  if (!result.ok) process.exit(1);
}

const isMain = process.argv[1] && (process.argv[1].endsWith("preflight.mjs") || process.argv[1].endsWith("preflight"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
