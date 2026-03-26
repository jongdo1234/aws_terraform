#!/bin/bash
echo "============================================"
echo "  2026 클라우드컴퓨팅 제2과제 채점 스크립트"
echo "============================================"
echo ""
PASS=0
FAIL=0
check() {
if [ "$1" = "PASS" ]; then
PASS=$((PASS+1))
echo "  ✅ PASS - $2"
else
FAIL=$((FAIL+1))
echo "  ❌ FAIL - $2"
fi
}
echo "[문제 1] EFS - Shared network storage"
echo "------------------------------------------"
EFS_COUNT=$(aws efs describe-file-systems --query 'length(FileSystems)' --output text 2>/dev/null)
[ "$EFS_COUNT" -gt 0 ] 2>/dev/null && check "PASS" "EFS 파일시스템 존재" || check "FAIL" "EFS 파일시스템 존재"
EFS_ID=$(aws efs describe-file-systems --query 'FileSystems[0].FileSystemId' --output text 2>/dev/null)
MT_COUNT=$(aws efs describe-mount-targets --file-system-id $EFS_ID --query 'length(MountTargets)' --output text 2>/dev/null)
[ "$MT_COUNT" -ge 1 ] 2>/dev/null && check "PASS" "Mount Target 존재 - ${MT_COUNT}개" || check "FAIL" "Mount Target 존재"
EC2_COUNT=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'length(Reservations[].Instances[])' --output text 2>/dev/null)
[ "$EC2_COUNT" -ge 2 ] 2>/dev/null && check "PASS" "EC2 인스턴스 2대 running - ${EC2_COUNT}대" || check "FAIL" "EC2 인스턴스 2대 running - ${EC2_COUNT}대"
INST1=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=worldpay-ec2-a" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null)
if [ "$INST1" != "None" ] && [ -n "$INST1" ]; then
CMD1=$(aws ssm send-command --instance-ids $INST1 --document-name "AWS-RunShellScript" \
  --parameters 'commands=["df -h /mnt/efs | grep -E efs"]' \
  --query 'Command.CommandId' --output text 2>/dev/null)
sleep 5
MOUNT1=$(aws ssm get-command-invocation --command-id $CMD1 --instance-id $INST1 \
  --query 'StandardOutputContent' --output text 2>/dev/null)
[ -n "$MOUNT1" ] && check "PASS" "EC2 #1 EFS 마운트 확인" || check "FAIL" "EC2 #1 EFS 마운트 확인"
else
check "FAIL" "EC2 #1 worldpay-ec2-a 없음"
fi
INST2=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=worldpay-ec2-b" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null)
if [ "$INST2" != "None" ] && [ -n "$INST2" ]; then
CMD2=$(aws ssm send-command --instance-ids $INST2 --document-name "AWS-RunShellScript" \
  --parameters 'commands=["cat /mnt/efs/test.txt"]' \
  --query 'Command.CommandId' --output text 2>/dev/null)
sleep 5
SHARE=$(aws ssm get-command-invocation --command-id $CMD2 --instance-id $INST2 \
  --query 'StandardOutputContent' --output text 2>/dev/null)
echo "$SHARE" | grep -q "Hello from EC2-A" && check "PASS" "EC2 #2 공유 파일 읽기" || check "FAIL" "EC2 #2 공유 파일 읽기"
else
check "FAIL" "EC2 #2 worldpay-ec2-b 없음"
fi
echo ""
echo "[문제 2] S3 + Athena - Query from S3"
echo "------------------------------------------"
STUDENT_ID="12345"
BUCKET="worldpay-data-${STUDENT_ID}"
aws s3 ls s3://$BUCKET/ >/dev/null 2>&1 && check "PASS" "S3 버킷 존재" || check "FAIL" "S3 버킷 존재"
aws s3 ls s3://$BUCKET/users/users.csv >/dev/null 2>&1 && check "PASS" "CSV 파일 존재" || check "FAIL" "CSV 파일 존재"
aws athena get-work-group --work-group worldpay-workgroup >/dev/null 2>&1 && check "PASS" "Athena WorkGroup 존재" || check "FAIL" "Athena WorkGroup 존재"
QUERY_ID=$(aws athena start-query-execution \
  --query-string "SELECT count(*) as cnt FROM worldpay_db.users;" \
  --work-group worldpay-workgroup \
  --query 'QueryExecutionId' --output text 2>/dev/null)
sleep 5
if [ -n "$QUERY_ID" ]; then
RESULT=$(aws athena get-query-results --query-execution-id $QUERY_ID \
  --query 'ResultSet.Rows[1].Data[0].VarCharValue' --output text 2>/dev/null)
