const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const DEFAULT_RULES_PATH = path.join(__dirname, '..', 'references', 'document-graph-phase2.yml');

class DocumentGraphChecker {
  constructor(rulesPath = DEFAULT_RULES_PATH) {
    this.rulesPath = rulesPath;
    this.rules = yaml.load(fs.readFileSync(rulesPath, 'utf-8'));
  }

  checkRoot(rootDir) {
    const repoRoot = path.resolve(rootDir);
    const candidateFiles = this.findCandidateFiles(repoRoot);
    const parsedDocs = candidateFiles.map(filePath => this.parseDocument(repoRoot, filePath));
    const issues = [];
    const nodes = new Map();

    for (const doc of parsedDocs) {
      issues.push(...this.validateDocumentShape(repoRoot, doc));
      if (doc.meta && this.isValidDocType(doc.meta.doc_type) && this.isValidStatus(doc.meta.status)) {
        nodes.set(doc.relPath, doc);
      }
    }

    issues.push(...this.validateGraph(nodes, repoRoot));

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
      return { relPath, content, meta: null };
    }

    let meta = null;
    try {
      meta = yaml.load(frontMatterMatch[1]) || {};
    } catch (error) {
      return {
        relPath,
        content,
        meta: null,
        parseError: error.message
      };
    }

