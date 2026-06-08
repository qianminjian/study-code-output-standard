# 案例 · wxcbrc 项目（来源参考）

> 抽象自 `~/<保密路径>/wxcbrc/docs/` 12 篇资产。
> 用于**横向对照本方法论产出物**。
> 真实项目位置：`~/<保密路径>/wxcbrc_mgmt/`

---

## 0. 项目概况

| 维度 | 实际值 |
|---|---|
| 名称 | wxcbrc（无锡银保监分局内部网站系统） |
| 类型 | 内部企业网站系统（管理端 + 前台 + 静态展示） |
| 代码量 | 22 Model / 19 Mapper / 15 Controller / 51 Vue 组件 / 18 表 |
| 技术栈 | Java 8 + Spring Boot + MyBatis-Plus + Druid + MySQL + Vue 2 + Element UI + jQuery 1.10.2 |
| 安全 | 自写 JWT（HS512 + 硬编码密钥）+ Spring Security |
| 子项目 | 3 个（后端 / 后台管理 / 静态前台） |
| 资产整理时间 | 2026-06-08 |

---

## 1. 12 篇资产摘要

### 00-文档索引

完整 12 篇入口 + 4 个角色阅读建议。结构稳定。

### 01-系统总览

**关键发现**：

- 3 个独立子项目，**禁止跨子项目引用**
- 端口冲突：bootstrap 9090 vs application 9091
- 多套技术栈：Java 8、Spring Boot、Vue 2、Element UI 2.13、jQuery 1.10.2
- 启动顺序 5 步

**借鉴点**：

- "数字一览" 表把所有计数集中（22/19/15/51/18/70/45/60+/5+）
- 关键路径表按子域分（后端 / 前端 / 静态）
- 多端关系 ASCII 图

### 02-数据模型与表结构

**关键发现**：

- **命名不一致**：业务表 `news_info` / `file_info` 用下划线，但 `linksinfo` / `passipinfo` / `imenu` / `iimenu` 无下划线
- **id 类型不一致**：`BaseModel.id` 是 Long，但 `NewsInfo.news_id / FileInfo.file_id` 是 String
- **Model 与 XML 命名不一致**：`LinksInfo.xml` / `PassIpInfo.xml` 缺 `Mapper` 后缀
- 字段命名约定：小驼峰 Java / 蛇形 DB / MyBatis 自动转换

**借鉴点**：

- 实体-表对应表（含继承关系）
- ER 关系图分权限模型 / 内容模型
- SQL 注入风险用 🔴P0 标注
- 性能问题（N+1、O(n×m)）单列

### 03-后端-Controller接口清单

**关键发现**：

- 15 个 Controller，约 70 个端点
- 4 处 `@Api(tags="用户管理接口")` 错标（复制粘贴）
- 7 处 `@CrossOrigin` 公开端点（无白名单）
- 45 个权限串，4 处错用

**借鉴点**：

- 概览表（含 tags、端点数、公开端点数）
- 强制 6 列（方法、路径、入参、鉴权、公开、说明）
- 权限字符串全集（按 view/add/edit/delete/upload/download 列）
- 公开端点单列

### 04-后端-Mapper操作清单

**关键发现**：

- 19 个 Mapper + 18 个 XML
- `MyBatisBaseDao` 通用方法**无 XML 实现**（继承者需自实现）
- `SysRoleDeptMapper` 继承基类无任何自定义
- `NewsInfoMapper.xml#listAll` 用 `${news_title}` 字符串拼接（**P0 SQL 注入**）
- 4 类 SQL 模式：分页（反射约定）/ Join（4 表 join）/ resultMap（树形递归）/ 派生字段

**借鉴点**：

- 接口与 XML 一览（含命名不一致标注）
- 每个 Mapper 方法清单（含业务用途）
- 4 类 SQL 模式分节
- 已知问题含严重度 + 文件 + 行号

### 05-后端-服务与业务逻辑

**关键发现**：

