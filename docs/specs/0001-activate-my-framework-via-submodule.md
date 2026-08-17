# SPEC: chore: activate my-framework via a submodule shim

## Problem

`notebookLm_clone` carries the `my-framework` standards as a submodule, but the
framework's activation path assumes copy-adoption, so none of its gates are
active in this repository.

## Design Decision

Keep the submodule as the single source of truth for the standards and add a
thin, repo-local activation layer that points at it. The repository gets its own
`.githooks/pre-push` that invokes `my-framework/scripts/r2-review.sh` and its own
`CLAUDE.md` that resolves the standards to
`my-framework/docs/standards/INDEX.md`; `core.hooksPath` is set to `.githooks`.
Upstream's hook silently `exit 0`s when the runner is absent
(`my-framework/.githooks/pre-push:10`); the shim instead fails loudly, because a
submodule that was never initialized is exactly the case where a silent skip
would hide a dead gate. Machine-global state (`--reviewer`, `--statusline`) is
already applied and is not touched.

## Alternatives Considered

- **Copy-adoption, as `README.md:51` prescribes.** Rejected: it duplicates
  `docs/standards/`, `docs/adr/`, `docs/agents/` and `scripts/` into this
  repository, freezing them at v0.3.0 and making `git submodule update --remote`
  meaningless. The submodule was the Developer's explicit choice precisely to
  keep one updatable source.
- **Point `core.hooksPath` straight at `my-framework/.githooks`.** Rejected:
  that hook resolves `runner="$repo_root/scripts/r2-review.sh"`, which under a
  submodule layout resolves to `notebookLm_clone/scripts/r2-review.sh` — a path
  that does not exist — so it would `exit 0` and the R2 gate would never run,
  without any message.
- **Patch the hook inside the submodule.** Rejected: it puts local divergence in
  a pinned upstream checkout, which the next `--remote` update discards.

## Scope

- Includes:
  - `.githooks/pre-push` — shim invoking the submodule runner, erroring when it
    is missing.
  - `CLAUDE.md` at the repo root — the framework's binding-standards block with
    the path adjusted to `my-framework/docs/standards/INDEX.md`, as
    `my-framework/CLAUDE.md:22` instructs.
  - `.github/PULL_REQUEST_TEMPLATE.md` and `.github/ISSUE_TEMPLATE/issue.md` —
    copied verbatim.
  - `git config core.hooksPath .githooks` (repo-local).
  - The five triage labels created on `LukeSantossz/notebookLm_clone` via `gh`.
  - `.gitattributes` pinning `*.sh` and `.githooks/*` to LF. Amended into scope
    during implementation: this machine sets `core.autocrlf=true`, so without it
    a fresh clone checks the shim out with CRLF and its shebang fails with
    "bad interpreter" — the activation this spec delivers would arrive broken.
- Does NOT include:
  - `CONTEXT.md` — `my-framework/docs/agents/domain.md` says it is created
    lazily once real domain terms are resolved, and this repository has no code
    yet.
  - `.github/workflows/ci.yml` — it runs `scripts/test/*.sh` of the framework,
    which do not exist here; the submodule's own CI already guards the standards
    tree, and this repository has nothing to test yet.
  - Any copy of `docs/standards/`, `docs/adr/`, `docs/agents/`, `AGENTS.md`, or
    the framework's `scripts/` into the repo root.
  - Any change inside the `my-framework/` working tree, or to the pinned commit
    `bfcd081`.
  - Any change to machine-global config (`--global` `r2.*`, status line) —
    already applied.
  - `git push`.

## Acceptance Criteria

- `hooks_path_resolves_to_repo_local_githooks`: `git config --get
  core.hooksPath` returns `.githooks`.
- `pre_push_shim_dispatches_to_submodule_runner`: running the shim with
  `R2_DRYRUN=1` prints the resolved backend chain from
  `my-framework/scripts/r2-review.sh` and exits 0.
- `pre_push_shim_errors_when_submodule_uninitialized`: with the runner path
  absent, the shim exits non-zero and names the missing file, rather than
  exiting 0.
- `pre_push_shim_honors_bypass`: `SKIP_R2_REVIEW=1` makes the shim exit 0
  without invoking a backend.
- `claude_md_standards_path_exists`: the path named in the root `CLAUDE.md`
  resolves to an existing `my-framework/docs/standards/INDEX.md`.
- `triage_labels_present`: `gh label list --json name` contains all five of
  `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`.
- `submodule_tree_passes_docs_consistency`: `bash
  my-framework/scripts/test/docs-consistency.sh` exits 0.
- `hook_and_tests_are_lf_and_executable`: `git ls-files --eol .githooks/pre-push`
  reports `w/lf` and `git ls-files -s` reports mode `100755` for the hook and
  its test suite.

## Reproducibility

Run from the repository root, `C:\Users\lucas\OneDrive\Desktop\notebookLm_clone`:

```sh
git config --get core.hooksPath
R2_DRYRUN=1 bash .githooks/pre-push
SKIP_R2_REVIEW=1 bash .githooks/pre-push
bash scripts/test/pre-push.test.sh
bash my-framework/scripts/test/docs-consistency.sh
gh label list --json name --jq '.[].name'
```

No randomness. Versions: git 2.54.0.windows.1, bash 5.3.9 (Cygwin), gh 2.93.0,
node v26.2.0, codex-cli 0.147.0, submodule pinned at `bfcd081` (`v0.3.0`).

## Risks and Assumptions

- Assumption: the R2 chain runs only off `main`; `r2-review.sh:57` skips when
  branch equals base, so the gate first exercises real work on a feature branch,
  not on this activation commit.
- Assumption: the DeepSeek fallback stays second-line — `r2.backends=codex,antigravity,openai`
  is already global and this spec does not re-tune it.
- Risk: a future `git submodule update --remote` that moves or renames
  `scripts/r2-review.sh` breaks the shim. The loud-failure criterion is what
  converts that into a visible error instead of a silently dead gate.
- Risk: `gh label create` needs write scope on the repository; without it the
  label criterion fails and the rest still holds.
