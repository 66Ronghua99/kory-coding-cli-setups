const crypto = require('node:crypto');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const DEFAULT_RULES_PATH = path.join(__dirname, '..', 'references', 'execution-drift-phase3.yml');

class ExecutionDriftChecker {
  constructor(rulesPath = DEFAULT_RULES_PATH) {
    this.rulesPath = rulesPath;
    this.rules = yaml.load(fs.readFileSync(rulesPath, 'utf-8'));
  }

  checkRoot(rootDir) {
    const repoRoot = path.resolve(rootDir);
    const parsedDocs = this.findCandidateFiles(repoRoot).map(filePath => this.parseDocument(repoRoot, filePath));
    const docsByRelPath = new Map(parsedDocs.map(doc => [doc.relPath, doc]));
    const typedDocs = new Map();
    const issues = [];

    for (const doc of parsedDocs) {
      if (this.isValidDocType(doc.meta?.doc_type)) {
        typedDocs.set(doc.relPath, doc);
      }
    }

    const specTruth = this.collectSpecTruth(typedDocs);
    const planTruth = this.collectPlanTruth(repoRoot, docsByRelPath, typedDocs, specTruth, issues);
    const evidenceTruth = this.collectEvidenceTruth(repoRoot, docsByRelPath, typedDocs, planTruth, issues);

    issues.push(...this.checkEvidenceCoverage(planTruth, evidenceTruth));

    return issues;
  }

  findCandidateFiles(repoRoot) {
    const files = [];

    for (const relRoot of this.rules.roots || []) {
      const fullRoot = path.join(repoRoot, relRoot);
      if (!fs.existsSync(fullRoot)) {
        continue;
      }

      this.walkMarkdown(fullRoot, files);
    }

    return files.sort();
  }

  walkMarkdown(currentPath, files) {
    const stat = fs.statSync(currentPath);
    if (stat.isDirectory()) {
      const entries = fs.readdirSync(currentPath, { withFileTypes: true });
      for (const entry of entries) {
        this.walkMarkdown(path.join(currentPath, entry.name), files);
      }
      return;
    }

    if (!currentPath.endsWith('.md')) {
      return;
    }

    if (path.basename(currentPath) === 'README.md') {
      return;
    }

    files.push(currentPath);
  }

  parseDocument(repoRoot, fullPath) {
    const relPath = path.relative(repoRoot, fullPath).replace(/\\/g, '/');
    const content = fs.readFileSync(fullPath, 'utf-8');
    const frontMatterMatch = content.match(/^---\n([\s\S]*?)\n---\n?/);

    if (!frontMatterMatch) {
      return { relPath, content, body: content, meta: null };
    }

    try {
      const meta = yaml.load(frontMatterMatch[1]) || {};
      const body = content.slice(frontMatterMatch[0].length);
      return { relPath, content, body, meta };
    } catch (error) {
      return {
        relPath,
        content,
        body: content,
        meta: null,
        parseError: error.message
      };
    }
  }

  collectSpecTruth(typedDocs) {
    const specTruth = new Map();

    for (const [relPath, doc] of typedDocs.entries()) {
      if (doc.meta.doc_type !== 'spec') {
        continue;
      }

      const sections = this.extractLevel2Sections(doc.body);
      const anchors = new Map();

      for (const [anchorId, rule] of Object.entries(this.rules.source_sections || {})) {
        const section = sections.find(candidate => candidate.heading === rule.heading);
        if (!section) {
          continue;
        }

        const anchor = this.extractDriftAnchor(section.content);
        if (anchor !== anchorId) {
          continue;
        }

        anchors.set(anchorId, {
          file: relPath,
          anchor: anchorId,
          heading: rule.heading,
          hash: this.hashSectionContent(section.content, anchorId)
        });
      }

      specTruth.set(relPath, {
        doc,
        anchors
      });
    }

    return specTruth;
  }

