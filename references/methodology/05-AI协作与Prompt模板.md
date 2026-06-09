<!--
@meta {
  "id": "05-AI协作与Prompt模板",
  "version": "1.0.0",
  "last_updated": "2026-06-08",
  "data_source": "抽象自 wxcbrc 项目 12 篇资产",
  "code_version": "n/a",
  "owner": "Tech Lead @ 团队",
  "ai_consumable": true,
  "severity_taxonomy": "P0|P1|P2|P3"
}
-->

# 05 · AI 协作与 Prompt 工具集

> 这一篇**给 AI 用**。每段 Prompt 都可以直接复制执行。
> 适用工具：Claude Code / Cursor / GitHub Copilot Workspace / Aider / Continue 等。

---

## 1. 通用 Prompt 三段式

所有反向阅读 Prompt 遵循**三段式**结构：

```
【背景】Context
- 项目类型 / 技术栈 / 路径

【任务】Task
- 输出哪篇资产
- 按 03-文档模板的哪个模板

【输入】Input
- 要扫描的文件 / 目录
- 关注的注解 / 模式

【输出】Output
- 文件路径
- 字段 / 表格列
- 强制约束

【反例】Anti-patterns
- 禁止的写法
```

完整模板在 `references/prompts/` 目录，下面给出 12 篇资产的核心 Prompt 速查。

---

## 2. 12 篇资产 Prompt 速查

### Prompt for 01-系统总览

```
【背景】
你正在为一个 <技术栈> 的 <项目类型> 项目写"系统总览"资产。
代码根目录：<path>。

【任务】
生成 docs/01-系统总览.md。按 docs/03-文档模板与质量标准.md §01 模板。

【输入】
- 跑 `tree -L 3 <path>`
- 读 README.md / package.json / pom.xml
- 找启动入口文件（main / Application）

【输出字段】
1. 项目背景（业务定位、目标用户）2-3 句
2. 项目边界（目录树）
3. 技术栈（后端 / 前端 / 静态端 三个表）
4. 多端关系（架构图）
5. 关键路径（按子域）
6. 启动顺序（Step-by-Step）
7. 数字一览（Controller / Service / Model / 端点 / TODO）

【反例】
- 不写"该项目使用 X 框架" 而不写版本
- 不写散文式"系统特点"
- 数字一览必须可验证
```

### Prompt for 02-数据模型与表结构

```
【任务】
生成 docs/02-数据模型与表结构.md。

【输入】
- ORM 实体目录：<path>（如 src/main/java/.../model/）
- Mapper XML 目录：<path>（如 src/main/resources/mybatis/）
- 数据库脚本：<path>（如 db-scripts/*.sql）

【输出字段】
1. 实体类与表对应关系（Model、表、继承、字段、备注）
2. 数据库表清单（表名、中文、字段、索引）
3. 关键关联关系（ER 图 + 字段映射约定）
4. MyBatis XML 命名空间总览
5. 关键 SQL 模式（分页、Join、resultMap、注入风险）

【反例】
- 不漏 BaseModel
- 不漏继承关系
- 必须标 SQL 注入风险（搜索 ${}）
```

### Prompt for 03-API 清单

```
【任务】
生成 docs/03-后端-Controller接口清单.md。

【输入】
- Controller 目录：<path>
- 关注注解：@RequestMapping / @GetMapping / @PostMapping / @PreAuthorize / @CrossOrigin

【输出字段】
1. 概览表（Controller、前缀、tags、端点数、公开端点）
2. 详细接口清单（每个 Controller 一节）
3. 权限字符串全集
4. 公开端点列表

【强制列】
| 方法 | 路径 | 入参 | 鉴权 | 公开 | 说明 |

【反例】
- 不写"见代码"
- 不省鉴权列
- 不漏 @CrossOrigin 公开端点
- 端点总数 = grep -c "@(Get|Post|Put|Delete)Mapping" 数量
```

### Prompt for 04-Mapper 清单

```
【任务】
生成 docs/04-后端-Mapper操作清单.md。

【输入】
- Mapper 接口目录
- Mapper XML 目录
- 关注：方法名、SQL 模式、resultMap

【输出字段】
1. 接口与 XML 一览
2. 通用基类
3. 每个 Mapper 方法清单（含业务用途）
4. 关键 SQL 模式
5. 已知问题（SQL 注入、字段映射错位、N+1）

【反例】
- 不漏 N+1 风险（扫子查询）
- 不漏字段映射错位（对比 Model 和 XML column）
```

