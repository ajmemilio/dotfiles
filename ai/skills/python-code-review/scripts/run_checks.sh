#!/usr/bin/env bash
# Run the project's own Python checks on changed files. Never installs anything.
# Usage: run_checks.sh [base_ref]   (run from repo root)
set -u

BASE="${1:-}"
if [ -z "$BASE" ]; then
  for b in origin/main main origin/master master; do
    if git rev-parse --verify -q "$b" >/dev/null; then BASE="$b"; break; fi
  done
fi

MB=""
[ -n "$BASE" ] && MB="$(git merge-base HEAD "$BASE" 2>/dev/null || true)"

# Changed .py files: branch commits + staged + unstaged + untracked
{
  [ -n "$MB" ] && git diff --name-only --diff-filter=ACMR "$MB" HEAD
  git diff --name-only --diff-filter=ACMR
  git diff --name-only --diff-filter=ACMR --cached
  git ls-files --others --exclude-standard
} 2>/dev/null | grep -E '\.py$' | sort -u > /tmp/_pcr_changed.txt

CHANGED_FILES=()
while IFS= read -r f; do [ -f "$f" ] && CHANGED_FILES+=("$f"); done < /tmp/_pcr_changed.txt

echo "== base: ${BASE:-<none>} merge-base: ${MB:-<none>}"
echo "== changed python files:"
if [ "${#CHANGED_FILES[@]}" -gt 0 ]; then printf '%s\n' "${CHANGED_FILES[@]}"; else echo "<none>"; fi
echo

# macOS has no `timeout` by default; fall back to gtimeout (coreutils) or no timeout
if ! command -v timeout >/dev/null 2>&1; then
  if command -v gtimeout >/dev/null 2>&1; then timeout() { gtimeout "$@"; }
  else timeout() { shift; "$@"; }; fi
fi

has_cfg() { grep -qs "$1" pyproject.toml setup.cfg tox.ini 2>/dev/null; }
have() { command -v "$1" >/dev/null 2>&1 || python -m "$1" --version >/dev/null 2>&1; }
run() { if command -v "$1" >/dev/null 2>&1; then "$@"; else python -m "$@"; fi; }

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ruff — use the repo's own config if it has one, else fall back to this skill's house config
RUFF_ARGS=()
if [ -f ruff.toml ] || [ -f .ruff.toml ] || has_cfg '\[tool.ruff'; then
  :
else
  RUFF_ARGS=(--config "$SKILL_ROOT/references/ruff.toml")
fi
if have ruff; then
  echo "== ruff (changed files)${RUFF_ARGS:+, using the skill default config}"
  if [ "${#CHANGED_FILES[@]}" -gt 0 ]; then run ruff check --output-format=concise "${RUFF_ARGS[@]}" "${CHANGED_FILES[@]}" 2>&1 | tail -n 60; else echo "no changed files"; fi
else echo "== ruff: not installed"; fi
echo

# ty
if [ -f ty.toml ] || has_cfg '\[tool.ty\]'; then
  if have ty; then
    echo "== ty (changed files)"
    if [ "${#CHANGED_FILES[@]}" -gt 0 ]; then timeout 180 bash -c "$(declare -f run); run ty check \"\$@\"" run_ty "${CHANGED_FILES[@]}" 2>&1 | tail -n 60; else echo "no changed files"; fi
  else echo "== ty: configured but not installed"; fi
else echo "== ty: not configured"; fi
echo

# pytest
if [ -d tests ] || [ -d test ] || has_cfg '\[tool.pytest' || [ -f pytest.ini ]; then
  if have pytest; then
    echo "== pytest (-x -q, 300s timeout)"
    timeout 300 bash -c "$(declare -f run); run pytest -x -q --no-header -p no:cacheprovider" 2>&1 | tail -n 40
    rc=${PIPESTATUS[0]}
    [ "$rc" = "124" ] && echo "pytest: TIMEOUT (likely needs infra or is slow)"
  else echo "== pytest: tests exist but pytest not installed"; fi
else echo "== pytest: no tests found"; fi
