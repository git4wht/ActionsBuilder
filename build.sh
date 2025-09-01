#!/bin/bash
# --------------------------
# 配置
OWNER="your-org"
REPO="multi-platform-build"
WORKFLOW_FILE="multi-platform-build.yml"
REF="main"
BUILD_REF="main"
ARTIFACT_DIR="./downloads"
GITHUB_TOKEN="YOUR_PAT"  # 或使用环境变量 $GITHUB_TOKEN

mkdir -p $ARTIFACT_DIR

# --------------------------
# 触发 workflow
echo "Triggering workflow..."
gh workflow run $WORKFLOW_FILE \
  --ref $REF \
  -f build_ref=$BUILD_REF \
  -f build_msi=true

# --------------------------
# 等待 workflow 运行完成
echo "Waiting for workflow completion..."
sleep 10  # 等待 GitHub 记录 workflow run
RUN_ID=$(gh run list -R $OWNER/$REPO -w $WORKFLOW_FILE --limit 1 --json databaseId --jq '.[0].databaseId')
echo "Triggered run ID: $RUN_ID"

# 可轮询状态直到完成
STATUS=""
while [[ "$STATUS" != "completed" ]]; do
  STATUS=$(gh run view $RUN_ID -R $OWNER/$REPO --json status -q '.status')
  echo "Current status: $STATUS"
  sleep 15
done

# 检查成功或失败
CONCLUSION=$(gh run view $RUN_ID -R $OWNER/$REPO --json conclusion -q '.conclusion')
echo "Workflow conclusion: $CONCLUSION"
if [[ "$CONCLUSION" != "success" ]]; then
  echo "Build failed."
  exit 1
fi

# --------------------------
# 下载 artifact
echo "Downloading artifacts..."
ARTIFACTS=$(gh run download $RUN_ID -R $OWNER/$REPO -D $ARTIFACT_DIR)
echo "Artifacts downloaded to $ARTIFACT_DIR"

# --------------------------
# 可选：上传到本地服务器或 FTP
# curl 或 lftp/scp 上传到服务器
# 示例：
# lftp -u $FTP_USER,$FTP_PASS $FTP_HOST <<EOF
# mirror -R $ARTIFACT_DIR /remote/path
# EOF

echo "Done!"
