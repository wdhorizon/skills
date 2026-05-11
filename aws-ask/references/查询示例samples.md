# AWS Ask 查询示例 (Query Samples)

> 所有 CLI 命令均使用 `--profile devops-readonly`，已在命令中体现。

---

## 一、简单查询示例 (SIMPLE_QUERY, L1-L2)

### 1.1 验证 AWS CLI 环境

```bash
# 验证 devops-readonly profile 是否配置正确
aws sts get-caller-identity --profile devops-readonly

# 输出示例
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/devops-readonly"
}
```

### 1.2 查询 EC2 实例详情

**用户查询**: "查看 EC2 实例 i-0123456789abcdef0 的详细信息"

```bash
# Step 1: 查询实例详情
aws ec2 describe-instances \
  --instance-ids i-0123456789abcdef0 \
  --profile devops-readonly \
  --region ap-southeast-1 \
  | jq '.Reservations[].Instances[] | {
      InstanceId,
      Name: (.Tags // [] | map(select(.Key == "Name")) | first | .Value // "N/A"),
      InstanceType,
      State: .State.Name,
      PrivateIpAddress,
      PublicIpAddress: (.PublicIpAddress // "N/A"),
      AvailabilityZone: .Placement.AvailabilityZone,
      VpcId,
      SubnetId,
      LaunchTime,
      IamProfile: (.IamInstanceProfile.Arn // "None")
    }'
```

**输出结果**:
```json
{
  "InstanceId": "i-0123456789abcdef0",
  "Name": "web-server-01",
  "InstanceType": "t3.medium",
  "State": "running",
  "PrivateIpAddress": "10.0.1.100",
  "PublicIpAddress": "N/A",
  "AvailabilityZone": "ap-southeast-1a",
  "VpcId": "vpc-0abc123def456789a",
  "SubnetId": "subnet-0abc123def456789a",
  "LaunchTime": "2025-01-01T00:00:00+00:00",
  "IamProfile": "arn:aws:iam::123456789012:instance-profile/WebServerRole"
}
```

---

### 1.3 查询 EC2 实例列表

**用户查询**: "列出 ap-southeast-1 所有运行中的 EC2 实例"

```bash
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --profile devops-readonly \
  --region ap-southeast-1 \
  --query 'Reservations[].Instances[].{
    ID:InstanceId,
    Name:Tags[?Key==`Name`]|[0].Value,
    Type:InstanceType,
    State:State.Name,
    PrivateIP:PrivateIpAddress,
    AZ:Placement.AvailabilityZone
  }' \
  --output table
```

---

### 1.4 查询 S3 Bucket 列表

**用户查询**: "列出所有 S3 Bucket"

```bash
# 列出所有 Bucket（全局）
aws s3 ls --profile devops-readonly

# 获取每个 Bucket 的区域
for bucket in $(aws s3api list-buckets --profile devops-readonly --query 'Buckets[].Name' --output text); do
  region=$(aws s3api get-bucket-location --bucket $bucket --profile devops-readonly --query 'LocationConstraint' --output text 2>/dev/null || echo "ap-southeast-1")
  echo "$bucket: $region"
done
```

---

### 1.5 查询 RDS 实例列表

**用户查询**: "列出所有 RDS 数据库实例"

```bash
aws rds describe-db-instances \
  --profile devops-readonly \
  --region ap-southeast-1 \
  | jq '.DBInstances[] | {
      DBInstanceIdentifier,
      DBInstanceClass,
      Engine,
      EngineVersion,
      DBInstanceStatus,
      Endpoint: .Endpoint.Address,
      Port: .Endpoint.Port,
      MultiAZ,
      StorageEncrypted,
      VpcId: .DBSubnetGroup.VpcId
    }'
```

---

### 1.6 查询 CloudWatch 告警状态

**用户查询**: "查看所有当前处于 ALARM 状态的 CloudWatch 告警"

```bash
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --profile devops-readonly \
  --region ap-southeast-1 \
  | jq '.MetricAlarms[] | {
      AlarmName,
      Namespace,
      MetricName,
      Threshold,
      ComparisonOperator,
      StateValue,
      StateReason,
      AlarmActions
    }'
```

---

### 1.7 查询 Lambda 函数列表

