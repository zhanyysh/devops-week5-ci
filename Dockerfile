# Pinned base image (minor version + slim variant, never "latest").
ARG PYTHON_IMAGE=python:3.12-slim

# ---------- Stage 1: builder ----------
# Installs dependencies into an isolated virtualenv. pip caches, wheels and
# build leftovers stay in this stage and never reach the final image.
FROM ${PYTHON_IMAGE} AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /build

# Layer caching: copy only the dependency manifest first, so this expensive
# layer is rebuilt only when requirements.txt changes, not on every code edit.
COPY requirements.txt .
RUN pip install -r requirements.txt

# ---------- Stage 2: runtime ----------
FROM ${PYTHON_IMAGE} AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Non-root user: a fixed, unprivileged UID/GID with no login shell or home.
RUN groupadd --system --gid 10001 app \
 && useradd --system --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app

WORKDIR /app

# Copy the ready-made virtualenv from the builder stage.
COPY --from=builder /opt/venv /opt/venv

# Source code last: it changes most often, so it is the last layer to rebuild.
COPY --chown=app:app app.py .

USER app

EXPOSE 8000

# Health check hits the real /healthz endpoint. The slim image has no curl,
# so Python's standard library does the HTTP request.
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --start-interval=2s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz', timeout=2)"]

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--access-logfile", "-", "app:app"]
