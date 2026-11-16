---
name: python-code-review
description: Review Python changes on a git branch or working tree (git diff vs main, staged/unstaged edits, a feature branch before opening a PR) and return a short, prioritized list of findings — Blocker / Should-fix / Nit — each with file:line and a concrete fix. Covers correctness, ML/MLOps pitfalls (data leakage, train/serve skew, reproducibility, non-idempotent pipelines, model/feature versioning), security and PII handling, and style/tests/performance, and runs ruff, ty and pytest when the repo has them. Use this whenever someone asks to review, check, sanity-check, or "take a look at" their Python changes, diff, branch, or commit, asks whether code is ready to merge or open a PR, or asks "what did I break" — even if they don't say "code review".
---

# Python code review

Review what changed, not the whole repo. The reader is an engineer who wants to act on findings fast, so the output is short and ranked by how much each issue matters. Every finding should be something worth the author's time to fix; a review padded with weak findings trains people to skim.

## 1. Scope the change

Work out the diff before reading code:

```bash
git rev-parse --abbrev-ref HEAD
git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main   # try master too
git diff --stat <base>...HEAD      # committed branch changes
git diff --stat; git diff --cached --stat   # uncommitted work
```

- If the user named a base, commit range or files, use that.
- Include uncommitted changes if there are any — that's usually what they just wrote.
- Only Python-relevant files matter: `*.py`, `pyproject.toml`, `requirements*.txt`, `setup.cfg`, notebooks, and configs the Python code reads (YAML/JSON pipeline/model configs, Dockerfiles, CI for Python jobs).
- For a large diff (>~1500 changed lines), say so and prioritize: core logic and pipelines first, generated files/lockfiles/vendored code last or skipped.

Then read the full diff (`git diff <base>...HEAD -- <files>`), and open the surrounding code for any hunk whose correctness depends on context — callers, the function being changed, the config it reads. Most real bugs are visible only with that context.

## 2. Run the tooling that exists

Run `scripts/run_checks.sh <base>` from this skill's directory (pass the repo root as the working directory). It detects which of ruff, ty and pytest the project uses (via `pyproject.toml`, `setup.cfg`, `ruff.toml`, `ty.toml`, `tests/`), runs them on the changed files where that makes sense, and prints a compact summary. It never installs anything.

- If the repo has no ruff config of its own, the script falls back to this skill's default config at `references/ruff.toml` (line-length 120, numpy docstring convention, broad rule selection — see that file for the exact rule set) so ruff still runs with our standard rules.
- Report only tool findings on **changed lines** (or newly failing tests). Pre-existing lint noise is not this author's problem; mention it in one line at most.
- If a tool isn't configured or installed, skip it and note that in the Checks line. Don't invent config.
- If tests take long or need infra (DB, cloud creds), the script times out on them — report "pytest: skipped (timeout/needs infra)" and move on.

## 3. Review

Read `references/checklist.md` for the full list. The categories, in priority order:

1. **Correctness** — logic errors, wrong edge-case handling (empty, None, NaN, tz-naive datetimes), swallowed exceptions, mutable default args, wrong types, broken contracts with callers, race conditions, resource leaks.
2. **ML/MLOps** — leakage (fitting scalers/encoders on full data, target in features, future data in time-series splits), train/serve skew (different preprocessing paths), missing seeds or unpinned versions that break reproducibility, non-idempotent pipeline steps (append without dedupe, no overwrite semantics, side effects on retry), unversioned model/feature artifacts, silent schema drift, metrics computed on the wrong split.
3. **Security & PII** — secrets in code/config, SQL/shell injection, `pickle`/`joblib`/`yaml.load` on untrusted input, `eval`, disabled TLS verification, and PII (names, emails, account numbers, IBANs, national IDs, IPs) being logged, printed, written to unencrypted storage, sent to third parties, or used outside its stated purpose. Treat PII exposure as a Blocker by default.
4. **Tests, style, performance** — changed behavior without tests, tests that can't fail, row-wise pandas loops/`apply` where vectorization is easy, N+1 queries, loading full tables into memory, unclear naming. Style that ruff already enforces doesn't need repeating.

For each candidate finding, ask: is it actually reachable in this code? Would a senior reviewer on the team flag it? If unsure, either verify it (read the caller, run a snippet) or drop it. Phrase a plausible-but-unverified concern as a question, not a claim.

### Severity

- **Blocker** — will cause wrong results, data loss/corruption, a security or PII exposure, or a broken pipeline/deploy. Don't merge as is.
- **Should-fix** — real risk or maintainability cost, but not immediately breaking: missing tests on new logic, reproducibility gaps, fragile error handling, clear perf problems.
- **Nit** — small and optional. Cap at ~5; drop the rest.

## 4. Output

Keep it tight. Use exactly this shape:

```
## Review: <branch> vs <base> — <N files, +X/−Y>

**Verdict:** <Ready to merge | Merge after fixes | Needs rework> — <one sentence why>
**Checks:** ruff ✅ | ty ⚠️ 2 new errors | pytest ✅ 48 passed   (or "not configured")

### Blockers
1. `path/file.py:42` — <what's wrong and the consequence>. **Fix:** <concrete change, code if short>

### Should-fix
1. `path/file.py:88` — ... **Fix:** ...

### Nits
- `path/file.py:12` — ...

### Questions
- <anything you couldn't verify that the author should confirm>
```

- Omit empty sections (but always keep Verdict and Checks).
- One or two lines per finding. Include a short code snippet in the fix only when it's clearer than prose.
- Use real line numbers from the new version of the file.
- If PII is involved, flag it explicitly as **PII** in the finding text so it's easy to spot.
- No praise section, no summary of what the change does unless the user asks — they wrote it.
- If there are no meaningful issues, say so in the Verdict and stop. A clean review is a valid result.

Don't modify the code unless the user asks you to apply fixes.
