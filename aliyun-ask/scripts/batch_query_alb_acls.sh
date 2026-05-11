#!/bin/bash

##############################################################################
# ALB 监听器 ACL 批量查询脚本
# 功能：批量查询多个 ALB 实例的监听端口及关联的 ACL 信息
# 用法：./batch_query_alb_acls.sh "alb-XXXXXXX,alb-YYYYYYY,alb-ZZZZZZZ" [RegionId]
# 可选环境变量：ALIYUN_PROFILE=dingtalk-readonly
#
# 输出：结果保存到 aliyun_memos/tmp/results_batch_alb_acls_<日期_时间>.json
##############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取当前日期和时间
CURRENT_DATE=$(date +%Y%m%d)
CURRENT_TIME=$(date +%H%M%S)

# 输出目录
OUTPUT_DIR="./aliyun_memos/tmp"

# 显示帮助信息
show_help() {
    echo "用法: $0 \"<ALB_ID1>,<ALB_ID2>,...\" [RegionId]"
    echo ""
    echo "参数说明:"
    echo "  ALB_IDs  - 必填，多个 ALB 实例 ID，用逗号分隔"
    echo "             例如: \"alb-abc123,alb-def456,alb-ghi789\""
    echo "  RegionId - 可选，地域 ID（默认：cn-beijing；ALIYUN_PROFILE=dingtalk-readonly 时默认：cn-zhangjiakou）"
    echo ""
    echo "示例:"
    echo "  $0 \"alb-wz9fjlqmz0783y4vglx13,alb-abc123def456\""
    echo "  $0 \"alb-wz9fjlqmz0783y4vglx13,alb-abc123def456\" cn-hangzhou"
    echo "  ALIYUN_PROFILE=dingtalk-readonly $0 \"alb-wz9fjlqmz0783y4vglx13,alb-abc123def456\""
    echo ""
    echo "输出格式: JSON（保存到 $OUTPUT_DIR/results_batch_alb_acls_<日期_时间>.json）"
    echo "  {"
    echo "    \"LoadBalancerId\": \"alb-XXXXX\","
    echo "    \"LoadBalancerName\": \"XXXXXX\","
    echo "    \"ListenerId\": \"lsn-XXXXX\","
    echo "    \"ListenerPort\": XXXXX,"
    echo "    \"AddressType\": \"Internet\","
    echo "    \"Protocol\": \"HTTPS\","
    echo "    \"AclStatus\": \"on\","
    echo "    \"AclType\": \"white\","
    echo "    \"AclIds\": [\"acl-xxxxx\"]"
    echo "  }"
    echo ""
    echo "缓存机制:"
    echo "  脚本会在 ./aliyun_cache 目录下缓存 ACL 关联关系"
    echo "  缓存文件格式: alb-acl-relations-<RegionId>-<YYYYMMDD>.json"
    echo "  缓存有效期: 当天有效（非当天日期会重新查询）"
}

