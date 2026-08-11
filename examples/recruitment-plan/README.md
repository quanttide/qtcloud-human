# 招聘计划参考实现（自 qtadmin 迁移）

「招聘计划 / 编制」参考实现，自 qtadmin 拆除时迁移，供 qtcloud-human 承接时参考。

## 结构

| 文件 | 说明 |
|------|------|
| `recruitment_model.dart` | 数据模型（手写，无 freezed）：`RecruitmentPlan`（月份 + 岗位）、`PositionPlan`（编制/已入职/进行中/备注）、`HumanPosition` / `PositionsFile`（岗位档案，对齐 CLI `positions.json`） |
| `recruitment_screen.dart` | 招聘计划页面：月度编制统计（编制/已入职/进行中/空缺）+ 岗位明细表 |
| `recruitment.json` | 契约示例（CLI `recruitment_plan.json` 同构：8 岗位默认计划） |
| `test/` | 模型 + 页面测试（14 个） |

## 数据契约（CLI 侧）

qtadmin CLI `human/status.rs` 产出 `recruitment_plan.json`：

```json
{
  "month": "2026-06",
  "positions": [
    { "name": "数据工程师", "headcount": 2, "filled": 0, "in_progress": 1, "note": "JD已发布" }
  ]
}
```

聚合字段：`totalHeadcount` / `totalFilled` / `totalInProgress` / `vacancies`。

## 承接建议

qtcloud-human 的 `plan` 模块（`lib/models/plan.dart`）目前只有通用计划骨架（type/cycle/status/progress）。
承接方向：将本参考实现的「编制明细 + 进度回填」（headcount/filled/in_progress）并入 `Plan`，
使招聘计划从骨架扩展为带编制进度的完整计划；岗位档案（`HumanPosition`）可对接后续员工关系模块。

## 测试

```bash
flutter pub get
flutter test
```
