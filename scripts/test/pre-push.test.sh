#!/usr/bin/env bash
# Tests for the R2 pre-push shim (.githooks/pre-push).
# Each test maps to an Acceptance Criterion in
# docs/specs/0001-activate-my-framework-via-submodule.md.
set -u

# Isolate git config lookups from this machine's global/system scope: the shim
# resolves a repository root, and a sandboxed repo must not inherit an
# operator's real settings.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TEST_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/.githooks/pre-push"

PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
no() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; printf '       %s\n' "$2"; }

# Sandbox: throwaway git repos, so a test never runs the real reviewer chain
# and never touches this repository's state. The stub runner stands in for
# my-framework/scripts/r2-review.sh and records that it was invoked.
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

# A repo laid out like this one: the shim at .githooks/pre-push and a runner
# under my-framework/scripts/. Pass an exit code to make the stub runner fail.
new_repo() {
  d="$SANDBOX/repo-$1"
  git init -q "$d"
  mkdir -p "$d/.githooks"
  cp "$HOOK" "$d/.githooks/pre-push"
  if [ "${2:-none}" != "none" ]; then
    mkdir -p "$d/my-framework/scripts"
    cat > "$d/my-framework/scripts/r2-review.sh" <<STUB
#!/bin/sh
printf 'STUB_RUNNER invoked\n' >> "\$RUNNER_LOG"
exit $2
STUB
  fi
  printf '%s\n' "$d"
}

# pre_push_shim_dispatches_to_submodule_runner
repo="$(new_repo dispatch 0)"
log="$SANDBOX/dispatch.log"; : > "$log"
out=$(cd "$repo" && RUNNER_LOG="$log" bash .githooks/pre-push 2>&1); code=$?
if [ "$code" -ne 0 ]; then
  no pre_push_shim_dispatches_to_submodule_runner "expected exit 0, got $code: $out"
elif ! grep -q 'STUB_RUNNER invoked' "$log"; then
  no pre_push_shim_dispatches_to_submodule_runner "the submodule runner was never invoked"
else
  ok pre_push_shim_dispatches_to_submodule_runner
fi

# pre_push_shim_dispatches_to_submodule_runner (dry run, real runner)
# The stub above proves dispatch; this proves the real runner is reached and
# resolves its chain. R2_DRYRUN=1 prints the resolved command and calls no
# backend, so this stays a read-only check against the real submodule.
if [ ! -f "$REPO_ROOT/my-framework/scripts/r2-review.sh" ]; then
  no pre_push_shim_dryrun_resolves_real_chain "the my-framework submodule is not initialized"
else
  # R2_BASE is pinned to a sentinel so the case does not depend on which branch
  # the suite runs from: the runner skips when the current branch equals the
  # base, which would make this assertion pass or fail by checkout rather than
  # by behavior. The sentinel also proves the base reaches the adapter.
  probe=__r2_dryrun_probe__
  out=$(cd "$REPO_ROOT" && R2_DRYRUN=1 R2_BASE="$probe" bash .githooks/pre-push 2>&1); code=$?
  if [ "$code" -ne 0 ]; then
    no pre_push_shim_dryrun_resolves_real_chain "expected exit 0, got $code: $out"
  elif ! printf '%s' "$out" | grep -q "codex review --base $probe"; then
    no pre_push_shim_dryrun_resolves_real_chain "the resolved backend chain was not printed: $out"
  else
    ok pre_push_shim_dryrun_resolves_real_chain
  fi
fi

# pre_push_shim_propagates_runner_failure
# A gate that swallows the reviewer's verdict is not a gate.
repo="$(new_repo failure 3)"
log="$SANDBOX/failure.log"; : > "$log"
out=$(cd "$repo" && RUNNER_LOG="$log" bash .githooks/pre-push 2>&1); code=$?
if [ "$code" -ne 3 ]; then
  no pre_push_shim_propagates_runner_failure "expected the runner's exit 3, got $code: $out"
else
  ok pre_push_shim_propagates_runner_failure
fi

# pre_push_shim_errors_when_submodule_uninitialized
# Upstream's hook exits 0 here, which leaves a dead gate looking healthy.
repo="$(new_repo missing none)"
out=$(cd "$repo" && bash .githooks/pre-push 2>&1); code=$?
if [ "$code" -eq 0 ]; then
  no pre_push_shim_errors_when_submodule_uninitialized "exited 0 with no runner present; the gate would silently not run"
elif ! printf '%s' "$out" | grep -q 'my-framework/scripts/r2-review.sh'; then
  no pre_push_shim_errors_when_submodule_uninitialized "failed without naming the missing runner: $out"
else
  ok pre_push_shim_errors_when_submodule_uninitialized
fi

# pre_push_shim_honors_bypass
repo="$(new_repo bypass 0)"
log="$SANDBOX/bypass.log"; : > "$log"
out=$(cd "$repo" && RUNNER_LOG="$log" SKIP_R2_REVIEW=1 bash .githooks/pre-push 2>&1); code=$?
if [ "$code" -ne 0 ]; then
  no pre_push_shim_honors_bypass "expected exit 0, got $code: $out"
elif grep -q 'STUB_RUNNER invoked' "$log"; then
  no pre_push_shim_honors_bypass "the bypass was set but a backend was still invoked"
else
  ok pre_push_shim_honors_bypass
fi

# pre_push_shim_bypass_survives_uninitialized_submodule
# The bypass exists for the case where the gate cannot run; an absent submodule
# is that case, so the check must come before the runner-existence check.
repo="$(new_repo bypass-missing none)"
out=$(cd "$repo" && SKIP_R2_REVIEW=1 bash .githooks/pre-push 2>&1); code=$?
if [ "$code" -ne 0 ]; then
  no pre_push_shim_bypass_survives_uninitialized_submodule "expected exit 0, got $code: $out"
else
  ok pre_push_shim_bypass_survives_uninitialized_submodule
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
