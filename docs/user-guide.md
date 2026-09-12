# 量潮人事云使用文档

本文档说明 `qtcloud-human` 项目的产品模块、日常使用、本地开发、API、配置和发布流程。内容以当前仓库代码为准，规划中的功能会单独标注。

## 1. 项目概览

量潮人事云（QtCloud HR）是人力资源业务工作台，当前覆盖：

- 招聘：候选人邮件同步、初筛、人工审核、招聘报告、招聘沟通动作、简历查看；
- 计划：招聘、培训、绩效、薪酬等计划展示；
- 培训：主线任务和带教反馈展示；
- 绩效：行为成果、参考指标和评估结果展示；
- 薪酬：有效工时、职级时薪和结算结果展示；
- 员工关系：入职、试用期、晋升、离职等生命周期记录展示；
- 岗位和招聘计划 CLI：岗位查询、招聘计划 Markdown 输出。

### 1.1 当前实现状态

| 模块 | 数据来源 | 当前状态 |
|------|----------|----------|
| 总览 | `src/studio/assets/mock/overview.json` | 页面演示 |
| 计划 | `src/studio/assets/mock/plans.json` | 页面演示 |
| 招聘 | provider API | 已接入主要真实链路 |
| 培训 | `src/studio/assets/mock/training.json` | 页面演示 |
| 绩效 | `src/studio/assets/mock/records.json` | 页面演示 |
| 薪酬 | `src/studio/assets/mock/compensation.json` | 页面演示 |
| 员工关系 | `src/studio/assets/mock/relations.json` | 页面演示 |

因此，当前工作台可以作为招聘操作台使用，但其他页面的数据不能视为生产业务数据。

## 2. 项目结构

```text
qtcloud-human/
├── src/
│   ├── provider/              Go provider API
│   ├── cli/                   Rust 命令行工具
│   └── studio/                Flutter 工作台
├── third_party/
│   └── qtrecurit/             招聘 CLI 子模块
├── manifests/terraform/       阿里云 FC 部署配置
├── examples/
│   ├── human-api/             人事 API 参考实现
│   └── recruitment-plan/      招聘计划页面与模型参考实现
├── scripts/                   CDN 等运维脚本
└── docs/                      项目级文档
```

## 3. 日常使用

### 3.1 访问工作台

生产工作台入口：

```text
https://human.cloud.quanttide.com/
```

进入后使用统一认证登录。前端通过 OAuth token 调用认证服务和 provider API，刷新令牌保存在浏览器会话存储中。

### 3.2 总览、计划、培训、绩效、薪酬和关系

这些页面当前主要用于展示页面结构和业务模型：

1. 从左侧导航进入目标模块；
2. 查看页面中的示例数据；
3. 使用对应页面确认字段、状态和交互是否符合产品设计；
4. 不要将页面上的姓名、金额、工时、绩效和生命周期记录当作真实业务记录。

真实数据接入时，页面模型和接口契约需要同步调整。

### 3.3 招聘页面

招聘页面支持以下操作：

- 检查 provider 运行环境、拉取 HR 邮箱新投递、生成招聘统计报告（三者都在右上角“运维”菜单内）；
- 查看候选人邮件和简历附件；
- 将候选人标记为通过或拒绝；
- 对**已通过**的候选人发送问卷、发送实训邀约、发送笔试邀请、生成面试通知；
- 手动预览或下载简历。

右栏的动作区随候选人状态变化，同一个位置只有三种形态：

| 候选人状态 | 动作区内容 |
|------------|------------|
| 待处理 | 只有“通过”和“拒绝”，不显示发送类动作 |
| 已通过 | 发送问卷、发送实训邀约、发送笔试、生成面试通知 |
| 已拒绝 | 不显示任何发送动作，只保留筛选依据说明 |

推荐操作顺序：

