import { execFileSync } from "node:child_process";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";

const FORBIDDEN_PATHS = [
  /(^|\/)\.github\/workflows\//,
  /(^|\/)exampleFolder\//,
  /(^|\/)auto-hyper-\//,
  /(^|\/)transcription\.srt$/,
  /(^|\/)runs\//,
  /(^|\/)scenes\//,
  /(^|\/)final\.mp4$/,
  /(^|\/)\.env$/,
];

const FORBIDDEN_TOKENS = [
  { pattern: /\.claude/, desc: "legacy .claude reference" },
  { pattern: /run-claude-ai\.sh/, desc: "legacy run-claude-ai.sh" },
  { pattern: /claude-ai/, desc: "legacy claude-ai reference" },
  { pattern: /(?<!=)"[A-Za-z0-9+/]{20,}" *=/, desc: "possible API key in committed file" },
];

function getTrackableFiles(root) {
  try {
    const result = execFileSync("git", [
      "ls-files", "--cached", "--others", "--exclude-standard", "-z",
    ], { cwd: root, encoding: "utf8", maxBuffer: 10 * 1024 * 1024 });
    return result.split("\0").filter(Boolean);
  } catch (e) {
    throw new Error(`Git unavailable: ${e.message}. Cannot verify template hygiene.`);
  }
}

async function checkTemplate(root) {
  const rootResolved = resolve(root);
  const errors = [];

  let files;
  try {
    files = getTrackableFiles(rootResolved);
  } catch (e) {
    errors.push({ path: null, error: e.message });
    return { ok: false, errors };
  }

  for (const file of files) {
    // Skip local collaboration state
    if (file.startsWith("docs/superpowers/") || file.startsWith("docs/plans/") || file.startsWith(".superpowers/")) continue;

    for (const fp of FORBIDDEN_PATHS) {
      if (fp.test(file)) {
        errors.push({ path: file, error: `Forbidden path: ${file}` });
        break;
      }
    }

    // Token scan for runtime/template files
    if (file.startsWith(".omp/") || file.startsWith("scripts/") || file === "PROMPT.md" || file === "README.md" || file === "README.en.md" || file.startsWith("auto-test/")) {
      try {
        const content = await readFile(resolve(rootResolved, file), "utf8");
        for (const ft of FORBIDDEN_TOKENS) {
          if (ft.pattern.test(content)) {
            // Don't match the checker's own source
            if (file === "scripts/check-template.mjs") continue;
            errors.push({ path: file, error: `Forbidden token: ${ft.desc}` });
          }
        }
      } catch {
        // binary or unreadable — skip
      }
    }
  }

  return { ok: errors.length === 0, errors };
}

async function main() {
  const root = process.argv[2] || ".";
  const result = await checkTemplate(root);
  process.stdout.write(JSON.stringify(result, null, 2) + "\n");
  if (!result.ok) process.exit(1);
}

main().catch((e) => { process.stderr.write(`${e.message}\n`); process.exit(1); });
