/**
 * 实体提取器
 * Layer 2: 从文档中提取 entity、method、flow 等结构化元素
 */

class EntityExtractor {
  constructor(spec) {
    this.spec = spec;
  }
  
  extract(doc) {
    const typeDef = this.spec.document_types[doc.docType];
    
    return {
      ...doc,
      entities: this.extractEntities(doc, typeDef),
      methods: this.extractMethods(doc, typeDef),
      flows: this.extractFlows(doc, typeDef),
      schemas: this.extractSchemas(doc, typeDef),
      queries: this.extractQueries(doc, typeDef),
      signatures: {} // 将在处理所有 docs 后填充
    };
  }
  
  extractEntities(doc, typeDef) {
    const entities = [];
    const structuralSections = typeDef?.structural_sections || [];
    const entitySection = structuralSections.find(s => s.name === 'entities');
    
    if (!entitySection) {
      // 尝试从内容中自动提取
      return this.autoExtractEntities(doc);
    }
    
    // 找到 section marker 后的内容
    const sectionStart = this.findSectionStart(doc, entitySection.marker);
    if (sectionStart === -1) return entities;
    
    // 提取标记的元素
    const elementPattern = new RegExp(entitySection.element_pattern || '^### (.+?) <!-- entity -->$', 'gm');
    let match;
    
    while ((match = elementPattern.exec(doc.content)) !== null) {
      const name = match[1].trim();
      const line = doc.content.substring(0, match.index).split('\n').length;
      const definition = this.extractDefinition(doc, line);
      
      entities.push({
        name,
        line,
        definition,
        signature: this.computeSignature(definition)
      });
    }
    
    return entities;
  }
  