1. 打开“招聘”；
2. 在“运维”菜单点击“检测环境”，确认 `qtrecurit` 和 HR 邮箱状态为可用；
3. 确认动作区下方横幅显示“演练模式 · 不会真实发送”；
4. 在“运维”菜单点击“拉取新邮件”；
5. 选择候选人，查看邮件正文、岗位和附件；
6. 保存“通过”或“拒绝”；
7. 候选人通过后，动作区出现流程动作，先在演练模式下确认参数和结果；
8. 需要统计时在“运维”菜单点击“生成报告”；
9. 只有生产负责人明确批准后，才关闭演练模式执行真实动作——横幅会变成红色的“真实发送已开启”。

### 3.4 简历预览和下载

简历不会在页面加载或切换候选人时自动下载，必须手动点击“预览”或“下载”：

- PDF 支持页面内嵌预览；
- DOC/DOCX 当前以下载后使用本地应用查看为主；
- provider 生成的临时简历链接有效期为 5 分钟；
- 简历预览和下载都会记录审计元数据。

如果提示“候选人不存在或数据已过期”，重新执行“拉取新邮件”即可刷新候选人快照。

## 4. 招聘安全门禁

真实招聘动作同时受以下条件控制：

1. 请求经过 API 网关，并携带正确的 provider 网关校验；
2. 请求带有有效的统一认证 Bearer token；
3. 当前认证用户的 `sub` 在招聘写入白名单中；
4. **候选人状态允许该动作**：只有人工审核结论为 `passed` 的候选人可以外发流程动作；
5. provider 已启用真实动作；
6. 请求将 `dry_run` 设置为 `false`；
7. provider 环境检查返回 `ready`；
8. FC 运行环境中的 `lark-cli` 已完成 HR 邮箱授权。

第 4 条是**状态闸门**，与 `dry_run` 无关：无论是否预览，待处理（`pending`）、已拒绝（`rejected`）或状态缺失的候选人都不能执行发送问卷、发送实训邀约、发送笔试和生成面试通知。被拦下时接口返回 `409 Conflict`，错误信息说明具体原因。

规则的唯一定义处是 provider 的 `domain.AllowedRecruitmentActions`。招聘页面通过同一套规则决定渲染哪些按钮——终态邮件不再显示发送按钮。

生产默认配置为：

```text
QTCLOUD_HUMAN_ALLOW_REAL_RECRUITMENT_ACTIONS=false
QTRECURIT_DRY_RUN_DEFAULT=true
```

任何一个门禁不满足，provider 都不会执行真实读信、发信或简历下载。

## 5. 本地开发

### 5.1 环境要求

| 组件 | 用途 |
|------|------|
| Go 1.26+ | provider |
| Rust 2024 toolchain | CLI |
| Flutter / Dart 3.11+ | Studio |
| Node.js/npm | provider 镜像中的 `lark-cli` |
| Terraform | 阿里云基础设施发布 |

### 5.2 启动 provider

```bash
cd src/provider
go run ./cmd/server
```

默认监听：

```text
http://127.0.0.1:8080
```

健康检查：

```bash
curl http://127.0.0.1:8080/healthz
```

预期响应：

```json
{"status":"ok"}
```

provider 默认使用 dry-run。要进行本地 API 联调，至少需要配置：

```powershell
$env:QTCLOUD_HUMAN_AUTH_USERINFO_URL = "https://api.quanttide.com/qtcloud-auth/userinfo"
$env:QTRECURIT_DRY_RUN_DEFAULT = "true"
$env:QTCLOUD_HUMAN_CORS_ORIGINS = "http://localhost:5080"
```

本地测试为了绕过正式网关，可以临时使用 `X-Operator` 和 `X-Recruitment-Permission` 请求头；这只适用于本地测试，不能作为生产认证方案。

### 5.3 启动 Flutter Studio

```bash
cd src/studio
flutter pub get
flutter run \
  --dart-define=QTCLOUD_HUMAN_API_BASE_URL=http://127.0.0.1:8080 \
  --dart-define=QTCLOUD_AUTH_BASE_URL=https://api.quanttide.com/qtcloud-auth
```

如果不设置 `QTCLOUD_HUMAN_API_BASE_URL`，招聘页面会继续显示页面但不能拉取 provider 候选人。

