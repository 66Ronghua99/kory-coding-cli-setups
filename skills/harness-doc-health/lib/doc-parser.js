/**
 * 文档解析器
 * 解析 markdown 文件，提取元数据和结构
 */

const path = require('path');

class DocParser {
  constructor(spec) {
    this.spec = spec;
  }
  
  parse(filePath, content) {
    const docType = this.detectDocType(filePath, content);
    const typeTag = this.extractTypeTag(content);
    
    return {
      filePath,
      content,
      lines: content.split('\n'),
      docType,
      typeTag,
      hasTypeTag: !!typeTag,
      sections: this.extractSections(content),
      markers: this.extractMarkers(content)
    };
  }
  
  detectDocType(filePath, content) {
    // 1. 首先检查显式类型标记
    const typeMatch = content.match(/<!--\s*type:\s*([\w-]+)\s*-->/);
    if (typeMatch) {
      return this.validateDocType(typeMatch[1]);
    }
    
    // 2. 根据路径模式推断（优先检查 auto_detect 类型）
    const types = this.spec.document_types;
    
    // 先检查 auto_detect 类型（README, TEMPLATE 等）
    for (const [typeName, typeDef] of Object.entries(types)) {
      if (typeDef.auto_detect && typeDef.path_pattern) {
        const pattern = this.globToRegex(typeDef.path_pattern);
        if (pattern.test(filePath)) {
          return typeName;
        }
      }
    }
    
    // 再检查其他类型
    for (const [typeName, typeDef] of Object.entries(types)) {
      if (!typeDef.auto_detect && typeDef.path_pattern) {
        const pattern = this.globToRegex(typeDef.path_pattern);
        if (pattern.test(filePath)) {
          return typeName;
        }
      }
    }
    
    return 'unknown';
  }
  
  validateDocType(type) {
    return this.spec.document_types[type] ? type : 'unknown';
  }
  
  extractTypeTag(content) {
    const match = content.match(/<!--\s*type:\s*([\w-]+)\s*-->/);
    return match ? match[1] : null;
  }
  
  extractSections(content) {
    const sections = [];
    const lines = content.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      // 匹配 section 标记
      const sectionMatch = line.match(/<!--\s*section:(\w+)\s*-->/);
      if (sectionMatch) {
        sections.push({
          name: sectionMatch[1],
          line: i + 1,
          type: 'marker'
        });
        continue;
      }
      
      // 匹配 ## 标题
      const headerMatch = line.match(/^(#{2,3})\s+(.+)$/);
      if (headerMatch) {
        sections.push({
          name: headerMatch[2].trim(),
          level: headerMatch[1].length,
          line: i + 1,
          type: 'header'
        });
      }
    }
    
    return sections;
  }
  
  extractMarkers(content) {
    const markers = [];
    const lines = content.split('\n');
    
    const markerPatterns = [
      { type: 'entity', pattern: /<!--\s*entity\s*-->/ },
      { type: 'method', pattern: /<!--\s*method\s*-->/ },
      { type: 'flow', pattern: /<!--\s*flow\s*-->/ },
      { type: 'schema', pattern: /<!--\s*schema\s*-->/ },
      { type: 'query', pattern: /<!--\s*query\s*-->/ }
    ];
    
    for (let i = 0; i < lines.length; i++) {
      for (const { type, pattern } of markerPatterns) {
        if (pattern.test(lines[i])) {
          // 提取前面的标题
          const titleMatch = lines[i].match(/^(#{3,4})\s+(.+?)\s*<!--/);
          markers.push({
            type,
            line: i + 1,
            raw: lines[i],
            title: titleMatch ? titleMatch[2].trim() : null
          });
        }
      }
    }
    
    return markers;
  }
  
  globToRegex(pattern) {
    // 简单的 glob 转正则
    const regex = pattern
      .replace(/\*\*/g, '{{GLOBSTAR}}')
      .replace(/\*/g, '[^/]*')
      .replace(/\?/g, '.')
      .replace(/\{\{GLOBSTAR\}\}/g, '.*');
    return new RegExp(regex);
  }
}

module.exports = { DocParser };
