import { resolve } from "node:path";
import { readJson } from "./lib/atomic.mjs";
import { resolveRunDir } from "./lib/paths.mjs";
import { parseArgs, requiredOption, option, printJson, failCli } from "./lib/cli.mjs";

export function parseReviewTimecode(value) {
  if (/^\d+$/.test(value)) return parseInt(value, 10);
  const reHMS = /^(\d{2}):(\d{2}):(\d{2})[.,](\d{3})$/;
  const reMS = /^(\d{2}):(\d{2})[.,](\d{3})$/;
  let m = value.match(reHMS);
  if (m) return (((parseInt(m[1]) * 60 + parseInt(m[2])) * 60 + parseInt(m[3])) * 1000) + parseInt(m[4]);
  m = value.match(reMS);
  if (m) return ((parseInt(m[1]) * 60 + parseInt(m[2])) * 1000) + parseInt(m[3]);
  throw new Error(`Invalid timecode: ${value}`);
}

function norm(text) { return text.toLowerCase().replace(/\s+/g, " ").trim(); }

export function locateFeedback({ reviewMap, transcript, scenePlans, query }) {
  // 1. Exact scene ID
  if (/^scene-\d{3}$/.test(query)) {
    const inMap = reviewMap.find((s) => s.scene_id === query);
    const inPlans = scenePlans.find((p) => p.id === query);
    if (inMap || inPlans) return { kind: "exact_scene_id", scene_ids: [query], candidates: [] };
  }

  // 2. Timecode
  try {
    const tcMs = parseReviewTimecode(query);
    for (const s of reviewMap) {
      if (tcMs >= s.start_ms && tcMs < s.end_ms) return { kind: "timecode", scene_ids: [s.scene_id], candidates: [] };
    }
  } catch {}

  // 3. Subtitle text / goal substring
  const nq = norm(query);
  const matching = [];
  const ids = new Set();
  for (const plan of scenePlans) {
    const cueText = plan.subtitle_ids.map((sid) => transcript.cues?.find((c) => c.id === sid)).filter(Boolean).map((c) => norm(c.text)).join(" ");
    if (cueText.includes(nq) || norm(plan.goal).includes(nq) || norm(plan.visual).includes(nq)) {
      if (!ids.has(plan.id)) { matching.push(plan.id); ids.add(plan.id); }
    }
  }
  if (matching.length === 1) return { kind: "subtitle_match", scene_ids: matching, candidates: [] };
  if (matching.length > 1) {
    return { kind: "ambiguous", scene_ids: [], candidates: matching.map((id) => {
      const p = scenePlans.find((x) => x.id === id);
      return { scene_id: id, goal: p?.goal ?? "", cues: (p?.subtitle_ids ?? []).map((sid) => transcript.cues?.find((c) => c.id === sid)?.text ?? "") };
    })};
  }

  // 4. Semantic fallback
  return {
    kind: "semantic", scene_ids: [],
    candidates: scenePlans.map((p) => ({ scene_id: p.id, goal: p.goal, cues: p.subtitle_ids.map((sid) => transcript.cues?.find((c) => c.id === sid)?.text ?? "") })),
  };
}

async function main() {
  const { options, positionals } = parseArgs();
  const runArg = requiredOption(options, "run");
  const query = positionals[0] || option(options, "query");
  if (!query) { failCli(new Error("Query required")); return; }

  const runDir = resolveRunDir(".", runArg);
  const reviewMap = await readJson(resolve(runDir, "review-map.json")).catch(() => ({ scenes: [] }));
  const transcript = await readJson(resolve(runDir, "transcription.json"));
  const manifest = await readJson(resolve(runDir, "scene-manifest.json"));
  const scenePlans = [];
  for (const s of manifest.scenes) {
    try { scenePlans.push(await readJson(resolve(runDir, "scenes", s.id, "scene-plan.json"))); } catch {}
  }
  printJson(locateFeedback({ reviewMap: reviewMap.scenes, transcript, scenePlans, query }));
}

const isMain = process.argv[1] && (process.argv[1].endsWith("locate-feedback.mjs") || process.argv[1].endsWith("locate-feedback"));
if (isMain) main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
