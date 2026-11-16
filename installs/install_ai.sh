#!/bin/bash
# AI tooling: link skills and always-on instructions into Claude Code, Codex, etc.
# Run from the repo root, like the other installs/ scripts. Re-run after adding a skill.
set -e
python3 ai/scripts/validate.py
ai/install.sh "$@"
