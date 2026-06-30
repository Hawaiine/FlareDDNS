#!/bin/bash
# ============================================================
# FlareDDNS  —  自动更新最快的 Cloudflare IP 到 DNS 记录
# 基于 CloudflareST 测速结果，将最快 IP 自动绑定到指定域名
#
# 使用方式:
#   1. 复制 config.example.conf 为 config.conf 并填入配置
#   2. 确保 CloudflareST (cfst) 在同一目录
#   3. 运行: bash flare_ddns.sh
# ============================================================

set -euo pipefail

# ---- 加载配置 ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 错误: 配置文件不存在: $CONFIG_FILE"
    echo "   请复制 config.example.conf 为 config.conf 并编辑"
    exit 1
fi
source "$CONFIG_FILE"

# ---- 依赖检查 ----
CFST_BIN="${SCRIPT_DIR}/cfst"
if [ ! -x "$CFST_BIN" ]; then
    echo "❌ 错误: 未找到 CloudflareST 可执行文件: $CFST_BIN"
    echo "   请从 https://github.com/XIU2/CloudflareSpeedTest 下载"
    exit 1
fi

# ---- 参数校验 ----
if [ -z "${CF_API_TOKEN:-}" ]; then
    echo "❌ 错误: CF_API_TOKEN 未设置"
    exit 1
fi
if [ -z "${CF_ZONE_ID:-}" ]; then
    echo "❌ 错误: CF_ZONE_ID 未设置"
    exit 1
fi
if [ ${#RECORD_NAMES[@]} -eq 0 ]; then
    echo "❌ 错误: RECORD_NAMES 数组为空，请至少设置一个域名"
    exit 1
fi

# ---- 颜色输出 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ---- Cloudflare API 函数 ----
CF_API_BASE="https://api.cloudflare.com/client/v4"

cf_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    local args=(
        -s
        -X "$method"
        -H "Authorization: Bearer $CF_API_TOKEN"
        -H "Content-Type: application/json"
    )

    if [ -n "$data" ]; then
        args+=(-d "$data")
    fi

    curl "${args[@]}" "${CF_API_BASE}${endpoint}"
}

# ---- 获取所有 DNS 记录，建立 name→id 映射 ----
echo -e "${CYAN}🔍 正在获取 DNS 记录列表...${NC}"
dns_records=$(cf_api "GET" "/zones/$CF_ZONE_ID/dns_records?type=A&per_page=100")

if ! echo "$dns_records" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('success') else 1)" 2>/dev/null; then
    echo -e "${RED}❌ API 认证失败！请检查 CF_API_TOKEN 是否正确${NC}"
    echo "API 返回: $(echo "$dns_records" | python3 -c "import sys,json; print(json.load(sys.stdin).get('errors','unknown'))" 2>/dev/null || echo "$dns_records")"
    exit 1
fi

declare -A RECORD_IDS
not_found=()

for name in "${RECORD_NAMES[@]}"; do
    id=$(echo "$dns_records" | python3 -c "
import sys,json
data = json.load(sys.stdin)
full_name = '$name'
for r in data.get('result', []):
    if r['name'] == full_name:
        print(r['id'])
        break
" 2>/dev/null)

    if [ -n "$id" ]; then
        RECORD_IDS["$name"]=$id
        echo -e "  ${GREEN}✅${NC} $name → ID: $id"
    else
        echo -e "  ${YELLOW}⚠️  未找到: $name${NC}"
        not_found+=("$name")
    fi
done

if [ ${#not_found[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}⚠️  以下域名未在 Zone 中找到，请检查域名是否正确:${NC}"
    printf "  • %s\n" "${not_found[@]}"
    echo "  可通过 Cloudflare 后台 → DNS → 确认域名拼写"
fi

if [ ${#RECORD_IDS[@]} -eq 0 ]; then
    echo -e "\n${RED}❌ 没有找到任何有效的 DNS 记录，退出${NC}"
    exit 1
fi

# ---- 运行 CloudflareST 测速 ----
echo -e "\n${CYAN}🚀 正在运行 CloudflareSpeedTest 测速...${NC}"
RESULT_CSV="${SCRIPT_DIR}/result.csv"

if [ -n "${CFST_ARGS:-}" ]; then
    # shellcheck disable=SC2086
    "$CFST_BIN" $CFST_ARGS
else
    "$CFST_BIN" -p 0 -o "${SCRIPT_DIR}/result.csv"
fi

if [ ! -f "$RESULT_CSV" ]; then
    echo -e "${RED}❌ 测速失败，未生成 result.csv${NC}"
    exit 1
fi

# ---- 读取测速结果并更新 DNS ----
echo -e "\n${CYAN}📡 正在更新 DNS 记录...${NC}"

TTL="${DNS_TTL:-60}"
PROXIED="${DNS_PROXIED:-false}"

updated=0
n=0

while IFS=',' read -r ip rest; do
    [ -z "$ip" ] && continue

    n=$((n + 1))
    idx=$((n - 1))

    if [ $idx -lt ${#RECORD_NAMES[@]} ]; then
        name="${RECORD_NAMES[$idx]}"
        record_id="${RECORD_IDS[$name]:-}"

        if [ -z "$record_id" ]; then
            echo -e "  ${YELLOW}⏭  跳过 $name（无对应 Record ID）${NC}"
            continue
        fi

        echo -e "  ${CYAN}[$n]${NC} 更新 $name → ${GREEN}$ip${NC}"

        response=$(cf_api "PUT" "/zones/$CF_ZONE_ID/dns_records/$record_id" \
            "{\"type\":\"A\",\"name\":\"$name\",\"content\":\"$ip\",\"ttl\":$TTL,\"proxied\":$PROXIED}")

        success=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success', False))" 2>/dev/null)
        if [ "$success" = "True" ]; then
            echo -e "    ${GREEN}✔  更新成功${NC}"
            updated=$((updated + 1))
        else
            error_msg=$(echo "$response" | python3 -c "import sys,json; e=json.load(sys.stdin).get('errors',[{}])[0]; print(e.get('message','?'))" 2>/dev/null)
            echo -e "    ${RED}✘  更新失败: $error_msg${NC}"
        fi
    fi
done < <(tail -n +2 "$RESULT_CSV")

rm -f "$RESULT_CSV"

echo -e "\n${GREEN}🎉 完成！共更新 $updated/${#RECORD_NAMES[@]} 条 DNS 记录${NC}"
if [ "$updated" -lt "${#RECORD_NAMES[@]}" ]; then
    echo -e "${YELLOW}💡 提示: 可能测速结果不足以覆盖所有域名，或部分域名未在 DNS 中找到${NC}"
fi