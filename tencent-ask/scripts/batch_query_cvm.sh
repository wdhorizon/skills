#!/bin/bash
# batch_query_cvm.sh — 批量查询所有地域的CVM实例
# 用法: bash batch_query_cvm.sh [region1 region2 ...]

PROFILE="devops-readonly"
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="./tencent_memos/tmp"
mkdir -p "$OUTPUT_DIR"

# 默认查询的地域列表（可通过参数覆盖）
if [ $# -gt 0 ]; then
  REGIONS=("$@")
else
  REGIONS=("ap-beijing" "ap-beijing" "ap-shanghai" "ap-chengdu" "ap-nanjing")
fi

TOTAL_COUNT=0
ALL_INSTANCES=()

echo "======================================================"
echo "  腾讯云 CVM 批量查询"
echo "  查询地域: ${REGIONS[*]}"
echo "  时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "======================================================"

for REGION in "${REGIONS[@]}"; do
  echo ""
  echo ">>> 查询地域: $REGION"

  OFFSET=0
  LIMIT=100
  REGION_COUNT=0

  while true; do
    RESULT=$(tccli cvm DescribeInstances \
      --profile "$PROFILE" \
      --region "$REGION" \
      --Offset $OFFSET \
      --Limit $LIMIT 2>&1)

    if echo "$RESULT" | grep -q '"RequestId"'; then
      REGION_TOTAL=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('TotalCount',0))" 2>/dev/null || echo 0)
      BATCH_COUNT=$(echo "$RESULT" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('InstanceSet',[])))" 2>/dev/null || echo 0)

      # 保存每个地域的数据
      echo "$RESULT" > "$OUTPUT_DIR/cvm_${REGION}_offset${OFFSET}.json"

      REGION_COUNT=$((REGION_COUNT + BATCH_COUNT))
      OFFSET=$((OFFSET + LIMIT))

      if [ $OFFSET -ge $REGION_TOTAL ]; then
        break
      fi
    else
      echo "  ⚠️ 查询失败: $RESULT"
      break
    fi
  done

  echo "  完成: $REGION 共 $REGION_COUNT 台CVM"
  TOTAL_COUNT=$((TOTAL_COUNT + REGION_COUNT))
done

echo ""
echo "======================================================"
echo "  查询完成！总计 $TOTAL_COUNT 台CVM"
echo "  数据已保存至: $OUTPUT_DIR/"
echo "======================================================"

# 汇总展示
echo ""
echo "各地域CVM汇总："
for REGION in "${REGIONS[@]}"; do
  FILES=$(ls "$OUTPUT_DIR"/cvm_${REGION}_*.json 2>/dev/null)
  if [ -n "$FILES" ]; then
    COUNT=$(cat $FILES | python3 -c "
import sys, json
total = 0
for line in sys.stdin:
    try:
        d = json.loads(line)
        total += len(d.get('InstanceSet', []))
    except:
        pass
print(total)
" 2>/dev/null || echo 0)
    echo "  $REGION: $COUNT 台"
  fi
done