  collectPlanTruth(repoRoot, docsByRelPath, typedDocs, specTruth, issues) {
    const planTruth = new Map();

    for (const [relPath, doc] of typedDocs.entries()) {
      if (doc.meta.doc_type !== 'plan') {
        continue;
      }

      const parsedBlock = this.parseExecutionTruthBlock(doc);
      if (!parsedBlock.exists) {
        if (doc.meta.status === 'active') {
          issues.push({
            level: 'WARNING',
            type: 'active_plan_missing_execution_truth',
            message: 'active 的 plan 建议声明 Execution Truth',
            file: relPath
          });
        }
        continue;
      }

      if (parsedBlock.error) {
        issues.push({
          level: 'ERROR',
          type: 'malformed_execution_truth_block',
          message: parsedBlock.error,
          file: relPath
        });
        continue;
      }

      const claims = new Map();
      for (const claim of parsedBlock.claims) {
        const claimIssue = this.validateExecutionClaim(repoRoot, docsByRelPath, specTruth, relPath, claim);
        if (claimIssue) {
          issues.push(claimIssue);
        }

        claims.set(claim.claim_id, {
          claim,
          hash: this.hashClaim(claim)
        });
      }

      planTruth.set(relPath, {
        doc,
        claims
      });
    }

    return planTruth;
  }

  collectEvidenceTruth(repoRoot, docsByRelPath, typedDocs, planTruth, issues) {
    const evidenceTruth = new Map();

    for (const [relPath, doc] of typedDocs.entries()) {
      if (doc.meta.doc_type !== 'evidence') {
        continue;
      }

      const parsedBlock = this.parseVerifiedClaimsBlock(doc);
      if (!parsedBlock.exists) {
        evidenceTruth.set(relPath, { doc, verifiedClaims: [] });
        continue;
      }

      if (parsedBlock.error) {
        issues.push({
          level: 'ERROR',
          type: 'malformed_verified_claims_block',
          message: parsedBlock.error,
          file: relPath
        });
        continue;
      }

      const verifiedClaims = [];
      for (const verifiedClaim of parsedBlock.verifiedClaims) {
        const claimIssue = this.validateVerifiedClaim(repoRoot, docsByRelPath, planTruth, relPath, verifiedClaim);
        if (claimIssue) {
          issues.push(claimIssue);
        }

        verifiedClaims.push(verifiedClaim);
      }

      evidenceTruth.set(relPath, {
        doc,
        verifiedClaims
      });
    }

    return evidenceTruth;
  }

  validateExecutionClaim(repoRoot, docsByRelPath, specTruth, planPath, claim) {
    const requiredFields = this.rules.execution_truth?.required_claim_fields || [];
    for (const field of requiredFields) {
      if (!this.hasNonEmptyString(claim[field])) {
        return {
          level: 'ERROR',
          type: 'malformed_execution_truth_block',
          message: `Execution Truth claim 缺少字段: ${field}`,
          file: planPath,
          claim_id: claim.claim_id || 'unknown'
        };
      }
    }

    if (!this.isRepoRelativeMarkdownPath(repoRoot, claim.source_spec)) {
      return {
        level: 'ERROR',
        type: 'missing_source_spec',
        message: `Execution Truth claim 指向无效 source_spec: ${claim.source_spec}`,
        file: planPath,
        claim_id: claim.claim_id,
        target: claim.source_spec
      };
    }

    const normalizedSourceSpec = this.normalizeRepoPath(claim.source_spec);
    const sourceDoc = docsByRelPath.get(normalizedSourceSpec);
    if (!sourceDoc) {
      return {
        level: 'ERROR',
        type: 'missing_source_spec',
        message: `Execution Truth claim 指向不存在的 source_spec: ${normalizedSourceSpec}`,
        file: planPath,
        claim_id: claim.claim_id,
        target: normalizedSourceSpec
      };
    }

    if (sourceDoc.meta?.doc_type !== 'spec') {
      return {
        level: 'ERROR',
        type: 'invalid_source_spec_type',
        message: `Execution Truth claim 必须引用 spec 文档: ${normalizedSourceSpec}`,
        file: planPath,
        claim_id: claim.claim_id,
        target: normalizedSourceSpec
      };
    }

    const sourceTruth = specTruth.get(normalizedSourceSpec);
    const anchorTruth = sourceTruth?.anchors.get(claim.source_anchor);
    if (!anchorTruth) {
      return {
        level: 'ERROR',
        type: 'missing_source_anchor',
        message: `Execution Truth claim 引用的 drift_anchor 不存在: ${claim.source_anchor}`,
        file: planPath,
        claim_id: claim.claim_id,
        anchor: claim.source_anchor,
        target: normalizedSourceSpec
      };
    }

    if (anchorTruth.hash !== claim.source_hash) {
      return {
        level: 'ERROR',
        type: 'stale_source_hash',
        message: `Execution Truth claim 的 source_hash 已过期: ${claim.source_anchor}`,
        file: planPath,
        claim_id: claim.claim_id,
        anchor: claim.source_anchor,
        target: normalizedSourceSpec
      };
    }

    return null;
  }

