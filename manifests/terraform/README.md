# qtcloud-human 部署选型（IaC）

对齐 qtdata、qtclass 与 qtrecurit 的部署模式，作为 Terraform 基础设施代码的设计依据。

## 部署选型

| 维度 | 选型 | 说明 |
|------|------|------|
| 客户端形态 | Flutter Web（量潮人事云工作台） | `src/studio`，`flutter build web --release` 产出站点 |
| 发布分发 | 阿里云 OSS 桶 `qtcloud-human-studio` | 静态网站托管（index.html 默认页）+ 公共读 |
| CDN | 阿里云 CDN `human.cloud.quanttide.com` | 源站 OSS（域名回源），泛域名证书 `*.quanttide.com`（acme.sh 签发，续期后重跑 `scripts/configure-human-cdn.sh`，与 recurit/data.cloud 等域名一致） |
| 服务端 | 无独立服务端（当前为客户端演示） | 后续接入 API 时独立部署，不在本 IaC 范围 |

## 本 IaC 范围

- **应用级**（`qtcloud-human-<env>` 命名）：OSS 发布分发桶 `qtcloud-human-studio`（`studio.tf`：桶 + 静态网站托管 + 公共读 + 关闭阻止公共访问）
- **不含** CDN / DNS / 证书（无组织级 IaC 先例，在控制台配置并记录于本文件）

## studio 客户端发布

- 基础设施：`terraform apply`（`studio.tf`）
- 构建上传：`.github/workflows/deploy-studio.yml`（推送 tag `studio/*` 触发 → flutter build web → ossutil cp → 刷新 CDN）

## 关键操作记录（手动部署踩坑，源自 qtrecurit 经验）

1. **阻止公共访问**：2023 后新 OSS 桶默认开启"阻止公共访问"，即使 ACL=public-read 匿名访问也返回 `AccessDenied`。需用 `alicloud_oss_bucket_public_access_block` 独立资源显式关闭。
2. **ACL drift**：桶创建后 ACL 可能回退为 private，`terraform plan` 可检测并修复。
3. **CDN 配置**（控制台/CLI 完成，`scripts/configure-human-cdn.sh` 固化证书与 DNS）：
   - `AddCdnDomain`：`human.cloud.quanttide.com`，源站 OSS `qtcloud-human-studio.oss-cn-hangzhou.aliyuncs.com`（type=oss, port=443）
   - HTTPS：上传 `*.quanttide.com` 泛域名证书（`SetCdnDomainSSLCertificate` CertType=upload，acme.sh 3 个月续期，续期后重跑脚本）
   - DNS：`human.cloud.quanttide.com` CNAME → `human.cloud.quanttide.com.w.kunlunaq.com`（RR=`human.cloud`，注意精确匹配，避免被前缀记录误判）

## 使用

```sh
terraform init \
  -backend-config="bucket=quanttide-terraform-state" \
  -backend-config="key=qtcloud-human/terraform.tfstate" \
  -backend-config="region=cn-hangzhou"
terraform plan
terraform apply
```