    return { relPath, content, meta };
  }

  validateDocumentShape(repoRoot, doc) {
    const issues = [];

    if (!doc.meta) {
      issues.push({
        level: 'ERROR',
        type: doc.parseError ? 'invalid_front_matter' : 'missing_front_matter',
        message: doc.parseError
          ? `YAML front matter 解析失败: ${doc.parseError}`
          : '缺少 YAML front matter',
        file: doc.relPath
      });
      return issues;
    }

    if (!this.isValidDocType(doc.meta.doc_type)) {
      issues.push({
        level: 'ERROR',
        type: 'invalid_doc_type',
        message: `无效 doc_type: ${String(doc.meta.doc_type)}`,
        file: doc.relPath
      });
    }

    if (!this.isValidStatus(doc.meta.status)) {
      issues.push({
        level: 'ERROR',
        type: 'invalid_status',
        message: `无效 status: ${String(doc.meta.status)}`,
        file: doc.relPath
      });
    }

    const relationFields = new Set(this.rules.relation_fields || []);
    const allowedFields = new Set(this.rules.allowed_relations?.[doc.meta.doc_type] || []);

    for (const field of relationFields) {
      if (!Object.prototype.hasOwnProperty.call(doc.meta, field)) {
        continue;
      }

      if (!allowedFields.has(field)) {
        issues.push({
          level: 'ERROR',
          type: 'illegal_relation_field',
          message: `字段 ${field} 不允许出现在 ${doc.meta.doc_type} 文档中`,
          file: doc.relPath,
          field
        });
        continue;
      }

      const value = doc.meta[field];
      if (!Array.isArray(value)) {
        issues.push({
          level: 'ERROR',
          type: 'invalid_relation_field_shape',
          message: `字段 ${field} 必须是数组`,
          file: doc.relPath,
          field
        });
        continue;
      }

      const seen = new Set();
      for (const entry of value) {
        if (typeof entry !== 'string') {
          issues.push({
            level: 'ERROR',
            type: 'invalid_relation_value',
            message: `字段 ${field} 只允许字符串路径`,
            file: doc.relPath,
            field
          });
          continue;
        }

        const normalized = this.normalizeRepoPath(entry);
        if (!this.isRepoRelativeMarkdownPath(repoRoot, normalized)) {
          issues.push({
            level: 'ERROR',
            type: 'invalid_relation_path',
            message: `字段 ${field} 包含无效仓库相对路径: ${entry}`,
            file: doc.relPath,
            field,
            target: entry
          });
          continue;
        }

        if (normalized === doc.relPath) {
          issues.push({
            level: 'ERROR',
            type: 'self_reference',
            message: `字段 ${field} 不允许自引用`,
            file: doc.relPath,
            field,
            target: normalized
          });
        }

        if (seen.has(normalized)) {
          issues.push({
            level: 'ERROR',
            type: 'duplicate_relation',
            message: `字段 ${field} 存在重复引用: ${normalized}`,
            file: doc.relPath,
            field,
            target: normalized
          });
          continue;
        }
        seen.add(normalized);

        const targetPath = path.join(repoRoot, normalized);
        if (!fs.existsSync(targetPath)) {
          issues.push({
            level: 'ERROR',
            type: 'missing_relation_target',
            message: `字段 ${field} 指向的文档不存在: ${normalized}`,
            file: doc.relPath,
            field,
            target: normalized
          });
        }
      }
    }

    return issues;
  }

  validateGraph(nodes, repoRoot) {
    const issues = [];
    const incoming = new Map();
    const outgoing = new Map();
    const supersedesIncoming = new Map();

    for (const relPath of nodes.keys()) {
      incoming.set(relPath, 0);
      outgoing.set(relPath, 0);
      supersedesIncoming.set(relPath, 0);
    }

    for (const [relPath, doc] of nodes.entries()) {
      const relations = this.getRelationEntries(doc.meta);

      if (doc.meta.doc_type === 'plan' && doc.meta.status === 'active' && relations.implements.length === 0) {
        issues.push({
          level: 'WARNING',
          type: 'active_plan_missing_implements',
          message: 'active 的 plan 建议显式声明 implements',
          file: relPath
        });
      }

      for (const [field, targets] of Object.entries(relations)) {
        for (const targetRel of targets) {
          const targetDoc = nodes.get(targetRel);

          if (targetDoc) {
            outgoing.set(relPath, outgoing.get(relPath) + 1);
            incoming.set(targetRel, incoming.get(targetRel) + 1);
            if (field === 'supersedes') {
              supersedesIncoming.set(targetRel, supersedesIncoming.get(targetRel) + 1);
            }
          }

          const expectedType = this.rules.type_targets?.[doc.meta.doc_type]?.[field];
          if (expectedType) {
            if (!targetDoc || targetDoc.meta.doc_type !== expectedType) {
              issues.push({
                level: 'ERROR',
                type: 'invalid_relation_target_type',
                message: `字段 ${field} 必须指向 ${expectedType} 文档: ${targetRel}`,
                file: relPath,
                field,
                target: targetRel
              });
              continue;
            }
          }

          if ((this.rules.same_type_relations || []).includes(field)) {
            if (!targetDoc || targetDoc.meta.doc_type !== doc.meta.doc_type) {
              issues.push({
                level: 'ERROR',
                type: 'invalid_relation_target_type',
                message: `字段 ${field} 必须指向同类型文档: ${targetRel}`,
                file: relPath,
                field,
                target: targetRel
              });
              continue;
            }
          }

          if (targetDoc && ['deprecated', 'superseded'].includes(targetDoc.meta.status)) {
            issues.push({
              level: 'WARNING',
              type: 'deprecated_reference',
              message: `引用了 ${targetDoc.meta.status} 文档: ${targetRel}`,
              file: relPath,
              field,
              target: targetRel
            });
          }
        }
      }
    }

    for (const [relPath, doc] of nodes.entries()) {
      if (doc.meta.status === 'superseded' && supersedesIncoming.get(relPath) === 0) {
        issues.push({
          level: 'WARNING',
          type: 'unanchored_superseded',
          message: '文档标记为 superseded，但没有任何 supersedes 关系指向它',
          file: relPath
        });
      }

      if (incoming.get(relPath) === 0 && outgoing.get(relPath) === 0) {
        issues.push({
          level: 'WARNING',
          type: 'isolated_document',
          message: '文档未与任何其他 metadata-bearing 文档建立关系',
          file: relPath
        });
      }
    }

    return issues;
  }

  getRelationEntries(meta) {
    const relations = {};

    for (const field of this.rules.relation_fields || []) {
      const value = meta[field];
      relations[field] = Array.isArray(value)
        ? value.map(entry => this.normalizeRepoPath(entry))
        : [];
    }

    return relations;
  }

  normalizeRepoPath(relPath) {
    return path.normalize(relPath).replace(/\\/g, '/').replace(/^\.\//, '');
  }

  isRepoRelativeMarkdownPath(repoRoot, relPath) {
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

  isValidStatus(status) {
    return (this.rules.statuses || []).includes(status);
  }
}

module.exports = { DocumentGraphChecker };
