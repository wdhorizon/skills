#!/bin/bash

##############################################################################
# ALB 监听器 ACL 查询脚本
# 功能：根据 ALB ID 查询所有监听端口及关联的 ACL 信息
# 注意：必须使用 ListAclRelations API 查询真实的 ACL 关联关系
# 用法：./query_alb_acls.sh <ALB_ID> [RegionId]
# 可选环境变量：ALIYUN_PROFILE=dingtalk-readonly
#
# 缓存机制：脚本会在当前目录下保存 ACL 关联关系缓存文件
#           文件名格式：alb-acl-relations-<REGION_ID>-<YYYYMMDD>.json
#           缓存有效期：当天有效（非当天日期会重新查询）
##############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取当前日期
CURRENT_DATE=$(date +%Y%m%d)

# 显示帮助信息
show_help() {
    echo "用法: $0 <ALB_ID> [RegionId]"
    echo ""
    echo "参数说明:"
    echo "  ALB_ID    - 必填，ALB 实例 ID（例如：alb-wz9fjlqmz0783y4vglx13）"
    echo "  RegionId  - 可选，地域 ID（默认：cn-beijing；ALIYUN_PROFILE=dingtalk-readonly 时默认：cn-zhangjiakou）"
    echo ""
    echo "示例:"
    echo "  $0 alb-wz9fjlqmz0783y4vglx13"
    echo "  $0 alb-wz9fjlqmz0783y4vglx13 cn-hangzhou"
    echo "  ALIYUN_PROFILE=dingtalk-readonly $0 alb-wz9fjlqmz0783y4vglx13"
    echo ""
    echo "输出格式: JSON"
    echo "  {"
    echo "    \"LoadBalancerId\": \"alb-XXXXX\","
    echo "    \"LoadBalancerName\": \"XXXXXX\","
    echo "    \"ListenerId\": \"lsn-XXXXX\","
    echo "    \"ListenerPort\": XXXXX,"
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
    echo "  清理缓存: rm -rf ./aliyun_cache"
    echo ""
    echo "注意: 通过 ListAclRelations API 查询真实的 ACL 关联关系"
}

