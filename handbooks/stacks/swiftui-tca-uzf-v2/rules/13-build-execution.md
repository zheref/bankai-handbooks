<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 13 — Build Execution & Hung-clang Recovery

Operational canon discovered on the iOS reference product for the SwiftUI/Xcode stack. This toolchain
periodically hangs inside `clang` mid-build — a known interaction between this Xcode
version, the simulator runtime, and macOS. There is **no configuration fix to
chase**; the response is mechanical: detect the stall, kill the stuck `clang`, let
the build finish on its own. Two things never change: **never wait out a stalled
compile**, and **never ask the user to wait**.

The interactive-vs-headless execution-context principle below is universal (it also
lives in the Bankai builder prompts `dev-build` / `roy-build`); the Xcode/clang
specifics are stack-owned here.

## Repo-specific placeholders

| Token | Illustrative example |
| --- | --- |
| `{{XCODEPROJ}}` | `Acme.xcodeproj` |
| `{{SCHEME}}` | `Acme` |
| `{{SNAPSHOT_DEVICE}}` | `iPhone 17 Pro` |
| `{{SNAPSHOT_OS}}` | `26.5` |
| `{{BUILD_LOG}}` | `/tmp/acme-build.log` |

## FIRST — which execution context are you in?

How you run a build depends entirely on **how you were invoked**. Decide this before
you build anything.

### Interactive session (local Claude Code, human present)

You have the full harness — `run_in_background`, `Monitor`, `ScheduleWakeup`. A
foreground multi-minute build freezes the chat, so background it and monitor (see
**Interactive pattern**). This is the ONLY context where the background + wakeup
pattern is allowed.

### Headless / CI run (a Bankai builder — Edward / Alphonse / Roy via `claude-code-action`)

**You are a single, one-shot, NON-RESUMABLE invocation.** `ScheduleWakeup`,
`Monitor`, and `run_in_background`-and-resume **do not work** — nothing re-invokes
you. The moment your turn ends, the **job ends**, and anything you have not pushed (a
local branch, an unopened PR) is **lost** (this is the `CON-20` provenance concern:
new content must arrive as a real pushed commit). So you MUST run the build
**synchronously** and finish the whole task — branch, commit, push, open the PR — **in
this one turn**. Use the **Headless pattern**: a single blocking command that runs
`xcodebuild` in the foreground with an in-turn watchdog that handles the clang hang
for you. **NEVER background a build and end your turn expecting to resume** — that is
exactly how a build gets stranded with nothing pushed.

> How to tell: if `$CI` or a GitHub Actions environment is set, or you were launched
> by `claude-code-action`, you are **headless**. When in doubt, assume headless and
> run foreground.

## The 3-minute budget — compile vs. test

The budget applies to the **compile phase** of an `xcodebuild` invocation, not the
whole run.

| Phase | Looks like in logs | Budget |
| --- | --- | --- |
| Compile (`xcodebuild … build`) | `SwiftCompile …`, `CompileC …`, `Ld …`, no `Test Case` lines yet | **3 minutes** — exceed it and assume clang is hung. |
| Test execution (`xcodebuild … test`) | `Test Suite '…' started`, `Test Case …`, `assertSnapshot` | Untimed — tests take as long as they need. |
| `simctl diagnose` (post-test) | `IDETestOperationsObserverDebug: …`, `simctl diagnose … --timeout=600` | Up to **10 minutes** after a test fails. Wait it out; don't kill. |

If you can see test cases running, the compile is done and the 3-minute budget no
longer applies. Only `SwiftCompile`/`CompileC` (or no output) means it's still
compiling.

## Symptom checklist — when to assume clang is stuck

The kill is justified only once **BOTH** hold:

1. **Total compile time is past 3 minutes** (elapsed since `xcodebuild` started,
   still in the compile phase), **and**
2. **No new build output for ~1 minute** — the log has stopped growing (or `ps aux |
   grep clang` shows `clang … -c /dev/null` capability-probe processes that should
   finish in milliseconds but are hanging).

Never act on the quiet-log signal alone: early in a build the compile can
legitimately go quiet for a stretch. The elapsed-3-minutes gate is what tells a hung
clang apart from a healthy-but-quiet compile.

## Recovery — the kill (both contexts)

```bash
# Stage 1 — scoped kill, the textbook stuck case (leaves other clang/clangd alone):
pkill -9 -f 'clang.*-c /dev/null'
# Stage 2 — ONLY if a prior scoped kill didn't unstick it: the broad kill.
pkill -9 clang
```

