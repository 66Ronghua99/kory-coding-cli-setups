const test = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const { BootstrapChecker } = require('../lib/bootstrap-checker');

const fixturesRoot = path.join(__dirname, 'fixtures');

function copyFixture(name, overlayName = null) {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'bootstrap-phase1-'));
  fs.cpSync(path.join(fixturesRoot, 'bootstrap-valid'), tempDir, { recursive: true });

  if (overlayName) {
    fs.cpSync(path.join(fixturesRoot, overlayName), tempDir, { recursive: true, force: true });
  }

  return tempDir;
}

test('valid bootstrap fixture has no blocking issues and only warning-level verify/e2e command gaps', () => {
  const repoRoot = copyFixture('bootstrap-valid');
  const checker = new BootstrapChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.equal(issues.filter(issue => issue.level === 'ERROR').length, 0);
  assert.ok(!issues.some(issue => issue.type === 'empty_manifest_command' && issue.key === 'docs_health_command'));
  assert.ok(issues.some(issue => issue.type === 'empty_manifest_command' && issue.key === 'verify_command'));
  assert.ok(issues.some(issue => issue.type === 'empty_manifest_command' && issue.key === 'e2e_command'));
});

test('missing required manifest key is blocking', () => {
  const repoRoot = copyFixture('bootstrap-valid', 'bootstrap-invalid-manifest');
  const checker = new BootstrapChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.ok(issues.some(issue => issue.type === 'missing_manifest_key' && issue.level === 'ERROR'));
});

test('missing routing marker is blocking', () => {
  const repoRoot = copyFixture('bootstrap-valid', 'bootstrap-invalid-routing');
  const checker = new BootstrapChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.ok(issues.some(issue => issue.type === 'missing_routing_marker' && issue.level === 'ERROR'));
});

test('missing required template heading is blocking', () => {
  const repoRoot = copyFixture('bootstrap-valid', 'bootstrap-invalid-template');
  const checker = new BootstrapChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.ok(issues.some(issue => issue.type === 'missing_required_heading' && issue.level === 'ERROR'));
});

test('greenfield bootstrap materializes a default docs health command', () => {
  const repoRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'bootstrap-greenfield-'));
  const greenfieldScript = path.join(__dirname, '..', '..', '..', 'harness-bootstrap', 'scripts', 'bootstrap_greenfield.sh');

  execFileSync(greenfieldScript, [repoRoot], { stdio: 'pipe' });

  const manifestPath = path.join(repoRoot, '.harness', 'bootstrap.toml');
  const manifest = fs.readFileSync(manifestPath, 'utf-8');
  const checker = new BootstrapChecker();
  const issues = checker.checkRoot(repoRoot);

  assert.match(manifest, /^docs_health_command = ["'].+["']$/m);
  assert.ok(!issues.some(issue => issue.type === 'empty_manifest_command' && issue.key === 'docs_health_command'));
  assert.ok(issues.some(issue => issue.type === 'empty_manifest_command' && issue.key === 'verify_command'));
  assert.ok(issues.some(issue => issue.type === 'empty_manifest_command' && issue.key === 'e2e_command'));
});

test('bootstrap CLI output explains how to read issue context', () => {
  const repoRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'bootstrap-cli-'));
  const greenfieldScript = path.join(__dirname, '..', '..', '..', 'harness-bootstrap', 'scripts', 'bootstrap_greenfield.sh');
  const scriptPath = path.join(__dirname, '..', 'scripts', 'doc-health.js');

  execFileSync(greenfieldScript, [repoRoot], { stdio: 'pipe' });

  const output = execFileSync('node', [scriptPath, repoRoot, '--phase', 'bootstrap'], {
    encoding: 'utf-8',
    stdio: 'pipe'
  });

  assert.match(output, /说明: 先修复所有 ERROR/);
  assert.match(output, /key.*缺失槽位/);
  assert.match(output, /\.harness\/bootstrap\.toml \| key=verify_command/);
});