# 检查参数
if [ $# -lt 1 ]; then
    echo -e "${RED}错误: 缺少必需参数${NC}"
    show_help
    exit 1
fi

ALB_ID="$1"
DEFAULT_REGION_ID="cn-beijing"
if [ "${ALIYUN_PROFILE:-}" = "dingtalk-readonly" ]; then
    DEFAULT_REGION_ID="cn-zhangjiakou"
fi
REGION_ID="${2:-$DEFAULT_REGION_ID}"

ALIYUN_CMD=(aliyun)
if [ -n "${ALIYUN_PROFILE:-}" ]; then
    ALIYUN_CMD+=(--profile "$ALIYUN_PROFILE")
fi

# 缓存文件路径
CACHE_DIR="./aliyun_cache"
PROFILE_CACHE_KEY="${ALIYUN_PROFILE:-default}"
CACHE_FILE="$CACHE_DIR/alb-acl-relations-${PROFILE_CACHE_KEY}-${REGION_ID}-${CURRENT_DATE}.json"
CACHE_LOCK="$CACHE_DIR/.lock"

# 验证 ALB ID 格式
if [[ ! "$ALB_ID" =~ ^alb-[a-z0-9]+$ ]]; then
    echo -e "${RED}错误: ALB ID 格式不正确${NC}"
    echo "正确格式示例: alb-wz9fjlqmz0783y4vglx13"
    exit 1
fi

# 创建缓存目录
mkdir -p "$CACHE_DIR"

# 函数：从缓存读取 ACL 关联关系
load_cache() {
    if [ -f "$CACHE_FILE" ]; then
        echo -e "  ${GREEN}✓ 发现本地缓存文件${NC}"
        echo "  缓存文件: $CACHE_FILE"

        # 验证缓存文件格式
        if jq -e '.AclRelations' "$CACHE_FILE" >/dev/null 2>&1; then
            ACL_RELATIONS=$(cat "$CACHE_FILE")
            RELATION_COUNT=$(echo "$ACL_RELATIONS" | jq -r '.AclRelations | length' 2>/dev/null || echo "0")
            echo -e "  ${GREEN}缓存有效，共 $RELATION_COUNT 条关联记录${NC}"
            return 0
        else
            echo -e "  ${YELLOW}缓存文件格式错误，将重新查询${NC}"
            rm -f "$CACHE_FILE"
            return 1
        fi
    fi
    return 1
}

# 函数：保存 ACL 关联关系到缓存
save_cache() {
    local acl_relations="$1"
    echo "$acl_relations" > "$CACHE_FILE"
    echo -e "  ${GREEN}✓ 缓存已保存到: $CACHE_FILE${NC}"

    # 清理过期缓存文件（保留最近 3 天）
    find "$CACHE_DIR" -name "alb-acl-relations-*.json" -type f -mtime +3 -delete 2>/dev/null || true
}

echo -e "${GREEN}开始查询 ALB 监听器 ACL 信息${NC}"
echo "ALB ID: $ALB_ID"
echo "Profile: ${ALIYUN_PROFILE:-default}"
echo "地域: $REGION_ID"
echo ""

# 第一步：查询 ALB 基本信息
echo -e "${YELLOW}[1/4] 查询 ALB 实例信息...${NC}"
ALB_INFO=$("${ALIYUN_CMD[@]}" alb GetLoadBalancerAttribute \
    --LoadBalancerId "$ALB_ID" \
    --RegionId "$REGION_ID" \
    2>/dev/null)

if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 无法查询 ALB 实例信息${NC}"
    echo "请检查:"
    echo "  1. ALB ID 是否正确"
    echo "  2. 地域 ID 是否正确"
    echo "  3. 是否有足够的权限"
    exit 1
fi

ALB_NAME=$(echo "$ALB_INFO" | jq -r '.LoadBalancerName // "未命名"')
echo "ALB 名称: $ALB_NAME"
echo ""

# 第二步：查询所有监听器
echo -e "${YELLOW}[2/4] 查询监听器列表...${NC}"
LISTENERS=$("${ALIYUN_CMD[@]}" alb ListListeners \
    --LoadBalancerIds.1 "$ALB_ID" \
    --RegionId "$REGION_ID" \
    --MaxResults 100 \
    --force \
    2>/dev/null)

if [ $? -ne 0 ] || [ -z "$LISTENERS" ]; then
    echo -e "${RED}错误: 无法查询监听器信息${NC}"
    exit 1
fi

# 获取监听器数组
LISTENER_ARRAY=$(echo "$LISTENERS" | jq '.Listeners // []')
LISTENER_COUNT=$(echo "$LISTENER_ARRAY" | jq 'length')

if [ "$LISTENER_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}警告: 该 ALB 实例没有监听器${NC}"
    exit 0
fi

echo -e "  找到 ${GREEN}$LISTENER_COUNT${NC} 个监听器"

# 第三步：查询所有 ACL 实例
echo ""
echo -e "${YELLOW}[3/4] 查询 ACL 实例列表...${NC}"
ACLS=$("${ALIYUN_CMD[@]}" alb ListAcls \
    --RegionId "$REGION_ID" \
    --MaxResults 100 \
    2>/dev/null)

if [ -z "$ACLS" ]; then
    echo -e "${YELLOW}未找到 ACL 实例${NC}"
    ACL_COUNT=0
else
    ACL_COUNT=$(echo "$ACLS" | jq '.Acls | length')
    echo -e "  找到 ${GREEN}$ACL_COUNT${NC} 个 ACL 实例"
fi

# 第四步：查询 ACL 关联关系（关键步骤）
echo ""
echo -e "${YELLOW}[4/4] 查询 ACL 关联关系...${NC}"

if [ "$ACL_COUNT" -eq 0 ]; then
    echo "  没有 ACL 实例，跳过关联关系查询"
    ACL_RELATIONS=""
else
    echo "  正在查询 $ACL_COUNT 个 ACL 的关联关系..."

    # 尝试从缓存加载
    if load_cache; then
        # 缓存加载成功
        :
    else
        # 缓存不存在或已过期，通过 API 查询
        echo -e "  ${YELLOW}缓存未命中或已过期，通过 API 查询...${NC}"

        # 分批查询 ACL 关联关系（每批最多 5 个 - API 限制）
        BATCH_SIZE=5
        BATCH_NUM=0

        # 临时文件存储所有关联关系
        TEMP_ACL_RELATIONS=$(mktemp)
        > "$TEMP_ACL_RELATIONS"

        # 收集所有 ACL ID 到数组
        ACL_ID_LIST=()
        while IFS= read -r acl_id; do
            if [ -n "$acl_id" ]; then
                ACL_ID_LIST+=("$acl_id")
            fi
        done < <(echo "$ACLS" | jq -r '.Acls[]?.AclId | select(. != null)')

        # 分批处理
        for ((i=0; i<${#ACL_ID_LIST[@]}; i+=BATCH_SIZE)); do
            ((BATCH_NUM++))

            # 构建当前批次的 ACL ID
            BATCH_END=$((i + BATCH_SIZE - 1))
            if [ $BATCH_END -ge ${#ACL_ID_LIST[@]} ]; then
                BATCH_END=$((${#ACL_ID_LIST[@]} - 1))
            fi

            CURRENT_SIZE=$((BATCH_END - i + 1))
            echo -e "  查询批次 $BATCH_NUM ($CURRENT_SIZE 个 ACL)..."

            # 构建查询命令
            ACL_RELATIONS_ARGS=(alb ListAclRelations --RegionId "$REGION_ID")
            ACL_INDEX=1

            for ((j=i; j<=BATCH_END; j++)); do
                ACL_RELATIONS_ARGS+=(--AclIds.$ACL_INDEX "${ACL_ID_LIST[$j]}")
                ((ACL_INDEX++))
            done

            # 执行查询并追加结果到临时文件
            BATCH_RESULT=$("${ALIYUN_CMD[@]}" "${ACL_RELATIONS_ARGS[@]}" --force 2>/dev/null)

            if [ $? -eq 0 ] && [ -n "$BATCH_RESULT" ]; then
                echo "$BATCH_RESULT" >> "$TEMP_ACL_RELATIONS"
            fi
        done

        # 合并所有批次的关联关系
        if [ -s "$TEMP_ACL_RELATIONS" ]; then
            # 将所有 JSON 结果合并成一个数组
            ACL_RELATIONS=$(jq -s '{AclRelations: [.[].AclRelations[]] | map(select(. != null)) | flatten}' "$TEMP_ACL_RELATIONS" 2>/dev/null)

            # 检查合并结果是否有效
            RELATION_COUNT=$(echo "$ACL_RELATIONS" | jq -r '.AclRelations | length' 2>/dev/null || echo "0")

            if [ "$RELATION_COUNT" -gt 0 ]; then
                echo -e "  ${GREEN}ACL 关联关系查询完成 (共 $RELATION_COUNT 条关联记录)${NC}"

                # 保存到缓存
                save_cache "$ACL_RELATIONS"
            else
                echo -e "${YELLOW}未找到 ACL 关联关系${NC}"
                ACL_RELATIONS=""
            fi
        else
            echo -e "${YELLOW}警告: 无法查询 ACL 关联关系，将使用监听器对象中的 ACL 信息${NC}"
            ACL_RELATIONS=""
        fi

        # 清理临时文件
        rm -f "$TEMP_ACL_RELATIONS"
    fi
fi

echo ""
echo -e "${GREEN}=== 查询结果 ===${NC}"
echo ""

# 建立 ACL 关联映射（使用临时文件，兼容 bash 3.x）
LISTENER_ACL_MAP_FILE=$(mktemp)
LISTENER_ACL_STATUS_FILE=$(mktemp)

if [ -n "$ACL_RELATIONS" ]; then
    # 解析 ListAclRelations 返回结果
    # API 返回格式：AclRelations[].AclId, AclRelations[].RelatedListeners[]
    echo "$ACL_RELATIONS" | jq -r '.AclRelations[]? | select(.RelatedListeners != null) | .AclId + "|" + (.RelatedListeners[]? | .ListenerId + "|" + (.Status // "on"))' | while IFS='|' read -r acl_id listener_id acl_status; do
        if [ -n "$listener_id" ] && [ -n "$acl_id" ]; then
            # 保存 ACL ID 映射（格式：listener_id:acl_id1,acl_id2,...）
            current_acls=$(grep "^${listener_id}:" "$LISTENER_ACL_MAP_FILE" 2>/dev/null | cut -d: -f2-)
            if [ -n "$current_acls" ]; then
                sed -i '' "s/^${listener_id}:.*/${listener_id}:${current_acls},${acl_id}/" "$LISTENER_ACL_MAP_FILE"
            else
                echo "${listener_id}:${acl_id}" >> "$LISTENER_ACL_MAP_FILE"
            fi

            # 保存 ACL 状态
            if ! grep -q "^${listener_id}:" "$LISTENER_ACL_STATUS_FILE" 2>/dev/null; then
                echo "${listener_id}:${acl_status}" >> "$LISTENER_ACL_STATUS_FILE"
            fi
        fi
    done
fi

# 生成 JSON 输出并保存到临时文件
TEMP_OUTPUT=$(mktemp)
> "$TEMP_OUTPUT"

echo "$LISTENER_ARRAY" | jq -r '.[] | @json' | while read -r listener_json; do
    listener_id=$(echo "$listener_json" | jq -r '.ListenerId')
    listener_port=$(echo "$listener_json" | jq -r '.ListenerPort')
    protocol=$(echo "$listener_json" | jq -r '.ListenerProtocol')

    # 从映射文件中获取 ACL 关联信息
    listener_acl_entry=$(grep "^${listener_id}:" "$LISTENER_ACL_MAP_FILE" 2>/dev/null)
    listener_status_entry=$(grep "^${listener_id}:" "$LISTENER_ACL_STATUS_FILE" 2>/dev/null)

    if [ -n "$listener_acl_entry" ]; then
        # 使用 ListAclRelations 查询到的真实关联关系
        associated_acl_ids=$(echo "$listener_acl_entry" | cut -d: -f2-)
        acl_status=$(echo "$listener_status_entry" | cut -d: -f2-)
        acl_type=""  # ACL 类型需要从 ACL 详情获取，这里暂留空

        # 转换为 JSON 数组格式（使用 jq 更可靠）
        acl_ids_array=$(echo "$associated_acl_ids" | jq -R 'split(",") | map(select(. != ""))')
    else
        # 监听器未关联 ACL，使用监听器对象中的信息（可能不准确）
        acl_ids_from_listener=$(echo "$listener_json" | jq -r 'select(.AclIds != null) | .AclIds[]? | select(. != null and . != "")')
        acl_status=$(echo "$listener_json" | jq -r '.AclStatus // "off"')
        acl_type=$(echo "$listener_json" | jq -r '.AclType // ""')

        if [ -n "$acl_ids_from_listener" ]; then
            acl_ids_array=$(echo "$acl_ids_from_listener" | awk 'BEGIN{ORS=""; print "["} NR>1{printf ","} {printf "\"%s\"", $0} END{print "]"}')
        else
            acl_ids_array="[]"
        fi
    fi

    # 输出 JSON（每行一个 JSON 对象）
    jq -n \
        --arg lb_id "$ALB_ID" \
        --arg lb_name "$ALB_NAME" \
        --arg lsn_id "$listener_id" \
        --arg port "$listener_port" \
        --arg proto "$protocol" \
        --arg status "$acl_status" \
        --arg type "$acl_type" \
        --argjson acl_ids "$acl_ids_array" \
        '{
            LoadBalancerId: $lb_id,
            LoadBalancerName: $lb_name,
            ListenerId: $lsn_id,
            ListenerPort: ($port | tonumber),
            Protocol: $proto,
            AclStatus: $status,
            AclType: $type,
            AclIds: $acl_ids
        }' >> "$TEMP_OUTPUT"
    echo "" >> "$TEMP_OUTPUT"
done

# 统计结果
has_acl_count=$(jq -s '[.[] | select(.AclIds != null and (.AclIds | length) > 0)] | length' "$TEMP_OUTPUT")
no_acl_count=$(jq -s '[.[] | select(.AclIds == null or (.AclIds | length) == 0)] | length' "$TEMP_OUTPUT")

# 输出结果
cat "$TEMP_OUTPUT"

# 清理临时文件
rm -f "$LISTENER_ACL_MAP_FILE" "$LISTENER_ACL_STATUS_FILE" "$TEMP_OUTPUT"

echo ""
echo -e "${GREEN}✅ 查询完成${NC}"
echo ""
echo -e "📊 ${BLUE}统计信息${NC}:"
echo "  监听器总数: $LISTENER_COUNT"
echo "  ACL 实例总数: $ACL_COUNT"
echo "  配置了 ACL 的监听器: $has_acl_count"
echo "  未配置 ACL 的监听器: $no_acl_count"
