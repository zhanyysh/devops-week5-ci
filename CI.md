# CI pipeline

Workflow file: [`.github/workflows/ci.yml`](.github/workflows/ci.yml). It tests
and builds the Week 3 Flask app (`app.py`, `Dockerfile`).

## Triggers

| Event | When it runs |
| --- | --- |
| `push` | Every push, on any branch |
| `pull_request` | Every pull request opened, updated (new commits) or reopened |
| `workflow_dispatch` | Manually, from the "Run workflow" button on the Actions tab |

The workflow token is limited to `permissions: contents: read`. No secrets or
cloud credentials are used.

## Jobs

| Job | Depends on | What it does |
| --- | --- | --- |
| `lint` | - | Sets up Python 3.12, installs `requirements-dev.txt`, runs `ruff check .` |
| `test` | - | Matrix over Python 3.12 and 3.13. Installs dependencies, runs `pytest` (5 tests in `tests/test_app.py`), uploads the JUnit XML report as the artifact `test-results-py<version>` |
| `build` | `lint`, `test` | Builds the Docker image with Buildx, starts a container and checks `GET /healthz`, uploads the image digest (`image-digest.txt`) as the artifact `image-digest` |

`lint` and `test` run in parallel. `build` starts only when both succeed, so an
image is never built from code that fails lint or tests.

## How a failing test fails the build

- `pytest` exits with code 1 when any test fails. GitHub Actions marks the step,
  the `test` job and the whole run as failed.
- `fail-fast: true` cancels the other matrix leg as soon as one fails.
- `build` has `needs: [lint, test]`, so it is skipped.
- The test report is still uploaded (`if: always()`), so the failure can be
  inspected from the artifact.

Checked locally by changing the expected `/healthz` body to `"broken"`:

```
FAILED tests/test_app.py::test_healthz_returns_ok - AssertionError: assert {'...
1 failed, 4 passed in 0.10s
pytest_exit=1
```

## Matrix

`test` runs once per Python version (3.12 and 3.13) on separate runners. 3.12 is
the version in the Docker image; 3.13 catches breakage before upgrading.

## Caching

- **pip cache.** `actions/setup-python` with `cache: pip` saves pip's download
  cache, keyed on the runner OS, Python version and the hash of
  `requirements-dev.txt`. On the next run with the same requirements, Flask,
  gunicorn, pytest and ruff are restored from the cache instead of downloaded
  from PyPI. Editing `requirements-dev.txt` changes the key, so a fresh cache
  is built. Each matrix leg has its own cache.
- **Docker layer cache.** `docker/build-push-action` uses
  `cache-from/cache-to: type=gha`, which stores image layers in the GitHub
  Actions cache. The Dockerfile copies `requirements.txt` and runs
  `pip install` before copying `app.py`, so a code-only change reuses the
  cached dependency layer and only rebuilds the final `COPY app.py` layer.

Both caches make runs faster and less dependent on PyPI and Docker Hub being
reachable.

## Pinned action versions

`actions/checkout@v4`, `actions/setup-python@v5`, `actions/upload-artifact@v4`,
`docker/setup-buildx-action@v3`, `docker/build-push-action@v6`. Tool versions
are pinned too: `pytest==9.1.1`, `ruff==0.17.1`, `Flask==3.1.2`,
`gunicorn==23.0.0`.

## Run the same checks locally

```bash
pip install -r requirements-dev.txt
ruff check .
pytest
docker build -t devops/week5:ci .
```
