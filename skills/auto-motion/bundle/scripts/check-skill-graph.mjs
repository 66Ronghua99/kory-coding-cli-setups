import { readFile, readdir, stat } from "node:fs/promises";
import { resolve, relative } from "node:path";
import YAML from "yaml";
import { readJson } from "./lib/atomic.mjs";

async function isDirectory(path) {
  try {
    return (await stat(path)).isDirectory();
  } catch {
    return false;
  }
}

async function isFile(path) {
  try {
    return (await stat(path)).isFile();
  } catch {
    return false;
  }
}

function extractFrontmatter(text) {
  const match = text.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return null;
  try {
    return YAML.parse(match[1]);
  } catch {
    return null;
  }
}

async function discoverSkills(root) {
  const skillsDir = resolve(root, ".omp", "skills");
  const skills = [];
  try {
    const entries = await readdir(skillsDir);
    for (const entry of entries) {
      const skillPath = resolve(skillsDir, entry);
      if (!(await isDirectory(skillPath))) continue;
      const skillMd = resolve(skillPath, "SKILL.md");
      if (!(await isFile(skillMd))) continue;
      const content = await readFile(skillMd, "utf8");
      const fm = extractFrontmatter(content);
      if (fm?.name) skills.push(fm.name);
    }
  } catch {
    // skills dir missing
  }
  return skills;
}

async function discoverAgents(root) {
  const agentsDir = resolve(root, ".omp", "agents");
  const agents = [];
  try {
    const entries = await readdir(agentsDir);
    for (const entry of entries) {
      if (!entry.endsWith(".md")) continue;
      const agentPath = resolve(agentsDir, entry);
      const content = await readFile(agentPath, "utf8");
      const fm = extractFrontmatter(content);
      if (fm?.name) {
        agents.push({
          name: fm.name,
          tools: fm.tools ?? [],
          spawns: fm.spawns ?? null,
          thinkingLevel: fm.thinkingLevel ?? null,
          readSummarize: fm["read-summarize"] ?? undefined,
          path: relative(root, agentPath),
        });
      }
    }
  } catch {
    // agents dir missing
  }
  return agents;
}

function resolveSkillUri(root, uri) {
  if (!uri.startsWith("skill://")) return null;
  const body = uri.slice("skill://".length);
  const slash = body.indexOf("/");
  const skill = slash < 0 ? body : body.slice(0, slash);
  const rest = slash < 0 ? "SKILL.md" : body.slice(slash + 1);
  if (!/^[A-Za-z0-9][A-Za-z0-9_-]*$/.test(skill)) return null;
  return resolve(root, ".omp", "skills", skill, rest);
}

async function countSkillReferences(root) {
  let references = 0;
  const unresolved = [];
  const skillsDir = resolve(root, ".omp", "skills");
  try {
    const files = await walkDir(skillsDir);
    for (const file of files) {
      if (!file.endsWith(".md")) continue;
      const content = await readFile(file, "utf8");
      // Match skill:// URIs in backticks: `skill://name/path`
      const matches = content.matchAll(/`skill:\/\/[A-Za-z0-9][A-Za-z0-9_\/.-]*`/g);
      for (const match of matches) {
        references++;
        const uri = match[0].slice(1, -1); // remove backticks
        const resolved = resolveSkillUri(root, uri);
        if (!resolved) {
          unresolved.push({ file: relative(root, file), uri });
        } else if (await isFile(resolved)) {
          // OK
        } else if (await isDirectory(resolved)) {
          // Directory reference (e.g., skill://hyperframes/core) — treat as valid
        } else {
          unresolved.push({ file: relative(root, file), uri });
        }
      }
    }
  } catch {
    // skills dir missing
  }
  return { references, unresolved };
}

async function walkDir(dir) {
  const results = [];
  try {
    const entries = await readdir(dir);
    for (const entry of entries) {
      const full = resolve(dir, entry);
      if (await isDirectory(full)) {
        results.push(...await walkDir(full));
      } else {
        results.push(full);
      }
    }
  } catch {
    // dir missing
  }
  return results;
}

export async function checkSkillGraph(root) {
  const skills = await discoverSkills(root);
  const agents = await discoverAgents(root);
  const { references, unresolved } = await countSkillReferences(root);

  return {
    skills,
    agents: agents.map((a) => a.name),
    agentDetails: agents,
    references,
    unresolved,
    ok: unresolved.length === 0,
  };
}

export async function loadCatalog(root) {
  const catalogPath = resolve(root, ".omp", "skills", "hyperframes-motion", "catalog.json");
  return readJson(catalogPath);
}

export async function validateCatalog(root) {
  const catalog = await loadCatalog(root);
  const blueprints = Object.keys(catalog.blueprints);
  const categories = Object.values(catalog.blueprints);

  const errors = [];
  for (const bp of blueprints) {
    const resolved = resolveSkillUri(root, bp);
    if (!resolved || !(await isFile(resolved))) {
      errors.push(`Blueprint not found: ${bp}`);
    }
  }
  for (const cat of categories) {
    const resolved = resolveSkillUri(root, cat);
    if (!resolved || !(await isFile(resolved))) {
      errors.push(`Category not found: ${cat}`);
    }
  }

  return {
    blueprintCount: blueprints.length,
    categoryRefs: [...new Set(categories)],
    errors,
    ok: errors.length === 0,
  };
}

// CLI entry
async function main() {
  if (process.argv[1] && (process.argv[1].endsWith("check-skill-graph.mjs") || process.argv[1].endsWith("check-skill-graph"))) {
    const root = resolve(process.argv[2] || ".");
    const result = await checkSkillGraph(root);
    const catalog = await validateCatalog(root);
    process.stdout.write(JSON.stringify({ ...result, catalog }, null, 2) + "\n");
    if (!result.ok || !catalog.ok) process.exit(1);
  }
}

main().catch((e) => {
  process.stderr.write(`${e.message}\n`);
  process.exit(1);
});
