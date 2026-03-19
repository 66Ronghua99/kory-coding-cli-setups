#!/usr/bin/env node
/**
 * harness-doc-health - 文档健康检查主入口
 * 
 * 三层检查架构:
 * 1. 规范符合性 (Spec Compliance)
 * 2. 结构提取 (Structure Extraction)  
 * 3. 一致性验证 (Consistency Validation)
 */

const fs = require('fs');
const path = require('path');

const { loadSpec } = require('../lib/spec-loader');
const { DocParser } = require('../lib/doc-parser');
const { SpecChecker } = require('../lib/spec-checker');
const { EntityExtractor } = require('../lib/entity-extractor');
const { ConsistencyChecker } = require('../lib/consistency-checker');
const { Reporter } = require('../lib/reporter');
const { BootstrapChecker } = require('../lib/bootstrap-checker');
const { DocumentGraphChecker } = require('../lib/document-graph-checker');
const { ExecutionDriftChecker } = require('../lib/execution-drift-checker');

// CLI 参数解析
function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    path: null,
    verbose: false,
    json: false,
    specOnly: false,
    config: null,
    phase: null
  };
  
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--verbose') {
      options.verbose = true;
    } else if (args[i] === '--json') {
      options.json = true;
    } else if (args[i] === '--spec-only') {
      options.specOnly = true;
    } else if (args[i] === '--phase' && i + 1 < args.length) {
      options.phase = args[++i];
    } else if (args[i] === '--config' && i + 1 < args.length) {
      options.config = args[++i];
    } else if (!args[i].startsWith('--')) {
      options.path = args[i];
    }
  }
  
  if (!options.path) {
    console.error('Usage: node doc-health.js <path> [--verbose] [--json] [--spec-only] [--phase bootstrap|graph|drift]');
    process.exit(1);
  }
  
  return options;
}

// 查找所有 markdown 文件
function findMarkdownFiles(dir) {
  const files = [];
  
  function traverse(currentDir) {
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });
    
    for (const entry of entries) {
      const fullPath = path.join(currentDir, entry.name);
      
      if (entry.isDirectory() && entry.name !== 'node_modules') {
        traverse(fullPath);
      } else if (entry.isFile() && entry.name.endsWith('.md')) {
        files.push(fullPath);
      }
    }
  }
  
  traverse(dir);
  return files.sort();
}

// 主流程
async function main() {
  const options = parseArgs();
  const targetPath = path.resolve(options.path);
  const reporter = new Reporter(options);

  if (options.phase === 'bootstrap') {
    if (!fs.statSync(targetPath).isDirectory()) {
      console.error('Bootstrap phase requires a repository root directory.');
      process.exit(1);
    }

    reporter.section('Phase 1: Bootstrap Health');
    const checker = new BootstrapChecker();
    const issues = checker.checkRoot(targetPath);
    reporter.reportBootstrapIssues(targetPath, issues);
    reporter.summary(issues, [], []);

    const hasBlockingIssues = issues.some(issue => issue.level === 'ERROR');
    process.exit(hasBlockingIssues ? 1 : 0);
  }

  if (options.phase === 'graph') {
    if (!fs.statSync(targetPath).isDirectory()) {
      console.error('Graph phase requires a repository root directory.');
      process.exit(1);
    }

    reporter.section('Phase 2: Document Graph Health');
    const checker = new DocumentGraphChecker();
    const issues = checker.checkRoot(targetPath);
    reporter.reportGraphIssues(targetPath, issues);
    reporter.summary([], [], issues);

    const hasBlockingIssues = issues.some(issue => issue.level === 'ERROR');
    process.exit(hasBlockingIssues ? 1 : 0);
  }

  if (options.phase === 'drift') {
    if (!fs.statSync(targetPath).isDirectory()) {
      console.error('Drift phase requires a repository root directory.');
      process.exit(1);
    }

    reporter.section('Phase 3: Execution Drift Health');
    const checker = new ExecutionDriftChecker();
    const issues = checker.checkRoot(targetPath);
    reporter.reportDriftIssues(targetPath, issues);
    reporter.summary([], [], issues);

    const hasBlockingIssues = issues.some(issue => issue.level === 'ERROR');
    process.exit(hasBlockingIssues ? 1 : 0);
  }
  
  // 加载规范
  const spec = loadSpec(options.config);
  
  // 查找文件
  const files = fs.statSync(targetPath).isDirectory() 
    ? findMarkdownFiles(targetPath)
    : [targetPath];
  
  // 初始化组件
  const parser = new DocParser(spec);
  const specChecker = new SpecChecker(spec);
  const extractor = new EntityExtractor(spec);
  const consistencyChecker = new ConsistencyChecker(spec);
  
  // 解析所有文档
  const docs = [];
  for (const file of files) {
    const content = fs.readFileSync(file, 'utf-8');
    const relativePath = path.relative(process.cwd(), file);
    const doc = parser.parse(relativePath, content);
    docs.push(doc);
  }
  
  // ========== Layer 1: 规范符合性检查 ==========
  reporter.section('Layer 1: 规范符合性');
  const specIssues = [];
  
  for (const doc of docs) {
    const issues = specChecker.check(doc);
    specIssues.push(...issues);
    reporter.reportDocCheck(doc, issues);
  }
  
  const hasSpecErrors = specIssues.some(i => i.level === 'ERROR');
  
  if (hasSpecErrors) {
    reporter.summary(specIssues, [], []);
    process.exit(1);
  }
  
  if (options.specOnly) {
    reporter.summary(specIssues, [], []);
    process.exit(0);
  }
  
  // ========== Layer 2: 结构提取 ==========
  reporter.section('Layer 2: 结构提取');
  
  const extractedDocs = [];
  for (const doc of docs) {
    const extracted = extractor.extract(doc);
    extractedDocs.push(extracted);
  }
  
  reporter.reportExtractionSummary(extractedDocs);
  
  // ========== Layer 3: 一致性验证 ==========
  reporter.section('Layer 3: 一致性验证');
  
  const consistencyIssues = consistencyChecker.check(extractedDocs);
  reporter.reportConsistencyIssues(consistencyIssues);
  
  // 输出总结
  reporter.summary(specIssues, [], consistencyIssues);
  
  // 退出码
  const hasBlockingIssues = consistencyIssues.some(i => i.level === 'ERROR');
  process.exit(hasBlockingIssues ? 1 : 0);
}

main().catch(err => {
  console.error('Error:', err.message);
  console.error(err.stack);
  process.exit(1);
});
