import { createHash } from "node:crypto";
import { open, readFile, rename, rm, copyFile, mkdir } from "node:fs/promises";
import { dirname, basename } from "node:path";
import { randomUUID } from "node:crypto";

export function canonicalize(value) {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === "object" && Object.getPrototypeOf(value) === Object.prototype) {
    return Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonicalize(value[key])]));
  }
  return value;
}

export function sha256Bytes(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

export async function sha256File(filePath) {
  return sha256Bytes(await readFile(filePath));
}

export function sha256Json(value) {
  return sha256Bytes(Buffer.from(JSON.stringify(canonicalize(value))));
}

async function atomicBytes(filePath, bytes, mode) {
  await mkdir(dirname(filePath), { recursive: true });
  const tempPath = `${filePath}.${process.pid}.${randomUUID()}.tmp`;
  let handle;
  try {
    handle = await open(tempPath, "wx", mode);
    await handle.writeFile(bytes);
    await handle.sync();
    await handle.close();
    handle = undefined;
    await rename(tempPath, filePath);
  } catch (error) {
    if (handle) await handle.close().catch(() => {});
    await rm(tempPath, { force: true }).catch(() => {});
    throw error;
  }
}

export async function writeTextAtomic(filePath, text, mode = 0o644) {
  if (typeof text !== "string") throw new TypeError("writeTextAtomic requires a string");
  await atomicBytes(filePath, Buffer.from(text, "utf8"), mode);
}

export async function writeJsonAtomic(filePath, value, mode = 0o644) {
  await writeTextAtomic(filePath, `${JSON.stringify(value, null, 2)}\n`, mode);
}

export async function writeYamlAtomic(filePath, value, stringifyYaml, mode = 0o644) {
  if (typeof stringifyYaml !== "function") throw new TypeError("writeYamlAtomic requires a YAML serializer");
  await writeTextAtomic(filePath, stringifyYaml(value), mode);
}

export async function copyFileAtomic(sourcePath, targetPath, mode = 0o644) {
  await mkdir(dirname(targetPath), { recursive: true });
  const tempPath = `${targetPath}.${process.pid}.${randomUUID()}.tmp`;
  try {
    await copyFile(sourcePath, tempPath);
    const handle = await open(tempPath, "r+");
    await handle.sync();
    await handle.close();
    await rename(tempPath, targetPath);
    await (async () => {
      try {
        const target = await open(targetPath, "r+");
        await target.chmod(mode);
        await target.close();
      } catch {
        // Preserve the source mode when chmod is unavailable.
      }
    })();
  } catch (error) {
    await rm(tempPath, { force: true }).catch(() => {});
    throw error;
  }
}

export async function readJson(filePath) {
  return JSON.parse(await readFile(filePath, "utf8"));
}

export { basename };
