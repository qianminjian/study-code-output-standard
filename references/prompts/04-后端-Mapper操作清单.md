# AI Prompt · 04 Mapper 清单

## 完整 Prompt

```
【背景】
项目 <name>，ORM 框架 <MyBatis/Hibernate/...>。本任务生成"数据访问操作清单"。

【任务】
生成 asset-docs/04-后端-Mapper操作清单.md。
按 references/methodology/03-文档模板与质量标准.md §04 模板。

【输入】
- Mapper 接口目录：<path>
- Mapper XML 目录：<path>
- 关注：方法名（findPage 约定）、SQL 模式、resultMap、字段映射错位

【输出字段】
1. 接口与 XML 一览（表：Mapper、XML、表、业务域）
2. 通用基类（如 MyBatisBaseDao）
3. 每个 Mapper 的方法清单（每个方法含业务用途）
4. 关键 SQL 模式（分页、Join、resultMap、子查询）
5. ⚠️ 已知 Mapper 问题

【强制列】
- 接口表：| Mapper | XML | 表 | 业务域 |
- 问题表：| 严重度 | 文件:行 | 问题 |

【关键扫描】
- SQL 注入：`grep -rE "\\$\\{[^}]+\\}" <xml-dir>`
- N+1：扫所有 `<select>` 找嵌套 `<select>` / 子查询
- 字段映射错位：对比 Model 字段与 XML column

【反例】
- 不漏 N+1 风险
- 不漏字段映射错位
- 不漏 XML 与接口命名不一致（如 LinksInfo.xml 缺 Mapper 后缀）
- 不漏空继承 Mapper

【自我校验】
- Mapper 数 = `find <mapper-dir> -name "*.java" | wc -l`
- XML 数 = `find <xml-dir> -name "*.xml" | wc -l`
- 注入数 = `grep -rE "\\$\\{[^}]+\\}" <xml-dir> | wc -l`
- 元信息头 7 字段
```

## 校验清单

- [ ] Mapper 数与 XML 数对账
- [ ] 每个方法标注业务用途
- [ ] 4 类 SQL 模式齐全
- [ ] 注入风险全部 P0
- [ ] 字段映射错位标注行号