[ "$RESULT" = "3" ] && check "PASS" "Athena 쿼리 결과 3건 확인" || check "FAIL" "Athena 쿼리 결과 ${RESULT}건"
else
check "FAIL" "Athena 쿼리 실행 실패"
fi
echo ""
echo "[문제 3] IAM Policy - Fine-grained"
echo "------------------------------------------"
aws iam get-role --role-name worldpay-app-role >/dev/null 2>&1 && check "PASS" "IAM Role worldpay-app-role 존재" || check "FAIL" "IAM Role worldpay-app-role 존재"
ATTACHED=$(aws iam list-attached-role-policies --role-name worldpay-app-role \
  --query 'length(AttachedPolicies)' --output text 2>/dev/null)
[ "$ATTACHED" -ge 1 ] 2>/dev/null && check "PASS" "정책 연결됨" || check "FAIL" "정책 연결됨"
POLICY_ARN=$(aws iam list-attached-role-policies --role-name worldpay-app-role \
  --query 'AttachedPolicies[0].PolicyArn' --output text 2>/dev/null)
POLICY_VER=$(aws iam get-policy --policy-arn $POLICY_ARN \
  --query 'Policy.DefaultVersionId' --output text 2>/dev/null)
POLICY_DOC=$(aws iam get-policy-version --policy-arn $POLICY_ARN --version-id $POLICY_VER \
  --query 'PolicyVersion.Document' --output json 2>/dev/null)
echo "$POLICY_DOC" | grep -q "s3:GetObject" && check "PASS" "s3:GetObject 허용 포함" || check "FAIL" "s3:GetObject 허용 미포함"
echo "$POLICY_DOC" | grep -q "Deny" && check "PASS" "명시적 Deny 규칙 존재" || check "FAIL" "명시적 Deny 규칙 없음"
echo "$POLICY_DOC" | grep -q "arn:aws:s3" && check "PASS" "Resource 특정 버킷 지정" || check "FAIL" "Resource가 * - Fine-grained 아님"
echo ""
echo "[문제 4] RDS + Lambda - MySQL with Lambda"
echo "------------------------------------------"
RDS_STATUS=$(aws rds describe-db-instances --db-instance-identifier worldpay-mysql \
  --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null)
[ "$RDS_STATUS" = "available" ] && check "PASS" "RDS MySQL available" || check "FAIL" "RDS MySQL - $RDS_STATUS"
RDS_ENGINE=$(aws rds describe-db-instances --db-instance-identifier worldpay-mysql \
  --query 'DBInstances[0].Engine' --output text 2>/dev/null)
[ "$RDS_ENGINE" = "mysql" ] && check "PASS" "RDS 엔진 = mysql" || check "FAIL" "RDS 엔진 = $RDS_ENGINE"
aws lambda get-function --function-name worldpay-mysql-lambda >/dev/null 2>&1 && check "PASS" "Lambda 함수 존재" || check "FAIL" "Lambda 함수 존재"
LAMBDA_VPC=$(aws lambda get-function-configuration --function-name worldpay-mysql-lambda \
  --query 'VpcConfig.VpcId' --output text 2>/dev/null)
[ -n "$LAMBDA_VPC" ] && [ "$LAMBDA_VPC" != "None" ] && check "PASS" "Lambda VPC 설정됨" || check "FAIL" "Lambda VPC 미설정"
RDS_EP=$(aws rds describe-db-instances --db-instance-identifier worldpay-mysql \
  --query 'DBInstances[0].Endpoint.Address' --output text 2>/dev/null)
aws lambda invoke \
  --function-name worldpay-mysql-lambda \
  --payload '{"action":"list"}' \
  --cli-binary-format raw-in-base64-out \
  /tmp/grade_output.json >/dev/null 2>&1
LAMBDA_RESULT=$(cat /tmp/grade_output.json 2>/dev/null)
echo "$LAMBDA_RESULT" | grep -q "200" && check "PASS" "Lambda -> RDS 연결 성공" || check "FAIL" "Lambda -> RDS 연결 실패"
echo ""
echo "============================================"
echo "  채점 결과"
echo "============================================"
TOTAL=$((PASS+FAIL))
echo "  총 $TOTAL 항목"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
SCORE=$((PASS * 100 / TOTAL))
echo "  점수: $SCORE / 100"
echo ""
if [ $FAIL -eq 0 ]; then
echo "  완벽! 전체 통과!"
elif [ $SCORE -ge 80 ]; then
echo "  거의 완성! FAIL 항목만 수정하세요."
elif [ $SCORE -ge 50 ]; then
echo "  절반 이상 통과. FAIL 항목 확인 필요."
else
echo "  다시 점검 필요."
fi
echo "============================================"
