import { readFile, readdir } from "node:fs/promises";
import { resolve, extname } from "node:path";
import Ajv2020 from "ajv/dist/2020.js";

const schemas = new Map();

async function loadSchema(root, name) {
  if (schemas.has(name)) return schemas.get(name);
  const schemaPath = resolve(root, "schemas", `${name}.schema.json`);
  const schema = JSON.parse(await readFile(schemaPath, "utf8"));
  schemas.set(name, schema);
  return schema;
}

export async function validateContract(root, schemaName, value) {
  const schema = await loadSchema(root, schemaName);
  const ajv = new Ajv2020({ allErrors: true, strict: false });
  // Load all schemas so $id cross-references work
  const schemasDir = resolve(root, "schemas");
  for (const entry of await readdir(schemasDir)) {
    if (!entry.endsWith(".schema.json")) continue;
    const name = entry.replace(".schema.json", "");
    if (name === schemaName) continue; // already loaded
    const s = JSON.parse(await readFile(resolve(schemasDir, entry), "utf8"));
    try { ajv.addSchema(s, s.$id); } catch { /* duplicate id */ }
  }
  const validate = ajv.compile(schema);
  if (!validate(value)) {
    const messages = validate.errors.map((e) => `${e.instancePath} ${e.message}`).join("; ");
    throw new Error(`Contract ${schemaName} failed: ${messages}`);
  }
}

export async function loadAllSchemaNames(root) {
  const schemasDir = resolve(root, "schemas");
  const entries = await readdir(schemasDir);
  return entries
    .filter((e) => e.endsWith(".schema.json"))
    .map((e) => e.replace(".schema.json", ""));
}
