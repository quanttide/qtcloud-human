#!/bin/bash
# 为 human.cloud.quanttide.com 配置 CDN HTTPS 证书 + DNS CNAME。
#
# 背景：human.cloud.quanttide.com 是量潮人事云工作台发布域名，CDN 源站为 OSS 桶 qtcloud-human-studio
# （桶与 ACL 见 manifests/terraform/studio.tf；发布流程见 .github/workflows/deploy-studio.yml）。
# 证书为 acme.sh 签发的泛域名证书 *.quanttide.com（ZeroSSL），续期后需重跑本脚本更新证书，
# 与 recurit/data.cloud/econ.cloud 等既有域名一致（同一张泛域名证书）。
#
# 前置：本机已登录 aliyun CLI（AK 模式）；acme.sh 证书目录存在。
set -e

DOMAIN='human.cloud.quanttide.com'
CERT_DIR='/home/iguo/.acme.sh/*.quanttide.com_ecc'
CERT_NAME="cert-${DOMAIN}-$(date +%s)"

echo "=== 1. 绑定 HTTPS 证书（CDN）==="
aliyun cdn SetCdnDomainSSLCertificate \
  --DomainName "$DOMAIN" \
  --CertName "$CERT_NAME" \
  --CertType upload \
  --SSLProtocol on \
  --SSLPub "$(cat "$CERT_DIR/fullchain.cer")" \
  --SSLPri "$(cat "$CERT_DIR/*.quanttide.com.key")"

echo "=== 2. 添加 DNS CNAME（已存在则跳过）==="
# RR=human.cloud（cloud.quanttide.com 子域记录）；RRKeyWord 会误匹配前缀，
# 需在结果中精确过滤 RR=human.cloud 且 Type=CNAME
EXISTING=$(aliyun alidns DescribeDomainRecords --DomainName quanttide.com --RRKeyWord human.cloud 2>/dev/null | python3 -c "
import sys, json
try:
    recs = json.load(sys.stdin).get('DomainRecords', {}).get('Record', [])
    cnames = [r for r in recs if r.get('RR') == 'human.cloud' and r.get('Type') == 'CNAME']
    print(len(cnames))
except Exception:
    print(0)
")
if [ "$EXISTING" -gt 0 ]; then
  echo "CNAME 记录已存在，跳过"
else
  aliyun alidns AddDomainRecord \
    --DomainName quanttide.com \
    --RR human.cloud \
    --Type CNAME \
    --Value "${DOMAIN}.w.kunlunaq.com"
fi