**用户查询**: "列出所有 Lambda 函数及其配置"

```bash
aws lambda list-functions \
  --profile devops-readonly \
  --region ap-southeast-1 \
  | jq '.Functions[] | {
      FunctionName,
      Runtime,
      Handler,
      MemorySize,
      Timeout,
      Role,
      LastModified,
      CodeSize
    }'
```

---

## 二、关联查询示例 (ASSOCIATION_QUERY, L2-L3)

### 2.1 查询 EC2 挂载的存储卷

**用户查询**: "EC2 实例 i-0123456789abcdef0 挂载了哪些 EBS 存储卷？"

```bash
# Step 1: 查询挂载的存储卷
aws ec2 describe-volumes \
  --filters "Name=attachment.instance-id,Values=i-0123456789abcdef0" \
  --profile devops-readonly \
  --region ap-southeast-1 \
  | jq '.Volumes[] | {
      VolumeId,
      Size: (.Size | tostring) + " GiB",
      VolumeType,
      State,
      Iops,
      Encrypted,
      AttachDevice: .Attachments[0].Device,
      DeleteOnTermination: .Attachments[0].DeleteOnTermination
    }'
```

**输出结果**:
```json
{
  "VolumeId": "vol-0123456789abcdef0",
  "Size": "100 GiB",
  "VolumeType": "gp3",
  "State": "in-use",
  "Iops": 3000,
  "Encrypted": true,
  "AttachDevice": "/dev/xvda",
  "DeleteOnTermination": true
}
```

---

### 2.2 查询 EC2 实例的安全组规则

**用户查询**: "查看 EC2 i-0xxx 的安全组规则，是否有 22 端口对外开放？"

```bash
# Step 1: 获取实例关联的安全组
SG_IDS=$(aws ec2 describe-instances \
  --instance-ids i-0123456789abcdef0 \
  --profile devops-readonly \
  --region ap-southeast-1 \
  --query 'Reservations[].Instances[].SecurityGroups[].GroupId' \
  --output text)

echo "安全组: $SG_IDS"

# Step 2: 查询安全组规则
for sg_id in $SG_IDS; do
  echo "=== 安全组: $sg_id ==="
  aws ec2 describe-security-groups \
    --group-ids $sg_id \
    --profile devops-readonly \
    --region ap-southeast-1 \
    | jq '.SecurityGroups[] | {
        GroupName,
        GroupId,
        入站规则: [.IpPermissions[] | {
          Protocol: .IpProtocol,
          FromPort,
          ToPort,
          Sources: [.IpRanges[].CidrIp // .Ipv6Ranges[].CidrIpv6 // "N/A"]
        }]
      }'
done
```

---

### 2.3 查询 ALB 后端实例健康状态

**用户查询**: "查看 ALB my-alb 的后端目标组中所有实例的健康状态"

```bash
# Step 1: 获取 ALB ARN
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names my-alb \
  --profile devops-readonly \
  --region ap-southeast-1 \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

echo "ALB ARN: $ALB_ARN"

# Step 2: 获取目标组列表
TARGET_GROUP_ARNS=$(aws elbv2 describe-target-groups \
  --load-balancer-arn $ALB_ARN \
  --profile devops-readonly \
  --region ap-southeast-1 \
  --query 'TargetGroups[].TargetGroupArn' \
  --output text)

# Step 3: 查询每个目标组的健康状态
for tg_arn in $TARGET_GROUP_ARNS; do
  TG_NAME=$(aws elbv2 describe-target-groups \
    --target-group-arns $tg_arn \
    --profile devops-readonly \
    --region ap-southeast-1 \
    --query 'TargetGroups[0].TargetGroupName' \
    --output text)

  echo "=== 目标组: $TG_NAME ==="
  aws elbv2 describe-target-health \
    --target-group-arn $tg_arn \
    --profile devops-readonly \
    --region ap-southeast-1 \
    | jq '.TargetHealthDescriptions[] | {
        TargetId: .Target.Id,
        Port: .Target.Port,
        HealthState: .TargetHealth.State,
        Reason: (.TargetHealth.Reason // "N/A"),
        Description: (.TargetHealth.Description // "N/A")
      }'
done
```

---

### 2.4 查询 VPC 下的所有资源

