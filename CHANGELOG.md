# CHANGELOG

## v3.5 (2026-06-12)

### 新增
- **v3.5 并行生成模式** (`## 并行生成模式 (v3.5)`)：4 阶段管线 + 4 Worker 认知变体（A/B/C/D）+ Worker Spawn 通用 Prompt 模板
- **references/parallel-mode.md**：v3.5 实施细则（116 行）
  - §C 4 阶段管线 / §D 4 Worker 变体 / §E Prompt 组装逻辑
- **共享事实字典协议** (SKILL.md §F)：编排者 Phase 间同步 schema (4 段 / 硬性协议)
- **scripts/yml-secret-scan.sh**：yml/properties 密文明文独立扫描 (v2.6)
- **docs/design/v3.5-parallel-architecture.md**：方案源迁移到 docs/（47KB / 12 章）
- **test suite 重组**：init-validate / secrets / no-leak-path / run-all

### 修复
- **P0 路径 bug**：Step 3 12 处 prompt 路径 `${PROJECT_ROOT}/...` → `${SKILL_HOME}/assets/*.tmpl` (commit 3c79edb)
- **scan-antipatterns.sh v2.5+**：扩展 yml + properties 扫描 + 字符类扩展 + 阈值 16→8
- **check-consistency.sh v2.5**：端点数 grep 收紧（仅 Controller 类，排除 test/）+ 跨资产语义检查
- **变体 C 软约束 → 硬约束**：未解之谜 ≥ 3 条改为硬约束
- **变体 A/B Read 策略**显式继承 Step 3 限制（500 行上限）
- **03-Controller 模板**：反引号格式要求说明（check-consistency 匹配）
- **SKILL.md 拆出**：711 → 624 行（-87，缓冲 800 阈值）

### 端到端验证
- **v3.5 Phase B**：在 devops-message（8.6K 行）上真实 AI 跑 10 资产 (332KB / 174 file:line)
- **v3.0 baseline**：同项目串行 7 步法产出 02/03/10 三资产对比
- **对比结论**：v3.5 在所有可量化维度 vs v3.0 +76%，保留 v3.5

---

## v3.0 (2026-06-09)

### 核心
- **串行生成模式 (v3.0)** (`## 串行生成模式 (v3.0)`)：单 agent 7 步法
  - Step 0 启动确认 / Step 1 勘探 / Step 2 分类 / Step 3 抽取 / Step 4 校验 / Step 5 反模式标注 / Step 6 派送 / Step 7 资产回写
- **14 个 .md.tmpl 模板**（资产 00-13 + CHANGELOG）
- **8 个校验/扫描脚本**
- **references/prompts/**：13 个资产的 AI prompt 单点真源
- **references/methodology/**：方法论文档
- **4 测试套件**

### 修复
- install/uninstall 中 Px-NN 标记清理
- init 5 个 bug 修复 + 过程信息清理
- 目录重命名对齐 Agent Skills 开放标准
