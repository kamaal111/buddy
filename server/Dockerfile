FROM python:3.13-slim-bookworm AS builder

COPY --from=ghcr.io/astral-sh/uv:0.6.2 /uv /uvx /bin/

WORKDIR /app

COPY src uv.lock pyproject.toml README.md ./

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --no-install-project --no-dev --no-python-downloads --locked

FROM python:3.13-slim-bookworm

COPY --from=builder --chown=app:app /app/.venv /app/.venv
COPY --from=builder --chown=app:app /app/buddy /app/buddy

EXPOSE 80
CMD ["/app/.venv/bin/fastapi", "run", "/app/buddy/main.py", "--port", "80"]
