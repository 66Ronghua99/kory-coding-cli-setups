import { mkdir, copyFile, writeFile, readFile, rm } from "node:fs/promises";
import { resolve, basename, extname, relative } from "node:path";
import { createHash } from "node:crypto";
import { parseArgs, requiredOption, option, printJson, failCli } from "./lib/cli.mjs";
import { resolveRunDir, resolveInside } from "./lib/paths.mjs";
import { readJson, writeJsonAtomic, sha256File, sha256Json } from "./lib/atomic.mjs";
import { validateContract } from "./lib/contracts.mjs";

const ROOT = resolve(".");
const ALLOWED_MEDIA_TYPES = [
  "image/svg+xml", "image/png", "image/jpeg", "image/webp", "image/gif", "video/mp4",
];
const MAX_RESPONSE_BYTES = 25 * 1024 * 1024; // 25 MiB

async function loadIndex(runDir) {
  const indexPath = resolve(runDir, "assets", "index.json");
  try {
    return await readJson(indexPath);
  } catch {
    return { schema_version: 1, assets: [] };
  }
}

async function saveIndex(runDir, index) {
  await validateContract(ROOT, "assets-index", index);
  await writeJsonAtomic(resolve(runDir, "assets", "index.json"), index);
}

export async function registerAsset({ runDir, id, file, mediaType, sourceUrl, licenseNote }) {
  if (!ALLOWED_MEDIA_TYPES.includes(mediaType)) {
    throw new Error(`Unsupported media type: ${mediaType}. Allowed: ${ALLOWED_MEDIA_TYPES.join(", ")}`);
  }
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/.test(id)) {
    throw new Error(`Invalid asset ID: ${id}`);
  }

  const sha256 = await sha256File(file);
  const destDir = resolve(runDir, "assets", "files");
  await mkdir(destDir, { recursive: true });

  const ext = extname(file).toLowerCase();
  const destFile = resolve(destDir, `${id}${ext}`);
  await copyFile(file, destFile);

  const index = await loadIndex(runDir);

  // Check for duplicate ID
  const existing = index.assets.find((a) => a.id === id);
  if (existing) {
    if (existing.sha256 === sha256 &&
        existing.media_type === mediaType &&
        existing.source_url === sourceUrl &&
        existing.license_note === licenseNote) {
      return { id, path: existing.path, sha256 };
    }
    throw new Error(`Duplicate asset ID "${id}" with different content`);
  }

  const relativePath = relative(runDir, destFile).split("\\").join("/");
  index.assets.push({
    id,
    path: relativePath,
    media_type: mediaType,
    source_url: sourceUrl,
    license_note: licenseNote,
    sha256,
  });
  await saveIndex(runDir, index);

  return { id, path: relativePath, sha256 };
}

export async function fetchAsset({ runDir, id, url, licenseNote }) {
  if (!/^https?:\/\//i.test(url)) {
    throw new Error(`Only HTTP(S) URLs allowed: ${url}`);
  }

  console.error(`Fetching ${url}...`);
  const controller = new AbortController();
  const timeout = AbortSignal.timeout(60_000);
  const response = await fetch(url, { signal: AbortSignal.any([controller.signal, timeout]) });
  if (!response.ok) {
    throw new Error(`HTTP ${response.status} fetching ${url}`);
  }

  const buffer = Buffer.from(await response.arrayBuffer());
  if (buffer.length > MAX_RESPONSE_BYTES) {
    throw new Error(`Response too large: ${buffer.length} bytes (max ${MAX_RESPONSE_BYTES})`);
  }

  const contentType = response.headers.get("content-type") ?? "";
  let mediaType = contentType.split(";")[0].trim().toLowerCase();
  if (!ALLOWED_MEDIA_TYPES.includes(mediaType)) {
    // Try to infer from URL extension
    const ext = extname(new URL(url).pathname).toLowerCase();
    const guess = {
      ".svg": "image/svg+xml", ".png": "image/png", ".jpg": "image/jpeg",
      ".jpeg": "image/jpeg", ".webp": "image/webp", ".gif": "image/gif", ".mp4": "video/mp4",
    }[ext];
    if (guess) mediaType = guess;
  }
  if (!ALLOWED_MEDIA_TYPES.includes(mediaType)) {
    throw new Error(`Cannot determine media type for ${url} (got ${contentType})`);
  }

  const extMap = { "image/svg+xml": ".svg", "image/png": ".png", "image/jpeg": ".jpg",
    "image/webp": ".webp", "image/gif": ".gif", "video/mp4": ".mp4" };
  const ext = extMap[mediaType];

  const destDir = resolve(runDir, "assets", "files");
  await mkdir(destDir, { recursive: true });
  const destFile = resolve(destDir, `${id}${ext}`);
  await writeFile(destFile, buffer);

  return registerAsset({
    runDir, id, file: destFile, mediaType,
    sourceUrl: url, licenseNote,
  });
}

async function main() {
  const { options, positionals } = parseArgs();
  const subcommand = positionals[0];
  if (!subcommand) {
    failCli(new Error("Subcommand required: fetch or register"));
    return;
  }

  const runArg = requiredOption(options, "run");
  const runDir = resolveRunDir(".", runArg);

  if (subcommand === "register") {
    const id = requiredOption(options, "id");
    const file = requiredOption(options, "file");
    const mediaType = requiredOption(options, "media-type");
    const sourceUrl = requiredOption(options, "source-url");
    const licenseNote = option(options, "license-note", "");
    const result = await registerAsset({ runDir, id, file, mediaType, sourceUrl, licenseNote });
    printJson(result);
  } else if (subcommand === "fetch") {
    const id = requiredOption(options, "id");
    const url = requiredOption(options, "url");
    const licenseNote = option(options, "license-note", "");
    const result = await fetchAsset({ runDir, id, url, licenseNote });
    printJson(result);
  } else {
    failCli(new Error(`Unknown subcommand: ${subcommand}`));
  }
}

const isMain = process.argv[1] && (process.argv[1].endsWith("asset.mjs") || process.argv[1].endsWith("asset"));
if (isMain) {
  main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
}
