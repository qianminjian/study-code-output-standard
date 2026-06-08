# 标准代码资产方法论（study-code-output-standard）

[![CI](https://github.com/qianminjian/study-code-output-standard/actions/workflows/ci.yml/badge.svg)](https://github.com/qianminjian/study-code-output-standard/actions/workflows/ci.yml)

> 抽象自 wxcbrc 项目的 12 篇资产，**通用化**为一套"代码反向阅读 → 标准资产"的工程方法论。
> **v2**：已封装为 Claude Code Skill，在任意项目调用即用。

---

## 是什么

这是一套**产出"对人和 AI 都可消费"的项目资产**的标准方法。

四个痛点：

1. **黑盒**：代码量大，文档过期，**没人敢动**
2. **不敢改**：不知道哪些是核心、哪些是炸弹
3. **AI 编程失效**：LLM 喂整个仓库也只会给局部补丁
4. **重复造轮子**：每次都重新摸一遍

**核心理念**：

> 改代码 = 改资产；改资产 = 改代码。资产是代码的伴生品而非附件。

---

## v2 重大更新：Skill 封装

整个方法论已封装为 Claude Code Skill：

```
study-code-output-standard/
├── docs/                              ← 9 篇方法论文档（00-08）
│   ├── 00-总览与方法论.md
│   ├── 01-资产清单与适用场景.md
│   ├── 02-目录与命名规范.md
│   ├── 03-文档模板与质量标准.md
│   ├── 04-反向阅读工作流.md
│   ├── 05-AI协作与Prompt模板.md
│   ├── 06-质量门禁与自检清单.md
│   ├── 07-典型案例与反模式.md
│   ├── 08-新项目接入指南.md          ← v2 升级到 Skill 模式
│   ├── templates/        (12 份)
│   ├── ai-prompts/       (12 份 + 全流程启动)
│   ├── examples/         (1 份 wxcbrc 案例)
│   └── scripts/          (5 校验脚本)
├── skill/                             ← v2 新增：Skill 入口
│   ├── SKILL.md                       ← Claude 读的入口
│   ├── install.sh + install.ps1       ← 跨平台安装
│   ├── uninstall.sh + uninstall.ps1
│   ├── references/                    ← 分层参考
│   │   ├── methodology.md
│   │   ├── asset-types.md
│   │   └── anti-patterns.md
│   └── scripts/                       ← 4 个核心脚本（+ 3 个 PowerShell 等价）
│       ├── init-asset-docs.sh         ← 创建 asset-docs/ 骨架
│       ├── write-claude-index.sh      ← 生成 CLAUDE.md 轻量索引
│       ├── write-claude-asset.sh      ← 生成 CLAUDE-ASSET.md 详情
│       ├── init-asset-docs.ps1        ← Windows PowerShell 等价
│       ├── write-claude-index.ps1
│       └── write-claude-asset.ps1
└── README.md
```

---

## 5 分钟上手

```bash
# 1. 安装 Skill（一次性）
bash <methodology-repo>/skill/install.sh --personal

# 2. 在任意项目调用
cd /path/to/target-app
claude
> /study-code-output-standard

# 3. AI 自动按 6 步法反向阅读，输出到 ./asset-docs/
# 4. 同时自动生成 ./CLAUDE.md（轻量索引）和 ./CLAUDE-ASSET.md（详情）
```

详细说明见 [docs/08-新项目接入指南.md](docs/08-新项目接入指南.md)。

---

## 输出结构

调用 Skill 后，目标项目得到：

```
target-app/
├── CLAUDE.md                ← 轻量索引（≤ 80 行，按需加载）
├── CLAUDE-ASSET.md          ← 资产详情（按需 Read）
└── asset-docs/              ← 12 篇资产
    ├── 00-文档索引.md
    ├── 01-系统总览.md
    ├── ... (02-12)
    ├── CHANGELOG.md
    ├── templates/      (12 份)
    ├── ai-prompts/     (12 份)
    ├── references/     (3 份)
    └── scripts/        (5 个)
```

---

## 三大核心原则

### 1. 资产分层（5 层）

```
L1 导航层    00-索引
L2 全局层    01-总览
L3 静态层    02-09（数据/API/Mapper/服务/安全/页面/状态/多端）
L4 行为层    10-业务流
L5 诊断层    11-技术债 / 12-修复
```

### 2. 资产可消费（双受众）

- **人**：自然语言 + 表格 + 流程图
- **AI**：严格的 Markdown 结构 + 编号 + 标签 + 元信息头

### 3. 资产可演进

- 元信息头 7 字段
- 严重度 P0-P3
- 编号稳定
- 配套 CI 校验

---

## 12 篇资产编号（稳定不变）

| 编号 | 资产 | 适用 |
|---|---|---|
| 00 | 文档索引 | 全部 |
| 01 | 系统总览 | 全部 |
| 02 | 数据模型与表结构 | 后端 |
| 03 | API 接口清单 | 后端 |
| 04 | 数据访问操作清单 | 后端 |
| 05 | 服务与业务逻辑 | 后端 |
| 06 | 安全 / 认证 / AOP / Config | 后端 |
| 07 | 前端页面与组件清单 | 前端 |
| 08 | 前端状态与路由 | 前端 |
| 09 | 静态 / 多端 | 多端 |
| 10 | 业务流图（端到端） | 全部 |
| 11 | 技术债与遗留项 | 全部 |
| 12 | 修复建议与优先级 | 全部 |

---

## CLAUDE.md 双文件策略

| 文件 | 行数 | 用途 |
|---|---|---|
| `CLAUDE.md` | ≤ 80 | 轻量索引，Claude 启动时自动加载 |
| `CLAUDE-ASSET.md` | 100-200 | 资产详情，**按需 Read** |

**反例**：把资产详情塞进 CLAUDE.md → 上下文超限 → 资产失效。

---

## AI 编程喂入策略

| 任务 | 喂入 |
|---|---|
| 简单 CRUD | 01 + 02 + 03（最小集） |
| 重构 | + 05 + 11（推荐集） |
| 修 P0 | + 11 + 12 |
| 完整 | 12 篇（可承担新功能/重构/修 Bug） |

---

## 跨平台安装

| 平台 | 命令 |
|---|---|
| Mac | `bash skill/install.sh --personal` |
| Linux | `bash skill/install.sh --personal` |
| Windows Git Bash | `bash skill/install.sh --personal` |
| Windows PowerShell | `powershell -ExecutionPolicy Bypass -File skill/install.ps1 -Personal` |

> **Windows 完整流程**：
> ```powershell
> # 安装
> powershell -ExecutionPolicy Bypass -File skill/install.ps1 -Personal
>
> # 创建资产骨架
> cd <目标项目>
> powershell -ExecutionPolicy Bypass -File <skill>/scripts/init-asset-docs.ps1 -TargetDir .
>
> # 生成 CLAUDE.md（Windows 用户需先安装 Git Bash）
> powershell -ExecutionPolicy Bypass -File <skill>/scripts/write-claude-index.ps1 -TargetDir .
> powershell -ExecutionPolicy Bypass -File <skill>/scripts/write-claude-asset.ps1 -TargetDir .
>
> # 校验（依赖 Git Bash）
> bash asset-docs/scripts/validate-all.sh
> ```

---

## 与业界体系的关系

| 体系 | 关系 |
|---|---|
| C4 Model | 互补：把"画图"标准化为"出资产" |
| arc42 | 互补：继承其"分段 + 模板"思想 |
| Diataxis | 互补：本文属于"Reference + Explanation"层 |
| ADR | 互补：04-修复建议可与 ADR 联动 |
| OpenAPI | 互补：03-API 清单是 OpenAPI 的"摘要 + 人话版" |
| OWASP | 互补：06-安全认证 对照 Top 10 |
| Backstage | 互补：本文输出可被 TechDocs 渲染 |

---

## 适用边界

**✅ 适用**：存量项目接手 / 老系统现代化 / AI 编程上下文建设 / 新人入职 / 架构治理

**❌ 不适用**：全新项目从零起步 / 1-2 周 Demo / 单一库

**🟡 部分适用**：微服务多仓 / 纯前端 SPA / 移动 App（需做变体）

---

## 元信息

| 字段 | 值 |
|---|---|
| 整理时间 | 2026-06-08 |
| 版本 | 2.0（v2: Skill 化） |
| 维护 | Tech Lead 团队 |
| 配套实施 | 12 模板 + 12 Prompt + 5 脚本 + 1 案例 + Skill 封装 |
