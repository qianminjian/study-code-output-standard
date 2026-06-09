# AI Prompt · 03 后端 Controller 接口清单

> ⚠️ **核心原则：按代码实际输出，不按模板预设清单**
>
> - **必须忠实还原代码中的实际 Controller/端点**，从代码扫描，有哪些列哪些
> - **端点信息从注解扫描得出**，不是按模板预设的示例端点
> - **权限串从代码实际发现汇总**，不是预设权限清单

---

## 完整 Prompt

```
【背景】
项目 <name>，后端技术栈 <list>。本任务生成"API 接口清单"资产。
通过逆向 Controller 代码，推断 API 设计。

【核心原则】
⚠️ 不按模板预设清单输出，按代码实际扫描结果输出！
- Controller 从 find 命令扫描，有哪些列哪些
- 端点从 @Mapping 注解扫描，有哪些列哪些
- 权限串从 @PreAuthorize 注解扫描汇总

【任务】
生成 asset-docs/03-后端-Controller接口清单.md。
严格按 ${SKILL_HOME}/assets/03-后端-Controller接口清单.md.tmpl 模板结构。

【输入】
- Controller 目录：src/main/java/.../controller/
- DTO/VO 目录：dto/, vo/, request/, response/
- WebSecurityConfig：安全配置类
- Swagger/OpenAPI 注解

【扫描命令（必跑）】
```bash
# 端点数
grep -rE "@(Get|Post|Put|Delete|Request)Mapping" <controller-dir> | wc -l

# Controller 数
find <controller-dir> -name "*Controller.java" | wc -l

# 权限串
grep -rEo "@PreAuthorize\\(\"([^\"]+)\"\\)" <controller-dir> | sort -u

# 公开端点
grep -rE "@PermitAll|@Anonymous" <controller-dir>
```

【输出字段·必须包含】

## 1. 概览表

| Controller | 前缀 | 模块 | 端点数 | 公开端点 | Swagger Tags | 备注 |
|---|---|---|---|---|---|---|
| UserController | /api/user | 用户管理 | 8 | 1 | User | 登录接口公开 |

**统计行**：
- Controller 总数：N
- API 端点总数：N
- 公开端点数：N
- 权限串去重数：N

## 2. 详细接口清单

### 2.1 UserController (`/api/user`)

| # | 方法 | 路径 | 入参 | 出参 | 鉴权 | 公开 | Swagger 描述 |
|---|---|---|---|---|---|---|---|
| 1 | POST | /login | LoginRequest | TokenResponse | ❌ | ✅ | 用户登录 |
| 2 | POST | /logout | — | — | ✅ | ❌ | 用户登出 |
| 3 | GET | /info | — | UserInfo | ✅ | ❌ | 获取用户信息 |

**入参类型说明**：
```java
LoginRequest {
    username: String (必填, 3-20字符)
    password: String (必填, Base64编码)
    authType: String (必填, "admin"|"user")
}
```

## 3. 接口语义分析（v3.0 核心）

> 分析每个接口的业务含义，而非仅列出参数。

| 接口 | 业务语义 | 业务规则 | 异常场景 |
|---|---|---|---|
| POST /login | 身份认证 | 密码 Base64 传输 | 账户锁定/密码错误 |
| POST /user | 创建用户 | 用户名唯一 | 用户名重复/权限不足 |

**接口设计问题识别**：
| 问题类型 | 示例 | 严重度 |
|---|---|---|
| RESTful 风格不一致 | 有的用 POST 有的用 GET 做创建 | 🟡P2 |
| 批量操作缺失 | 用户删除只能单删 | 🟡P2 |
| 分页参数不规范 | 不用 PageRequest 而用 Map | 🟡P2 |

## 4. 权限字符串全集

```java
// 去重后的权限串
perm:user:view      // 查看用户
perm:user:add       // 新增用户
perm:user:edit      // 编辑用户
perm:user:delete    // 删除用户
perm:role:view      // 查看角色
perm:role:add       // 新增角色
...
```

| 权限串 | 出现位置 | 使用次数 | 备注 |
|---|---|---|---|
| perm:user:view | UserController, RoleController | 3 | 权限字符串不一致风险 |

## 5. 公开端点清单（无需认证）

| 方法 | 路径 | Controller | 用途 |
|---|---|---|---|
| POST | /oauth/token | AuthController | OAuth2 登录 |
| GET | /captcha | CaptchaController | 验证码 |
| GET | /public/config | ConfigController | 公开配置 |

**⚠️ 风险标注**：
| 端点 | 风险 | 严重度 |
|---|---|---|
| GET /public/config | 可能暴露敏感配置 | 🔴P1 |

## 6. 错误码规范分析（v3.0 核心）

| 错误码 | 消息 | HTTP 状态 | 出现位置 |
|---|---|---|---|
| 10001 | 用户名或密码错误 | 401 | AuthController |
| 10002 | 账户已锁定 | 403 | AuthController |
| 20001 | 权限不足 | 403 | XxxController |

**错误码问题识别**：
| 问题 | 位置 | 建议 |
|---|---|---|
| 错误码未统一 | 各 Controller 自定义 | 应统一到 ErrorCode 枚举 |
| 错误信息暴露实现细节 | "密码盐值校验失败" | 应返回通用错误 |

## 7. 请求/响应示例（v3.0 核心）

### 登录接口
**请求**：
```json
POST /api/user/login
{
  "username": "admin",
  "password": "MTIzNDU2",  // Base64("123456")
  "authType": "admin"
}
```

**响应（成功）**：
```json
{
  "code": 0,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 7200
  }
}
```

**响应（失败）**：
```json
{
  "code": 10001,
  "message": "用户名或密码错误"
}
```

## 8. 版本管理分析（v3.0 核心）

| 路径模式 | 版本策略 | 实现方式 |
|---|---|---|
| /api/v1/user | URL 路径版本 | @RequestMapping("/v1") |
| /api/user | 无版本 | — |

**问题识别**：
- 缺少 API 版本管理 → 🔴P1（升级困难）
- 老版本无兼容策略 → 🔴P1

## 9. CORS 与跨域配置

| 配置项 | 值 | 风险 |
|---|---|---|
| allowedOrigins | * | 🔴CORS 通配 |
| allowCredentials | true | 与 * 冲突 |
| allowedMethods | GET,POST,PUT,DELETE | — |
| maxAge | 3600 | — |

## 10. API 质量问题汇总

| 严重度 | 问题 | 位置 | 建议 |
|---|---|---|---|
| 🔴P1 | @CrossOrigin("*") + allowCredentials(true) | AuthController | 改为明确域名白名单 |
| 🟡P2 | Swagger tags 重复 | 多个 Controller | 统一 tags 命名 |
| 🟡P2 | 入参无校验注解 | UserController | 添加 @Valid @NotNull |

【元信息】
| 字段 | 值 |
|---|---|
| 配套 | 01-系统总览 / 05-服务与业务逻辑 |
| Controller 数 | N |
| 端点总数 | N |
| 公开端点数 | N |

【强制要求】
- 每个端点必须列出（含入参、出参、鉴权）
- 公开端点必须单独标注
- 错误码必须分析
- Swagger tags 错位必须记录

【自我校验】
- 端点总数 = grep 结果
- Controller 数 = find 结果
- 鉴权列无空缺
- 公开端点与 @PermitAll 对应
```
