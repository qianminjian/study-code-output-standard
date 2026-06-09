# AI Prompt · 04 后端 Mapper 操作清单

> ⚠️ **核心原则：按代码实际输出，不按模板预设清单**
>
> - **必须忠实还原代码中的实际 Mapper**，从代码扫描，有哪些列哪些
> - **方法清单从 XML/接口扫描得出**，不是从模板预设——如果某个 Mapper 没有 `findPage`，就不写这一行
> - **SQL 模式从代码实际归纳**，不是画一个模板分页/Join 模式

---

## 完整 Prompt

```
【背景】
项目 <name>，ORM 方案 <MyBatis/MyBatis-Plus/JPA>。本任务生成"Mapper 操作清单"资产。
通过逆向 Mapper/DAO 层代码，推断数据访问模式。

【核心原则】
⚠️ 不按模板预设清单输出，按代码实际扫描结果输出！
- Mapper 从 find 命令扫描，有哪些列哪些
- 方法从 XML/接口扫描，有哪些列哪些
- SQL 模式从代码实际归纳，不是预设模板

【任务】
生成 asset-docs/04-后端-Mapper操作清单.md。
严格按 ${SKILL_HOME}/assets/04-后端-Mapper操作清单.md.tmpl 模板结构。

【输入】
- Mapper 接口目录：src/main/java/.../mapper/ 或 dao/
- Mapper XML 目录：src/main/resources/mapper/ 或 mybatis/
- 实体类目录：src/main/java/.../entity/ 或 model/
- 数据库配置：application*.yml

【扫描命令（必跑）】
```bash
# Mapper 接口数
find <mapper-dir> -name "*Mapper.java" | wc -l

# XML 文件数
find <xml-dir> -name "*.xml" | wc -l

