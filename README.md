# DevOps Homework — Week 5: CI pipeline with GitHub Actions

Student: `zhanyysh` · Class date: 13-10-2026

[![CI](https://github.com/zhanyysh/devops-week5-ci/actions/workflows/ci.yml/badge.svg)](https://github.com/zhanyysh/devops-week5-ci/actions/workflows/ci.yml)

GitHub Actions CI for the Flask app containerized in Week 3: separate `lint`,
`test` and `build` jobs, pip and Docker layer caching, a Python 3.12/3.13
matrix, and test results plus the image digest uploaded as artifacts.

## Green run

GitHub only runs workflows from `.github/workflows/` at the root of a
repository, so this folder's contents are also pushed to the root of
[zhanyysh/devops-week5-ci](https://github.com/zhanyysh/devops-week5-ci), where
the workflow runs. The badge above is that repo's status.

Green run: GREEN_RUN_LINK

## Files

| File | Purpose |
| --- | --- |
| `.github/workflows/ci.yml` | CI workflow (`lint`, `test`, `build`) |
| `CI.md` | Jobs, triggers, matrix and caching explained |
| `tests/test_app.py` | 5 unit tests for `/`, `/healthz` and `/info` |
| `pytest.ini` | Lets pytest import `app.py` from the folder root |
| `requirements-dev.txt` | App dependencies plus pinned `pytest` and `ruff` |
| `app.py`, `requirements.txt`, `Dockerfile`, `.dockerignore` | The Week 3 app, unchanged |

## Requirements checklist

| # | Requirement | How it is met |
| --- | --- | --- |
| 1 | Separate jobs | `lint`, `test` and `build` jobs; `build` needs `lint` and `test` |
| 2 | Dependency caching | `actions/setup-python` `cache: pip`; Docker layers cached with `type=gha` |
| 3 | Matrix build | `test` runs on Python 3.12 and 3.13 |
| 4 | Artifact upload | `test-results-py3.12`, `test-results-py3.13` (JUnit XML) and `image-digest` |
| 5 | Fail fast | A failing test makes `pytest` exit 1, which fails the run; `fail-fast: true`; `build` is skipped |
| 6 | Pinned actions | `actions/checkout@v4`, `actions/setup-python@v5`, `actions/upload-artifact@v4`, `docker/setup-buildx-action@v3`, `docker/build-push-action@v6` |
| - | At least three tests | 5 tests in `tests/test_app.py` |

Triggers: `push`, `pull_request` and `workflow_dispatch`. Details are in
[`CI.md`](CI.md).

## Run locally

```bash
pip install -r requirements-dev.txt
ruff check .
pytest
docker build -t devops/week5:ci .
```