  validateVerifiedClaim(repoRoot, docsByRelPath, planTruth, evidencePath, verifiedClaim) {
    const requiredFields = this.rules.verified_claims?.required_claim_fields || [];
    for (const field of requiredFields) {
      if (field === 'artifacts') {
        if (!Array.isArray(verifiedClaim.artifacts) || verifiedClaim.artifacts.some(item => typeof item !== 'string')) {
          return {
            level: 'ERROR',
            type: 'malformed_verified_claims_block',
            message: 'Verified Claims claim 的 artifacts 必须是字符串数组',
            file: evidencePath,
            claim_id: verifiedClaim.claim_id || 'unknown'
          };
        }
        continue;
      }

      if (!this.hasNonEmptyString(verifiedClaim[field])) {
        return {
          level: 'ERROR',
          type: 'malformed_verified_claims_block',
          message: `Verified Claims claim 缺少字段: ${field}`,
          file: evidencePath,
          claim_id: verifiedClaim.claim_id || 'unknown'
        };
      }
    }

    if (!this.isRepoRelativeMarkdownPath(repoRoot, verifiedClaim.plan_path)) {
      return {
        level: 'ERROR',
        type: 'missing_plan_document',
        message: `Verified Claims claim 指向无效 plan_path: ${verifiedClaim.plan_path}`,
        file: evidencePath,
        claim_id: verifiedClaim.claim_id,
        target: verifiedClaim.plan_path
      };
    }

    const normalizedPlanPath = this.normalizeRepoPath(verifiedClaim.plan_path);
    const planDoc = docsByRelPath.get(normalizedPlanPath);
    if (!planDoc) {
      return {
        level: 'ERROR',
        type: 'missing_plan_document',
        message: `Verified Claims claim 指向不存在的 plan_path: ${normalizedPlanPath}`,
        file: evidencePath,
        claim_id: verifiedClaim.claim_id,
        target: normalizedPlanPath
      };
    }

    if (planDoc.meta?.doc_type !== 'plan') {
      return {
        level: 'ERROR',
        type: 'invalid_plan_document_type',
        message: `Verified Claims claim 必须引用 plan 文档: ${normalizedPlanPath}`,
        file: evidencePath,
        claim_id: verifiedClaim.claim_id,
        target: normalizedPlanPath
      };
    }

    const planRecord = planTruth.get(normalizedPlanPath);
    const planClaim = planRecord?.claims.get(verifiedClaim.plan_claim_id);
    if (!planClaim) {
      return {
        level: 'ERROR',
        type: 'missing_plan_claim',
        message: `Verified Claims claim 指向不存在的 plan claim: ${verifiedClaim.plan_claim_id}`,
        file: evidencePath,
        claim_id: verifiedClaim.claim_id,
        plan_claim_id: verifiedClaim.plan_claim_id,
        target: normalizedPlanPath
      };
    }

    if (planClaim.hash !== verifiedClaim.plan_hash) {
      return {
        level: 'ERROR',
        type: 'stale_plan_hash',
        message: `Verified Claims claim 的 plan_hash 已过期: ${verifiedClaim.plan_claim_id}`,
        file: evidencePath,
        claim_id: verifiedClaim.claim_id,
        plan_claim_id: verifiedClaim.plan_claim_id,
        target: normalizedPlanPath
      };
    }

    return null;
  }

  checkEvidenceCoverage(planTruth, evidenceTruth) {
    const coverage = new Map();
    const issues = [];

    for (const evidenceRecord of evidenceTruth.values()) {
      for (const verifiedClaim of evidenceRecord.verifiedClaims || []) {
        const planPath = this.normalizeRepoPath(verifiedClaim.plan_path);
        if (!coverage.has(planPath)) {
          coverage.set(planPath, new Set());
        }
        coverage.get(planPath).add(verifiedClaim.plan_claim_id);
      }
    }

    for (const [planPath, planRecord] of planTruth.entries()) {
      const claimIds = [...planRecord.claims.keys()];
      const covered = coverage.get(planPath) || new Set();
      if (claimIds.length === 0 || covered.size === 0 || covered.size === claimIds.length) {
        continue;
      }

      issues.push({
        level: 'WARNING',
        type: 'partial_evidence_coverage',
        message: 'Evidence 只验证了部分 Execution Truth claims',
        file: planPath
      });
    }

    return issues;
  }

