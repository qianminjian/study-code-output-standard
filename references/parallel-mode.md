# v3.5 并行模式 · 实施细则

> 本文件是 `SKILL.md` `## 并行生成模式 (v3.5)` 章节的**细节拆分**。
> 触发条件、容错降级、缺陷模式、审计流程、Go/No-Go 门等高层决策见 **SKILL.md**。
> 编排者 spawn worker 时的**具体指令**、**变体 → 资产映射**、**prompt 模板结构**见本文件。

---

## C. 4 阶段管线

```
Phase 1 ─── 7 worker 并行（02/03/04/06/07/08/09，无依赖，全部读源码）
           全栈 7 个 / 纯后端 4 个（跳 07/08/09）/ 纯前端 3 个（跳 02-06）
           run_in_background: true 全部同时启动 → 编排者等待全部完成
    ▼
Phase 2 ─── 1 worker（05 服务逻辑，可选依赖 03+04 输出）
    ▼
Phase 3 ─── 1 worker（10 业务流图，依赖 Phase 1+2 全部）
    ▼
Phase 4 ─── 并行 11+13，然后 12
           11 技术债 + 13 反模式（并行）→ 12 修复建议（派生自 11）
    ▼
编排者 ─── 01 系统总览 → 00 文档索引（自己写，不 spawn）
```

**Phase 1 并行可行性**：02-09 资产**输出无依赖**（各自写到不同文件），但**文件读取有重叠**（02/04 共享 XML；06 与 02/03/04 跨目录扫描；07/08 边界模糊）。重叠不冲突——同一文件被读出不同维度。交叉引用一致性推迟到 Step 4 校验阶段统一处理（v3.0 串行时一致性天然存在，但 v3.0 也需要 human review 抽查，所以校验量不增加）。

---

## D. 4 种 Worker 认知变体（内联指令）

> 编排者 spawn worker 时按资产编号选择变体，对应指令直接拼进 prompt。

| 变体 | 适用资产 | 核心任务 | 关键 guard |
|------|---------|---------|-----------|
| **A: Extract** | 02, 03, 04, 07, 08, 09 | grep→提取→填表→计数校验 | grep 数 = 表格行数 |
| **B: Analyze** | 06, 11, 13 | 模式匹配→严重度分类→根因分析 | 每条结论带 `<file>:<line>` |
| **C: Synthesize** | 05, 10 | 调用链追踪→语义重建→决策点 | 如实报告异常路径数，不足时 `@incomplete-coverage` |
| **D: Aggregate** | 01, 00, 12 | 读上游资产→交叉校验→综合 | 不复制粘贴，必须合成 |

**共享 Preamble**（5 铁律，违规 = 输出作废）：

```
1. 完全反应：代码中每个实体/端点/类都必须出现在输出中
2. 不丢失：grep 计数 = 表格行数，差 1 就重新扫
3. 不幻觉：每条结论带 <file>:<line> 证据，找不到写"未确认"
4. 不偷懒：深度分析是强制的，不抽样，不全读等于没读
5. 不怕消耗 token：宁可读 50 个文件产出完整资产
```

**诚实标注**：铁律 1-3 可脚本/审计验证（硬铁律）；铁律 4-5 仅靠 worker 自觉 + 审计间接推断（软约束）。v3.0 串行同样面临 4-5 不可硬验证。

**变体 A 扫描流程**（Extract）：
1. 跑 grep/find 记录精确计数
2. 逐个 Read 源文件——**遵守 Step 3 Read 策略**（每个 Read 上限 500 行；超 500 行用 grep 定位关键字段 + Read 上下文 ±50 行；**禁止整文件 Read**）
3. 按模板结构填表
4. 重 grep 计数校验（防止漏数 + 防止多填）

**变体 B 扫描流程**（Analyze）：
1. 跑 `scan-antipatterns.sh`（**注意：仅扫 Java 源码；yml 密钥需 06 worker 人工补查**）
2. 对命中 Read 源文件确认非误报——**遵守 Step 3 Read 策略**
3. 手动 grep 补 TODO/FIXME/password/secret/yml-config
4. 06 必逐项扫描 yml/properties（**scan-antipatterns.sh 不覆盖**）
5. 分类严重度 + 根因类型

**变体 C 扫描流程**（Synthesize）：
- 见 references/methodology/04 §3.1
- **反偷懒门（硬约束）**：
  - 调用链追踪 ≥ 3 层（Service → Mapper → 跨服务 Feign）
  - 异常场景分析 ≥ 3 个（per 业务流）
  - 决策点 ≥ 2 个（per 业务流）
  - 隐含假设 ≥ 2 个（per 业务流）
  - **未解之谜 ≥ 3 条（硬约束）**——少于此数必须显式说明为什么这个项目不适用
