const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const DEFAULT_RULES_PATH = path.join(__dirname, '..', 'references', 'bootstrap-phase1.yml');

class BootstrapChecker {
  constructor(rulesPath = DEFAULT_RULES_PATH) {
    this.rulesPath = rulesPath;
    this.rules = yaml.load(fs.readFileSync(rulesPath, 'utf-8'));
  }

  checkRoot(rootDir) {
    const repoRoot = path.resolve(rootDir);
    const issues = [];

    issues.push(...this.checkManifest(repoRoot));
    issues.push(...this.checkRequiredFiles(repoRoot, this.rules.governance_files || []));
    issues.push(...this.checkRequiredFiles(repoRoot, this.rules.template_files || []));
    issues.push(...this.checkTemplateHeadings(repoRoot));
    issues.push(...this.checkRoutingMarkers(repoRoot));
    issues.push(...this.checkNextStepClarity(repoRoot));

    return issues;
  }

  checkManifest(repoRoot) {
    const issues = [];
    const manifestRelPath = this.rules.manifest?.file;
    const manifestPath = path.join(repoRoot, manifestRelPath);

    if (!fs.existsSync(manifestPath)) {
      issues.push({
        level: 'ERROR',
        type: 'missing_manifest_file',
        message: `缺少 bootstrap manifest: ${manifestRelPath}`,
        file: manifestRelPath
      });
      return issues;
    }

    const content = fs.readFileSync(manifestPath, 'utf-8');
    const parsed = this.parseFlatToml(content);

    for (const key of this.rules.manifest?.required_keys || []) {
      if (!Object.prototype.hasOwnProperty.call(parsed, key) || parsed[key] === '') {
        issues.push({
          level: 'ERROR',
          type: 'missing_manifest_key',
          message: `bootstrap manifest 缺少必需字段: ${key}`,
          file: manifestRelPath,
          key
        });
      }
    }

    for (const key of this.rules.manifest?.warning_keys || []) {
      if (!Object.prototype.hasOwnProperty.call(parsed, key) || parsed[key] === '') {
        issues.push({
          level: 'WARNING',
          type: 'empty_manifest_command',
          message: `bootstrap manifest 建议配置字段: ${key}`,
          file: manifestRelPath,
          key
        });
      }
    }

    return issues;
  }

  parseFlatToml(content) {
    const result = {};
    const lines = content.split('\n');

    for (const rawLine of lines) {
      const line = rawLine.trim();
      if (!line || line.startsWith('#')) {
        continue;
      }

      const match = line.match(/^([A-Za-z0-9_-]+)\s*=\s*(.+)$/);
      if (!match) {
        continue;
      }

      const [, key, rawValue] = match;
      let value = rawValue.trim();

      if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
        value = value.slice(1, -1);
      }

      result[key] = value;
    }

    return result;
  }

  checkRequiredFiles(repoRoot, files) {
    const issues = [];

    for (const relPath of files) {
      const fullPath = path.join(repoRoot, relPath);
      if (!fs.existsSync(fullPath)) {
        issues.push({
          level: 'ERROR',
          type: 'missing_required_file',
          message: `缺少必需文件: ${relPath}`,
          file: relPath
        });
      }
    }

    return issues;
  }

  checkTemplateHeadings(repoRoot) {
    const issues = [];
    const headingRules = this.rules.template_headings || {};

    for (const [relPath, headings] of Object.entries(headingRules)) {
      const fullPath = path.join(repoRoot, relPath);
      if (!fs.existsSync(fullPath)) {
        continue;
      }

      const content = fs.readFileSync(fullPath, 'utf-8');
      for (const heading of headings) {
        if (!content.includes(heading)) {
          issues.push({
            level: 'ERROR',
            type: 'missing_required_heading',
            message: `缺少必需模板段落: ${heading}`,
            file: relPath,
            heading
          });
        }
      }
    }

    return issues;
  }

  checkRoutingMarkers(repoRoot) {
    const issues = [];
    const routingRules = this.rules.routing_markers || {};

    for (const [relPath, markers] of Object.entries(routingRules)) {
      if (relPath === 'warning_markers') {
        continue;
      }

      const fullPath = path.join(repoRoot, relPath);
      if (!fs.existsSync(fullPath)) {
        continue;
      }

      const content = fs.readFileSync(fullPath, 'utf-8');
      for (const marker of markers) {
        if (!content.includes(marker)) {
          issues.push({
            level: 'ERROR',
            type: 'missing_routing_marker',
            message: `缺少必需路由标记: ${marker}`,
            file: relPath,
            marker
          });
        }
      }
    }

    const warningRules = routingRules.warning_markers || {};
    for (const [relPath, markers] of Object.entries(warningRules)) {
      const fullPath = path.join(repoRoot, relPath);
      if (!fs.existsSync(fullPath)) {
        continue;
      }

      const content = fs.readFileSync(fullPath, 'utf-8');
      for (const marker of markers) {
        if (!content.includes(marker)) {
          issues.push({
            level: 'WARNING',
            type: 'missing_warning_routing_marker',
            message: `建议补充路由标记: ${marker}`,
            file: relPath,
            marker
          });
        }
      }
    }

    return issues;
  }

  checkNextStepClarity(repoRoot) {
    const relPath = 'NEXT_STEP.md';
    const fullPath = path.join(repoRoot, relPath);

    if (!fs.existsSync(fullPath)) {
      return [];
    }

    const content = fs.readFileSync(fullPath, 'utf-8');
    const hasFilePath = /`[^`\/]+\/[^`]+`|`[^`]+\.md`/.test(content);
    const hasActionVerb = /\b(Write|Update|Implement|Execute|Review|Define|Create|Run)\b/i.test(content);

    if (hasFilePath && hasActionVerb) {
      return [];
    }

    return [{
      level: 'WARNING',
      type: 'vague_next_step',
      message: 'NEXT_STEP.md 缺少明确动作或文件路径',
      file: relPath
    }];
  }
}

module.exports = { BootstrapChecker };
