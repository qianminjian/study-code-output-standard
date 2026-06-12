# Troubleshooting · 常见错误与解决方案

> 适用版本：v3.5 (并行 4 阶段管线)
> 维护约定：每个错误附带 **症状 / 根因 / 解决** 三段式诊断

---

## 1. check-consistency MISMATCH（Controller 数 / 端点数）

**症状**：`check-consistency.sh` 报告 `MISMATCH: asset says N controllers but grep found M`

**根因**：
- grep 仅匹配 Controller 类文件（排除 test/ 和非 Controller Java 文件），而资产可能汇总了所有 Controller 注解的类
- v3.5 并行模式下，03 资产由 Worker A（Extract）产出，grep 范围可能与校验脚本不一致（`--include` 模式差异）
- 03 摘要表中端点使用反引号而非尖括号，正则匹配需对齐

**解决**：
1. 检查 `SRC_DIR` 环境变量是否正确指向源码根目录
2. 验证 03 资产中的 Controller 列表是否来自实际文件系统 `grep -rl "@RestController\|@Controller" "$SRC_DIR" | grep -v test/`
3. 确认端点计数正则：`grep -cP '^\s*(GET|POST|PUT|DELETE|PATCH)\s+'`（排除注释行）
4. 如差异在 ±5% 内且无 P0 遗漏，标记为 WARN（v2.7 行为）

---

## 2. Agent stall（context 溢出 / Read 超 200）

**症状**：Worker 运行超过预期时间（Phase 1 通常 3-5min），无输出，无进度

**根因**：
- Worker 的 Read 操作超过 200 行限，被拒绝后无限重试
- Context 窗口溢出导致 worker 进入退化循环（重复读取大文件）
- 分层抽样模式下文件数超过 worker 上限

**解决**：
1. 检查 `agent-watchdog.sh` 是否在运行（每 60s 检查一次）
2. 手动 kill 卡住的 worker session，检查 `.phase-facts.md` 中 `exit_code`
3. 如为 context 溢出：减小目标模块文件范围，启用分层抽样模式（>100 文件时自动激活）
4. 如为 Read 限：检查 SKILL.md 变体限制（A/B 均 ≤ 500 行上限）
5. 重新 spawn worker 时指定更小文件集合

---

## 3. .phase-facts.md missing（Phase 间交接失败）

**症状**：下一个 Phase 无法启动，编排者报 `FATAL: .phase-facts.md not found`

**根因**：
- 前一 Phase 未完成或产出路径错误
- Worker 异常退出，未写入 `.phase-facts.md`
- Turn 中断后恢复时忘记检查状态文件

**解决**：
1. 检查 `asset-docs/.phase-facts.md` 是否存在（Phase 1 产出，Phase 2/3/4 消费）
2. 若缺失：检查对应 Phase 的 worker 输出目录 `asset-docs/` 是否有对应资产文件
3. 若资产生成但 `.phase-facts.md` 缺失：手动从 `asset-docs/` 的 `## 元信息` frontmatter 重建
4. 从空白恢复：重新 spawn 该阶段的 worker（使用备选 prompt 模板，不覆盖已有资产）

---

## 4. 输出路径错误（写到 _proc-use/ 而非 asset-docs/）

**症状**：Worker 声称完成了，但 `find asset-docs/ -name "*.md"` 返回空或不足

**根因**：
- Worker prompt 中输出路径写错（`_proc-use/` / `_test-output/` / `/tmp/`）
- `${PROJECT_ROOT}` 变量在 worker 环境中未正确展开
- v3.5 约束不够强硬：SKILL.md 写的是 SHOULD 而非 MUST

**解决**：
1. 检查 `SKILL.md` 中资产输出位置是否标为 **硬性红线**（v3.5 已修正为 MUST）
2. 在 spawn worker 的 prompt 中显式写入输出路径：`${PROJECT_ROOT}/asset-docs/`
3. 每个 Phase 完成后，编排者跑 `find ${PROJECT_ROOT}/asset-docs -name "*.md" | wc -l` 确认资产数
4. 如果错误已发生：将产出从错误目录 `cp` 到 `asset-docs/`，并标注迁移

---

## 5. 03 Controller 接口清单格式错误（尖括号 vs 反引号）

**症状**：`check-consistency.sh` 的 grep 无法匹配 03 资产中的端点路径

**根因**：
- 03 模板或 Worker 产出中，端点路径用 `<angle brackets>` 包裹，而非反引号
- `check-consistency.sh` v2.6+ 正则匹配反引号格式：`` `GET /api/users/{id}` ``
- v3.0 早期模板未明确说明此格式要求，Worker 可能误用 `<GET /api/users/{id}>`

