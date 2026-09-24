#!/usr/bin/env bash
# Put the GitHub PAT currently on the clipboard into Cloudflare Pages as the
# encrypted build var CONTENT_REPO_TOKEN (production + preview), then clear the
# clipboard. The token is never printed.
# Usage: copy the PAT, then run: bash scripts/set-content-token.sh
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT="${PAGES_PROJECT:-poiseacademy-site}"
TOKEN="$(pbpaste | tr -d '[:space:]')"
case "$TOKEN" in
  github_pat_*|ghp_*) ;;
  *) echo "✗ 剪贴板里不是 GitHub PAT（应以 github_pat_ 开头），未做任何改动" >&2; exit 1 ;;
esac

# Sanity check: token can read the content repo
code=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TOKEN" \
  https://api.github.com/repos/EricDong/tiwenzhe-content/contents/publish)
[ "$code" = 200 ] || { echo "✗ 该 token 读不到 tiwenzhe-content（HTTP $code），检查仓库授权" >&2; exit 1; }

CF="$(npx wrangler auth token 2>/dev/null | tail -1)"
ACCT=$(curl -s -H "Authorization: Bearer $CF" https://api.cloudflare.com/client/v4/accounts \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"][0]["id"])')

body=$(TOKEN="$TOKEN" python3 -c 'import os,json
v={"CONTENT_REPO_TOKEN":{"type":"secret_text","value":os.environ["TOKEN"]}}
print(json.dumps({"deployment_configs":{"production":{"env_vars":v},"preview":{"env_vars":v}}}))')
ok=$(curl -s -X PATCH -H "Authorization: Bearer $CF" -H 'Content-Type: application/json' \
  --data-binary @- "https://api.cloudflare.com/client/v4/accounts/$ACCT/pages/projects/$PROJECT" <<<"$body" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["success"])')

printf '' | pbcopy
# Verify existing vars (NODE_VERSION, CONTENT_REPO) survived the PATCH
curl -s -H "Authorization: Bearer $CF" "https://api.cloudflare.com/client/v4/accounts/$ACCT/pages/projects/$PROJECT" \
  | python3 -c 'import sys,json
for e,c in json.load(sys.stdin)["result"]["deployment_configs"].items(): print(" ", e, sorted((c.get("env_vars") or {}).keys()))'
[ "$ok" = True ] && echo "✓ CONTENT_REPO_TOKEN 已写入 ${PROJECT}（production+preview），剪贴板已清空" \
  || { echo "✗ Cloudflare 写入失败" >&2; exit 1; }
