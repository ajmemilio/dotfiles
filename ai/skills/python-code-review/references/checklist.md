# Review checklist

Use as a prompt for what to look for, not a form to fill in. Skip what doesn't apply to the diff.

## Correctness
- Off-by-one, inverted conditions, wrong operator (`is` vs `==`, `and`/`or` precedence)
- `None`/empty/NaN handling; `if x:` where `0`, `""` or empty DataFrame is valid
- Mutable default arguments (`def f(x=[])`, `=dict()`)
- Bare `except:` / `except Exception: pass` hiding failures; retries without backoff or limit
- Exceptions re-raised without context (`raise X` instead of `raise X from e`)
- Datetimes: naive vs aware mixing, `datetime.now()` without tz, DST assumptions
- Float equality, money in floats (use `Decimal` or integer minor units)
- pandas: chained assignment / `SettingWithCopy`, `inplace` returning None, index misalignment on assignment, `merge` producing duplicates (missing `validate=`), dtype changes after `fillna`/`merge`
- Changed function signature/return type without updating callers
- Resources not closed (files, DB connections, sessions) — prefer context managers
- Async: blocking calls inside `async def`, un-awaited coroutines, shared mutable state across tasks
- Type hints that lie (`-> str` but can return `None`)

## ML / MLOps
- **Leakage:** fitting scalers/encoders/imputers before train/test split; target or post-outcome columns in features; random split on time-series data; group leakage (same customer in train and test)
- **Train/serve skew:** preprocessing duplicated in training and inference code instead of shared; feature defaults differ between paths; different library versions
- **Reproducibility:** no seeds (numpy, random, torch, sklearn `random_state`); unpinned dependencies; data read without a snapshot/version; non-deterministic ordering (`set` iteration, unordered SQL without `ORDER BY`)
- **Idempotency:** pipeline steps that append without dedupe, write to fixed paths without partitioning, or have side effects on retry; missing `overwrite`/upsert semantics
- **Artifacts:** models/features saved without version, commit hash, or training-data reference; overwriting `latest` with no history
- **Evaluation:** metrics on training data; threshold tuned on the test set; class imbalance ignored; wrong averaging (`micro` vs `macro`)
- **Data contracts:** no schema validation on inputs (pandera/pydantic/Great Expectations) where upstream can change; silently dropping rows/columns
- **Serving:** model loaded per request; no input validation; unbounded batch sizes; no timeout on downstream calls
- **Observability:** no logging of model version / prediction metadata; metrics not emitted for drift or latency

## Security & PII
- Hardcoded secrets, tokens, connection strings; secrets in default arg values or committed `.env`
- SQL built with f-strings/`%`/`.format` instead of parameters; `subprocess(..., shell=True)` with user input
- `pickle.load`, `joblib.load`, `torch.load` (without `weights_only=True`), `yaml.load` (not `safe_load`), `eval`/`exec` on data that could be untrusted
- `verify=False` on requests; disabled cert checks
- Path traversal from user-supplied filenames
- **PII:** names, emails, phone numbers, bank account numbers, IBANs, card data, national IDs, IP addresses, device IDs
  - logged at any level, included in exception messages, or printed
  - written to unencrypted buckets, temp files, or notebooks committed to git
  - sent to third-party APIs (including LLM APIs) or used for a purpose beyond the stated one
  - present in test fixtures as real-looking data
  - Missing masking/hashing/tokenization where the pipeline only needs a join key
- Overly broad IAM/permissions in infra changes that ship with the code

## Tests
- New or changed behavior with no test
- Tests that assert nothing meaningful (`assert result is not None`), or mock the thing under test
- Tests depending on wall-clock time, network, or ordering
- Missing edge cases that the code explicitly handles (empty input, error paths)

## Performance
- Row-wise `iterrows`/`apply` over large DataFrames where a vectorized op exists
- N+1 queries; queries inside loops
- Reading whole tables/files into memory where chunks or pushdown filters work
- Repeated expensive work inside loops (compiling regexes, loading models, opening connections)
- Quadratic list membership checks (`x in list` in a loop) — use a set

## Style / maintainability (only what ruff doesn't catch)
- Misleading names; functions doing several unrelated things
- Dead code, commented-out blocks, leftover debug prints
- Magic numbers that should be config
- Public functions with non-obvious behavior and no docstring