**解决**：
1. 检查 03 资产 `assets/03-后端-Controller接口清单.md.tmpl` 中是否已有格式说明
2. Worker prompt 中明确："端点路径用反引号包裹，不用尖括号"
3. 已产出的 03 资产可通过 `sed` 批量修复：`sed -i 's/<\(GET\|POST\|PUT\|DELETE\|PATCH\) \([^>]*\)>/`\1 \2`/g'`
4. 重跑 `check-consistency.sh` 验证修复结果

---

## 6. scan-antipatterns yml 密文明文漏报

**症状**：`scan-antipatterns.sh` 的 `@secret-leak` 标签未报告 yml/properties 文件中的明文密码

**根因**：
- yml 扫描正则未覆盖嵌套 YAML 结构（如 `spring.datasource.password` 的缩进格式）
- properties 文件使用 `key: value` 格式而非 `key = value`，正则表达式未匹配冒号分隔
- v2.6 新增 `@secret-yml` 标签后正则仍有漏报（v3.0 函数式重构已收敛）

**解决**：
1. 确保 `scan-antipatterns.sh` 版本 ≥ v3.0（函数式重构，24 个 scan_label 全部收敛）
2. 检查 `@secret-yml` 函数中的正则：`grep -nP '(password|passwd|secret|token|api[_-]?key)\s*[:=]\s*[^{$"\n]{3,}'`
3. 确认扫描范围包含 `*.yml` 和 `*.properties`（非仅 `*.yaml`）
4. 手动验证：`grep -rnP 'password\s*[:=]\s*[^{]' "$PROJECT_ROOT" | grep -v '${'`

---

## 7. v3.5 并行 worker 超载

**症状**：Phase 1 的 7 个 worker 同时启动后，系统 CPU 持续 100%，多个 worker 超时

**根因**：
- 目标模块过大（Controller > 50 或端点 > 200），v3.5 自动开启 10 拆分但 Phase 1 仍 7 并行
- macOS 的 `ulimit -n` 限制导致 worker 间文件描述符争抢
- Worker 变体 A/B 的 Read 策略重叠（02/03/04 共享 XML 目录读取）

**解决**：
1. 分批启动：Phase 1 分 2 批（4 + 3 或 3 + 4），每批间隔 30s
2. 使用 `run_in_background: true` 启动全部 worker 后，编排者不做 CPU 密集型操作
3. 对于单模块项目，Phase 1 可降级到 4 worker（只跑后端 02/03/04/06）
4. `ulimit -n 1024` 确保文件描述符充足（macOS 默认 256 可能不足）

---

## 8. 分层抽样标注缺失

**症状**：大模块（>100 文件）Worker 产出中，资产标注了 `@sampled` 但缺失具体抽样策略说明

**根因**：
- 分层抽样协议要求 Worker 在资产开头标注"实际抽样策略"（文件数/层数/覆盖率）
- Worker 可能标注了 `@sampled` 但未展开抽样详情（属于格式不完整）
- 编排者在 Phase 间交接时未校验抽样标注完整性

**解决**：
1. 检查资产开头是否有如下标注：
   ```
   > @sampled: 实际读取 18/86 文件 (21%)，分 4 层（Controller/Service/Mapper/Config），层内全量
   ```
2. 如仅有 `@sampled` 标签无详情：在 SKILL.md 分层抽样协议中补充"标注格式"示例
3. 编排者在 Phase 1 完成后校验所有产出是否含完整抽样标注
4. 缺失标注的资产标记为 WARN，不阻塞下一 Phase

---

## 9. Turn 中断恢复失败

**症状**：Agent session 中断后恢复，编排者重新 spawn worker 但产出冲突

**根因**：
- `.batch-progress.json` / `.module-status.json` 状态文件不存在或过期
- 恢复时重复覆盖已有资产（v3.5 无幂等保护）
- Turn 恢复逻辑依赖 `asset-docs/` 文件存在性判断，但文件存在不等于内容完整

**解决**：
1. 恢复前先读 `asset-docs/.batch-progress.json` 确认上次进度
2. 检查每个资产文件的元信息 frontmatter `生成状态` 字段（`✓` / `占位` / `缺失`）
3. 对于 `✓` 状态的资产跳过重新生成（幂等保护）
4. 对于 `占位` 或 `缺失` 状态：重新 spawn 对应 worker
5. Turn 中断恢复协议（SKILL.md §多模块批量执行协议）规定不得覆盖 `✓` 资产

---

## 10. 跨 Worker 严重度不一致

**症状**：同一反模式在不同模块中被标为不同严重度（P1 vs P3）