**用户查询**: "VPC vpc-0abc123def456789a 下有哪些子网和 EC2 实例？"

```bash
VPC_ID="vpc-0abc123def456789a"
REGION="ap-southeast-1"

# Step 1: 查询 VPC 基本信息
echo "=== VPC 信息 ==="
aws ec2 describe-vpcs \
  --vpc-ids $VPC_ID \
  --profile devops-readonly \
  --region $REGION \
  | jq '.Vpcs[] | {VpcId, CidrBlock, State, Name: (.Tags // [] | map(select(.Key == "Name")) | first | .Value // "N/A")}'

# Step 2: 查询子网
echo "=== 子网列表 ==="
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --profile devops-readonly \
  --region $REGION \
  | jq '.Subnets[] | {
      SubnetId,
      CidrBlock,
      AvailabilityZone,
      AvailableIpAddressCount,
      Name: (.Tags // [] | map(select(.Key == "Name")) | first | .Value // "N/A"),
      Type: (if .MapPublicIpOnLaunch then "Public" else "Private" end)
    }'

# Step 3: 查询 EC2 实例
echo "=== EC2 实例列表 ==="
aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --profile devops-readonly \
  --region $REGION \
  | jq '.Reservations[].Instances[] | {
      InstanceId,
      Name: (.Tags // [] | map(select(.Key == "Name")) | first | .Value // "N/A"),
      InstanceType,
      State: .State.Name,
      PrivateIpAddress,
      SubnetId
    }'
```

---

### 2.5 查询 Lambda 函数的 IAM 角色权限

**用户查询**: "Lambda 函数 my-function 使用了什么 IAM 角色？角色有哪些权限策略？"

```bash
FUNC_NAME="my-function"

# Step 1: 获取函数配置和角色 ARN
ROLE_ARN=$(aws lambda get-function-configuration \
  --function-name $FUNC_NAME \
  --profile devops-readonly \
  --region ap-southeast-1 \
  --query 'Role' \
  --output text)

ROLE_NAME=$(echo $ROLE_ARN | awk -F'/' '{print $NF}')
echo "IAM 角色: $ROLE_NAME ($ROLE_ARN)"

# Step 2: 查询角色的附加策略
echo "=== 附加的托管策略 ==="
aws iam list-attached-role-policies \
  --role-name $ROLE_NAME \
  --profile devops-readonly \
  | jq '.AttachedPolicies[] | {PolicyName, PolicyArn}'

# Step 3: 查询角色的内联策略
echo "=== 内联策略列表 ==="
aws iam list-role-policies \
  --role-name $ROLE_NAME \
  --profile devops-readonly
```

---

### 2.6 查询 Route53 域名解析指向

**用户查询**: "域名 api.example.com 解析到哪个 ALB？"

```bash
# Step 1: 查找 Hosted Zone
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
  --profile devops-readonly \
  --query "HostedZones[?Name=='example.com.'].Id" \
  --output text | sed 's|/hostedzone/||')

echo "Hosted Zone ID: $HOSTED_ZONE_ID"

# Step 2: 查询 DNS 记录
aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --profile devops-readonly \
  | jq '.ResourceRecordSets[] | select(.Name | startswith("api.example.com")) | {
      Name,
      Type,
      AliasTarget: (.AliasTarget.DNSName // "N/A"),
      Records: (.ResourceRecords[].Value // "N/A")
    }'
```

---

## 三、复合查询示例 (COMPOUND_QUERY, L3-L4)

### 3.1 按实例类型统计 EC2

**用户查询**: "统计 ap-southeast-1 所有运行中的 EC2 实例，按实例类型分组并显示数量"

```bash
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --profile devops-readonly \
  --region ap-southeast-1 \
  | jq '
    [.Reservations[].Instances[].InstanceType] |
    group_by(.) |
    map({type: .[0], count: length}) |
    sort_by(.count) |
    reverse
  '
```

**输出结果**:
```json
[
  {"type": "t3.medium", "count": 15},
  {"type": "m5.large", "count": 8},
  {"type": "c5.xlarge", "count": 3}
]
```

---

### 3.2 跨多区域查询 EC2 实例

**用户查询**: "查询 ap-southeast-1 和 us-west-2 中所有 EC2 实例，汇总显示"

