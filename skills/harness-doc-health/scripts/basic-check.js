#!/usr/bin/env node
/**
 * 基础文档检查
 * 
 * 快速识别明显的文档问题，无需配置。
 * 适用于任何项目，作为文档健康的第一道检查。
 * 
 * 检测项（全部自动，无需配置）：
 * - 失效的内部链接
 * - 文档过长（>300行）
 * - 缺少维护者信息
 * - 模糊词汇（快速、大量、主要）
 */

const fs = require('fs');
const path = require('path');

function collectFiles(dir) {
  const files = [];
  
  function walk(current) {
    const entries = fs.readdirSync(current, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.name.startsWith('.') || entry.name === 'node_modules') continue;
      
      const full = path.join(current, entry.name);
      if (entry.isDirectory()) {
        walk(full);
      } else if (entry.name.endsWith('.md')) {
        files.push({
          path: full,
          content: fs.readFileSync(full, 'utf-8')
        });
      }
    }
  }
  
  walk(dir);
  return files;
}

function checkBrokenLinks(file) {
  const issues = [];
  const regex = /\[([^\]]+)\]\((\.\/[^)]+)\)/g;
  let match;
  
  while ((match = regex.exec(file.content)) !== null) {
    const linkPath = match[2];
    const resolved = path.resolve(path.dirname(file.path), linkPath);
    
    const exists = ['', '.md', '.ts', '.js'].some(ext => fs.existsSync(resolved + ext));
    
    if (!exists) {
      const line = file.content.substring(0, match.index).split('\n').length;
      issues.push({
        level: 'P1',
        type: 'broken-link',
        message: `链接 "${linkPath}" 指向的文件不存在`,
        location: `${file.path}:${line}`
      });
    }
  }
  
  return issues;
}

function checkDocSize(file) {
  const lines = file.content.split('\n').length;
  if (lines > 300) {
    return [{
      level: 'P2',
      type: 'doc-too-long',
      message: `${lines} 行，建议拆分为多个文件`,
      location: file.path
    }];
  }
  return [];
}

function checkMaintainer(file) {
  if (!/维护者|maintainer|author/i.test(file.content)) {
    return [{
      level: 'P2',
      type: 'no-maintainer',
      message: '缺少维护者信息',
      location: file.path
    }];
  }
  return [];
}

function checkVagueTerms(file) {
  const issues = [];
  const patterns = [
    { word: '快/高效', pattern: /(?:很|非常)?(?:快|高效|迅速)/ },
    { word: '大量', pattern: /(?:大量|高并发|许多)/ },
    { word: '主要', pattern: /主要|大部分/ },
  ];
  
  const lines = file.content.split('\n');
  
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('```')) continue;
    
    for (const { word, pattern } of patterns) {
      if (pattern.test(lines[i]) && !/\d/.test(lines[i])) {
        issues.push({
          level: 'P1',
          type: 'vague-term',
          message: `模糊词汇 "${word}"，建议量化`,
          location: `${file.path}:${i + 1}`
        });
      }
    }
  }
  
  return issues;
}

function main() {
  const targetDir = process.argv[2] || 'docs';
  
  if (!fs.existsSync(targetDir)) {
    console.error(`Error: Directory not found: ${targetDir}`);
    process.exit(1);
  }
  
  console.log(`\n🔍 Basic Doc Health Check`);
  console.log(`Target: ${targetDir}\n`);
  
  const files = collectFiles(targetDir);
  console.log(`Found ${files.length} markdown files\n`);
  
  const allIssues = [];
  
  for (const file of files) {
    allIssues.push(...checkBrokenLinks(file));
    allIssues.push(...checkDocSize(file));
    allIssues.push(...checkMaintainer(file));
    allIssues.push(...checkVagueTerms(file));
  }
  
  // 按级别分组
  const p0 = allIssues.filter(i => i.level === 'P0');
  const p1 = allIssues.filter(i => i.level === 'P1');
  const p2 = allIssues.filter(i => i.level === 'P2');
  
  // 输出
  if (p0.length > 0) {
    console.log('🔴 P0 - Critical');
    p0.forEach(i => console.log(`  [${i.type}] ${i.message}\n    at ${i.location}`));
    console.log();
  }
  
  if (p1.length > 0) {
    console.log('🟡 P1 - Important');
    p1.slice(0, 10).forEach(i => console.log(`  [${i.type}] ${i.message}\n    at ${i.location}`));
    if (p1.length > 10) console.log(`  ... and ${p1.length - 10} more`);
    console.log();
  }
  
  if (p2.length > 0) {
    console.log('🟢 P2 - Recommended');
    p2.slice(0, 5).forEach(i => console.log(`  [${i.type}] ${i.message}\n    at ${i.location}`));
    if (p2.length > 10) console.log(`  ... and ${p2.length - 5} more`);
    console.log();
  }
  
  if (allIssues.length === 0) {
    console.log('✅ No issues found!\n');
  } else {
    console.log(`Summary: ${p0.length} Critical | ${p1.length} Important | ${p2.length} Recommended\n`);
  }
  
  process.exit(p0.length > 0 ? 1 : 0);
}

main();
