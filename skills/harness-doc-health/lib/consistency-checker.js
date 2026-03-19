/**
 * 一致性检查器
 * Layer 3: 跨文档一致性验证和回归检测
 */

class ConsistencyChecker {
  constructor(spec) {
    this.spec = spec;
  }
  
  check(extractedDocs) {
    const issues = [];
    
    // 1. Entity 定义一致性
    issues.push(...this.checkEntityConsistency(extractedDocs));
    
    // 2. Plan 引用检查
    issues.push(...this.checkPlanReferences(extractedDocs));
    
    // 3. 回归检测
    issues.push(...this.checkRegression(extractedDocs));
    
    // 4. 时间戳存储格式检查
    issues.push(...this.checkTimeStorageFormat(extractedDocs));
    
    // 5. 状态同步检查
    issues.push(...this.checkStatusSync(extractedDocs));
    
    return issues;
  }
  
  checkEntityConsistency(docs) {
    const issues = [];
    
    // 收集所有 entity
    const allEntities = [];
    for (const doc of docs) {
      for (const entity of doc.entities || []) {
        allEntities.push({
          ...entity,
          docPath: doc.filePath,
          docType: doc.docType
        });
      }
    }
    
    // 按名称分组
    const byName = new Map();
    for (const entity of allEntities) {
      if (!byName.has(entity.name)) {
        byName.set(entity.name, []);
      }
      byName.get(entity.name).push(entity);
    }
    
    // 检查每个同名 entity
    for (const [name, definitions] of byName) {
      if (definitions.length < 2) continue;
      
      // 对比所有定义
      const base = definitions[0];
      for (let i = 1; i < definitions.length; i++) {
        const compare = definitions[i];
        const diff = this.compareDefinitions(base, compare);
        
        if (diff.hasDiff) {
          issues.push({
            level: 'ERROR',
            type: 'entity_conflict',
            entity: name,
            message: `${name} 定义不一致`,
            locations: [
              { file: base.docPath, line: base.line },
              { file: compare.docPath, line: compare.line }
            ],
            diff: diff.details
          });
        }
      }
    }
    
    return issues;
  }
  
  compareDefinitions(a, b) {
    const details = {
      missingFields: [],
      typeMismatches: [],
      optionalMismatches: []
    };
    
    if (!a.definition || !b.definition) {
      return { hasDiff: false, details };
    }
    
    const aFields = a.definition.fields || [];
    const bFields = b.definition.fields || [];
    
    const aFieldMap = new Map(aFields.map(f => [f.name, f]));
    const bFieldMap = new Map(bFields.map(f => [f.name, f]));
    
    // 检查缺失字段
    for (const [name, field] of aFieldMap) {
      if (!bFieldMap.has(name)) {
        details.missingFields.push({
          field: name,
          existsIn: a.docPath,
          missingIn: b.docPath
        });
      } else {
        // 检查类型一致性
        const bField = bFieldMap.get(name);
        if (this.normalizeType(field.type) !== this.normalizeType(bField.type)) {
          details.typeMismatches.push({
            field: name,
            inA: { type: field.type, doc: a.docPath },
            inB: { type: bField.type, doc: b.docPath }
          });
        }
        
        // 检查可选性
        if (!!field.optional !== !!bField.optional) {
          details.optionalMismatches.push({
            field: name,
            inA: { optional: !!field.optional, doc: a.docPath },
            inB: { optional: !!bField.optional, doc: b.docPath }
          });
        }
      }
    }
    
    // 反向检查（B 有但 A 没有）
    for (const [name, field] of bFieldMap) {
      if (!aFieldMap.has(name)) {
        details.missingFields.push({
          field: name,
          existsIn: b.docPath,
          missingIn: a.docPath
        });
      }
    }
    
    const hasDiff = details.missingFields.length > 0 ||
                   details.typeMismatches.length > 0 ||
                   details.optionalMismatches.length > 0;
    
    return { hasDiff, details };
  }
  
  normalizeType(type) {
    if (!type) return 'unknown';
    
    const sigConfig = this.spec.signature_config || {};
    const typeAliases = sigConfig.type_aliases || {};
    
    // 去除空白和可选标记
    let normalized = type.replace(/\s+/g, ' ').trim();
    
    // 检查别名
    for (const [canonical, aliases] of Object.entries(typeAliases)) {
      if (aliases.includes(normalized)) {
        return canonical;
      }
    }
    
    return normalized;
  }
  
  checkPlanReferences(docs) {
    const issues = [];
    
    // 获取所有 Plan
    const plans = docs.filter(d => d.docType === 'plan');
    
    // 获取所有 Architecture entity
    const architectureDocs = docs.filter(d => 
      d.docType === 'domain-types' || d.docType === 'domain-service'
    );
    const architectureEntities = new Set();
    for (const doc of architectureDocs) {
      for (const entity of doc.entities || []) {
        architectureEntities.add(entity.name);
      }
    }
    
    // 检查每个 Plan
    for (const plan of plans) {
      for (const entity of plan.entities || []) {
        if (!architectureEntities.has(entity.name)) {
          issues.push({
            level: 'ERROR',
            type: 'missing_entity_reference',
            entity: entity.name,
            message: `Plan 引用 "${entity.name}"，但在 Architecture 中未定义`,
            planFile: plan.filePath,
            planLine: entity.line
          });
        }
      }
    }
    
    return issues;
  }
  