- 15 个 Service + 15 个 Impl
- 10 个核心业务流（密码加盐 / admin 保护 / 菜单树 / 点击数累加 / 标题去重 / 栏目树 / IP 白名单 / 改密 / Excel 导出 / 字典查询）
- 改密重置 salt → token 失效（P0）
- `saveRpt` 未在接口声明（反模式）
- 标题查重更新时未做（P1）

**借鉴点**：

- 接口与实现对应表
- 每个业务流含输入/步骤/输出/边界
- 业务流编号与 10 对齐
- 已知问题与 11 联动

### 06-后端-安全认证

**关键发现**：

- Spring Security + 自写 JWT
- JWT 密钥硬编码 `"hardcoded-default-secret"`（P0）
- CORS `allowedOrigins("*")` + `allowCredentials(true)`（P0）
- `/actuator/**` 全部暴露（P0）
- `SysLogAspect` Pointcut 写错包名 → 永远不触发（半成品）
- JWT 24h 无刷新
- 5 个 Config 类、12 个 Utils 类
- 4 个 application-{env}.properties 内容相同（应按环境区分）

**借鉴点**：

- 鉴权全流程 4 节（签发/过滤/Provider/用户加载）
- AOP 切面含"未触发"标注
- 5 类 Config、12 类 Utils 列表
- 多环境配置表
- 密钥用 `<REDACTED>` 替代

### 07-前端-页面与组件清单

**关键发现**：

- 51 个 Vue 组件（views + components）
- 5 类组件：顶层视图、Core 通用、Sys 系统管理、Web 业务、辅助
- `Login.vue` 用 `res.msg === '交易成功'` 判成功（**P0**）
- 搜索按钮 perms 错写（`sys:role:view` 而非 `sys:user:view`）
- `Passipinfomgmt.vue` 整套 perms 错用 `web:linksinfomgmt:*`
- 4 个死代码组件（About/Notice/Message/ThemePicker）

**借鉴点**：

- 5 类组件分组
- 强制列（文件/用途/关键 API/权限）
- props（仅 Core 通用组件）
- 死代码单列

### 08-前端-状态管理与路由

**关键发现**：

- 5 个 Vuex 模块（app/user/menu/tab/iframe）
- 静态路由 4 条 + 动态路由（按用户菜单生成）
- 16 个 API 模块文件（15 + index）
- `axios` request 拦截器对所有请求校验 token → 登录死循环（P0）
- token header 用 `token` 而非 `Authorization: Bearer`（P0）
- `setPerms` 历史上可能写错位置
- axios 每次 new instance

**借鉴点**：

- Vuex 模块表（state/mutations/备注）
- 路由-组件映射表
- API 模块清单 + REST_URLS 字典
- axios 封装代码片段
- 已知问题含行号

### 09-静态前台

**关键发现**：

- 3 个 HTML + 22 JS + 5 CSS
- jQuery 1.10.2 + artDialog + SuperSlide + 自写
- `baseUrl` 写死内网 IP
- 富文本 `.html()` 无 XSS 过滤（P1）
- 端口 9090 vs 9091 不同步

**借鉴点**：

- 文件结构树
- 3 个页面独立节
- AJAX 模式代码片段
- 已知问题分类

### 10-业务流图（端到端）

**关键发现**：

- 7 个核心业务流：登录（前后台）/ 新闻发布 / 新闻浏览 / 文件上传（2 个）/ 改密 / 菜单权限
- 流程图用 ASCII 完整覆盖 触发→前端→后端→落库→响应
- 8 个业务流相关 Bug

**借鉴点**：

- 每个流一节
- ASCII 流程图统一格式（`[用户] → ...`）
- 关键决策点（IP 白名单 / 权限校验 / admin 保护）
- 业务流编号与 05 对齐

### 11-技术债与遗留项

**关键发现**：

