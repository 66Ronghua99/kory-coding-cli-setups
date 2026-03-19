/**
 * 报告生成器
 * 格式化输出检查结果
 */

class Reporter {
  constructor(options = {}) {
    this.options = options;
    this.output = [];
  }
  
  section(title) {
    this.log(`\n=== ${title} ===`);
  }
  
  log(message) {
    this.output.push(message);
    if (!this.options.json) {
      console.log(message);
    }
  }

  formatIssueContext(issue, fallbackPath) {
    const parts = [issue.file || fallbackPath];

    if (issue.claim_id) {
      parts.push(`claim_id=${issue.claim_id}`);
    }

    if (issue.plan_claim_id) {
      parts.push(`plan_claim_id=${issue.plan_claim_id}`);
    }

    if (issue.anchor) {
      parts.push(`anchor=${issue.anchor}`);
    }

    if (issue.field) {
      parts.push(`field=${issue.field}`);
    }

    if (issue.key) {
      parts.push(`key=${issue.key}`);
    }

    if (issue.heading) {
      parts.push(`heading=${issue.heading}`);
    }

    if (issue.marker) {
      parts.push(`marker=${issue.marker}`);
    }

    if (issue.target) {
      parts.push(`target=${issue.target}`);
    }

    return parts.join(' | ');
  }

  explainBootstrapOutput() {
    this.log('  说明: 先修复所有 ERROR。括号中的第一段是源文档；`key` / `heading` / `marker` 表示具体缺失槽位。');
  }

  explainGraphOutput() {
    this.log('  说明: 先修复所有 ERROR。括号中的第一段是源文档；`field` 是关系字段；`target` 是被引用的目标文档。');
  }

  explainDriftOutput() {
    this.log('  说明: 先修复所有 ERROR。括号中的第一段是源文档；`claim_id` 表示具体执行或验证 claim；`anchor` 表示 drift_anchor；`target` 是被引用的上游文档。');
  }
  
  reportDocCheck(doc, issues) {
    const errors = issues.filter(i => i.level === 'ERROR');
    const warnings = issues.filter(i => i.level === 'WARNING');
    const infos = issues.filter(i => i.level === 'INFO');
    
    if (errors.length === 0 && warnings.length === 0 && infos.length === 0) {
      this.log(`  ✅ ${doc.filePath} (${doc.docType})`);
      return;
    }
    
    const parts = [`  ${errors.length > 0 ? '❌' : warnings.length > 0 ? '⚠️' : 'ℹ️'} ${doc.filePath} (${doc.docType})`];
    if (errors.length) parts.push(`${errors.length} error(s)`);
    if (warnings.length) parts.push(`${warnings.length} warning(s)`);
    if (infos.length) parts.push(`${infos.length} info`);
    
    this.log(parts.join(' - '));
    
    for (const issue of issues) {
      const icon = issue.level === 'ERROR' ? '  🔴' : issue.level === 'WARNING' ? '  🟡' : '  🟢';
      const location = issue.line ? `:${issue.line}` : '';
      this.log(`${icon} [${issue.type}] ${issue.message} (${doc.filePath}${location})`);
      
      if (this.options.verbose && issue.expected) {
        this.log(`      期望: ${issue.expected}`);
      }
    }
  }

  reportBootstrapIssues(rootPath, issues) {
    const errors = issues.filter(i => i.level === 'ERROR');
    const warnings = issues.filter(i => i.level === 'WARNING');
    const infos = issues.filter(i => i.level === 'INFO');

    if (errors.length === 0 && warnings.length === 0 && infos.length === 0) {
      this.log(`  ✅ ${rootPath} (bootstrap)`);
      this.explainBootstrapOutput();
      return;
    }

    const parts = [`  ${errors.length > 0 ? '❌' : warnings.length > 0 ? '⚠️' : 'ℹ️'} ${rootPath} (bootstrap)`];
    if (errors.length) parts.push(`${errors.length} error(s)`);
    if (warnings.length) parts.push(`${warnings.length} warning(s)`);
    if (infos.length) parts.push(`${infos.length} info`);

    this.log(parts.join(' - '));
    this.explainBootstrapOutput();

    for (const issue of issues) {
      const icon = issue.level === 'ERROR' ? '  🔴' : issue.level === 'WARNING' ? '  🟡' : '  🟢';
      this.log(`${icon} [${issue.type}] ${issue.message} (${this.formatIssueContext(issue, rootPath)})`);
    }
  }

  reportGraphIssues(rootPath, issues) {
    const errors = issues.filter(i => i.level === 'ERROR');
    const warnings = issues.filter(i => i.level === 'WARNING');
    const infos = issues.filter(i => i.level === 'INFO');

    if (errors.length === 0 && warnings.length === 0 && infos.length === 0) {
      this.log(`  ✅ ${rootPath} (graph)`);
      this.explainGraphOutput();
      return;
    }

    const parts = [`  ${errors.length > 0 ? '❌' : warnings.length > 0 ? '⚠️' : 'ℹ️'} ${rootPath} (graph)`];
    if (errors.length) parts.push(`${errors.length} error(s)`);
    if (warnings.length) parts.push(`${warnings.length} warning(s)`);
    if (infos.length) parts.push(`${infos.length} info`);

    this.log(parts.join(' - '));
    this.explainGraphOutput();

    for (const issue of issues) {
      const icon = issue.level === 'ERROR' ? '  🔴' : issue.level === 'WARNING' ? '  🟡' : '  🟢';
      this.log(`${icon} [${issue.type}] ${issue.message} (${this.formatIssueContext(issue, rootPath)})`);
    }
  }

