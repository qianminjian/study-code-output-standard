# AI Prompt · 03 API 清单

## 完整 Prompt

```
【背景】
项目 <name>，后端 <栈>。本任务生成"API 接口清单"资产。

【任务】
生成 asset-docs/03-后端-Controller接口清单.md。
严格按 references/methodology/03-文档模板与质量标准.md §03 模板。

【输入】
- Controller 目录：<path>
- 关注注解：
  - @RequestMapping / @GetMapping / @PostMapping / @PutMapping / @DeleteMapping
  - @PreAuthorize / @RequiresPermissions / @Secured
  - @CrossOrigin
  - @Api(tags = ...)
  - @PermitAll
- WebSecurityConfig 中的放行路径

【输出字段】
1. 概览表（Controller、前缀、tags、端点数、公开端点）
2. 详细接口清单（每个 Controller 一节）
3. 权限字符串全集（去重表）
4. 公开端点列表（无需 token）

【强制列（每个端点）】
| 方法 | 路径 | 入参 | 鉴权 | 公开 | 说明 |
| GET/POST/PUT/DELETE | /api/... | 实体/DTO/PageRequest | @PreAuthorize 值或"无" | ✅/— | 业务含义 |

【关键发现】
- Swagger tags 错位（复制粘贴未改）
- 权限字符串错用
- @CrossOrigin 公开端点未做白名单
- 端点缺少鉴权

【反例】
- 不写"见代码"代替入参
- 不省鉴权列
- 不漏 @CrossOrigin 公开端点
- 不省全局前缀
- 不写"约 70 个端点"

【自我校验】
- 端点总数 = `grep -rE "@(Get|Post|Put|Delete)Mapping" <controller-dir> | wc -l`
- Controller 数 = `find <controller-dir> -name "*.java" | wc -l`
- 公开端点数 = 概览表"公开端点"列之和
- 权限串数 = `grep -rEo "@PreAuthorize\\(\"([^\"]+)\"\\)" <controller-dir> | sort -u | wc -l`
- 元信息头 7 字段齐全
```

## 校验清单

- [ ] 端点总数与 grep 一致
- [ ] Controller 数与 find 一致
- [ ] 鉴权列无空缺
- [ ] 公开端点单独列
- [ ] 权限串全集与 @PreAuthorize 一致
- [ ] tags 错位单列标注
- [ ] 路径含全局前缀
