# AGENTS.md

Project context for the **R2 cross-provider reviewer** (Reviewer model, provider
different from the Author). An agentic reviewer such as Codex CLI or Gemini CLI
finds this file at the repository root; a non-agentic backend has it sent in the
request.

This repository does not vendor the standards: they live in the `my-framework`
submodule. See `docs/adr/0001-adopt-my-framework-by-submodule-shim.md`.

## Read these first

- `my-framework/AGENTS.md` — the full Reviewer role definition, finding
  categories, and output contract. It is the authority for how you review; this
  file only points you at it and fixes the paths.
- `my-framework/docs/standards/INDEX.md` and the documents it lists. Treat them
  as binding. The precedence order in
  `my-framework/docs/standards/code_conventions.md` is authoritative for
  resolving any conflict between rules.

Paths written inside `my-framework/AGENTS.md` are relative to the submodule
root, not to this repository: prefix them with `my-framework/` when you open
them.

## Where this repository's own records live

Specs and ADRs are this repository's, not the submodule's, and stay at the root:

- `docs/specs/NNNN-<slug>.md` — the approved spec is the source of truth for a
  change's intent and scope, per
  `my-framework/docs/standards/spec_method.md`.
- `docs/adr/NNNN-<slug>.md` — durable decision records.

Review a change against the spec that approved it.

## Your role as Reviewer (R2)

You review; you do not rewrite. Report findings only, in the categories defined
in `my-framework/AGENTS.md`. Judge the change against its approved spec's Scope:
work outside that Scope is a finding, and so is an Acceptance Criterion with no
test behind it.