- 违反硬约束 = 输出作废

**变体 D 扫描流程**（Aggregate）：
1. 通读全部上游资产（**不是摘要**）
2. 提取关键数据点
3. 交叉一致性检查（entity 名 / 端点交集 / 集成债）
4. 综合**非复制粘贴**——必须产生 11 资产未提及的**集成债**

> **关键发现（v3.5 端到端验证）**：11 资产的"集成债"是 v3.5 跨资产对比的**核心价值**——单看任何上游资产都漏。变体 D 必须做跨资产对比，不能停留在单资产聚合。

---

## E. 编排者 Prompt 组装逻辑

**变量来源解析**：

| 变量 | 来源 |
|------|------|
| `${PROJECT_ROOT}` | Step 0 用户确认（`pwd` 或 `--path`）|
| `${SKILL_HOME}` | Skill 系统注入（当前 skill 安装位置）|
| `${SRC_DIR}` | Step 1 勘探推断（`src/main/java` 或 `src/`）|
| `${WEB_SRC}` | 前端源码目录（`src/web/` 或 `src/main/resources/static/`）|
| `${MODEL}` | `CLAUDE_CODE_MODEL` / 模型标识 |

**变体 → 资产映射表**：

| 资产 | 变体 | 模板文件 | 特殊参数 |
|:-:|:-:|---|---|
| 02 | A | `assets/02-数据模型与表结构.md.tmpl` | 无 DDL 时加 `--infer-mode` |
| 03 | A | `assets/03-后端-Controller接口清单.md.tmpl` | — |
| 04 | A | `assets/04-后端-Mapper操作清单.md.tmpl` | — |
| 06 | B | `assets/06-后端-安全认证.md.tmpl` | 强制 OWASP 10 项逐项回应 |
| 07/08/09 | A | 对应 `assets/0[789]-*.tmpl` | 纯后端跳过 |
| 05 | C | `assets/05-后端-服务与业务逻辑.md.tmpl` | 传入 Phase 1 的 03+04 路径 |
| 10 | C | `assets/10-业务流图.md.tmpl` | 传入 Phase 1+2 全部路径 |
| 11 | B | `assets/11-技术债与遗留项.md.tmpl` | 传入上游资产路径 |
| 13 | B | `assets/13-反模式扫描报告.md.tmpl` | 传入 `scan-antipatterns.sh` 结果 |
| 12 | D | `assets/12-修复建议与优先级.md.tmpl` | 传入 W-11 输出 |
| 01/00 | D | 01 用 `assets/01-系统总览.md.tmpl` | **编排者自己写**（不 spawn）|

**Worker Spawn 通用 Prompt 结构**：

```
【角色】你是 {变体} Worker，负责产出资产 {NN}-{资产名}.md
【5 铁律】{共享 Preamble §D}
【模板】Read: ${SKILL_HOME}/assets/{NN}-{模板}.md.tmpl
【prompt 参考】可选 Read: ${SKILL_HOME}/references/prompts/{NN}-{prompt}.md
【共享事实字典】**必读** ${PROJECT_ROOT}/asset-docs/.phase-facts.md（违反 = 跨资产一致性无保证 = 输出作废）
{变体指令（§D 中 A/B/C/D 扫描流程）}
【项目信息】PROJECT_ROOT=${PROJECT_ROOT} SRC_DIR=${SRC_DIR} WEB_SRC=${WEB_SRC} 技术栈={Step 1 继承}
【Phase 1 共享事实】{项目规模 / 关键目录 / 已知警惕区域}
【输出要求】写入 ${PROJECT_ROOT}/asset-docs/{NN}-{资产名}.md；frontmatter 必填 id/version/last_updated/data_source/code_version/owner/ai_consumable；自检过变体清单；返回文件路径+行数+grep 数 vs 表格行数对比
【降级约束】源文件 > 200 个时优先核心包（排除 test/ 和 deprecated/）；单文件 Read > 500 行时 grep 定位 + Read 上下文 ±50 行；严禁压缩到跳过实体
```

**Sonnet 合并 worker**（1 worker = 多资产）prompt 结构：开头标注"你是 Extract Worker，负责 02+04"，内部按 `【资产 A: 02】+【资产 B: 04】` 分块，每块带变体指令和独立自检清单；**内部执行顺序**：先完成 A 全部（读→写→自检），再开始 B（避免模板字段混淆）。

---

## 导航

- 高层决策（触发条件、容错、审计、Go/No-Go）→ **`SKILL.md` `## 并行生成模式 (v3.5)`**
- 方案设计源 → `docs/design/v3.5-parallel-architecture.md`
- 反偷懒门细节 → `references/methodology/04-反向阅读工作流.md §3.1`