### 5.4 使用 Rust CLI

```bash
cd src/cli
cargo run -- status
cargo run -- position list
cargo run -- position list --department 技术部 --active true
cargo run -- position get <position-id>
```

CLI 默认从 profile 目录读取岗位数据：

```text
../../data/profile/human/positions.json
```

也可以通过环境变量指定：

```powershell
$env:QTRECURIT_PROFILE = "D:\path\to\profile"
```

招聘计划文件可以通过 `QTRECURIT_DATA` 指定：

```powershell
$env:QTRECURIT_DATA = "D:\path\to\data"
cargo run -- status
```

## 6. Provider API

以下路径以 provider API 根路径为基准。生产环境应通过 API 网关访问，不应直接访问 FC HTTP 触发器。

### 6.1 通用接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/healthz` | 服务健康检查 |
| GET | `/timesheets` | 查询工时记录 |
| POST | `/timesheets` | 创建工时记录 |
| GET | `/timesheets/{id}` | 查询单条工时记录 |
| PUT | `/timesheets/{id}` | 更新工时记录 |
| DELETE | `/timesheets/{id}` | 删除工时记录 |

工时 API 是 provider 中的基础领域接口，当前尚未接入 Studio 薪酬页面。

### 6.2 招聘接口

| 方法 | 路径 | 权限/用途 |
|------|------|-----------|
| GET | `/api/v1/recruitment/provider/status` | 检查 `qtrecurit` 和 HR 邮箱环境 |
| GET | `/api/v1/recruitment/candidates` | 查询候选人快照 |
| POST | `/api/v1/recruitment/inbox/sync` | 同步收件箱，需要写权限 |
| POST | `/api/v1/recruitment/reports` | 生成招聘 Markdown 报告 |
| PATCH | `/api/v1/recruitment/candidates/{candidate_id}` | 保存通过/拒绝，需要写权限 |
| POST | `/api/v1/recruitment/candidates/{candidate_id}/actions` | 执行招聘沟通动作，需要写权限 |
| POST | `/api/v1/recruitment/candidates/{candidate_id}/resume/{attachment_index}/view` | 生成临时简历链接，需要写权限 |
| GET | `/api/v1/recruitment/resume-view/{token}` | 访问临时简历内容，仅允许网关转发 |

### 6.3 招聘请求示例

生成最近 30 天报告：

```bash
curl -X POST "$API_BASE/api/v1/recruitment/reports" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"days":30,"dry_run":true}'
```

同步收件箱：

```bash
curl -X POST "$API_BASE/api/v1/recruitment/inbox/sync" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "mailbox": "hr@quanttide.com",
    "folder": "INBOX",
    "page_size": 50,
    "dry_run": true
  }'
```

保存人工审核结果：

```bash
curl -X PATCH "$API_BASE/api/v1/recruitment/candidates/cand_001" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status":"passed"}'
```

发送问卷的 dry-run：

```bash
curl -X POST "$API_BASE/api/v1/recruitment/candidates/cand_001/actions" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "send_survey",
    "dry_run": true,
    "params": {
      "link": "https://example.com/survey"
    }
  }'
```

上例要求 `cand_001` 已经通过人工审核（`status` 为 `passed`）。对未审核或已拒绝的候选人调用任何流程动作都会返回 `409 Conflict`。

支持的动作：

| `action` | 参数 |
|----------|------|
| `send_survey` | 可选 `link`，必须是有效 URL |
| `send_training_invite` | 可选 `qr`，受控资源引用 |
| `send_exam` | 无额外参数 |
| `create_interview_notice` | 必填 `position` 和 `time` |

候选人状态目前支持：

```text
passed
rejected
```

状态初始为 `pending`（尚未审核）。`PATCH` 只接受 `passed` 和 `rejected`；写入后会在后续收件箱同步中保留，不会被来源数据覆盖。只有 `passed` 的候选人可以执行上表中的流程动作，这一规则在 provider 领域层定义，与是否 `dry_run` 无关。

