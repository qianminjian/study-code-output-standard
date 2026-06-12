# 02 无 DDL 时的推断模式（降级参考）

> 本文件是 `assets/02-数据模型与表结构.md.tmpl` §2-B 的独立版本。
> 02 模板中仅留 3 行交叉引用，完整降级逻辑见本文件。

## 何时启用

项目**没有** `*.sql` / `flyway/` / `liquibase/` / `db-scripts/` 等 DDL 来源时启用本模式；**同时** 02 §2 "数据库表清单" 标 N/A。

**典型场景**：老项目（wxcbrc、legacy Web）只有 XML + Model，无建表脚本。

## 推断源（按可信度从高到低）

1. **MyBatis XML 的 resultType / parameterType**（最可信）— grep `<resultMap>` 和 `resultType="<entity>"` 拿表/字段映射
2. **ORM 实体的 `@Table` / `@Entity` 注解**（Java JPA / Hibernate）
3. **Mapper 接口方法签名**（参数 + 返回值类型）
4. **前端 `http/modules/*.js` 中的字段名**（最弱，仅做交叉验证）

## 强制标记

所有推断出的表，**「表名」列前加 ⚠️**，并在 §元信息 表中加一行 "DDL 来源：无（推断）"。

## 示例

| ⚠️ 表名（推断） | 中文 | 主要字段 | 索引/约束 |
|---|---|---|---|
| ⚠️ `<table_from_resultType>` | 推断：<根据 Model 名> | 推断：<从 resultMap> | ⚠️ 未知 |
| ⚠️ `<table_from_xml_namespace>` | 推断：<根据 Mapper> | 推断：<从 SQL> | ⚠️ 未知 |

## 为什么独立成段

与 §2 "真实 DDL" 隔离，强制读者意识到这是推断，不是事实。CI 校验脚本会扫 ⚠️ 标记，提示 "是否补充 DDL"。

## 真实案例（v3.5 验证）

在 devops-message 项目中：
- 6 张表有 DDL（sql/devops-message-basic.sql）
- 5 张表无 DDL（message_system_notice_* / message_notify_status），启用推断模式
- 推断源：`@TableName` 注解 + MyBatis XML namespace
- 结果：推断表的 DDL 不完整是项目的真实技术债（见 11 资产技术债清单）
