/**
 * 规范检查器
 * Layer 1: 检查文档是否符合类型规范
 */

class SpecChecker {
  constructor(spec) {
    this.spec = spec;
  }
  
  check(doc) {
    const issues = [];
    const typeDef = this.spec.document_types[doc.docType];
    
    if (!typeDef) {
      issues.push({
        level: 'WARNING',
        type: 'unknown_doc_type',
        message: `无法识别文档类型: ${doc.filePath}`,
        file: doc.filePath
      });
      return issues;
    }
    
    // 检查类型标记
    issues.push(...this.checkTypeTag(doc, typeDef));
    
    // 检查必需 section
    issues.push(...this.checkRequiredSections(doc, typeDef));
    
    // 检查结构标记
    issues.push(...this.checkStructuralMarkers(doc, typeDef));
    
    // 通用检查（链接、模糊词汇、长度）
    issues.push(...this.checkGeneralRules(doc));
    
    return issues;
  }
  
  checkTypeTag(doc, typeDef) {
    const issues = [];
    
    // auto_detect 类型不强制要求类型标记
    if (typeDef.auto_detect) {
      return issues;
    }
    
    if (typeDef.type_tag && !doc.hasTypeTag) {
      issues.push({
        level: 'ERROR',
        type: 'missing_type_tag',
        message: `缺少文档类型标记: ${typeDef.type_tag}`,
        file: doc.filePath,
        expected: typeDef.type_tag
      });
    }
    
    if (doc.hasTypeTag && doc.typeTag !== doc.docType) {
      issues.push({
        level: 'ERROR',
        type: 'type_mismatch',
        message: `文档类型标记与推断类型不一致: 标记为 ${doc.typeTag}, 推断为 ${doc.docType}`,
        file: doc.filePath
      });
    }
    
    return issues;
  }
  
  checkRequiredSections(doc, typeDef) {
    const issues = [];
    const sections = typeDef.required_sections || [];
    
    for (const section of sections) {
      // 如果标记为可选，跳过
      if (section.required === false) {
        continue;
      }
      
      const found = doc.sections.some(s => {
        if (section.pattern) {
          const regex = new RegExp(section.pattern, 'm');
          return regex.test(doc.content);
        }
        return s.name === section.name;
      });
      
      if (!found) {
        issues.push({
          level: 'ERROR',
          type: 'missing_required_section',
          message: `缺少必需 section: ${section.name}`,
          file: doc.filePath,
          expected: section.pattern || section.name
        });
      }
    }
    
    return issues;
  }
  
  checkStructuralMarkers(doc, typeDef) {
    const issues = [];
    const structuralSections = typeDef.structural_sections || [];
    
    for (const section of structuralSections) {
      if (!section.required) continue;
      
      // 检查是否有 section marker
      const hasMarker = doc.sections.some(s => 
        s.type === 'marker' && s.name === section.name
      );
      
      if (!hasMarker) {
        issues.push({
          level: 'WARNING',
          type: 'missing_section_marker',
          message: `建议添加 section 标记: ${section.marker}`,
          file: doc.filePath,
          expected: section.marker
        });
      }
      
      // 检查元素标记
      if (section.element_marker) {
        const pattern = new RegExp(section.element_pattern || section.element_marker, 'm');
        const hasElements = pattern.test(doc.content);
        
        if (!hasElements) {
          issues.push({
            level: 'ERROR',
            type: 'missing_structural_elements',
            message: `未找到标记的元素: ${section.element_marker}`,
            file: doc.filePath
          });
        }
      }
    }
    
    return issues;
  }
  
  checkGeneralRules(doc) {
    const issues = [];
    const rules = this.spec.lint_rules || {};
    
    // 检查文档长度
    if (rules.max_lines && doc.lines.length > rules.max_lines) {
      issues.push({
        level: rules.max_lines_severity || 'INFO',
        type: 'doc_too_long',
        message: `文档过长: ${doc.lines.length} 行 (建议 <= ${rules.max_lines})`,
        file: doc.filePath,
        line: doc.lines.length
      });
    }
    
    // 检查模糊词汇
    if (rules.vague_terms) {
      for (const term of rules.vague_terms) {
        const regex = new RegExp(term, 'g');
        let match;
        while ((match = regex.exec(doc.content)) !== null) {
          const line = doc.content.substring(0, match.index).split('\n').length;
          issues.push({
            level: rules.vague_terms_severity || 'WARNING',
            type: 'vague_term',
            message: `发现模糊词汇: "${term}"`,
            file: doc.filePath,
            line
          });
        }
      }
    }
    
    // 检查失效链接
    if (rules.check_broken_links) {
      issues.push(...this.checkBrokenLinks(doc));
    }
    
    return issues;
  }
  
  checkBrokenLinks(doc) {
    const issues = [];
    const linkRegex = /\[([^\]]+)\]\(([^)]+)\)/g;
    let match;
    
    while ((match = linkRegex.exec(doc.content)) !== null) {
      const linkPath = match[2];
      
      // 只检查相对链接
      if (linkPath.startsWith('http') || linkPath.startsWith('#')) {
        continue;
      }
      
      // 解析相对路径
      const baseDir = require('path').dirname(doc.filePath);
      const fullPath = require('path').resolve(baseDir, linkPath);
      
      if (!require('fs').existsSync(fullPath)) {
        const line = doc.content.substring(0, match.index).split('\n').length;
        issues.push({
          level: (this.spec.lint_rules?.link_check_severity) || 'WARNING',
          type: 'broken_link',
          message: `失效链接: ${linkPath}`,
          file: doc.filePath,
          line
        });
      }
    }
    
    return issues;
  }
}

module.exports = { SpecChecker };
