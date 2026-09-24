#!/usr/bin/env bash
# Fetch content from the content repo at build time.
# Used by Cloudflare Pages and local builds.
set -euo pipefail

CONTENT_REPO="${CONTENT_REPO:-https://github.com/EricDong/tiwenzhe-content.git}"
CONTENT_BRANCH="${CONTENT_BRANCH:-main}"
CONTENT_PUBLISH_DIR="${CONTENT_PUBLISH_DIR:-publish}"
CONTENT_DIR="content"
TMP_DIR="$(mktemp -d)"
SOURCE_DIR="$TMP_DIR/source"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "→ Syncing content from $CONTENT_REPO ($CONTENT_BRANCH)"

rm -rf "$CONTENT_DIR"
# Private content repo: set CONTENT_REPO_TOKEN (fine-grained PAT, Contents: read-only
# on tiwenzhe-content) in Cloudflare Pages env. Unset = anonymous clone (public repo).
CLONE_URL="$CONTENT_REPO"
if [ -n "${CONTENT_REPO_TOKEN:-}" ]; then
  CLONE_URL="${CONTENT_REPO/https:\/\//https://x-access-token:${CONTENT_REPO_TOKEN}@}"
fi
git clone --quiet --depth=1 --branch "$CONTENT_BRANCH" "$CLONE_URL" "$SOURCE_DIR"

if [ ! -d "$SOURCE_DIR/$CONTENT_PUBLISH_DIR" ]; then
  echo "Expected publish directory not found: $CONTENT_PUBLISH_DIR" >&2
  exit 1
fi

mkdir -p "$CONTENT_DIR"
cp -R "$SOURCE_DIR/$CONTENT_PUBLISH_DIR/." "$CONTENT_DIR/"

# Strip any git metadata so Quartz' git-date plugin uses the site repo.
rm -rf "$CONTENT_DIR/.git"

echo "→ Content synced:"
find "$CONTENT_DIR" -maxdepth 2 -name '*.md' | head -20
