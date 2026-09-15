#!/usr/bin/env bash
# Launch TDM windowed, no map, skip intros. Wait for session init, screenshot, stop.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GAME="$ROOT/darkmod"
BIN="$GAME/TheDarkMod.app/Contents/MacOS/TheDarkMod"
if [[ ! -x "$BIN" ]]; then
	BIN="$GAME/thedarkmod.arm64"
fi
STAMP="${1:-capture}"
AUDIT="$ROOT/.audit"
LOG="$AUDIT/${STAMP}.log"
SHOT="$AUDIT/${STAMP}.png"
BOUNDS="$AUDIT/${STAMP}_bounds.txt"
QCON="$GAME/fms/qconsole.log"

test -x "$BIN"
mkdir -p "$AUDIT"

# Exact-name only. Never pkill -f.
for name in TheDarkMod thedarkmod.arm64; do
	if pgrep -x "$name" >/dev/null; then
		pkill -x "$name" || true
		sleep 1
	fi
	if pgrep -x "$name" >/dev/null; then
		echo "FAILED: leftover $name" >&2
		exit 1
	fi
done

: >"$LOG"
rm -f "$SHOT" "$BOUNDS"
# Truncate so we don't match a previous run's "session initialized".
: >"$QCON"
cd "$GAME"
"$BIN" \
	+set com_smp 0 \
	+set r_fullscreen 0 \
	+set r_glCoreProfile 2 \
	+set com_skipIntroVideos 1 \
	+set com_allowConsole 1 \
	>"$LOG" 2>&1 &
PID=$!

cleanup() {
	if kill -0 "$PID" 2>/dev/null; then
		kill -TERM "$PID" 2>/dev/null || true
		for _ in 1 2 3 4 5; do
			kill -0 "$PID" 2>/dev/null || break
			sleep 0.4
		done
		kill -KILL "$PID" 2>/dev/null || true
		wait "$PID" 2>/dev/null || true
	fi
}
trap cleanup EXIT

ready() {
	grep -q "session initialized" "$QCON" 2>/dev/null && return 0
	grep -q "session initialized" "$LOG" 2>/dev/null && return 0
	return 1
}

ok=0
for i in $(seq 1 90); do
	if ! kill -0 "$PID" 2>/dev/null; then
		echo "FAILED: process died before session init" >&2
		tail -40 "$LOG" >&2
		exit 1
	fi
	if ready; then
		ok=1
		break
	fi
	sleep 1
done
if [[ "$ok" != 1 ]]; then
	echo "FAILED: no session initialized after 90s" >&2
	tail -40 "$LOG" >&2
	tail -40 "$QCON" >&2 || true
	exit 1
fi
sleep 5

osascript <<'APPLESCRIPT' >"$BOUNDS" 2>/dev/null || true
tell application "System Events"
	set procs to (every process whose unix id is (do shell script "pgrep -x thedarkmod.arm64 | head -1"))
	if (count of procs) is 0 then
		return "windows=0"
	end if
	set p to item 1 of procs
	set frontmost of p to true
	set wins to windows of p
	set out to "windows=" & (count of wins) & linefeed
	repeat with w in wins
		set out to out & "title=" & (name of w) & " pos=" & ((position of w) as text) & " size=" & ((size of w) as text) & linefeed
	end repeat
	return out
end tell
APPLESCRIPT

if ! screencapture -x "$SHOT" 2>"$AUDIT/${STAMP}_screencapture.err"; then
	echo "FAILED: screencapture" >&2
	cat "$AUDIT/${STAMP}_screencapture.err" >&2
	exit 1
fi
if [[ ! -s "$SHOT" ]]; then
	echo "FAILED: empty screenshot" >&2
	exit 1
fi

echo "pid=$PID"
echo "log=$LOG"
echo "shot=$SHOT"
echo "bounds=$(tr '\n' ' ' <"$BOUNDS" 2>/dev/null || true)"
grep -E "GLFW |Initializing OpenGL|session initialized|MODE:|vidWidth|framebuffer|Failed|Fatal" "$LOG" || true
if [[ -f "$QCON" ]]; then
	grep -E "GLFW |MODE:|session initialized|map |Training" "$QCON" | tail -20 || true
fi
echo "DONE"
