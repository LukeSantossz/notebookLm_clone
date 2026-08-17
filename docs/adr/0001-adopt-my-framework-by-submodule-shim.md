# Adopt my-framework by submodule plus a local shim, not by copy

`my-framework` documents adoption as a copy: `README.md:51` instructs an adopting
repository to copy `docs/standards/`, `docs/adr/`, `docs/agents/`, `CLAUDE.md`,
`AGENTS.md`, `CONTEXT.md`, `scripts/`, `.githooks/` and `.github/` into its own
root, then run `scripts/setup.sh`. This repository instead carries the framework
as a git submodule at `my-framework/`, pinned at `bfcd081` (`v0.3.0`), and adds a
thin repo-local activation layer that points into it: a `.githooks/pre-push`
shim that invokes `my-framework/scripts/r2-review.sh`, and a root `CLAUDE.md`
that resolves the standards to `my-framework/docs/standards/INDEX.md`.

The reason is update path. A copy freezes the standards at the tag it was taken
from and gives no mechanism to advance them; the submodule keeps one source of
truth that `git submodule update --remote` advances, with the pinned commit
recorded in this repository's history. The cost is that the framework's own
activation script does not fit this layout, which is what the shim absorbs.

## Status

Accepted.

## Considered Options

- **Submodule plus a local shim (chosen)**: the standards stay in one updatable
  place; the repository owns only the small activation layer that binds them to
  itself. Cost: `scripts/setup.sh` cannot be used as-is, and the shim must track
  the runner's path across upstream updates.
- **Copy-adoption as the README prescribes**: rejected — it duplicates four
  documentation trees and the framework's scripts into this repository, freezing
  them at `v0.3.0` and making the submodule redundant. It is the path the
  framework tests, but it forfeits the only reason to carry a submodule at all.
- **Point `core.hooksPath` at `my-framework/.githooks` directly**: rejected —
  that hook resolves its runner as `$repo_root/scripts/r2-review.sh`
  (`my-framework/.githooks/pre-push:8`), which under this layout names a
  nonexistent path in the parent repository, and it `exit 0`s when the runner is
  absent. The R2 gate would be configured, appear active, and never run.
- **Patch the hook inside the submodule working tree**: rejected — local
  divergence inside a pinned upstream checkout is discarded by the next
  `git submodule update --remote`, so the fix would silently disappear.

## Consequences

- The R2 pre-push gate reaches the framework through `.githooks/pre-push` in
  this repository, not through the submodule's own hook. `core.hooksPath` is
  `.githooks`.
- Unlike upstream's hook, the shim exits non-zero and names the missing file
  when the runner is absent. An uninitialized submodule is the expected way this
  layout breaks, and a silent skip there would leave a dead gate looking healthy.
- Upstream renaming or moving `scripts/r2-review.sh` breaks the shim. That
  breakage is loud by the previous consequence, which is the trade accepted in
  exchange for not vendoring the scripts.
- `scripts/setup.sh` is not run from this repository's root: it would set
  `core.hooksPath` to a `.githooks` whose runner it cannot supply, and its
  machine-global steps (`--reviewer`, `--statusline`) are already applied.
- Non-agentic R2 backends read the wrong reviewer instructions. The `openai`
  adapter hardcodes `agents_file="$script_dir/../../AGENTS.md"`
  (`my-framework/scripts/reviewers/openai.sh:37`) and then sets
  `R2_OPENAI_AGENTS` from it (`:104`), so an outside override cannot reach it.
  A fallback review therefore receives the submodule's `AGENTS.md` — the correct
  Reviewer role, but with every path relative to the submodule root and no
  mention of this repository's `docs/specs/`. The agentic `codex` backend, which
  heads the chain, does find the root `AGENTS.md` and is unaffected. Fixing this
  properly means making `agents_file` overridable upstream; patching it here
  would be exactly the local divergence this ADR rejects, so it stays a
  limitation until upstream takes the change.
- The standards advance by moving the submodule pin, and every advance is a
  reviewable commit in this repository's history.
