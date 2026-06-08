# Anti-Patterns Reference — 24 个反模式标签

> **按需加载**：在 Step 5 标注时 Read 本文件。
> 把扫出的反模式按本标签体系标注到 11-技术债清单。

---

## 标签全集

| 标签 | 含义 | 严重度 | 扫法 |
|---|---|:-:|---|
| `@sqlinjection` | SQL 注入风险 | 🔴 P0 | `grep -rE "\\$\\{[^}]+\\}" <xml-dir>` |
| `@secret-leak` | 密钥/密码明文 | 🔴 P0 | `grep -rE "(secret\|password\|token)\\s*=\\s*[\"'][^\"']{8,}[\"']"` |
| `@cors-wildcard` | CORS 通配 | 🔴 P0 | `grep -rn "allowedOrigins(\"\\*\")" <java-dir>` |
| `@actuator-exposure` | actuator 全部暴露 | 🔴 P0 | `grep -rn "actuator"` |
| `@wrong-token-hdr` | Token header 非标准 | 🔴 P0 | `grep -rn "headers\.\(token\\|x-token\)"` |
| `@xss` | XSS 风险 | 🟡 P1 | `grep -rE "\\.html\\([^)]*content[^)]*\\)"` |
| `@csrf` | CSRF 风险 | 🟡 P1 | 人工识别 |
| `@perm-mismatch` | 权限字符串错用 | 🟡 P1 | 人工 + 03 文档对账 |
| `@admin-bypass` | 绕过 admin 保护 | 🟡 P1 | 人工识别 |
| `@null-pointer` | 空指针风险 | 🟡 P1 | 静态分析工具 |
| `@n+1` | N+1 查询 | 🟢 P2 | 扫子查询 |
| `@missing-tx` | 缺事务 | 🟡 P1 | 扫 `@Transactional` 缺失 |
| `@hardcoded` | 硬编码 | 🟢 P2 | `grep -rE "(127\\.0\\.0\\.1\|10\\.\\d+\\.\\d+\\.\\d+)"` |
| `@dead-code` | 死代码 | ⚪ P3 | 静态分析 |
| `@todo-stub` | TODO 占位未实现 | ⚪ P3 | `grep -r "TODO Auto-generated"` |
| `@copy-paste` | 复制粘贴未改 | 🟢 P2 | 人工识别 |
| `@magic-number` | 魔法数 | ⚪ P3 | 人工识别 |
| `@long-function` | 过长函数 | ⚪ P3 | 静态分析 |
| `@long-param` | 长参数列表 | ⚪ P3 | 静态分析 |
| `@feature-envy` | 依恋情结 | ⚪ P3 | 静态分析 |
| `@shotgun-surgery` | 散弹枪修改 | ⚪ P3 | 静态分析 |
| `@wrong-package` | 包名/路径错 | ⚪ P3 | 人工识别 |
| `@wrong-tag` | 注解标签错 | 🟢 P2 | 人工识别 |
| `@missing-i18n` | 缺多语言键 | ⚪ P3 | CI 校验 |
| `@wrong-default` | 默认值错误 | 🟡 P1 | 人工识别 |

---

## 写入格式

在 11-技术债清单中，**每条问题带反模式标签**：

```markdown
🔴 P0 `@sqlinjection` `NewsInfoMapper.xml#listAll:42` 使用 `${news_title}` 字符串拼接，建议改 `#{}` 预编译。
🟡 P1 `@perm-mismatch` `Passipinfomgmt.vue:10` 整套 perms 错用 `web:linksinfomgmt:*`，应改 `web:passipinfomgmt:*`。
🟢 P2 `@n+1` `SysUserMapper.findAll:38` 标量子查询 N+1，建议改 JOIN。
```

---

## 5 个反复出现的"老朋友"

### 老朋友 1：密钥 / 密码硬编码

**症状**：
```java
String secret = "huawei";  // @secret-leak
```

**修复**：
```java
@Value("${jwt.secret}")
private String secret;
```
+ `application.properties`: `jwt.secret=${JWT_SECRET:PLEASE_OVERRIDE}`
+ 启动时校验非默认值

### 老朋友 2：SQL 字符串拼接

**症状**：
```xml
<select id="listAll">
  SELECT * FROM news_info WHERE news_title = '${news_title}'
</select>
```

**修复**：用 `<where>` + `<if>` + `#{}` 预编译

### 老朋友 3：复制粘贴 perms

**症状**：
```vue
<NewsButton perms="['web:linksinfomgmt:view', ...]"/>
<!-- 实际是 Passip 页面 -->
```

**修复**：用 `utils/perms.js` 集中定义枚举

### 老朋友 4：登录响应判断

**症状**：
```js
if (res.msg === '交易成功') { ... }
```

**修复**：
```js
if (res.code === 200) { ... }
```

### 老朋友 5：硬编码 baseUrl

**症状**：
```js
const baseUrl = 'http://10.52.9.110:9091/api'
```

**修复**：
```js
const baseUrl = process.env.VUE_APP_API_BASE || `${location.origin}/api`
```

---

## 业界反模式分类

### 安全类（OWASP Top 10）

| 反模式 | 对应 OWASP |
|---|---|
| `@sqlinjection` | A03 注入 |
| `@secret-leak` | A02 加密失败 |
| `@cors-wildcard` | A05 安全配置错误 |
| `@xss` | A03 注入 |
| `@csrf` | A01 访问控制失效 |
| `@perm-mismatch` | A01 访问控制失效 |
| `@actuator-exposure` | A05 安全配置错误 |
| `@wrong-token-hdr` | A07 鉴权失败 |

### 工程类（Code Smells）

| 反模式 | 对应 Code Smell |
|---|---|
| `@long-function` | Long Function |
| `@long-param` | Long Parameter List |
| `@magic-number` | Magic Number |
| `@dead-code` | Dead Code |
| `@copy-paste` | Duplicate Code |
| `@feature-envy` | Feature Envy |
| `@shotgun-surgery` | Shotgun Surgery |
| `@wrong-package` | Wrong Package |
| `@hardcoded` | Hardcoded |

### 性能类

| 反模式 | 含义 |
|---|---|
| `@n+1` | N+1 查询 |
| `@missing-tx` | 缺事务 |

### 协作类

| 反模式 | 含义 |
|---|---|
| `@wrong-tag` | 注解标签错（Swagger tags 错位） |
| `@missing-i18n` | 缺多语言键 |
| `@todo-stub` | TODO 占位未实现 |
| `@admin-bypass` | 绕过 admin 保护 |
| `@null-pointer` | 空指针风险 |
| `@wrong-default` | 默认值错误 |

---

## 元信息

| 字段 | 值 |
|---|---|
| 配套 | references/methodology.md / asset-types.md |
| 适用 | Step 5 标注时 |
| 标签数 | 25（24 反模式 + 1 占位） |