  parseExecutionTruthBlock(doc) {
    return this.parseYamlSection(doc.body, this.rules.execution_truth?.heading, this.rules.execution_truth?.schema, 'claims');
  }

  parseVerifiedClaimsBlock(doc) {
    return this.parseYamlSection(doc.body, this.rules.verified_claims?.heading, this.rules.verified_claims?.schema, 'verified_claims');
  }

  parseYamlSection(body, heading, expectedSchema, listField) {
    const escapedHeading = heading.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const match = body.match(new RegExp(`## ${escapedHeading}\\n(?:[\\s\\S]*?)\`\`\`yaml\\n([\\s\\S]*?)\\n\`\`\``));

    if (!match) {
      return { exists: false };
    }

    try {
      const parsed = yaml.load(match[1]) || {};
      if (parsed.schema !== expectedSchema) {
        return {
          exists: true,
          error: `schema 必须是 ${expectedSchema}`
        };
      }

      if (!Array.isArray(parsed[listField])) {
        return {
          exists: true,
          error: `${listField} 必须是数组`
        };
      }

      return {
        exists: true,
        [listField === 'claims' ? 'claims' : 'verifiedClaims']: parsed[listField]
      };
    } catch (error) {
      return {
        exists: true,
        error: `YAML 解析失败: ${error.message}`
      };
    }
  }

  extractLevel2Sections(body) {
    const matches = [...body.matchAll(/^## (.+)$/gm)];
    const sections = [];

    for (let index = 0; index < matches.length; index++) {
      const match = matches[index];
      const heading = match[1].trim();
      const start = match.index;
      const end = index + 1 < matches.length ? matches[index + 1].index : body.length;
      sections.push({
        heading,
        content: body.slice(start, end)
      });
    }

    return sections;
  }

  extractDriftAnchor(sectionContent) {
    const match = sectionContent.match(/<!--\s*drift_anchor:\s*([A-Za-z0-9_-]+)\s*-->/);
    return match ? match[1] : null;
  }

  hashSectionContent(sectionContent, anchorId) {
    const marker = `<!-- drift_anchor: ${anchorId} -->`;
    const startIndex = sectionContent.indexOf(marker);
    if (startIndex === -1) {
      return null;
    }

    const afterAnchor = sectionContent.slice(startIndex + marker.length);
    return this.shortHash(this.normalizeMultiline(afterAnchor));
  }

  hashClaim(claim) {
    return this.shortHash(this.stableStringify(claim));
  }

  stableStringify(value) {
    if (Array.isArray(value)) {
      return `[${value.map(item => this.stableStringify(item)).join(',')}]`;
    }

    if (value && typeof value === 'object') {
      return `{${Object.keys(value).sort().map(key => `${JSON.stringify(key)}:${this.stableStringify(value[key])}`).join(',')}}`;
    }

    return JSON.stringify(value);
  }

  normalizeMultiline(value) {
    return value
      .split('\n')
      .map(line => line.trimEnd())
      .join('\n')
      .trim();
  }

  shortHash(value) {
    return crypto.createHash('sha256').update(value).digest('hex').slice(0, 12);
  }

  hasNonEmptyString(value) {
    return typeof value === 'string' && value.trim() !== '';
  }

  normalizeRepoPath(relPath) {
    return path.normalize(relPath).replace(/\\/g, '/').replace(/^\.\//, '');
  }

  isRepoRelativeMarkdownPath(repoRoot, relPath) {
    if (typeof relPath !== 'string' || relPath.trim() === '') {
      return false;
    }

    if (path.isAbsolute(relPath)) {
      return false;
    }

    if (!relPath.endsWith('.md')) {
      return false;
    }

    const resolved = path.resolve(repoRoot, relPath);
    const relative = path.relative(repoRoot, resolved);
    return relative && !relative.startsWith('..') && !path.isAbsolute(relative);
  }

  isValidDocType(docType) {
    return (this.rules.doc_types || []).includes(docType);
  }
}

module.exports = { ExecutionDriftChecker };
