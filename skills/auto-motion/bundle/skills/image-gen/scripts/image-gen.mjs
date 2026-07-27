import { writeFile, mkdir } from "node:fs/promises";
import { dirname } from "node:path";
import { createHash } from "node:crypto";

const API_URL = "https://api.minimaxi.com/v1/image_generation";
const MAX_PROMPT = 1500;
const MIN_DIM = 512;
const MAX_DIM = 2048;

function validateArgs(prompt, width, height, outputPath) {
  if (typeof prompt !== "string" || prompt.length === 0) throw new Error("prompt is required");
  if (prompt.length > MAX_PROMPT) throw new Error(`prompt exceeds ${MAX_PROMPT} characters`);
  if (typeof width !== "number" || !Number.isInteger(width) || width < MIN_DIM || width > MAX_DIM || width % 8 !== 0) {
    throw new Error(`width must be an integer ${MIN_DIM}-${MAX_DIM} and divisible by 8`);
  }
  if (typeof height !== "number" || !Number.isInteger(height) || height < MIN_DIM || height > MAX_DIM || height % 8 !== 0) {
    throw new Error(`height must be an integer ${MIN_DIM}-${MAX_DIM} and divisible by 8`);
  }
  if (typeof outputPath !== "string" || outputPath.length === 0) throw new Error("output filename is required");
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length !== 4) {
    process.stderr.write("Usage: node image-gen.mjs <prompt> <width> <height> <output_filename>\n");
    process.exit(1);
  }

  const [prompt, widthStr, heightStr, outputPath] = args;
  const width = Number(widthStr);
  const height = Number(heightStr);
  validateArgs(prompt, width, height, outputPath);

  const apiKey = (process.env.MINIMAX_API_KEY ?? "").trim();
  if (!apiKey) {
    process.stderr.write("MINIMAX_API_KEY environment variable is required\n");
    process.exit(1);
  }

  const controller = new AbortController();
  const timeout = AbortSignal.timeout(60_000);

  const response = await fetch(API_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "image-01",
      prompt,
      width,
      height,
      n: 1,
      response_format: "base64",
    }),
    signal: AbortSignal.any([controller.signal, timeout]),
  });

  if (!response.ok) {
    const text = await response.text().catch(() => "");
    throw new Error(`MiniMax API error ${response.status}: ${text}`);
  }

  const data = await response.json();
  const imageBase64 = data?.data?.image_base64?.[0];
  if (!imageBase64) throw new Error("No image data in MiniMax response");

  const bytes = Buffer.from(imageBase64, "base64");
  await mkdir(dirname(outputPath), { recursive: true });
  await writeFile(outputPath, bytes);
  console.log(`Saved ${outputPath}`);
}

main().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
});