```bash
echo "[]" > aws_memos/tmp/all_instances.json

for region in ap-southeast-1 us-west-2; do
  echo "=== 查询区域: $region ==="
  aws ec2 describe-instances \
    --profile devops-readonly \
    --region $region \
    | jq --arg region "$region" '
      [.Reservations[].Instances[] | {
        Region: $region,
        InstanceId,
        Name: (.Tags // [] | map(select(.Key == "Name")) | first | .Value // "N/A"),
        InstanceType,
        State: .State.Name,
        PrivateIpAddress
      }]
    ' >> aws_memos/tmp/instances_$region.json
done

# 合并所有区域结果
jq -s 'add' aws_memos/tmp/instances_ap-southeast-1.json aws_memos/tmp/instances_us-west-2.json \
  > aws_memos/tmp/all_instances.json

echo "=== 汇总统计 ==="
jq '
  {
    总实例数: length,
    各区域实例数: (group_by(.Region) | map({区域: .[0].Region, 数量: length})),
    运行中: (map(select(.State == "running")) | length),
    已停止: (map(select(.State == "stopped")) | length)
  }
' aws_memos/tmp/all_instances.json
```

---

### 3.3 查询 VPC 下的所有资源（跨服务）

**用户查询**: "列出 VPC vpc-0xxx 下的 EC2、RDS 实例和 ELB，以及它们的内网地址"

```bash
VPC_ID="vpc-0abc123def456789a"
REGION="ap-southeast-1"

echo "=== EC2 实例 ==="
aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running" \
  --profile devops-readonly \
  --region $REGION \
  | jq '.Reservations[].Instances[] | {类型: "EC2", ID: .InstanceId, Name: (.Tags // [] | map(select(.Key == "Name")) | first | .Value // "N/A"), IP: .PrivateIpAddress}'

echo "=== RDS 实例 ==="
aws rds describe-db-instances \
  --profile devops-readonly \
  --region $REGION \
  | jq --arg vpc "$VPC_ID" '
    .DBInstances[] |
    select(.DBSubnetGroup.VpcId == $vpc) |
    {类型: "RDS", ID: .DBInstanceIdentifier, Endpoint: .Endpoint.Address, 状态: .DBInstanceStatus}
  '

echo "=== ALB/NLB ==="
aws elbv2 describe-load-balancers \
  --profile devops-readonly \
  --region $REGION \
  | jq --arg vpc "$VPC_ID" '
    .LoadBalancers[] |
    select(.VpcId == $vpc) |
    {类型: ("ELBv2/" + .Type), Name: .LoadBalancerName, DNS: .DNSName, 状态: .State.Code}
  '
```

---

### 3.4 查询本月 AWS 费用

**用户查询**: "查看本月各 AWS 服务的费用分布"

```bash
# 获取当月起始日期
START_DATE=$(date -u +"%Y-%m-01")
END_DATE=$(date -u +"%Y-%m-%d")

aws ce get-cost-and-usage \
  --time-period "Start=$START_DATE,End=$END_DATE" \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by "Type=DIMENSION,Key=SERVICE" \
  --profile devops-readonly \
  --region ap-southeast-1 \
  | jq '.ResultsByTime[].Groups | sort_by(.Metrics.BlendedCost.Amount | tonumber) | reverse | .[] | {
      服务: .Keys[0],
      费用: (.Metrics.BlendedCost.Amount + " " + .Metrics.BlendedCost.Unit)
    }'
```

---

## 四、诊断查询示例 (DIAGNOSTIC_QUERY, L3-L5)

### 4.1 安全组高危端口检查

**用户查询**: "检查所有安全组，是否有 22/3389 端口对 0.0.0.0/0 开放（高风险）？"