## 7. 配置参考

### 7.1 Studio 构建参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `QTCLOUD_HUMAN_API_BASE_URL` | provider API 或 API 网关地址 | 空 |
| `QTCLOUD_AUTH_BASE_URL` | 统一认证服务地址 | `https://api.quanttide.com/qtcloud-auth` |
| `QTCLOUD_HUMAN_OPERATOR` | 本地开发用操作员标识 | `studio-user` |

生产前端应配置 API 网关地址，例如：

```text
https://api.quanttide.com/qtcloud-human
```

不要把 FC HTTP 触发器直连地址写入前端构建参数。

### 7.2 Provider 运行参数

| 环境变量 | 说明 | 默认值 |
|----------|------|--------|
| `LISTEN_ADDR` | 监听地址 | `:8080` |
| `QTRECURIT_BIN` | `qtrecurit` 路径 | `qtrecurit` |
| `QTRECURIT_MANIFEST_PATH` | 本地通过 Cargo 运行 qtrecurit 时的 manifest 路径 | 空 |
| `QTRECURIT_TIMEOUT_SECONDS` | CLI 调用超时 | `60` |
| `QTRECURIT_DRY_RUN_DEFAULT` | 未指定 `dry_run` 时的默认值 | `true` |
| `QTCLOUD_HUMAN_ALLOW_REAL_RECRUITMENT_ACTIONS` | 是否允许真实招聘动作 | `false` |
| `QTCLOUD_HUMAN_AUTH_USERINFO_URL` | 统一认证 userinfo 地址 | 无，生产必填 |
| `QTCLOUD_HUMAN_RECRUITMENT_WRITERS` | 允许招聘写操作的认证用户 `sub`，逗号分隔 | 空 |
| `QTCLOUD_HUMAN_GATEWAY_SHARED_SECRET` | API 网关到 provider 的共享校验值 | 生产必填 |
| `QTCLOUD_HUMAN_CORS_ORIGINS` | 允许跨域来源，逗号分隔 | 内置本地来源和生产域名 |
| `QTCLOUD_HUMAN_CACHE_HOME` | qtrecurit 和简历缓存目录 | 系统临时目录 |
| `QTCLOUD_HUMAN_ACTION_LOG_DIR` | 招聘审计日志目录 | 空 |
| `QTCLOUD_HUMAN_RECRUITMENT_STATE_PATH` | 候选人快照路径 | 空 |
| `QTCLOUD_HUMAN_RESUME_VIEW_STATE_PATH` | 临时简历链接状态路径 | 空 |

生产 FC 默认使用 `/home/app` 下的私有运行目录保存缓存、状态和审计日志。

## 8. 发布流程

### 8.1 发布 provider

推送 `provider/*` tag 后，GitHub Actions 会：

1. 拉取仓库和 `qtrecurit` 子模块；
2. 构建 provider Go 二进制；
3. 构建 `qtrecurit` CLI；
4. 构建并推送 ACR 镜像；
5. 使用 Terraform 更新阿里云 FC 函数。

镜像构建上下文必须是仓库根目录：

```bash
docker build -f src/provider/Dockerfile .
```

### 8.2 发布 Studio

推送 `studio/*` tag 后，GitHub Actions 会：

1. 安装 Flutter；
2. 执行 `flutter pub get`；
3. 使用 API 地址和认证地址构建 Flutter Web；
4. 上传到 OSS 静态站点桶；
5. 刷新 CDN。

### 8.3 推荐发布顺序

1. 确认 API 网关路由和共享密钥；
2. 发布 provider；
3. 调用 provider status，确认环境状态；
4. 以 dry-run 验证报告、收件箱同步和招聘动作；
5. 发布 Studio；
6. 访问工作台验证前端和 provider API；
7. 真实动作仍保持关闭，直到 HR 邮箱认证和写入白名单确认完成。

## 9. 生产凭证与数据安全

