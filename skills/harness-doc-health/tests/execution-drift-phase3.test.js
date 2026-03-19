const test = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const crypto = require('node:crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const yaml = require('js-yaml');

const { ExecutionDriftChecker } = require('../lib/execution-drift-checker');

const fixturesRoot = path.join(__dirname, 'fixtures');

function copyFixture(overlayName = null) {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'drift-phase3-'));
  fs.cpSync(path.join(fixturesRoot, 'drift-valid'), tempDir, { recursive: true });

  if (overlayName) {
    fs.cpSync(path.join(fixturesRoot, overlayName), tempDir, { recursive: true, force: true });
  }

  hydrateFixture(tempDir);
  return tempDir;
}

function hydrateFixture(repoRoot) {
  const specPath = path.join(repoRoot, 'docs', 'superpowers', 'specs', 'spec.md');
  const planPath = path.join(repoRoot, 'docs', 'superpowers', 'plans', 'plan.md');
  const evidencePath = path.join(repoRoot, 'artifacts', 'checks', 'evidence.md');

  const specContent = fs.readFileSync(specPath, 'utf-8');
  const anchorHashes = {
    frozen_contracts: computeAnchorHash(specContent, 'frozen_contracts'),
    acceptance: computeAnchorHash(specContent, 'acceptance')
  };

  let planContent = fs.readFileSync(planPath, 'utf-8');
  if (anchorHashes.frozen_contracts) {
    planContent = planContent.replaceAll('__FROZEN_HASH__', anchorHashes.frozen_contracts);
  }
  if (anchorHashes.acceptance) {
    planContent = planContent.replaceAll('__ACCEPTANCE_HASH__', anchorHashes.acceptance);
  }
  fs.writeFileSync(planPath, planContent);

  const planClaims = parseExecutionClaims(planContent);
  const claimHashes = new Map(
    planClaims.map(claim => [claim.claim_id, computeClaimHash(claim)])
  );

  let evidenceContent = fs.readFileSync(evidencePath, 'utf-8');
  if (claimHashes.has('plan.example.frozen-contracts')) {
    evidenceContent = evidenceContent.replaceAll(
      '__PLAN_HASH_FROZEN__',
      claimHashes.get('plan.example.frozen-contracts')
    );
  }
  if (claimHashes.has('plan.example.acceptance')) {
    evidenceContent = evidenceContent.replaceAll(
      '__PLAN_HASH_ACCEPTANCE__',
      claimHashes.get('plan.example.acceptance')
    );
  }
  fs.writeFileSync(evidencePath, evidenceContent);
}

function computeAnchorHash(content, anchorId) {
  const marker = `<!-- drift_anchor: ${anchorId} -->`;
  const startIndex = content.indexOf(marker);
  if (startIndex === -1) {
    return null;
  }

  const afterAnchor = content.slice(startIndex + marker.length);
  const nextSectionMatch = afterAnchor.match(/\n## /);
  const sectionBody = nextSectionMatch
    ? afterAnchor.slice(0, nextSectionMatch.index)
    : afterAnchor;

  return shortHash(normalizeMultiline(sectionBody));
}

function parseExecutionClaims(content) {
  const block = extractYamlBlock(content, 'Execution Truth');
  const parsed = yaml.load(block) || {};
  return Array.isArray(parsed.claims) ? parsed.claims : [];
}

function extractYamlBlock(content, heading) {
  const escapedHeading = heading.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const match = content.match(new RegExp(`## ${escapedHeading}\\n(?:[\\s\\S]*?)\`\`\`yaml\\n([\\s\\S]*?)\\n\`\`\``));
  if (!match) {
    throw new Error(`Missing YAML block for heading: ${heading}`);
  }
  return match[1];
}

function computeClaimHash(claim) {
  return shortHash(stableStringify(claim));
}

function stableStringify(value) {
  if (Array.isArray(value)) {
    return `[${value.map(stableStringify).join(',')}]`;
  }

  if (value && typeof value === 'object') {
    return `{${Object.keys(value).sort().map(key => `${JSON.stringify(key)}:${stableStringify(value[key])}`).join(',')}}`;
  }

  return JSON.stringify(value);
}

function normalizeMultiline(value) {
  return value
    .split('\n')
    .map(line => line.trimEnd())
    .join('\n')
    .trim();
}

function shortHash(value) {
  return crypto.createHash('sha256').update(value).digest('hex').slice(0, 12);
}

test('valid execution-drift fixture passes without blocking or warning issues', () => {
  const repoRoot = copyFixture();
  const checker = new ExecutionDriftChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.equal(issues.filter(issue => issue.level === 'ERROR').length, 0);
  assert.equal(issues.filter(issue => issue.level === 'WARNING').length, 0);
});

test('missing source anchor is blocking', () => {
  const repoRoot = copyFixture('drift-invalid-missing-anchor');
  const checker = new ExecutionDriftChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.ok(issues.some(issue => issue.type === 'missing_source_anchor' && issue.level === 'ERROR'));
});

test('stale plan source hash is blocking', () => {
  const repoRoot = copyFixture('drift-invalid-stale-plan-hash');
  const checker = new ExecutionDriftChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.ok(issues.some(issue => issue.type === 'stale_source_hash' && issue.level === 'ERROR'));
});

test('stale evidence plan hash is blocking', () => {
  const repoRoot = copyFixture('drift-invalid-stale-evidence-hash');
  const checker = new ExecutionDriftChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.ok(issues.some(issue => issue.type === 'stale_plan_hash' && issue.level === 'ERROR'));
});

test('drift CLI output names the stale claim and source target', () => {
  const repoRoot = copyFixture('drift-invalid-stale-plan-hash');
  const scriptPath = path.join(__dirname, '..', 'scripts', 'doc-health.js');

  let output = '';
  try {
    execFileSync('node', [scriptPath, repoRoot, '--phase', 'drift'], {
      encoding: 'utf-8',
      stdio: 'pipe'
    });
  } catch (error) {
    output = `${error.stdout || ''}${error.stderr || ''}`;
  }

  assert.match(output, /docs\/superpowers\/plans\/plan\.md/);
  assert.match(output, /说明: 先修复所有 ERROR/);
  assert.match(output, /claim_id=.*plan\.example\.frozen-contracts/);
  assert.match(output, /target=docs\/superpowers\/specs\/spec\.md/);
});