```bash
echo "=== 安全组高危端口检查 ==="
aws ec2 describe-security-groups \
  --profile devops-readonly \
  --region ap-southeast-1 \
  | jq '
    .SecurityGroups[] as $sg |
    $sg.IpPermissions[] as $rule |
    ($rule.IpRanges[] | select(.CidrIp == "0.0.0.0/0")) as $range |
    select(
      ($rule.IpProtocol == "tcp" and (
        ($rule.FromPort <= 22 and $rule.ToPort >= 22) or
        ($rule.FromPort <= 3389 and $rule.ToPort >= 3389) or
        ($rule.FromPort <= 3306 and $rule.ToPort >= 3306) or
        ($rule.FromPort <= 5432 and $rule.ToPort >= 5432)
      )) or
      $rule.IpProtocol == "-1"
    ) |
    {
      风险: "⚠️ 高危",
      安全组ID: $sg.GroupId,
      安全组名: $sg.GroupName,
      VPC: $sg.VpcId,
      协议: $rule.IpProtocol,
      端口范围: (($rule.FromPort | tostring) + "-" + ($rule.ToPort | tostring)),
      来源: $range.CidrIp,
      描述: ($range.Description // "无描述")
    }
  '
```

---

### 4.2 S3 Bucket 安全配置审计

**用户查询**: "审计所有 S3 Bucket 的安全配置：公开访问封锁、加密、版本控制"

```bash
echo "=== S3 Bucket 安全配置审计 ==="
buckets=$(aws s3api list-buckets --profile devops-readonly --query 'Buckets[].Name' --output text)

for bucket in $buckets; do
  echo ""
  echo "--- Bucket: $bucket ---"

  # 1. 公开访问封锁
  public_block=$(aws s3api get-public-access-block \
    --bucket $bucket \
    --profile devops-readonly 2>/dev/null \
    | jq '.PublicAccessBlockConfiguration | {
        BlockPublicAcls,
        IgnorePublicAcls,
        BlockPublicPolicy,
        RestrictPublicBuckets
      }' 2>/dev/null || echo '{"BlockPublicAcls": false}')

  block_all=$(echo $public_block | jq '.BlockPublicAcls and .IgnorePublicAcls and .BlockPublicPolicy and .RestrictPublicBuckets')
  if [ "$block_all" = "true" ]; then
    echo "  ✅ 公开访问: 已完全封锁"
  else
    echo "  ⚠️  公开访问: 未完全封锁 - $public_block"
  fi

  # 2. 服务端加密
  encryption=$(aws s3api get-bucket-encryption \
    --bucket $bucket \
    --profile devops-readonly 2>/dev/null \
    | jq '.ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' -r 2>/dev/null || echo "未启用")
  echo "  加密状态: $encryption"

  # 3. 版本控制
  versioning=$(aws s3api get-bucket-versioning \
    --bucket $bucket \
    --profile devops-readonly 2>/dev/null \
    | jq '.Status // "未启用"' -r)
  echo "  版本控制: $versioning"

  # 4. 日志记录
  logging=$(aws s3api get-bucket-logging \
    --bucket $bucket \
    --profile devops-readonly 2>/dev/null \
    | jq '.LoggingEnabled.TargetBucket // "未启用"' -r)
  echo "  访问日志: $logging"
done
```

---

### 4.3 IAM 用户 MFA 审计

**用户查询**: "审计所有 IAM 用户，列出没有启用 MFA 的用户及其最近登录时间"

```bash
echo "=== IAM 用户 MFA 审计 ==="

aws iam list-users --profile devops-readonly \
  | jq '.Users[].UserName' -r \
  | while read username; do
    # 检查 MFA 设备
    mfa_count=$(aws iam list-mfa-devices \
      --user-name $username \
      --profile devops-readonly \
      --query 'length(MFADevices)' \
      --output text)

    # 获取最近登录时间
    last_login=$(aws iam get-user \
      --user-name $username \
      --profile devops-readonly \
      --query 'User.PasswordLastUsed' \
      --output text 2>/dev/null || echo "从未登录")

    if [ "$mfa_count" -eq 0 ] 2>/dev/null; then
      echo "⚠️  用户: $username | MFA: 未启用 | 最近登录: $last_login"
    fi
  done
```

---

### 4.4 未使用资源检查（成本优化）

**用户查询**: "找出所有未挂载的 EBS 存储卷和未绑定的弹性 IP（可能造成费用浪费）"

