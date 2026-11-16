# my-dotfiles
My dotfiles

## AI (skills + agent instructions)

`ai/` holds [Agent Skills](https://agentskills.io) (`SKILL.md` folders) and an
`AGENTS.md` with always-on conventions, linked into Claude Code, Codex and other
tools.

```bash
installs/install_ai.sh --dry-run   # preview
installs/install_ai.sh             # validate, then symlink
ai/install.sh --uninstall          # remove only the links it created
```

- `ai/targets.conf` lists skill **sources** and the tool folders to link into.
  Work-only skills come from a separate private repo (`~/Workspace/skills`),
  which is skipped on machines where it isn't cloned.
- Links are symlinks, so `git pull` updates every tool at once.
- New skill: `cp -R ai/skills/_template ai/skills/<name>`, set `name:` in
  its frontmatter, run `installs/install_ai.sh`.
- claude.ai / Cowork can't read your disk: `ai/scripts/package.sh` builds
  `ai/dist/<name>.skill` to upload.
- Keep anything company-specific, secret or PII-bearing **out of this repo**.
