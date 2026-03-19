const test = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const { DocumentGraphChecker } = require('../lib/document-graph-checker');

const fixturesRoot = path.join(__dirname, 'fixtures');

function copyFixture(name) {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'graph-phase2-'));
  fs.cpSync(path.join(fixturesRoot, name), tempDir, { recursive: true });
  return tempDir;
}

test('valid graph fixture passes without blocking or warning issues', () => {
  const repoRoot = copyFixture('graph-valid');
  const checker = new DocumentGraphChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.equal(issues.filter(issue => issue.level === 'ERROR').length, 0);
  assert.equal(issues.filter(issue => issue.level === 'WARNING').length, 0);
});

test('missing front matter is blocking', () => {
  const repoRoot = copyFixture('graph-invalid-missing-frontmatter');
  const checker = new DocumentGraphChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.ok(issues.some(issue => issue.type === 'missing_front_matter' && issue.level === 'ERROR'));
});

test('plan implements target must be a spec', () => {
  const repoRoot = copyFixture('graph-invalid-target-type');
  const checker = new DocumentGraphChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.ok(issues.some(issue => issue.type === 'invalid_relation_target_type' && issue.level === 'ERROR'));
});

test('self reference is blocking', () => {
  const repoRoot = copyFixture('graph-invalid-self-reference');
  const checker = new DocumentGraphChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.ok(issues.some(issue => issue.type === 'self_reference' && issue.level === 'ERROR'));
});

test('references to deprecated documents warn without blocking', () => {
  const repoRoot = copyFixture('graph-warning-deprecated-reference');
  const checker = new DocumentGraphChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.equal(issues.filter(issue => issue.level === 'ERROR').length, 0);
  assert.ok(issues.some(issue => issue.type === 'deprecated_reference' && issue.level === 'WARNING'));
});

test('graph CLI output names the offending source document and target', () => {
  const repoRoot = copyFixture('graph-invalid-target-type');
  const scriptPath = path.join(__dirname, '..', 'scripts', 'doc-health.js');

  let output = '';
  try {
    execFileSync('node', [scriptPath, repoRoot, '--phase', 'graph'], {
      encoding: 'utf-8',
      stdio: 'pipe'
    });
  } catch (error) {
    output = `${error.stdout || ''}${error.stderr || ''}`;
  }

  assert.match(output, /docs\/superpowers\/plans\/plan\.md/);
  assert.match(output, /说明: 先修复所有 ERROR/);
  assert.match(output, /field.*关系字段/);
  assert.match(output, /field=implements/);
  assert.match(output, /target=artifacts\/checks\/evidence\.md/);
});
