# CLAUDE.md

## Development Standards

The standards are not vendored into this repository: they live in the
`my-framework` submodule, pinned in git history and advanced by moving that pin.
See `docs/adr/0001-adopt-my-framework-by-submodule-shim.md`.

Before any development work in this repository, read
`my-framework/docs/standards/INDEX.md` and the documents it lists. Treat them as
binding:

- Specify before building: produce a spec under `docs/specs/NNNN-<slug>.md` per
  `my-framework/docs/standards/spec_method.md` and pass the Spec Gate before
  writing code for any non-trivial change.
- Follow `my-framework/docs/standards/code_conventions.md`, including its
  precedence order, which is authoritative for resolving any conflict between
  rules.
- Write tests before implementation (red-green-refactor), per the Testing
  section of `code_conventions.md`.
- Follow `my-framework/docs/standards/ai_guidelines.md` for self-review and the
  Review Composition hierarchy (R1 internal, R2 cross-provider, R3 automated PR).
- Follow `my-framework/docs/standards/github.md` for Conventional Commits, branch
  naming, and the PR, Issue, and README templates. No co-author or
  AI-attribution lines in commits.
- Token economy per `my-framework/docs/standards/token_economy.md`: terse mode is
  allowed in conversation but never in spec, PR, Issue, or commit artifacts; it
  never overrides Safety or Correctness.
- All output in English: identifiers, comments, commit/PR/issue text,
  documentation.

Specs and ADRs are this repository's own durable records and live at the root
(`docs/specs/`, `docs/adr/`), not in the submodule. A number, once assigned, is
never reused.

## R2 gate

The R2 cross-provider review runs on `git push` through `.githooks/pre-push`,
which dispatches to `my-framework/scripts/r2-review.sh`. Activate it in a fresh
clone with:

```sh
git submodule update --init --recursive
git config core.hooksPath .githooks
```

Preview the resolved backend chain without running any reviewer with
`R2_DRYRUN=1 bash .githooks/pre-push`. Bypass with `SKIP_R2_REVIEW=1`.

## Agent skills

### Issue tracker

Issues live in this repo's GitHub Issues, managed via the `gh` CLI. See
`my-framework/docs/agents/issue-tracker.md`.

### Triage labels

Five canonical triage roles using default label strings (`needs-triage`,
`needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See
`my-framework/docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` + `docs/adr/` at the repo root. See
`my-framework/docs/agents/domain.md`. `CONTEXT.md` is created lazily, once the
project has domain terms worth resolving.