```bash
REGION="ap-southeast-1"

echo "=== 未挂载的 EBS 存储卷 ==="
aws ec2 describe-volumes \
  --filters "Name=status,Values=available" \
  --profile devops-readonly \
  --region $REGION \
  | jq '.Volumes[] | {
      VolumeId,
      Size: (.Size | tostring) + " GiB",
      VolumeType,
      CreateTime,
      Name: (.Tags // [] | map(select(.Key == "Name")) | first | .Value // "N/A")
    }'

echo ""
echo "=== 未绑定的弹性 IP ==="
aws ec2 describe-addresses \
  --filters "Name=domain,Values=vpc" \
  --profile devops-readonly \
  --region $REGION \
  | jq '.Addresses[] | select(.InstanceId == null and .NetworkInterfaceId == null) | {
      AllocationId,
      PublicIp,
      Domain
    }'

echo ""
echo "=== 未关联实例的安全组（排除 default）==="
# 获取所有安全组
all_sgs=$(aws ec2 describe-security-groups \
  --profile devops-readonly \
  --region $REGION \
  --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
  --output text)

# 获取已使用的安全组
used_sgs=$(aws ec2 describe-instances \
  --profile devops-readonly \
  --region $REGION \
  --query 'Reservations[].Instances[].SecurityGroups[].GroupId' \
  --output text | tr '\t' '\n' | sort -u)

echo "提示：请手动对比以上两个列表，未在实例中使用的安全组可能可以清理。"
```

---

### 4.5 EC2 性能诊断

**用户查询**: "查看过去 1 小时 EC2 实例 i-0xxx 的 CPU、网络和磁盘使用情况"

```bash
INSTANCE_ID="i-0123456789abcdef0"
REGION="ap-southeast-1"
START_TIME=$(date -u -v-1H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%SZ")
END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "=== CPU 使用率（最近1小时，平均值/最大值）==="
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions "Name=InstanceId,Value=$INSTANCE_ID" \
  --start-time $START_TIME \
  --end-time $END_TIME \
  --period 300 \
  --statistics Average Maximum \
  --profile devops-readonly \
  --region $REGION \
  | jq '[.Datapoints | sort_by(.Timestamp) | .[] | {
      时间: .Timestamp,
      平均CPU: (.Average | round | tostring) + "%",
      最大CPU: (.Maximum | round | tostring) + "%"
    }]'

echo "=== 网络流量（最近1小时）==="
for metric in NetworkIn NetworkOut; do
  echo "--- $metric ---"
  aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name $metric \
    --dimensions "Name=InstanceId,Value=$INSTANCE_ID" \
    --start-time $START_TIME \
    --end-time $END_TIME \
    --period 300 \
    --statistics Sum \
    --profile devops-readonly \
    --region $REGION \
    | jq '[.Datapoints | sort_by(.Timestamp) | .[-3:] | .[] | {
        时间: .Timestamp,
        流量MB: ((.Sum / 1048576 * 100 | round) / 100 | tostring) + " MB"
      }]'
done
```

---

## 五、复杂场景综合示例 (L4-L5)

### 5.1 ECS 服务状态全面诊断

**用户查询**: "诊断 ECS 集群 my-cluster 中所有服务的健康状态"

```bash
CLUSTER="my-cluster"
REGION="ap-southeast-1"

echo "=== ECS 集群概览 ==="
aws ecs describe-clusters \
  --clusters $CLUSTER \
  --profile devops-readonly \
  --region $REGION \
  | jq '.clusters[] | {
      ClusterName,
      Status,
      RunningTasksCount,
      PendingTasksCount,
      ActiveServicesCount,
      RegisteredContainerInstancesCount
    }'

echo ""
echo "=== 各服务状态 ==="
service_arns=$(aws ecs list-services \
  --cluster $CLUSTER \
  --profile devops-readonly \
  --region $REGION \
  --query 'serviceArns' \
  --output text)

if [ -n "$service_arns" ]; then
  aws ecs describe-services \
    --cluster $CLUSTER \
    --services $service_arns \
    --profile devops-readonly \
    --region $REGION \
    | jq '.services[] | {
        ServiceName,
        Status,
        DesiredCount,
        RunningCount,
        PendingCount,
        健康状态: (if .runningCount == .desiredCount then "✅ 正常" else "⚠️ 异常" end),
        LoadBalancers: [.loadBalancers[] | {ContainerName, ContainerPort, TargetGroupArn}],
        DeploymentStatus: .deployments[0].status
      }'
fi
```

