#!/usr/bin/env bash
# Zip each skill into ai/dist/<name>.skill for upload to claude.ai / Cowork.
set -eu
AI="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$AI/dist"
cd "$AI/skills"
for d in */; do
  name="${d%/}"
  case "$name" in _*) continue ;; esac
  rm -f "$AI/dist/$name.skill"
  zip -qr "$AI/dist/$name.skill" "$name" -x "$name/evals/*" "*/__pycache__/*" "*.DS_Store"
  echo "packaged ai/dist/$name.skill"
done
