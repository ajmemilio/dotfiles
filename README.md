# dotfiles

Personal machine setup: shell/editor/terminal configs plus a set of
`installs/*.sh` scripts that install and wire each piece up on a fresh
machine. Everything is split so you can pull in only what you need.

## Layout

- `.vimrc`, `.vimrc.*`, `.config/nvim/` — Vim/Neovim config and plugins
- `.tmux.conf`, `.tmux.conf.osx`, `.tmux.powerline.conf` — tmux config
- `installs/` — one script per tool; run the ones you want on a new machine:
  - `install_vim.sh` — Vim/Neovim + plugin manager
  - `install_tmux.sh` — tmux config
  - `install_git.sh` — git + aliases
  - `install_sys_apps.sh` — CLI tools (htop, ranger, fzf, ripgrep)
  - `install_ai.sh` — AI agent skills/instructions, see below
- `ai/` — portable AI agent skills and always-on instructions, symlinked into
  Claude Code, Codex, and other tools. See [ai/README.md](ai/README.md) for
  how it's structured and configured.
- `.github/workflows/` — CI that validates `ai/` on every change touching it.

## Usage

```bash
installs/install_<tool>.sh
```

Each script is independent and safe to run on its own; most just copy or
symlink config files and install the matching package(s).