### Prompt for 05-服务与业务逻辑

```
【任务】
生成 docs/05-后端-服务与业务逻辑.md。

【输入】
- Service 接口目录
- ServiceImpl 目录
- 关注：跨 Mapper 协作、关键算法、异常处理

【输出字段】
1. 接口与实现对应
2. 核心业务流（每个流：输入→步骤→输出→边界）
3. 已知 Service 实现问题

【反例】
- 不写"调用 X 然后 Y"的纯流水账
- 不漏事务边界
- 不漏管理员保护逻辑
```

### Prompt for 06-安全认证

```
【任务】
生成 docs/06-后端-安全认证.md。

【输入】
- Security 配置类
- 鉴权 Filter
- AOP 切面
- Config 类
- Utils 工具类
- application*.properties / yml

【输出字段】
1. Spring Security 配置
2. 鉴权全流程（签发/过滤/校验）
3. AOP 切面（含未触发的死切面）
4. Config 类清单
5. Utils 工具类
6. 多环境配置
7. ⚠️ 安全风险清单（与 OWASP Top 10 对照）

【反例】
- 密钥、token、密码**必须**用 <REDACTED> 替代
- 必须标 actuator 暴露
- 必须标 CORS 通配
```

### Prompt for 07-前端页面与组件清单

```
【任务】
生成 docs/07-前端-页面与组件清单.md。

【输入】
- views/ 目录
- components/ 目录
- 关注：路由、API 调用、权限

【输出字段】
1. 顶层视图（路由 + 关键 API）
2. 通用组件（props + 用途）
3. 业务组件（按域）
4. 辅助组件
5. 已知组件问题

【反例】
- 不漏死代码（未被路由引用）
- 不漏权限错用
```

### Prompt for 08-前端状态与路由

```
【任务】
生成 docs/08-前端-状态管理与路由.md。

【输入】
- store/ 目录
- router/ 目录
- http/ 或 api/ 目录
- utils/ 目录

【输出字段】
1. 状态管理模块（state / mutations）
2. 路由（静态 + 动态 + 映射表）
3. API 模块清单
4. HTTP 客户端封装（拦截器）
5. i18n / 工具
6. 已知问题（拦截器 bug、token 传递）

【反例】
- 不漏 setPerms 位置
- 不漏 token header 非标准
```

### Prompt for 09-静态前台

```
【任务】
生成 docs/09-静态前台.md。

【输入】
- 静态站根目录（如 wxcbrc-web/）
- HTML 入口
- 全局 JS / CSS

【输出字段】
1. 文件结构
2. 页面清单
3. 关键 JS / AJAX 模式
4. 已知问题（baseUrl 硬编码、XSS 风险等）

【反例】
- 不漏 XSS 风险（`.html()` 渲染富文本）
- 不漏 baseUrl 硬编码
```

### Prompt for 10-业务流图

```
【任务】
生成 docs/10-业务流图.md。

【输入】
- 02/03/05/07/08 已写完
- 关注：跨层调用链

【输出字段】
每个核心业务流：
- 触发条件
- 完整调用链（ASCII 流程图）
- 关键决策点
- 相关代码位置
- 已知流相关 Bug

【必备业务流（至少）】
1. 主登录流
2. 主业务创建流
3. 主业务查询流
4. 权限校验流
5. 文件上传/导出流
6. 改密流

【反例】
- 不写"调了 service" 而不写 service 名
- 不漏异常分支
```

### Prompt for 11-技术债清单

```
【任务】
生成 docs/11-技术债与遗留项.md。

【输入】
- 全 01-10 资产
- 关注：TODO/FIXME、注释代码、硬编码、命名不一致

【输出字段】
1. 注释代码块（应清理）
2. 命名不一致
3. 死代码
4. TODO/FIXME 清单
5. 硬编码（应外置）
6. 注解/标签错位
7. 权限字符串错用
8. 性能问题
9. 版本/生态落后
10. 文档与代码不一致

【强制列】
| 严重度 | 类别 | 位置 | 问题 | 建议 |

【反例】
- 不写"建议重构" 而不给具体方案
- 不写"性能有问题" 而不给行号
```

### Prompt for 12-修复建议