- 9 大类问题：注释代码 / 命名不一致 / 死代码 / TODO / 硬编码 / 注解错位 / 权限错用 / 性能 / 版本落后
- 60+ 个 TODO Auto-generated
- 5+ 处 5+ 行注释代码
- 严重度分布：🔴P0 (5) / 🟡P1 (~10) / 🟢P2 (~10) / ⚪P3 (~30)

**借鉴点**：

- 9 大类问题分节
- 强制列（严重度/类别/位置/问题/建议）
- 反模式标签（@sqlinjection / @secret-leak / @cors-wildcard 等）
- 数量 > 20 才算摸到本质

### 12-修复建议与优先级

**关键发现**：

- P0：10 条（24h 内）
- P1：15 条（季度）
- P2：10 条（半年）
- P3：13 条（顺便）
- 整体重构路径 5 大块

**借鉴点**：

- P0 每条都有具体修改方案
- 工作量 + 责任人
- 整体重构路径分 5 块
- 严格 P0-P3 体系

---

## 2. wxcbrc 给本方法论带来的核心经验

### 经验 1：P0 必须有"具体到代码"的修复方案

| 反例 | 正例 |
|---|---|
| "JWT 密钥外置" | "JwtTokenUtils 改为读 `${jwt.secret}` + 启动时校验非默认值 + 增加 test case" |

### 经验 2：AOP 切面必须有"已触发"测试

`SysLogAspect` Pointcut 写错包名 → 表结构存在但永远没数据。

**对策**：本方法论 11-技术债清单的反模式标签 `@todo-stub` 必须能识别这种"半成品"。

### 经验 3：复制粘贴是 bug 重灾区

- 4 处 Swagger tags 错位
- 搜索按钮 perms 错写
- 整套 perms 错用

**对策**：**枚举/常量集中定义**是必杀技。

### 经验 4：拦截器必加白名单

`axios` request 拦截器对所有请求校验 token → 登录接口自身也被拦截 → 死循环。

**对策**：拦截器白名单 = `{ url: NOT_IN [login, captcha, ...] }`。

### 经验 5：改密是高频踩坑点

- 改密重置 salt → token 失效
- 改密用 GET 传密码
- 改密未校验复杂度

**对策**：**改密必须独立业务流分析**（10-业务流图必备）。

### 经验 6：硬编码必扫

- 密钥 `"hardcoded-default-secret"`
- 端口 `9090` vs `9091`
- 内网 IP `10.52.9.110`
- DB 密码 `root/root`

**对策**：本方法论 06 必带 `硬编码扫描` 节。

### 经验 7：技术债数量与质量

- wxcbrc：60+ TODO、5+ 死代码、4 处 P0 安全漏洞、10 处 P1
- **数量 > 20 才算"摸到本质"**
- **P0 < 10%** 才算分级合理

### 经验 8：跨项目可复用模板

本案例展示了：

- 12 篇资产编号稳定
- 严重度 P0-P3 体系统一
- 反模式标签集
- 强制列（6 列 API、5 列技术债等）
- 元信息头 7 字段

→ 全部可抽象为**通用方法论**，落到本仓库的 `docs/`。

---

## 3. wxcbrc 没说但本方法论补的

| 缺口 | 本方法论的补 |
|---|---|
| 无元信息头 | 强制 frontmatter 7 字段 |
| 无版本号 | 强制 SemVer |
| 无自动化校验 | scripts/ + CI 接入 |
| 无资产-代码一致性检查 | 06-质量门禁 §3 |
| 无 AI 协作规范 | 05-AI Prompt 工具集 |
| 无反模式标签体系 | 24 个反模式标签 |
| 无严重度合理性检查 | 06 §6 |
| 无演进 SLA | 02 §7 + 04 Step 6 |

---

## 4. 元信息

| 字段 | 值 |
|---|---|
| 抽象时间 | 2026-06-08 |
| 真实项目 | wxcbrc 12 篇资产 |
| 用途 | 本方法论 examples + 培训材料 |
| 注意 | 真实项目数据已脱敏，全部用 `<REDACTED>` 或抽象 |