**根因**：
- Worker B（Analyze）的 prompt 中严重度判定标准模糊（"影响大" vs "影响小" 主观）
- 缺少跨 Worker 共享的严重度基准表
- Phase 1 的 Worker 各自独立判定，无跨 Worker 协调

**解决**：
1. 编排者在 Phase 1 spawn 前加载 `references/cross-module-aggregation.md` 中的 **P0-P3 定义表**
2. Worker B 的 prompt 中包含统一的严重度基准：
   - P0：安全漏洞、数据丢失、生产不可用
   - P1：重大性能问题、无 fallback 的外部依赖
   - P2：代码规范违规、重复逻辑
   - P3：注释缺失、命名不规范
3. 所有 worker 完成后，编排者跑 `scripts/check-severity.sh` 做跨 worker 对齐
4. 差异 >1 级的严重度标注自动标记为 WARN，需人工复核

---

## 11. Windows / PowerShell 已知局限

> 本章记录 4 个 `.ps1` 脚本在 Windows 环境下的已知局限和替代方案。
> 脚本路径：`scripts/init-asset-docs.ps1`、`scripts/write-claude-asset.ps1`、`scripts/write-claude-index.ps1`、`scripts/validate-all.ps1`
> 配套 `.sh` 版本：macOS / Linux / Git Bash 均已通过端到端验证

### 状态总览

| 脚本 | 大小 | 语法验证 | Linux/macOS 测试 | Windows 测试 |
|------|:----:|:--------:|:----------------:|:------------:|
| `init-asset-docs.ps1` | 181 行 | PASS | N/A（.ps1 不适用） | **未测试** |
| `write-claude-asset.ps1` | 213 行 | PASS | N/A | **未测试** |
| `write-claude-index.ps1` | 114 行 | PASS | N/A | **未测试** |
| `validate-all.ps1` | 67 行 | PASS | N/A | **未测试** |

> **验证方法**：`grep -c '{'` vs `grep -c '}'` (brace match), `head -1` (comment header), `grep 'param('` (param block), `grep 'ErrorActionPreference'` (error handling)

### 已知局限

1. **未在 Windows 上执行过端到端测试**
   - 4 个 `.ps1` 文件仅在语法层面验证（括号匹配 / 参数块 / 错误处理），未在 Windows PowerShell 5.1+ 或 PowerShell 7+ 上实际执行
   - 路径分隔符差异（`\` vs `/`）在 `Set-Content` / `Copy-Item` 调用中可能产生不一致行为

2. **依赖 Git Bash 的间接调用**
   - `validate-all.ps1` 通过 `& bash` 调用 4 个 `.sh` 校验脚本，需要在 Windows 上额外安装 Git for Windows
   - `init-asset-docs.ps1` 无此依赖（纯 PowerShell），可直接在 PowerShell 中执行

3. **交互行为差异**
   - `Read-Host` 在非交互 PowerShell 会话中的行为与 Git Bash / zsh 不同（`.ps1` 脚本有非交互模式 fallback，`.sh` 脚本通过 `-f` flag 控制）

### 替代方案（推荐）

| 场景 | 推荐方案 |
|------|---------|
| Windows 用户需要脚本 | 使用 `.sh` 版本通过 WSL / Git Bash 运行 |
| 纯 PowerShell 环境 | 使用 `.ps1` 脚本并配合 Git Bash |
| CI Windows runner | 使用 `ubuntu-latest` runner 执行 `.sh` 脚本（已验证通过） |
| 本地 macOS/Linux | 直接使用 `.sh` 脚本（已验证 10 模块） |

### 待验证清单（Windows 环境）

- [ ] PowerShell 5.1 下 `init-asset-docs.ps1 -TargetDir . -Force` 端到端
- [ ] PowerShell 7+ 下 `init-asset-docs.ps1 -TargetDir . -Force` 端到端
- [ ] `write-claude-index.ps1` 产出的 `CLAUDE.md` 格式完整性
- [ ] `write-claude-asset.ps1` 产出的 `CLAUDE-ASSET.md` 格式完整性
- [ ] `validate-all.ps1` 在 Windows runner 上的 CI job 绿灯
- [ ] 路径包含中文 / 空格时的 `Join-Path` 行为

> 上述验证需要 Windows 环境，待未来 Phase 4（新场景覆盖）中安排。

---

> **文档版本**：v1.0.0
> **最后更新**：2026-06-12
> **覆盖率**：10 个错误模式（check-consistency / agent stall / .phase-facts / 输出路径 / 03 格式 / yml 漏报 / worker 超载 / 分层抽样 / turn 恢复 / 严重度不一致）
