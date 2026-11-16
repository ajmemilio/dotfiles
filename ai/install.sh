#!/usr/bin/env bash
# Symlink skills and AGENTS.md into each AI tool's config folder (see targets.conf).
# Usage: ai/install.sh [--dry-run] [--uninstall]
set -eu
AI="$(cd "$(dirname "$0")" && pwd)"
CONF="$AI/targets.conf"
DRY=0; UNINSTALL=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --uninstall) UNINSTALL=1 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

do_() { if [ "$DRY" = 1 ]; then echo "    [dry-run] $*"; else "$@"; fi; }
expand() { local p="${1/#\~/$HOME}"; echo "${p/#@/$AI}"; }

# 1. collect skills from sources (first source wins on name clash)
NAMES=(); SRCS=()
while read -r kind a _; do
  [ "${kind:-}" = "source" ] || continue
  dir="$(expand "$a")"
  if [ ! -d "$dir" ]; then echo "-- source $a: not found, skipping"; continue; fi
  for md in "$dir"/*/SKILL.md; do
    [ -e "$md" ] || continue
    src="$(cd "$(dirname "$md")" && pwd)"; name="$(basename "$src")"
    case "$name" in _*) continue ;; esac
    dup=0
    for n in "${NAMES[@]+"${NAMES[@]}"}"; do [ "$n" = "$name" ] && dup=1; done
    if [ "$dup" = 1 ]; then echo "-- WARNING: '$name' in $a shadowed by an earlier source"; continue; fi
    NAMES+=("$name"); SRCS+=("$src")
  done
done < <(sed 's/#.*//' "$CONF")

# 2. link into each tool
while read -r kind tool path _; do
  case "${kind:-}" in
    skills)
      dir="$(expand "$path")"; echo "== skills → $tool ($dir)"
      [ "$UNINSTALL" = 0 ] && do_ mkdir -p "$dir"
      for i in "${!NAMES[@]}"; do
        name="${NAMES[$i]}"; src="${SRCS[$i]}"; dst="$dir/$name"
        if [ "$UNINSTALL" = 1 ]; then
          [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ] && do_ rm "$dst" && echo "   removed $name"; continue
        fi
        if [ -e "$dst" ] && [ ! -L "$dst" ]; then echo "   SKIP $name: real folder exists at $dst"; continue; fi
        do_ ln -sfn "$src" "$dst"; echo "   linked $name"
      done ;;
    instructions)
      dst="$(expand "$path")"; echo "== instructions → $tool ($dst)"
      if [ "$UNINSTALL" = 1 ]; then
        [ -L "$dst" ] && [ "$(readlink "$dst")" = "$AI/AGENTS.md" ] && do_ rm "$dst" && echo "   removed"; continue
      fi
      if [ -e "$dst" ] && [ ! -L "$dst" ]; then echo "   SKIP: $dst already exists (merge ai/AGENTS.md into it by hand)"; continue; fi
      do_ mkdir -p "$(dirname "$dst")"; do_ ln -sfn "$AI/AGENTS.md" "$dst"; echo "   linked AGENTS.md" ;;
  esac
done < <(sed 's/#.*//' "$CONF")