- 不要把 `lark-cli` token、app secret、AccessKey 或 OAuth token 提交到 Git；
- Windows 本机的 DPAPI 凭证不能直接复制到 Linux/FC；
- 生产 `lark-cli` 凭证应在 Linux/FC 等价环境重新授权，或通过 `Bootstrap Lark CLI Credentials` workflow 上传到私有 OSS 前缀；
- 凭证 OSS 前缀必须保持私有，不能与 Studio 静态站点共用；
- 前端只保存访问令牌，不保存 HR 邮箱凭证；
- 招聘审计日志只记录动作元数据，不记录邮件正文、候选人邮箱、token 或环境变量；
- provider 只接受固定的招聘动作白名单和结构化参数，不直接执行客户端传入的 shell 字符串。

## 10. 测试与验证

执行 provider 测试：

```bash
cd src/provider
go test ./...
```

执行 CLI 测试：

```bash
cd src/cli
cargo test
```

执行 Flutter 测试：

```bash
cd src/studio
flutter test
```

执行参考 API 测试：

```bash
cd examples/human-api
go test ./...
go build ./...
```

文档或 Terraform 变更提交前，至少完成对应模块的构建或测试，并确认没有把生产凭证写入配置文件。

## 11. 常见问题

### 11.1 招聘列表为空

可能原因：

- provider 没有配置到 Studio；
- 尚未点击“拉取新邮件”；
- 当前环境保持真实动作关闭；
- provider 候选人状态为空；
- 认证或网关校验失败。

先点击“检测环境”，再检查 `QTCLOUD_HUMAN_API_BASE_URL` 和 provider 日志。

### 11.2 真实同步返回 403

检查：

- `QTCLOUD_HUMAN_ALLOW_REAL_RECRUITMENT_ACTIONS` 是否为 `true`；
- 当前用户 `sub` 是否在 `QTCLOUD_HUMAN_RECRUITMENT_WRITERS`；
- 请求是否经过 API 网关；
- 页面是否关闭了 `dry_run`。

### 11.3 流程动作返回 409

说明候选人状态不允许该动作。provider 只在候选人已通过人工审核时才执行发送问卷、发送实训邀约、发送笔试和生成面试通知。

检查：

- 该候选人的 `status` 是否为 `passed`（可在招聘页面右栏或 `GET /api/v1/recruitment/candidates` 查看）；
- 是否为已拒绝的候选人——终态邮件不再提供外发动作；
- 候选人快照的 `status` 是否为空，空值按“尚未审核”处理，同样会被拒绝。

正确顺序是先用 `PATCH /api/v1/recruitment/candidates/{candidate_id}` 保存 `{"status":"passed"}`，再执行流程动作。页面上的动作区会自动跟随状态变化：待处理只显示“通过 / 拒绝”，已通过才显示流程动作，已拒绝不再显示任何发送按钮。

### 11.4 真实操作返回 503

说明 provider 环境未就绪。检查 `/api/v1/recruitment/provider/status`，重点确认：

- `qtrecurit` 是否可执行；
- `lark-cli` 是否能访问 `hr@quanttide.com`；
- 生产凭证目录是否完整挂载；
- FC 网络和运行时配置是否正常。

### 11.5 简历预览失败

检查：

- 候选人是否刚刚同步，快照是否已过期；
- 附件是否为 PDF、DOC 或 DOCX；
- provider 是否允许真实招聘动作；
- 简历缓存是否位于配置的私有缓存根目录；
- 临时链接是否已超过 5 分钟有效期。

### 11.6 页面仍显示旧版本

Studio 发布使用 OSS/CDN。先强制刷新浏览器；如果仍未更新，检查发布 workflow 和 CDN 刷新结果。

## 12. 相关文档

- [项目说明邮件](./project-overview-email.md)
- [Studio 预览版使用说明](../src/studio/doc/preview-user-guide.md)
- [qtrecurit CLI 接入设计](../src/studio/doc/qtrecurit-cli-integration.md)
- [Terraform 部署说明](../manifests/terraform/README.md)
- [贡献与提交流程](../CONTRIBUTING.md)