# SQL 类型统计
grep -c "<insert" <xml-dir>/*.xml
grep -c "<update" <xml-dir>/*.xml
grep -c "<delete" <xml-dir>/*.xml
grep -c "<select" <xml-dir>/*.xml

# 注入风险
grep -rE "\\$\\{[^}]+\\}" <xml-dir>
```

【输出字段·必须包含】

## 1. Mapper 概览

| Mapper | 对应表/实体 | 操作类型 | CRUD 完整度 | 备注 |
|---|---|---|---|---|
| UserMapper | sys_user | MyBatis-Plus | ✅4/4 | 含分页查询 |
| RoleMapper | sys_role | XML+注解 | ✅4/4 | — |

**统计行**：
- Mapper 接口数：N
- XML 文件数：N
- insert/update/delete/select 操作数统计

## 2. 核心 Mapper 详解

### 2.1 UserMapper

**接口定义**：
```java
public interface UserMapper extends BaseMapper<User> {
    // 继承 MyBatis-Plus BaseMapper (CRUD 基础操作)

    // 自定义查询
    User selectByUsername(@Param("username") String username);

    List<User> selectByRoleId(@Param("roleId") Long roleId);

    Page<User> selectByCondition(UserQuery query);

    int batchInsert(@Param("list") List<User> users);
}
```

**XML SQL 片段**：
```xml
<!-- 按用户名查询 -->
<select id="selectByUsername" resultType="User">
    SELECT * FROM sys_user
    WHERE username = #{username}
    AND deleted = 0
</select>

<!-- 条件分页查询 -->
<select id="selectByCondition" resultType="User">
    SELECT u.*, r.name as role_name
    FROM sys_user u
    LEFT JOIN sys_role r ON u.role_id = r.id
    <where>
        <if test="username != null">AND u.username LIKE #{username}</if>
        <if test="status != null">AND u.status = #{status}</if>
    </where>
    ORDER BY u.create_time DESC
</select>
```

## 3. SQL 操作类型分析

### 3.1 分页查询模式

| Mapper | 分页方式 | 实现 |
|---|---|---|
| UserMapper | MyBatis-Plus Page | selectByCondition 使用 Page<User> |
| OrderMapper | XML + RowBounds | 已废弃 |
| ProductMapper | 手动 LIMIT | XML 中 #{page}, #{size} |

### 3.2 批量操作

| Mapper | 批量操作 | 性能风险 |
|---|---|---|
| UserMapper | batchInsert | 🔴 5000+ 条需分批 |
| OrderMapper | batchUpdate | 🟡 建议 ≤ 1000/批 |

### 3.3 关联查询（JOIN）

| Mapper | JOIN 类型 | 表 | 用途 |
|---|---|---|---|
| UserMapper | LEFT JOIN | sys_role | 获取角色名 |
| OrderMapper | INNER JOIN | sys_user, sys_product | 订单详情 |

**N+1 查询风险**：
| 场景 | 风险 | 严重度 |
|---|---|---|
| 查询用户列表时循环查角色 | N+1 | 🟡P2 |
| 查询订单时循环查商品 | N+1 | 🔴P1 |

## 4. 复杂 SQL 模式分析

### 4.1 动态 SQL 使用

```xml
<!-- if 判断 -->
<if test="status != null and status != ''">
    AND status = #{status}
</if>

<!-- choose 选择 -->
<choose>
    <when test="type == 1">AND type = 1</when>
    <when test="type == 2">AND type = 2</when>
    <otherwise>AND deleted = 0</otherwise>
</choose>

<!-- foreach 循环 -->
<foreach collection="ids" item="id">
    #{id}
</foreach>
```

| 动态 SQL 模式 | Mapper | 使用场景 |
|---|---|---|
| if 判断 | 多个 | 条件筛选 |
| foreach 循环 | UserMapper, RoleMapper | 批量 ID 查询 |
| trim 去前缀 | ProductMapper | 动态 SET |

### 4.2 resultMap 映射

```xml
<resultMap id="UserWithRoleMap" type="User">
    <id property="id" column="id"/>
    <result property="username" column="username"/>
    <association property="role" javaType="Role">
        <id property="id" column="role_id"/>
        <result property="name" column="role_name"/>
    </association>
</resultMap>
```

| resultMap 类型 | 使用场景 | 问题 |
|---|---|---|
| 简单映射 | 大多数单表查询 | — |
| 嵌套映射 | 关联查询 | 🔴 嵌套过深影响性能 |
| 分步查询 | 大数据量关联 | 🟡 需要配置 |

## 5. SQL 注入风险

**必跑**：
```bash
grep -rE "\\$\\{[^}]+\\}" <xml-dir>
```

| 文件 | 行号 | SQL 片段 | 注入风险 | 严重度 |
|---|---|---|---|---|
| UserMapper.xml | 42 | WHERE name = ${name} | 直接拼接 | 🔴P0 |
| ProductMapper.xml | 28 | ORDER BY ${sortField} | 列名注入 | 🔴P0 |

## 6. 数据访问模式

| 模式 | Mapper | 缓存策略 | 事务类型 |
|---|---|---|---|
| 读多写少 | ConfigMapper | Redis 缓存 | 只读事务 |
| 写多读少 | LogMapper | 无缓存 | 读写事务 |
| 强一致 | AccountMapper | 无缓存 | 必需事务 |

**事务边界分析**：
| Service | Mapper 调用链 | 事务范围 |
|---|---|---|
| UserService.createUser() | UserMapper.insert() + RoleMapper.insert() | ✅ 开启事务 |
| UserService.syncExternal() | UserMapper.select() + UserMapper.update() + LogMapper.insert() | 🔴 无事务 |

## 7. CRUD 完整度评估

| Mapper | insert | delete | update | select | 缺失 |
|---|---|---|---|---|---|
| UserMapper | ✅ | ✅ | ✅ | ✅ | — |
| RoleMapper | ✅ | ❌ | ✅ | ✅ | delete |
| PermissionMapper | ✅ | ❌ | ❌ | ✅ | delete, update |

## 8. 命名规范问题

| 问题类型 | 示例 | 正确 | 位置 |
|---|---|---|---|
| Mapper 名不一致 | UserDAO | UserMapper | dao/UserDAO.java |
| 方法名不语义 | selectA() | selectByUsername() | UserMapper.java:15 |
| XML namespace 错 | com.old.UserMapper | com.new.UserMapper | UserMapper.xml:2 |

## 9. Mapper 与 Service 映射

| Service | Mapper | 事务边界 | 潜在风险 |
|---|---|---|---|
| UserServiceImpl | UserMapper, RoleMapper | 无显式事务 | UPMS 调用失败可能污染 |

【元信息】
| 字段 | 值 |
|---|---|
| 配套 | 02-数据模型 / 05-服务与业务逻辑 |
| Mapper 数 | N |
| XML 数 | N |

【强制要求】
- 每个 Mapper 列出核心方法
- SQL 注入必须扫描
- N+1 风险必须标注
- 事务边界必须分析

【自我校验】
- Mapper 数 = find 结果
- 注入数与 grep 结果一致
- CRUD 完整度评估覆盖所有 Mapper
```
