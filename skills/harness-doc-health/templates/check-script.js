/**
 * doc-health.config.js 模板
 * 
 * 将此文件复制到项目根目录，自定义文档健康检查配置。
 * 会覆盖内置的 doc-spec.yml 配置。
 */

module.exports = {
  // 添加自定义文档类型
  document_types: {
    // 示例：API 文档类型
    api_doc: {
      type_tag: '<!-- type: api-doc -->',
      path_pattern: 'docs/api/**/*.md',
      required_sections: [
        { name: 'Endpoint', pattern: '^## Endpoint' },
        { name: 'Request', pattern: '^## Request' },
        { name: 'Response', pattern: '^## Response' }
      ],
      structural_sections: [
        {
          name: 'endpoints',
          marker: '<!-- section:endpoints -->',
          element_marker: '<!-- endpoint -->',
          element_pattern: '^### (.+?) <!-- endpoint -->$'
        }
      ]
    }
  },
  
  // 扩展类型别名（签名计算）
  signature_config: {
    type_aliases: {
      // 添加项目特定的类型别名
      money: ['number', 'Integer', 'Float', 'Decimal', 'Money'],
      email: ['string', 'Email', 'EmailAddress'],
      url: ['string', 'URL', 'Url']
    }
  },
  
  // 自定义检查规则
  lint_rules: {
    // 文档长度限制
    max_lines: 400,
    
    // 项目特定的模糊词汇
    vague_terms: [
      '主要', '大部分', '大量', '高并发', '快速', '高效',
      '可能', '适当', '合理', '通常情况下', '一般来说'
    ],
    
    // 是否检查链接
    check_broken_links: true
  },
  
  // 回归检测配置
  regression_detection: {
    check_completed_plans: true,
    completed_plan_mismatch_severity: 'warning',
    
    // 项目关键实体
    critical_entities: [
      'Transaction',
      'User',
      'Account',
      'Order',
      'Payment'
    ]
  }
};
