# Adopt uv for ultra-fast dependency management and local-first execution

## Context

Development of the Socratic RAG laboratory involves rapid iteration, local testing,
and benchmark execution across modern Python environments (Python >= 3.12). Legacy
tools like pip, virtualenv, and poetry introduce slow install times, complex lockfile
resolution, and environment drift.

## Status

Accepted.

## Considered Options

- **`uv` package manager (chosen)**: Ultra-fast Rust-based dependency resolver and
  virtual environment manager providing reproducible lockfiles (`uv.lock`), rapid
  syncing, and seamless CLI tool execution (`uv run`).
- **Poetry**: Rejected — slower resolution times, heavier CLI footprint, and slower
  CI container builds.
- **Vanilla pip + requirements.txt**: Rejected — lacks deterministic lockfile
  generation and dependency isolation across development and production layers.

## Consequences

- All environment management, dependency synchronization (`uv sync`), test runs
  (`uv run pytest`), and CLI operations (`uv run rag-lab ...`) are unified under `uv`.
- Local execution is fast and reproducible across different developer machines.