```
【任务】
生成 docs/12-修复建议与优先级.md。

【输入】
- 11-技术债清单

【输出字段】
- P0（24h）
- P1（季度）
- P2（半年）
- P3（顺便）
- 整体重构路径（远期）

【强制列】
| # | 位置 | 问题 | 建议 | 工作量 | 责任人 |

【反例】
- 不写"考虑升级" 而不给具体版本
- P0 必须有具体修改方案
```

---

## 3. 通用 AI 协作模式

### 3.1 让 AI 自我校验

在 Prompt 末尾加：

```
【自我校验】
生成后请：
1. 用 `grep -c "@\(Get\|Post\|Put\|Delete\)Mapping" <path>` 验证端点数
2. 用 `find <path> -name "*.java" | wc -l` 验证文件数
3. 检查元信息头 7 必填字段齐全（+ 1 可选 `severity_taxonomy`）
4. 检查严重度字段值在 P0-P3 范围
```

### 3.2 让 AI 出反例

```
【反例检查】
请列出本文档可能存在的 3 类反模式：
1. 数据不一致（与 02 字段冲突）
2. 严重度误判（应 P0 标为 P2）
3. 反模式标签遗漏
```

### 3.3 让 AI 交叉引用

```
【交叉引用】
请检查本文档与以下资产的交叉引用是否一致：
- 02-数据模型 §3.1
- 03-API 清单 §2.1
- 10-业务流图 §1
```

---

## 4. 反 Prompt（不要这样写）

| ❌ 反 Prompt | ✅ 正 Prompt |
|---|---|
| "帮我看看这个项目" | "按 03-API 清单模板生成 docs/03-..." |
| "写个文档" | "输出 docs/03-...md，端点列表用 6 列" |
| "找出 bug" | "扫 11-技术债清单的 9 类，重点 P0" |
| "性能怎么样" | "扫描 Mapper，标 N+1 风险位置" |
| "重构方案" | "按 12-修复建议 P2 给出可执行方案" |

---

## 5. 进阶：让 AI 写"修复 PR"

当 11/12 资产已存在：

```
【背景】
项目 <name>，技术栈 <list>。docs/12-修复建议与优先级.md 已就绪。

【任务】
执行 P0 #1：JWT 密钥硬编码。
【输入】docs/12-修复建议与优先级.md §P0
【输出】一个 PR，含：
1. JwtTokenUtils 改为读 application.properties
2. application.properties 新增 jwt.secret
3. 启动时校验非默认值
4. 单元测试
5. 同步更新 11/12 资产
```

---

## 6. Prompt 模板存放

每个资产的完整 Prompt 模板放 `references/prompts/`：

```
references/prompts/
├── 01-overview.md           ← Step 1 勘探
├── 02-data-model.md         ← 02 数据模型
├── 03-api-list.md           ← 03 API 清单
├── 04-mapper-list.md        ← 04 Mapper 清单
├── 05-service-logic.md      ← 05 服务与业务
├── 06-security.md           ← 06 安全
├── 07-frontend-pages.md     ← 07 前端页面
├── 08-frontend-state.md     ← 08 前端状态
├── 09-static-web.md         ← 09 静态站
├── 10-business-flow.md      ← 10 业务流
├── 11-tech-debt.md          ← 11 技术债
└── 12-fix-priority.md       ← 12 修复建议
```

每个文件含**完整可执行** Prompt（含项目占位符）。

---

## 7. 工具链推荐

| 任务 | 工具 |
|---|---|
| 文件扫描 | `grep` / `rg` / `ast-grep` |
| 结构分析 | LSP（clangd、typescript-language-server） |
| ER 图 | `mermerd` / `dbml` / `draw.io` |
| 流程图 | `mermaid` / `plantuml` / `graphviz` |
| 文档渲染 | VitePress / Docusaurus / Backstage TechDocs |
| CI 校验 | GitHub Actions / GitLab CI |
| 版本锚定 | `git rev-parse HEAD` |
| 资产-代码一致性 | 自定义脚本（见 04-Step 4） |

---

## 元信息

| 字段 | 值 |
|---|---|
| 配套模板 | `references/prompts/` |
| 工具 | Claude Code / Cursor / Continue / Aider |
| 适用 | LLM 编程助手 / Agent |
| 演进 | 随模型升级持续优化 Prompt |
