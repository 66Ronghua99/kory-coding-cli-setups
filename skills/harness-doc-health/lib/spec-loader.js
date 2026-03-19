/**
 * 规范加载器
 * 加载内置 doc-spec.yml 和项目级配置
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const DEFAULT_SPEC_PATH = path.join(__dirname, '..', 'references', 'doc-spec.yml');

function loadSpec(configPath = null) {
  // 加载内置规范
  const builtinSpec = yaml.load(fs.readFileSync(DEFAULT_SPEC_PATH, 'utf-8'));
  
  // 如果提供了项目级配置，合并
  if (configPath && fs.existsSync(configPath)) {
    const projectSpec = yaml.load(fs.readFileSync(configPath, 'utf-8'));
    return mergeSpecs(builtinSpec, projectSpec);
  }
  
  // 检查项目根目录是否有 doc-health.config.js
  const projectConfig = findProjectConfig();
  if (projectConfig) {
    const projectSpec = require(projectConfig);
    return mergeSpecs(builtinSpec, projectSpec);
  }
  
  return builtinSpec;
}

function findProjectConfig() {
  let currentDir = process.cwd();
  
  while (currentDir !== path.dirname(currentDir)) {
    const configPath = path.join(currentDir, 'doc-health.config.js');
    if (fs.existsSync(configPath)) {
      return configPath;
    }
    currentDir = path.dirname(currentDir);
  }
  
  return null;
}

function mergeSpecs(base, override) {
  // 简单深合并
  const result = JSON.parse(JSON.stringify(base));
  
  for (const [key, value] of Object.entries(override)) {
    if (typeof value === 'object' && !Array.isArray(value) && value !== null) {
      result[key] = mergeSpecs(result[key] || {}, value);
    } else {
      result[key] = value;
    }
  }
  
  return result;
}

module.exports = { loadSpec };