  reportDriftIssues(rootPath, issues) {
    const errors = issues.filter(i => i.level === 'ERROR');
    const warnings = issues.filter(i => i.level === 'WARNING');
    const infos = issues.filter(i => i.level === 'INFO');

    if (errors.length === 0 && warnings.length === 0 && infos.length === 0) {
      this.log(`  ✅ ${rootPath} (drift)`);
      this.explainDriftOutput();
      return;
    }

    const parts = [`  ${errors.length > 0 ? '❌' : warnings.length > 0 ? '⚠️' : 'ℹ️'} ${rootPath} (drift)`];
    if (errors.length) parts.push(`${errors.length} error(s)`);
    if (warnings.length) parts.push(`${warnings.length} warning(s)`);
    if (infos.length) parts.push(`${infos.length} info`);

    this.log(parts.join(' - '));
    this.explainDriftOutput();

    for (const issue of issues) {
      const icon = issue.level === 'ERROR' ? '  🔴' : issue.level === 'WARNING' ? '  🟡' : '  🟢';
      this.log(`${icon} [${issue.type}] ${issue.message} (${this.formatIssueContext(issue, rootPath)})`);
    }
  }
  
  reportExtractionSummary(docs) {
    let totalEntities = 0;
    let totalMethods = 0;
    let totalFlows = 0;
    let bareEntities = 0;
    
    for (const doc of docs) {
      totalEntities += doc.entities?.length || 0;
      totalMethods += doc.methods?.length || 0;
      totalFlows += doc.flows?.length || 0;
      bareEntities += doc.entities?.filter(e => !e.marked).length || 0;
    }
    
    this.log(`  提取 entity: ${totalEntities} 个${bareEntities > 0 ? ` (${bareEntities} 个未标记)` : ''}`);
    this.log(`  提取 method: ${totalMethods} 个`);
    this.log(`  提取 flow: ${totalFlows} 个`);
  }
  
  reportConsistencyIssues(issues) {
    if (issues.length === 0) {
      this.log('  ✅ 所有一致性检查通过');
      return;
    }
    
    // 分组显示
    const byType = new Map();
    for (const issue of issues) {
      if (!byType.has(issue.type)) {
        byType.set(issue.type, []);
      }
      byType.get(issue.type).push(issue);
    }
    
    for (const [type, typeIssues] of byType) {
      for (const issue of typeIssues) {
        const icon = issue.level === 'ERROR' ? '🔴' : issue.level === 'WARNING' ? '🟡' : '🟢';
        this.log(`\n  ${icon} ${issue.type}: ${issue.message}`);
        
        if (issue.locations) {
          for (const loc of issue.locations) {
            this.log(`     - ${loc.file}:${loc.line}`);
          }
        }
        
        if (this.options.verbose && issue.diff) {
          this.reportDiff(issue.diff);
        }
        
        if (issue.plan && issue.architecture) {
          this.log(`     Plan: ${issue.plan.file} [${issue.plan.status}] 签名: ${issue.plan.signature}`);
          this.log(`     Architecture: ${issue.architecture.file} 签名: ${issue.architecture.signature}`);
        }
      }
    }
  }
  
  reportDiff(diff) {
    if (diff.missingFields?.length) {
      this.log(`     缺失字段:`);
      for (const f of diff.missingFields) {
        this.log(`       - ${f.field} (存在于 ${f.existsIn})`);
      }
    }
    if (diff.typeMismatches?.length) {
      this.log(`     类型不一致:`);
      for (const m of diff.typeMismatches) {
        this.log(`       - ${m.field}: ${m.inA.type} vs ${m.inB.type}`);
      }
    }
  }
  
  summary(specIssues, extractIssues, consistencyIssues) {
    const errors = [
      ...specIssues.filter(i => i.level === 'ERROR'),
      ...consistencyIssues.filter(i => i.level === 'ERROR')
    ];
    const warnings = [
      ...specIssues.filter(i => i.level === 'WARNING'),
      ...consistencyIssues.filter(i => i.level === 'WARNING')
    ];
    const infos = specIssues.filter(i => i.level === 'INFO');
    
    this.log(`\n=== 总结 ===`);
    this.log(`错误: ${errors.length} | 警告: ${warnings.length} | 提示: ${infos.length}`);
    
    const blocking = errors.length > 0;
    this.log(blocking ? '状态: ❌ 阻止实施' : '状态: ✅ 通过');
    
    if (this.options.json) {
      const report = {
        summary: {
          errors: errors.length,
          warnings: warnings.length,
          infos: infos.length,
          blocking
        },
        errors: errors.map(e => ({
          type: e.type,
          message: e.message,
          file: e.file || e.planFile,
          line: e.line,
          ...(e.entity && { entity: e.entity }),
          ...(e.diff && { diff: e.diff })
        })),
        warnings: warnings.map(w => ({
          type: w.type,
          message: w.message,
          file: w.file || w.plan?.file,
          ...(w.entity && { entity: w.entity }),
          ...(w.diff && { diff: w.diff })
        }))
      };
      
      console.log(JSON.stringify(report, null, 2));
    }
  }
}

module.exports = { Reporter };