  autoExtractEntities(doc) {
    const entities = [];
    
    // 模式 1: ### Name <!-- entity -->
    const markedPattern = /^### (.+?) <!-- entity -->$/gm;
    let match;
    
    while ((match = markedPattern.exec(doc.content)) !== null) {
      const name = match[1].trim();
      const line = doc.content.substring(0, match.index).split('\n').length;
      const definition = this.extractDefinition(doc, line);
      
      entities.push({
        name,
        line,
        definition,
        signature: this.computeSignature(definition),
        marked: true
      });
    }
    
    // 模式 2: 裸 interface（警告但提取）
    const interfacePattern = /```typescript\s*\ninterface (\w+)\s*\{([^}]+)\}/g;
    while ((match = interfacePattern.exec(doc.content)) !== null) {
      const name = match[1];
      // 检查是否已被标记提取
      if (entities.some(e => e.name === name)) continue;
      
      const line = doc.content.substring(0, match.index).split('\n').length;
      const body = match[2];
      
      entities.push({
        name,
        line,
        definition: this.parseInterfaceBody(body),
        signature: this.computeSignatureFromInterface(body),
        marked: false, // 裸定义
        warning: '未标记的 entity，建议添加 <!-- entity -->'
      });
    }
    
    return entities;
  }
  
  extractMethods(doc, typeDef) {
    const methods = [];
    const structuralSections = typeDef?.structural_sections || [];
    const methodSection = structuralSections.find(s => s.name === 'methods');
    
    if (!methodSection) return methods;
    
    const elementPattern = new RegExp(methodSection.element_pattern || '^### (.+?) <!-- method -->$', 'gm');
    let match;
    
    while ((match = elementPattern.exec(doc.content)) !== null) {
      const name = match[1].trim();
      const line = doc.content.substring(0, match.index).split('\n').length;
      
      methods.push({
        name,
        line,
        // 方法签名提取较复杂，简化处理
        inputs: [],
        outputs: []
      });
    }
    
    return methods;
  }
  
  extractFlows(doc, typeDef) {
    const flows = [];
    const structuralSections = typeDef?.structural_sections || [];
    const flowSection = structuralSections.find(s => s.name === 'flows');
    
    if (!flowSection) return flows;
    
    const elementPattern = new RegExp(flowSection.element_pattern || '^### (.+?) <!-- flow -->$', 'gm');
    let match;
    
    while ((match = elementPattern.exec(doc.content)) !== null) {
      flows.push({
        name: match[1].trim(),
        line: doc.content.substring(0, match.index).split('\n').length
      });
    }
    
    return flows;
  }
  
  extractSchemas(doc, typeDef) {
    // 类似 entities，但标记为 schema
    return [];
  }
  
  extractQueries(doc, typeDef) {
    const queries = [];
    const structuralSections = typeDef?.structural_sections || [];
    const querySection = structuralSections.find(s => s.name === 'queries');
    
    if (!querySection) return queries;
    
    const elementPattern = new RegExp(querySection.element_pattern || '^### (.+?) <!-- query -->$', 'gm');
    let match;
    
    while ((match = elementPattern.exec(doc.content)) !== null) {
      queries.push({
        name: match[1].trim(),
        line: doc.content.substring(0, match.index).split('\n').length
      });
    }
    
    return queries;
  }
  
  findSectionStart(doc, marker) {
    for (let i = 0; i < doc.lines.length; i++) {
      if (doc.lines[i].includes(marker)) {
        return i;
      }
    }
    return -1;
  }
  
  extractDefinition(doc, startLine) {
    // 从 startLine 开始，提取代码块或表格定义
    const lines = doc.lines.slice(startLine - 1);
    
    // 找 TypeScript 代码块
    for (let i = 0; i < lines.length && i < 50; i++) {
      if (lines[i].trim() === '```typescript') {
        const codeBlock = [];
        i++;
        while (i < lines.length && lines[i].trim() !== '```') {
          codeBlock.push(lines[i]);
          i++;
        }
        return this.parseTypeScriptDefinition(codeBlock.join('\n'));
      }
    }
    
    // 找 Markdown 表格
    for (let i = 0; i < lines.length && i < 30; i++) {
      if (lines[i].includes('| 字段 |') || lines[i].includes('| Field |')) {
        return this.parseTableDefinition(lines.slice(i, i + 20));
      }
    }
    
    return null;
  }
  
  parseTypeScriptDefinition(code) {
    const fields = [];
    
    // 简单解析 interface 字段
    const fieldPattern = /(\w+)(\?)?:\s*(.+?);(?:\s*\/\/\s*(.+))?/g;
    let match;
    
    while ((match = fieldPattern.exec(code)) !== null) {
      fields.push({
        name: match[1],
        optional: !!match[2],
        type: match[3].trim(),
        comment: match[4]?.trim()
      });
    }
    
    return { type: 'typescript', fields };
  }
  
  parseTableDefinition(lines) {
    const fields = [];
    
    // 跳过表头和分隔符
    for (let i = 2; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line.startsWith('|')) break;
      
      const cells = line.split('|').map(c => c.trim()).filter(c => c);
      if (cells.length >= 2) {
        fields.push({
          name: cells[0].replace(/`/g, ''),
          type: cells[1],
          constraints: cells[2] || '',
          description: cells[3] || ''
        });
      }
    }
    
    return { type: 'table', fields };
  }
  
  parseInterfaceBody(body) {
    const fields = [];
    const lines = body.split('\n');
    
    for (const line of lines) {
      const match = line.match(/(\w+)(\?)?:\s*(.+?);/);
      if (match) {
        fields.push({
          name: match[1],
          optional: !!match[2],
          type: match[3].trim()
        });
      }
    }
    
    return { type: 'typescript', fields };
  }
  
  computeSignature(definition) {
    if (!definition || !definition.fields) return null;
    
    const sigConfig = this.spec.signature_config || {};
    const typeAliases = sigConfig.type_aliases || {};
    
    const normalizedFields = definition.fields.map(f => {
      let normalizedType = f.type;
      
      // 类型归一化
      for (const [canonical, aliases] of Object.entries(typeAliases)) {
        if (aliases.includes(f.type)) {
          normalizedType = canonical;
          break;
        }
      }
      
      return {
        name: f.name,
        type: normalizedType,
        optional: !!f.optional
      };
    });
    
    // 排序后哈希
    normalizedFields.sort((a, b) => a.name.localeCompare(b.name));
    return this.hashString(JSON.stringify(normalizedFields));
  }
  
  computeSignatureFromInterface(body) {
    const definition = this.parseInterfaceBody(body);
    return this.computeSignature(definition);
  }
  
  hashString(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return (hash >>> 0).toString(16).substring(0, 8);
  }
}

module.exports = { EntityExtractor };
