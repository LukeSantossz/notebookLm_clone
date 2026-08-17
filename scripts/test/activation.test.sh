#!/usr/bin/env bash
# Tests for the activation state of this repository against the my-framework
# submodule. Covers the Acceptance Criteria of
# docs/specs/0001-activate-my-framework-via-submodule.md that assert repository
# and configuration state rather than the shim's behavior; the shim itself is
# covered by pre-push.test.sh.
#
# These assert the checked-out repository, not a sandbox: activation is a
# property of this working copy, and a sandbox copy of it would prove nothing.
set -u

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TEST_DIR/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

PASS=0
FAIL=0
SKIP=0

ok() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
no() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; printf '       %s\n' "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'skip - %s\n' "$1"; printf '       %s\n' "$2"; }

# hooks_path_resolves_to_repo_local_githooks
hooks="$(git config --get core.hooksPath || true)"
if [ "$hooks" != ".githooks" ]; then
  no hooks_path_resolves_to_repo_local_githooks "core.hooksPath is '${hooks:-<unset>}'; run: git config core.hooksPath .githooks"
else
  ok hooks_path_resolves_to_repo_local_githooks
fi

# claude_md_standards_path_exists
# The root CLAUDE.md is only useful if the path it sends the agent to resolves.
named="$(grep -o 'my-framework/docs/standards/INDEX.md' CLAUDE.md | head -1 || true)"
if [ -z "$named" ]; then
  no claude_md_standards_path_exists "CLAUDE.md does not name my-framework/docs/standards/INDEX.md"
elif [ ! -f "$named" ]; then
  no claude_md_standards_path_exists "CLAUDE.md names $named, which does not exist (submodule not initialized?)"
else
  ok claude_md_standards_path_exists
fi

# reviewer_instructions_reachable_from_repo_root
if [ ! -f AGENTS.md ]; then
  no reviewer_instructions_reachable_from_repo_root "no AGENTS.md at the repo root; an agentic R2 backend reviews without its role"
elif ! grep -q 'my-framework/AGENTS.md' AGENTS.md || ! grep -q 'my-framework/docs/standards/INDEX.md' AGENTS.md; then
  no reviewer_instructions_reachable_from_repo_root "AGENTS.md does not redirect to both my-framework/AGENTS.md and the standards index"
else
  ok reviewer_instructions_reachable_from_repo_root
fi

# no_instruction_points_at_an_absent_root_standards_dir
# Scoped to the files that tell a reader or an agent where to look. docs/specs
# and docs/adr name the bare path as prose describing the rejected layout.
stray="$(git grep -n 'docs/standards/' -- .github AGENTS.md CLAUDE.md | grep -v 'my-framework/docs/standards/' || true)"
if [ -n "$stray" ]; then
  no no_instruction_points_at_an_absent_root_standards_dir "these point at a root docs/standards/ that does not exist: $stray"
else
  ok no_instruction_points_at_an_absent_root_standards_dir
fi

# hook_and_tests_are_lf_and_executable
# Executable bits are read from the git index, not the filesystem: Windows does
# not report them reliably, which is why `git ls-files -s` is the source of truth.
bad=''
for f in .githooks/pre-push scripts/test/pre-push.test.sh scripts/test/activation.test.sh; do
  mode="$(git ls-files -s "$f" | awk '{print $1}')"
  eol="$(git ls-files --eol "$f" | awk '{print $2}')"
  [ "$mode" = "100755" ] || bad="$bad $f(mode=${mode:-absent})"
  [ "$eol" = "w/lf" ] || bad="$bad $f(${eol:-absent})"
done
if [ -n "$bad" ]; then
  no hook_and_tests_are_lf_and_executable "expected mode 100755 and w/lf for each;$bad"
else
  ok hook_and_tests_are_lf_and_executable
fi

# submodule_tree_passes_docs_consistency
# Run with the working directory inside the submodule: the script resolves its
# target through `git rev-parse --show-toplevel`, so from here it would resolve
# to this repository, find no docs/standards/, and exit 0 having checked nothing.
checker=my-framework/scripts/test/docs-consistency.sh
if [ ! -f "$checker" ]; then
  no submodule_tree_passes_docs_consistency "$checker is missing; run: git submodule update --init --recursive"
else
  out="$(cd my-framework && bash scripts/test/docs-consistency.sh 2>&1)"; code=$?
  if [ "$code" -ne 0 ]; then
    no submodule_tree_passes_docs_consistency "exited $code: $(printf '%s' "$out" | tail -3)"
  elif ! printf '%s' "$out" | grep -q 'all checks passed'; then
    no submodule_tree_passes_docs_consistency "exited 0 without reporting a real pass: $(printf '%s' "$out" | tail -3)"
  else
    ok submodule_tree_passes_docs_consistency
  fi
fi

# triage_labels_present
# Needs network and an authenticated gh, so it reports as skipped rather than
# failing a local run that is otherwise green.
if ! command -v gh >/dev/null 2>&1; then
  skip triage_labels_present "gh is not installed"
elif ! gh auth status >/dev/null 2>&1; then
  skip triage_labels_present "gh is not authenticated (run: gh auth login)"
elif ! labels="$(gh label list --limit 500 --json name --jq '.[].name' 2>/dev/null)"; then
  skip triage_labels_present "could not list labels (permission or network)"
else
  missing=''
  for l in needs-triage needs-info ready-for-agent ready-for-human wontfix; do
    printf '%s\n' "$labels" | grep -qx "$l" || missing="$missing $l"
  done
  if [ -n "$missing" ]; then
    no triage_labels_present "missing:$missing"
  else
    ok triage_labels_present
  fi
fi

printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
