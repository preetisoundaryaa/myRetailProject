#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   export DOCKERHUB_USERNAME="your-username"
#   export DOCKERHUB_TOKEN="your-dockerhub-token"
#   export GITHUB_TOKEN="ghp_xxx"   # token with repo scope
#   export GITHUB_OWNER="your-github-username-or-org"
#   export GITHUB_REPO="myRetailProject"
#   ./scripts_automation_update_docker_v1.sh

IMAGE_NAME="preetisoundaryaa/myretail-app"
IMAGE_TAG="v1"
BRANCH_NAME="update-docker-v1"
PR_TITLE="Update Docker image tag to v1"
PR_BODY="This PR updates the Docker image tag in values.yaml from 'latest' to 'v1' and pushes the corresponding image to Docker Hub."
VALUES_FILE="helm/retail-app/values.yaml"

required_vars=(DOCKERHUB_USERNAME DOCKERHUB_TOKEN GITHUB_TOKEN GITHUB_OWNER GITHUB_REPO)
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: Environment variable $var is required." >&2
    exit 1
  fi
done

echo "[1/8] Docker login"
echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin

echo "[2/8] Build Docker image"
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "[3/8] Push Docker image"
docker push "${IMAGE_NAME}:${IMAGE_TAG}"

echo "[4/8] Update Helm values tag latest -> v1"
if grep -qE '^\s*tag:\s*latest\s*$' "$VALUES_FILE"; then
  sed -i -E 's/^([[:space:]]*tag:[[:space:]]*)latest([[:space:]]*)$/\1v1\2/' "$VALUES_FILE"
else
  echo "WARNING: expected tag: latest not found in $VALUES_FILE" >&2
fi

echo "[5/8] Create/update branch and commit"
git fetch origin
if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
  git checkout "$BRANCH_NAME"
else
  git checkout -b "$BRANCH_NAME"
fi

git add "$VALUES_FILE"
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "Update Docker image tag to v1"
fi

echo "[6/8] Push branch"
git push -u origin "$BRANCH_NAME"

echo "[7/8] Create PR using GitHub API"
PR_RESPONSE=$(curl -sS -X POST \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/pulls" \
  -d "{\"title\":\"${PR_TITLE}\",\"head\":\"${BRANCH_NAME}\",\"base\":\"main\",\"body\":\"${PR_BODY}\"}")

PR_URL=$(echo "$PR_RESPONSE" | python -c 'import sys,json; print(json.load(sys.stdin).get("html_url",""))')
if [[ -z "$PR_URL" ]]; then
  echo "ERROR: Failed to create PR. Response:" >&2
  echo "$PR_RESPONSE" >&2
  exit 1
fi

echo "[8/8] Done"
echo "Commands executed:"
echo "  docker login -u \"\$DOCKERHUB_USERNAME\" --password-stdin"
echo "  docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
echo "  docker push ${IMAGE_NAME}:${IMAGE_TAG}"
echo "  sed -i -E 's/^([[:space:]]*tag:[[:space:]]*)latest([[:space:]]*)$/\\1v1\\2/' ${VALUES_FILE}"
echo "  git checkout -b ${BRANCH_NAME}"
echo "  git add ${VALUES_FILE}"
echo "  git commit -m \"Update Docker image tag to v1\""
echo "  git push -u origin ${BRANCH_NAME}"
echo "  curl -X POST https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/pulls ..."
echo "PR URL: ${PR_URL}"
