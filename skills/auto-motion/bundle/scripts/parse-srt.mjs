import { readFile, writeFile, mkdir } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { createHash } from "node:crypto";
import { parseArgs, requiredOption, option, printJson, failCli } from "./lib/cli.mjs";
import { sha256Json } from "./lib/atomic.mjs";

/**
 * Parse an SRT timestamp (HH:MM:SS,mmm or HH:MM:SS.mmm) to integer milliseconds.
 */
export function parseTimestamp(value) {
  const re = /^(\d{2}):(\d{2}):(\d{2})[.,](\d{3})$/;
  const match = value.match(re);
  if (!match) throw new Error(`Invalid SRT timestamp: ${value}`);
  const hours = parseInt(match[1], 10);
  const minutes = parseInt(match[2], 10);
  const seconds = parseInt(match[3], 10);
  const milliseconds = parseInt(match[4], 10);
  return (((hours * 60 + minutes) * 60 + seconds) * 1000) + milliseconds;
}

/**
 * Parse SRT text into a Transcript object.
 */
export function parseSrt(text, sourcePath, sourceSha256) {
  const cues = [];
  const lines = text.replace(/\r\n/g, "\n").split("\n");
  let i = 0;
  const seenIds = new Set();

  while (i < lines.length) {
    // Skip empty lines
    if (lines[i].trim() === "") { i++; continue; }

    // Parse cue ID
    const idStr = lines[i].trim();
    const id = parseInt(idStr, 10);
    if (isNaN(id) || id <= 0) throw new Error(`Invalid cue ID at line ${i + 1}: ${idStr}`);
    if (seenIds.has(id)) throw new Error(`Duplicate cue ID: ${id}`);
    seenIds.add(id);
    i++;

    // Parse timestamp line
    if (i >= lines.length) throw new Error(`Missing timestamp for cue ${id}`);
    const tsLine = lines[i].trim();
    const tsMatch = tsLine.match(/^(\d{2}:\d{2}:\d{2}[.,]\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2}[.,]\d{3})$/);
    if (!tsMatch) throw new Error(`Invalid timestamp line for cue ${id}: ${tsLine}`);
    const startMs = parseTimestamp(tsMatch[1]);
    const endMs = parseTimestamp(tsMatch[2]);
    if (endMs <= startMs) throw new Error(`Cue ${id}: end <= start`);
    i++;

    // Parse text lines (until blank line or EOF)
    const textLines = [];
    while (i < lines.length && lines[i].trim() !== "") {
      textLines.push(lines[i].trim());
      i++;
    }
    if (textLines.length === 0) throw new Error(`Cue ${id}: missing text`);
    // Skip the blank separator if present
    if (i < lines.length && lines[i].trim() === "") i++;

    cues.push({ id, start_ms: startMs, end_ms: endMs, text: textLines.join("\n") });
  }

  if (cues.length === 0) throw new Error("Transcript is empty");

  // Validate monotonic IDs and no overlaps
  for (let j = 1; j < cues.length; j++) {
    if (cues[j].id <= cues[j - 1].id) {
      throw new Error(`Non-monotonic cue IDs: ${cues[j - 1].id} -> ${cues[j].id}`);
    }
    if (cues[j].start_ms < cues[j - 1].end_ms) {
      throw new Error(`Overlapping cues: ${cues[j - 1].id} ends at ${cues[j - 1].end_ms}ms but cue ${cues[j].id} starts at ${cues[j].start_ms}ms`);
    }
  }

  const originMs = cues[0].start_ms;
  const endMs = cues[cues.length - 1].end_ms;

  return {
    schema_version: 1,
    source_path: sourcePath,
    source_sha256: sourceSha256,
    timeline_origin_ms: originMs,
    timeline_end_ms: endMs,
    cues,
  };
}

/**
 * Convert a millisecond timestamp to a frame number relative to the timeline origin.
 */
export function frameAtMs(ms, originMs, fps) {
  return Math.round(((ms - originMs) * fps) / 1000);
}

async function main() {
  const { options } = parseArgs();
  const inputPath = requiredOption(options, "input");
  const outputPath = requiredOption(options, "output");

  const text = await readFile(inputPath, "utf8");
  const sourceSha256 = createHash("sha256").update(text).digest("hex");
  const transcript = parseSrt(text, inputPath, sourceSha256);

  await mkdir(dirname(outputPath), { recursive: true });
  await writeFile(outputPath, JSON.stringify(transcript, null, 2) + "\n", "utf8");
  printJson(transcript);
}

const isMain = process.argv[1] && (process.argv[1].endsWith("parse-srt.mjs") || process.argv[1].endsWith("parse-srt"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