---

### 5.2 全账号安全合规检查报告

**用户查询**: "生成一个账号安全合规检查报告"

```bash
REGION="ap-southeast-1"
DATE=$(date +%Y%m%d)

echo "============================================="
echo " AWS 账号安全合规检查报告"
echo " 账号: $(aws sts get-caller-identity --profile devops-readonly --query Account --output text)"
echo " 时间: $(date)"
echo "============================================="

echo ""
echo "## 1. IAM 安全检查"

# 检查根账号 MFA
echo "### 1.1 根账号 MFA"
root_mfa=$(aws iam get-account-summary \
  --profile devops-readonly \
  --query 'SummaryMap.AccountMFAEnabled' \
  --output text)
[ "$root_mfa" = "1" ] && echo "  ✅ 根账号已启用 MFA" || echo "  ❌ 根账号未启用 MFA（高危！）"

# 检查未启用 MFA 的 IAM 用户数量
echo "### 1.2 IAM 用户 MFA 状态"
total_users=$(aws iam list-users --profile devops-readonly --query 'length(Users)' --output text)
echo "  总用户数: $total_users"

echo ""
echo "## 2. S3 安全检查"
bucket_count=$(aws s3api list-buckets --profile devops-readonly --query 'length(Buckets)' --output text)
echo "  总 Bucket 数: $bucket_count"

echo ""
echo "## 3. EC2 安全检查"
echo "### 3.1 公开开放 22/3389 端口的安全组"
risky_sg_count=$(aws ec2 describe-security-groups \
  --profile devops-readonly \
  --region $REGION \
  | jq '
    [.SecurityGroups[] |
    select(
      .IpPermissions[] |
      (.IpRanges[] | .CidrIp == "0.0.0.0/0") and
      (.IpProtocol == "tcp" and (
        (.FromPort <= 22 and .ToPort >= 22) or
        (.FromPort <= 3389 and .ToPort >= 3389)
      ) or .IpProtocol == "-1")
    )] | length
  ')
echo "  高危安全组数量: $risky_sg_count"

echo ""
echo "## 4. CloudTrail 检查"
trail_count=$(aws cloudtrail describe-trails \
  --profile devops-readonly \
  --region $REGION \
  --query 'length(trailList)' \
  --output text)
echo "  活跃 Trail 数量 ($REGION): $trail_count"

echo ""
echo "============================================="
echo " 报告生成完毕"
echo "============================================="
```

---

## 六、常用 jq 处理模式

### 6.1 提取 EC2 Name 标签

```bash
# EC2 实例的 Name 标签提取（处理标签可能为空的情况）
.Tags // [] | map(select(.Key == "Name")) | first | .Value // "N/A"
```

### 6.2 处理 AWS CLI 分页

```bash
# 使用 --no-paginate 获取所有结果
aws ec2 describe-instances --no-paginate --profile devops-readonly --region ap-southeast-1

# 或者使用 --max-items 和 --starting-token 手动分页
aws ec2 describe-instances --max-items 100 --profile devops-readonly --region ap-southeast-1
```

### 6.3 过滤 EC2 Tags

```bash
# --query 过滤方式（JMESPath）
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=production" \
  --profile devops-readonly \
  --region ap-southeast-1 \
  --query 'Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key==`Name`]|[0].Value}'
```

### 6.4 多条件过滤

```bash
# 多个 --filters 条件（AND 关系）
aws ec2 describe-instances \
  --filters \
    "Name=instance-state-name,Values=running" \
    "Name=instance-type,Values=t3.medium,t3.large" \
    "Name=tag:Environment,Values=production" \
  --profile devops-readonly \
  --region ap-southeast-1
```

### 6.5 计算时间差（检查资源年龄）

```bash
# 查找超过 30 天未使用的快照
aws ec2 describe-snapshots \
  --owner-ids self \
  --profile devops-readonly \
  --region ap-southeast-1 \
  | jq --arg cutoff "$(date -u -v-30d +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -d "30 days ago" +"%Y-%m-%dT%H:%M:%S")Z" '
    .Snapshots[] |
    select(.StartTime < $cutoff) |
    {SnapshotId, StartTime, Description, VolumeSize}
  '
```
