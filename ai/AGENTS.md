# Agent instructions (always on)

Personal conventions loaded into every AI session. Keep it short: workflows
belong in `skills/`. Company-specific rules live in the private work repo.

## Python
- Python 3.11+. Lint/format with `ruff`; type-check with `mypy` where configured.
- Tests with `pytest`. New behavior ships with a test.
- Type hints on public functions; `pathlib`; context managers for I/O.

## ML / data
- Set seeds and pin dependencies; record model version, git SHA and data snapshot with every artifact.
- Fit preprocessing on the training split only; share feature code between training and serving.
- Pipeline steps must be idempotent (partitioned overwrite or upsert, never blind append).

## Security & PII
- Never hardcode secrets; read them from env or a secrets manager.
- Never log, print or return PII; log internal IDs instead. Flag any new use of PII.
- Parameterize SQL; no `pickle`/`yaml.load`/`eval` on untrusted input.

## Working style
- Code/PR reviews: short and prioritized (Blocker / Should-fix / Nit, file:line, concrete fix).
- Architecture and tradeoff discussions: explain the reasoning.
- Don't modify code during a review unless asked.