`xcodebuild` auto-respawns `clang` and continues within seconds. **Never kill
`xcodebuild` itself** — that loses all in-progress compilation. The broad `pkill -9
clang` is unscoped (it hits every clang/clangd for the user), so it is a **second
stage** only, never the first swing and never run just because the scoped pattern
matched nothing.

## Headless pattern (CI builders) — foreground build + in-turn watchdog

One **blocking** Bash call. `xcodebuild` runs in a shell subprocess; a watchdog **in
the same command** enforces the two-part budget above and then `wait`s for the build.
Everything completes inside this single tool invocation — no harness backgrounding, no
`ScheduleWakeup`, nothing to resume. Run this in the FOREGROUND (do NOT set
`run_in_background`):

```bash
set -o pipefail
LOG={{BUILD_LOG}}; : > "$LOG"
xcodebuild -project {{XCODEPROJ}} -scheme {{SCHEME}} \
    -destination 'platform=iOS Simulator,name={{SNAPSHOT_DEVICE}}' \
    -configuration Debug build > "$LOG" 2>&1 &
build_pid=$!
start=$(date +%s); last=0; quiet=0; scoped_tried=0
while kill -0 "$build_pid" 2>/dev/null; do
  sleep 20
  # Past the compile phase (tests running or build finished)? stop watching for clang.
  grep -qE 'Test Case|\*\* BUILD (SUCCEEDED|FAILED)' "$LOG" && continue
  elapsed=$(( $(date +%s) - start ))
  size=$(wc -c < "$LOG" 2>/dev/null || echo 0)
  if [ "$size" -eq "$last" ]; then quiet=$((quiet + 20)); else quiet=0; last=$size; scoped_tried=0; fi
  # Act ONLY when BOTH hold: past the 3-minute budget AND ~60s with no new output.
  if [ "$elapsed" -ge 180 ] && [ "$quiet" -ge 60 ]; then
    if [ "$scoped_tried" -eq 0 ]; then
      pkill -9 -f 'clang.*-c /dev/null' 2>/dev/null || true   # stage 1: scoped
      scoped_tried=1
    else
      pkill -9 clang 2>/dev/null || true                      # stage 2: broad, only after scoped didn't help
    fi
    quiet=0
  fi
done
wait "$build_pid"; rc=$?
tail -20 "$LOG"
exit "$rc"
```

The `&` + `wait` here is **shell-level** backgrounding inside ONE agent tool call —
the call blocks until the build finishes, so from your turn's perspective it is fully
synchronous. That is the whole point: no work is deferred past the end of your turn.
For `xcodebuild … test`, use the same wrapper (the watchdog stops once `Test Case`
lines appear).

## Interactive pattern (local session only) — background + monitor + wakeup

Only in a live local session with the human present. Background the build via the
harness's `run_in_background: true` so monitoring stays possible, pair it with a
`Monitor` on the log for `** BUILD SUCCEEDED **` / `** BUILD FAILED **` / `error:`,
and — because the hung-clang case doesn't naturally complete — combine it with a
**`ScheduleWakeup` at delaySeconds: 240** as the safety net; on wakeup, if the compile
is past 3 minutes and quiet, run the recovery. **Do not use this pattern in a headless
CI run** — see the context rule above.

## What NOT to do

- Don't cancel/`kill` the parent `xcodebuild`.
- Don't sleep-poll waiting the hang out; it doesn't self-resolve on this machine.
- Don't `pkill clang` before the 3-minute compile budget is exceeded — a healthy
  compile can be briefly quiet; the elapsed gate is what prevents killing it. And
  prefer the scoped form; the broad `pkill -9 clang` is a second-stage escalation,
  not a first swing.
- **Don't background a build + `ScheduleWakeup` in a headless/CI run** and end your
  turn — the run never resumes and your branch is never pushed.
- Don't ask the user; this recovery recipe is the agreed, recorded canon for this
  stack. Ask only if a stage-2 `pkill -9 clang` still doesn't unstick the build.

## Cross-references

- [10-migration.md](10-migration.md) — the CI lint workflow this build feeds.
- [14-github-version-control.md](14-github-version-control.md) — monitoring CI to a
  verdict after a push (`CON-19` build-gate).
- **CON-19** — integration branches stay buildable: the build/test CI must actually
  run and pass on every child PR before merge.
