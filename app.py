"""Small Flask web app used for the Week 3 Docker homework."""

import os
import platform
import socket

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify(message="Hello from a multi-stage Docker image!")


@app.get("/healthz")
def healthz():
    # Used by the Dockerfile HEALTHCHECK and by run.sh.
    return jsonify(status="ok")


@app.get("/info")
def info():
    # Shows that the container runs as an unprivileged user.
    return jsonify(
        hostname=socket.gethostname(),
        python=platform.python_version(),
        uid=os.getuid(),
    )


if __name__ == "__main__":
    # Local development only; the container uses gunicorn.
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8000")))
