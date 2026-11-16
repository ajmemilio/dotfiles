# ai/

Portable AI tooling for this machine: [Agent Skills](https://agentskills.io)
(`SKILL.md` folders) and always-on agent instructions (`AGENTS.md`), linked
into Claude Code, Codex, and any other tool that understands the same
conventions.

Nothing in here is tool-specific. `ai/install.sh` is what wires it into each
tool's own config folder via symlinks, so a single `git pull` updates every
tool at once.

## Layout

```
ai/
├── AGENTS.md           always-on instructions, linked into each tool's global config
├── targets.conf        config for install.sh: skill sources + link targets
├── install.sh          symlinks skills/AGENTS.md into each tool's folders
├── skills/
│   ├── _template/      copy this to start a new skill
│   └── <name>/
│       ├── SKILL.md    required: frontmatter (name, description) + instructions
│       ├── scripts/    optional: deterministic helpers the skill shells out to
│       └── references/ optional: longer checklists/docs the skill points to
├── scripts/
│   ├── validate.py     checks every skill's SKILL.md frontmatter is valid
│   └── package.sh      zips each skill into ai/dist/<name>.skill (for claude.ai upload)
└── dist/                build output of package.sh, not committed
```

## How install.sh works

1. **Collect.** For each `source` line in `targets.conf`, scan `<dir>/*/SKILL.md`
   and register that folder under its name. Sources are read top to bottom;
   folders starting with `_` (like `_template`) are skipped; on a name clash
   the **first** source wins and later ones are skipped with a warning.
2. **Link.** For each `skills <tool> <dir>` line, symlink every collected skill
   into `<dir>/<name>`. For each `instructions <tool> <file>` line, symlink
   `AGENTS.md` to `<file>` — but only if nothing real is there yet, so it never
   clobbers a file you wrote by hand.

Run it via `installs/install_ai.sh` (which also runs `scripts/validate.py`
first), or directly:

```bash
ai/install.sh --dry-run     # preview what would be linked
ai/install.sh                # do it
ai/install.sh --uninstall    # remove only the symlinks it created
```

Re-run after adding, renaming, or removing a skill.

## targets.conf

Three directive types, one per line. `#` starts a comment, `~` expands to
`$HOME`, `@` expands to this `ai/` folder. Blank/comment lines are ignored.

```
source  <dir>
```
A folder of skills, i.e. `<dir>/<name>/SKILL.md`. Missing folders are
skipped silently, so it's safe to list a source that only exists on some
machines — work-only skills can live in a separate private repo
(`~/Workspace/skills`), which is simply skipped on machines where it isn't
cloned. List a source you want to take priority **above** another one.

```
skills  <tool>  <dir>
```
Where `<tool>` looks for personal skills — every collected skill gets
symlinked into `<dir>/<name>`.

```
instructions  <tool>  <file>
```
Where `<tool>` reads its global always-on instructions — `AGENTS.md` gets
symlinked to `<file>` (skipped if `<file>` already exists and isn't a
symlink this script made).

Current config:

```
# source  ~/Workspace/skills/skills      # private work repo (only on the work laptop)
source  @/skills                       # @ = this ai/ folder

skills  claude   ~/.claude/skills

instructions  claude  ~/.claude/CLAUDE.md
```

The private-repo `source` line is commented out — uncomment it on machines
where that repo is cloned to pull in work-only skills alongside this
repo's. The commented-out `skills`/`instructions` lines for `agents`,
Codex, Gemini, Copilot and Cursor are there to uncomment once you've
checked that tool's current docs for where it expects these files — paths
change.

## Adding a skill

```bash
cp -R ai/skills/_template ai/skills/<name>
# edit SKILL.md: set name: <name> and a description that says when to use it
installs/install_ai.sh
```

`scripts/validate.py` enforces: `name` matches the folder and is
lowercase-hyphenated, `description` is non-empty, `SKILL.md` stays under
500 lines (move long checklists into `references/`), and any
`scripts/`/`references/`/`assets/` path mentioned in the file actually
exists.

## Uploading to claude.ai / Cowork

Those can't read your disk, so `ai/scripts/package.sh` zips each skill
(minus `evals/`, `__pycache__`, `.DS_Store`) into `ai/dist/<name>.skill` for
manual upload.

## Keep this repo clean

Nothing here should be company-specific, secret, or PII-bearing — that
belongs in the private work skills repo instead, referenced as a `source`
in `targets.conf`.
