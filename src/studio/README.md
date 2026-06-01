# 量潮人事云工作台 (QtCloud HR Studio)

量潮人事云工作台是一款跨平台人力资源管理应用，提供招聘筛选、薪资核算等核心 HR 功能的管理界面。

## 功能模块

### 招聘
- 简历收件箱管理
- AI 初筛结果审核
- 候选人匹配度排序

### 薪资
- 计时工资核算
- 加班费与绩效奖金计算
- 政策参数集中配置

## 平台支持

| 平台 | 状态 |
|------|------|
| Android | ✅ |
| iOS | ✅ |
| Web | ✅ |
| macOS | ✅ |
| Linux | ✅ |
| Windows | ✅ |

## 开发环境

- Flutter SDK: ^3.11.5
- Dart SDK: ^3.11.5

## 快速开始

```bash
# 获取依赖
flutter pub get

# 运行应用
flutter run

# 运行测试
flutter test
```

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── app/                   # 应用配置
├── features/              # 功能模块
│   ├── recruitment/       # 招聘模块
│   └── salary/           # 薪资模块
├── shared/                # 共享组件
└── services/             # 业务服务
```