# 检查参数
if [ $# -lt 1 ]; then
    echo -e "${RED}错误: 缺少必需参数${NC}"
    show_help
    exit 1
fi

# 解析输入参数
ALB_IDS_INPUT="$1"
DEFAULT_REGION_ID="cn-beijing"
if [ "${ALIYUN_PROFILE:-}" = "dingtalk-readonly" ]; then
    DEFAULT_REGION_ID="cn-zhangjiakou"
fi
REGION_ID="${2:-$DEFAULT_REGION_ID}"

ALIYUN_CMD=(aliyun)
if [ -n "${ALIYUN_PROFILE:-}" ]; then
    ALIYUN_CMD+=(--profile "$ALIYUN_PROFILE")
fi

# 验证输入不为空
if [ -z "$ALB_IDS_INPUT" ]; then
    echo -e "${RED}错误: ALB ID 列表不能为空${NC}"
    exit 1
fi

# 将逗号分隔的 ALB IDs 转换为数组
IFS=',' read -ra ALB_ID_ARRAY <<< "$ALB_IDS_INPUT"

# 验证至少有一个 ALB ID
if [ ${#ALB_ID_ARRAY[@]} -eq 0 ]; then
    echo -e "${RED}错误: 未找到有效的 ALB ID${NC}"
    exit 1
fi

# 验证每个 ALB ID 格式
for alb_id in "${ALB_ID_ARRAY[@]}"; do
    # 去除空格
    alb_id=$(echo "$alb_id" | xargs)
    if [[ ! "$alb_id" =~ ^alb-[a-z0-9]+$ ]]; then
        echo -e "${RED}错误: ALB ID 格式不正确: $alb_id${NC}"
        echo "正确格式示例: alb-wz9fjlqmz0783y4vglx13"
        exit 1
    fi
done

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 输出文件路径
OUTPUT_FILE="$OUTPUT_DIR/results_batch_alb_acls_${CURRENT_DATE}_${CURRENT_TIME}.json"

# 临时文件存储所有结果
TEMP_RESULTS=$(mktemp)
> "$TEMP_RESULTS"

# 统计变量
TOTAL_ALBS=${#ALB_ID_ARRAY[@]}
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_ALBS=()

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ALB ACL 批量查询工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Profile: ${ALIYUN_PROFILE:-default}"
echo "地域: $REGION_ID"
echo "待查询 ALB 数量: $TOTAL_ALBS"
echo "输出文件: $OUTPUT_FILE"
echo ""

# 缓存设置
CACHE_DIR="./aliyun_cache"
PROFILE_CACHE_KEY="${ALIYUN_PROFILE:-default}"
CACHE_FILE="$CACHE_DIR/alb-acl-relations-${PROFILE_CACHE_KEY}-${REGION_ID}-${CURRENT_DATE}.json"
mkdir -p "$CACHE_DIR"

# 函数：从缓存读取 ACL 关联关系
load_cache() {
    if [ -f "$CACHE_FILE" ]; then
        if jq -e '.AclRelations' "$CACHE_FILE" >/dev/null 2>&1; then
            cat "$CACHE_FILE"
            return 0
        else
            rm -f "$CACHE_FILE"
        fi
    fi
    return 1
}

# 函数：保存 ACL 关联关系到缓存
save_cache() {
    local acl_relations="$1"
    echo "$acl_relations" > "$CACHE_FILE"
    find "$CACHE_DIR" -name "alb-acl-relations-*.json" -type f -mtime +3 -delete 2>/dev/null || true
}

# 查询所有 ACL 实例和关联关系（一次性查询，提高效率）
echo -e "${YELLOW}[准备] 查询区域 ACL 信息...${NC}"

# 查询所有 ACL 实例
ACLS=$("${ALIYUN_CMD[@]}" alb ListAcls \
    --RegionId "$REGION_ID" \
    --MaxResults 100 \
    2>/dev/null)

ACL_COUNT=0
ACL_RELATIONS=""

if [ -n "$ACLS" ]; then
    ACL_COUNT=$(echo "$ACLS" | jq '.Acls | length')
    echo -e "  找到 ${GREEN}$ACL_COUNT${NC} 个 ACL 实例"

    # 尝试从缓存加载关联关系
    if ACL_RELATIONS_CACHE=$(load_cache); then
        echo -e "  ${GREEN}✓ 使用缓存的 ACL 关联关系${NC}"
        ACL_RELATIONS="$ACL_RELATIONS_CACHE"
    elif [ $ACL_COUNT -gt 0 ]; then
        echo "  正在查询 ACL 关联关系..."

        # 分批查询 ACL 关联关系
        BATCH_SIZE=5
        TEMP_ACL_RELATIONS=$(mktemp)
        > "$TEMP_ACL_RELATIONS"

        ACL_ID_LIST=()
        while IFS= read -r acl_id; do
            [ -n "$acl_id" ] && ACL_ID_LIST+=("$acl_id")
        done < <(echo "$ACLS" | jq -r '.Acls[]?.AclId | select(. != null)')

        for ((i=0; i<${#ACL_ID_LIST[@]}; i+=BATCH_SIZE)); do
            BATCH_END=$((i + BATCH_SIZE - 1))
            [ $BATCH_END -ge ${#ACL_ID_LIST[@]} ] && BATCH_END=$((${#ACL_ID_LIST[@]} - 1))

            ACL_RELATIONS_ARGS=(alb ListAclRelations --RegionId "$REGION_ID")
            ACL_INDEX=1

            for ((j=i; j<=BATCH_END; j++)); do
                ACL_RELATIONS_ARGS+=(--AclIds.$ACL_INDEX "${ACL_ID_LIST[$j]}")
                ((ACL_INDEX++))
            done

            BATCH_RESULT=$("${ALIYUN_CMD[@]}" "${ACL_RELATIONS_ARGS[@]}" --force 2>/dev/null)
            [ $? -eq 0 ] && [ -n "$BATCH_RESULT" ] && echo "$BATCH_RESULT" >> "$TEMP_ACL_RELATIONS"
        done

        if [ -s "$TEMP_ACL_RELATIONS" ]; then
            ACL_RELATIONS=$(jq -s '{AclRelations: [.[].AclRelations[]] | map(select(. != null)) | flatten}' "$TEMP_ACL_RELATIONS" 2>/dev/null)
            save_cache "$ACL_RELATIONS"
            RELATION_COUNT=$(echo "$ACL_RELATIONS" | jq -r '.AclRelations | length' 2>/dev/null || echo "0")
            echo -e "  ${GREEN}✓ ACL 关联关系查询完成 ($RELATION_COUNT 条记录)${NC}"
        fi

        rm -f "$TEMP_ACL_RELATIONS"
    fi
else
    echo -e "  ${YELLOW}未找到 ACL 实例${NC}"
fi

echo ""

# 建立 ACL 关联映射
LISTENER_ACL_MAP_FILE=$(mktemp)
LISTENER_ACL_STATUS_FILE=$(mktemp)

if [ -n "$ACL_RELATIONS" ]; then
    echo "$ACL_RELATIONS" | jq -r '.AclRelations[]? | select(.RelatedListeners != null) | .AclId + "|" + (.RelatedListeners[]? | .ListenerId + "|" + (.Status // "on"))' | while IFS='|' read -r acl_id listener_id acl_status; do
        if [ -n "$listener_id" ] && [ -n "$acl_id" ]; then
            current_acls=$(grep "^${listener_id}:" "$LISTENER_ACL_MAP_FILE" 2>/dev/null | cut -d: -f2-)
            if [ -n "$current_acls" ]; then
                sed -i '' "s/^${listener_id}:.*/${listener_id}:${current_acls},${acl_id}/" "$LISTENER_ACL_MAP_FILE"
            else
                echo "${listener_id}:${acl_id}" >> "$LISTENER_ACL_MAP_FILE"
            fi

            if ! grep -q "^${listener_id}:" "$LISTENER_ACL_STATUS_FILE" 2>/dev/null; then
                echo "${listener_id}:${acl_status}" >> "$LISTENER_ACL_STATUS_FILE"
            fi
        fi
    done
fi

# 处理每个 ALB 实例
for alb_id in "${ALB_ID_ARRAY[@]}"; do
    # 去除空格
    alb_id=$(echo "$alb_id" | xargs)

    echo -e "${YELLOW}[$((SUCCESS_COUNT + FAILED_COUNT + 1))/$TOTAL_ALBS] 查询 ALB: $alb_id${NC}"

    # 查询 ALB 基本信息
    ALB_INFO=$("${ALIYUN_CMD[@]}" alb GetLoadBalancerAttribute \
        --LoadBalancerId "$alb_id" \
        --RegionId "$REGION_ID" \
        2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$ALB_INFO" ]; then
        echo -e "  ${RED}✗ 无法查询 ALB 实例信息${NC}"
        ((FAILED_COUNT++))
        FAILED_ALBS+=("$alb_id")
        echo ""
        continue
    fi

    ALB_NAME=$(echo "$ALB_INFO" | jq -r '.LoadBalancerName // "未命名"')
    ADDRESS_TYPE=$(echo "$ALB_INFO" | jq -r '.AddressType // "Unknown"')

    echo "  名称: $ALB_NAME"
    echo "  类型: $ADDRESS_TYPE"

    # 查询监听器
    LISTENERS=$("${ALIYUN_CMD[@]}" alb ListListeners \
        --LoadBalancerIds.1 "$alb_id" \
        --RegionId "$REGION_ID" \
        --MaxResults 100 \
        --force \
        2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$LISTENERS" ]; then
        echo -e "  ${RED}✗ 无法查询监听器信息${NC}"
        ((FAILED_COUNT++))
        FAILED_ALBS+=("$alb_id")
        echo ""
        continue
    fi

    LISTENER_ARRAY=$(echo "$LISTENERS" | jq '.Listeners // []')
    LISTENER_COUNT=$(echo "$LISTENER_ARRAY" | jq 'length')

    if [ "$LISTENER_COUNT" -eq 0 ]; then
        echo -e "  ${YELLOW}无监听器${NC}"
        ((SUCCESS_COUNT++))
        echo ""
        continue
    fi

    echo "  监听器: $LISTENER_COUNT 个"

    # 使用 jq 处理每个监听器并直接输出到临时文件
    echo "$LISTENER_ARRAY" | jq -c '.[]' | while IFS= read -r listener_json; do
        [ -z "$listener_json" ] && continue

        listener_id=$(echo "$listener_json" | jq -r '.ListenerId // empty')
        listener_port=$(echo "$listener_json" | jq -r '.ListenerPort // "0"')
        protocol=$(echo "$listener_json" | jq -r '.ListenerProtocol // "unknown"')

        [ -z "$listener_id" ] && continue

        listener_acl_entry=$(grep "^${listener_id}:" "$LISTENER_ACL_MAP_FILE" 2>/dev/null || true)
        listener_status_entry=$(grep "^${listener_id}:" "$LISTENER_ACL_STATUS_FILE" 2>/dev/null || true)

        if [ -n "$listener_acl_entry" ]; then
            associated_acl_ids=$(echo "$listener_acl_entry" | cut -d: -f2-)
            acl_status=$(echo "$listener_status_entry" | cut -d: -f2-)
            acl_type=""
            acl_ids_array=$(echo "$associated_acl_ids" | jq -R 'split(",") | map(select(. != ""))')
        else
            acl_ids_from_listener=$(echo "$listener_json" | jq -r 'select(.AclIds != null) | .AclIds[]? | select(. != null and . != "")')
            acl_status=$(echo "$listener_json" | jq -r '.AclStatus // "off"')
            acl_type=$(echo "$listener_json" | jq -r '.AclType // ""')

            if [ -n "$acl_ids_from_listener" ]; then
                acl_ids_array=$(echo "$acl_ids_from_listener" | awk 'BEGIN{ORS=""; print "["} NR>1{printf ","} {printf "\"%s\"", $0} END{print "]"}')
            else
                acl_ids_array="[]"
            fi
        fi

        jq -n \
            --arg lb_id "$alb_id" \
            --arg lb_name "$ALB_NAME" \
            --arg lsn_id "$listener_id" \
            --arg port "$listener_port" \
            --arg addr_type "$ADDRESS_TYPE" \
            --arg proto "$protocol" \
            --arg status "$acl_status" \
            --arg type "$acl_type" \
            --argjson acl_ids "$acl_ids_array" \
            '{
                LoadBalancerId: $lb_id,
                LoadBalancerName: $lb_name,
                ListenerId: $lsn_id,
                ListenerPort: ($port | tonumber),
                AddressType: $addr_type,
                Protocol: $proto,
                AclStatus: $status,
                AclType: $type,
                AclIds: $acl_ids
            }' >> "$TEMP_RESULTS"
        echo "" >> "$TEMP_RESULTS"
    done

    echo -e "  ${GREEN}✓ 查询完成${NC}"
    ((SUCCESS_COUNT++))
    echo ""
done

# 清理临时映射文件
rm -f "$LISTENER_ACL_MAP_FILE" "$LISTENER_ACL_STATUS_FILE"

# 将结果写入输出文件
cp "$TEMP_RESULTS" "$OUTPUT_FILE"
rm -f "$TEMP_RESULTS"

# 统计信息 - 使用 jq 计算实际对象数量
TOTAL_ENTRIES=$(jq -s 'length' "$OUTPUT_FILE" 2>/dev/null || echo "0")
HAS_ACL_COUNT=$(jq -s '[.[] | select(.AclIds != null and (.AclIds | length) > 0)] | length' "$OUTPUT_FILE" 2>/dev/null || echo "0")

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  查询完成${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "输出文件: $OUTPUT_FILE"
echo ""
echo -e "${BLUE}📊 统计信息${NC}:"
echo "  ALB 实例总数: $TOTAL_ALBS"
echo "  查询成功: $SUCCESS_COUNT"
echo "  查询失败: $FAILED_COUNT"

if [ $FAILED_COUNT -gt 0 ]; then
    echo ""
    echo -e "${RED}失败的 ALB 实例${NC}:"
    for failed_alb in "${FAILED_ALBS[@]}"; do
        echo "  - $failed_alb"
    done
fi

echo ""
echo "  监听配置总数: $TOTAL_ENTRIES"
echo "  配置了 ACL 的监听器: $HAS_ACL_COUNT"
echo ""