  checkRegression(docs) {
    const issues = [];
    const regConfig = this.spec.regression_detection || {};
    
    if (!regConfig.check_completed_plans) return issues;
    
    // 获取已完成的 Plan
    const completedPlans = docs.filter(d => {
      if (d.docType !== 'plan') return false;
      // 检查状态标记
      return d.content.includes('状态:') && 
             (d.content.includes('✅ 已完成') || d.content.includes('已完成'));
    });
    
    // 获取 Architecture entity 映射
    const archEntityMap = new Map();
    for (const doc of docs) {
      if (doc.docType === 'domain-types') {
        for (const entity of doc.entities || []) {
          archEntityMap.set(entity.name, {
            ...entity,
            docPath: doc.filePath
          });
        }
      }
    }
    
    // 对比每个已完成的 Plan
    for (const plan of completedPlans) {
      for (const planEntity of plan.entities || []) {
        const archEntity = archEntityMap.get(planEntity.name);
        if (!archEntity) continue;
        
        // 对比签名
        if (planEntity.signature && archEntity.signature &&
            planEntity.signature !== archEntity.signature) {
          
          const diff = this.compareDefinitions(
            { ...planEntity, docPath: plan.filePath },
            { ...archEntity, docPath: archEntity.docPath }
          );
          
          issues.push({
            level: regConfig.completed_plan_mismatch_severity || 'WARNING',
            type: 'signature_drift',
            entity: planEntity.name,
            message: `${planEntity.name} 签名漂移（回归）`,
            plan: {
              file: plan.filePath,
              status: '已完成',
              signature: planEntity.signature
            },
            architecture: {
              file: archEntity.docPath,
              signature: archEntity.signature
            },
            diff: diff.details
          });
        }
      }
    }
    
    return issues;
  }
  
  checkTimeStorageFormat(docs) {
    const issues = [];
    
    // 获取 domain-types 中时间相关字段
    const typeDocs = docs.filter(d => d.docType === 'domain-types');
    const repoDocs = docs.filter(d => d.docType === 'domain-repo');
    
    for (const repo of repoDocs) {
      // 检查 repo 文档中是否提到了时间戳存储格式
      const hasTimeStorage = /时间戳.*存储|Unix.*秒|毫秒|存储.*时间/i.test(repo.content);
      
      if (hasTimeStorage) {
        // 提取存储格式
        const storageMatch = repo.content.match(/时间戳.*(Unix\s*秒|秒级|毫秒|timestamp)/i);
        const storageFormat = storageMatch ? storageMatch[1] : 'unknown';
        
        // 检查对应的 types.md 中是否有 DateTime 字段
        const relatedTypeDoc = typeDocs.find(t => 
          t.filePath.includes(repo.filePath.replace('repo.md', ''))
        );
        
        if (relatedTypeDoc) {
          const hasDateTimeField = relatedTypeDoc.content.includes('DateTime') ||
                                   relatedTypeDoc.content.includes('Date');
          
          if (hasDateTimeField && storageFormat.includes('秒')) {
            // 发现潜在不一致：DateTime 类型 vs 秒级存储
            issues.push({
              level: 'WARNING',
              type: 'time_storage_format_mismatch',
              message: `Repo 使用 ${storageFormat} 存储，但 Entity 定义为 DateTime，需确保转换逻辑完整`,
              repo: repo.filePath,
              types: relatedTypeDoc.filePath,
              suggestion: '在 repo.md 中明确说明转换逻辑：new Date(timestamp * 1000)'
            });
          }
        }
      }
    }
    
    return issues;
  }
  
  checkStatusSync(docs) {
    const issues = [];
    
    // 获取 Review 和 Plan 的关联
    const reviews = docs.filter(d => d.docType === 'review');
    const plans = docs.filter(d => d.docType === 'plan');
    
    for (const review of reviews) {
      // 从 Review 内容中提取关联的 Plan
      const planLinks = this.extractPlanLinks(review.content);
      
      for (const planRef of planLinks) {
        const plan = plans.find(p => p.filePath.includes(planRef));
        if (!plan) continue;
        
        // 检查状态一致性
        const reviewApproved = review.content.includes('✅ 已修正') ||
                               review.content.includes('✅ 可实施');
        const planCompleted = plan.content.includes('✅ 已完成');
        
        if (reviewApproved && !planCompleted) {
          issues.push({
            level: 'WARNING',
            type: 'status_mismatch',
            message: `Review 标记可实施，但 Plan 未标记完成`,
            review: review.filePath,
            plan: plan.filePath
          });
        }
      }
    }
    
    return issues;
  }
  
  extractPlanLinks(content) {
    const links = [];
    const pattern = /\[.+?\]\((.+?\/([\w-]+)\.md)\)/g;
    let match;
    
    while ((match = pattern.exec(content)) !== null) {
      if (match[1].includes('plans/')) {
        links.push(match[2]);
      }
    }
    
    return links;
  }
}

module.exports = { ConsistencyChecker };
