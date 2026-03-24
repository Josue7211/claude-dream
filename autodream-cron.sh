#!/usr/bin/env bash
# autodream-cron.sh — runs as a cron job, checks thresholds, dreams if due
# Cron entry: 0 3 * * * $HOME/.claude/hooks/autodream-cron.sh >> $HOME/.claude/dream-cron.log 2>&1

set -euo pipefail

STATE_FILE="$HOME/.claude/autodream-state.json"
FLAG_FILE="$HOME/.claude/autodream-due.flag"
LOG_FILE="$HOME/.claude/dream-cron.log"

echo "$(date '+%Y-%m-%d %H:%M') — autodream cron check"

# SAFETY: Don't run if user is actively working
if pgrep -f "claude" | grep -v "$$" | grep -qv "autodream"; then
  echo "  SKIPPED: Active Claude session detected."
  exit 0
fi

idle_ms=$(xprintidle 2>/dev/null || echo "999999999")
if [[ $((idle_ms / 60000)) -lt 30 ]]; then
  echo "  SKIPPED: User active (idle $((idle_ms/60000))m)."
  exit 0
fi

# Check if enabled
if ! python3 -c "import json; s=json.load(open('$STATE_FILE')); exit(0 if s.get('enabled') else 1)" 2>/dev/null; then
  echo "  autodream disabled. Skipping."
  exit 0
fi

# Check thresholds
SHOULD_DREAM=$(python3 -c "
import json
from datetime import datetime, timezone
s = json.load(open('$STATE_FILE'))
hours = (datetime.now(timezone.utc) - datetime.fromisoformat(s['lastDream'].replace('Z','+00:00'))).total_seconds() / 3600
sessions = s.get('sessionsSinceLastDream', 0)
min_h = s.get('minHours', 24)
min_s = s.get('minSessions', 5)
print('yes' if sessions >= min_s and hours >= min_h else 'no')
print(f'  sessions={sessions}/{min_s} hours={hours:.1f}/{min_h}')
")

echo "$SHOULD_DREAM"

if echo "$SHOULD_DREAM" | head -1 | grep -q "yes"; then
  echo "  Thresholds met. Running /dream all..."

  # Run claude in non-interactive mode with the dream prompt
  claude -p "Run /dream all. Consolidate memories across all projects: delete duplicates with rules, merge cross-project patterns, anchor relative dates, flag stale memories, update indexes. After completion run: bash ~/.claude/hooks/autodream-reset.sh" \
    --allowedTools "Read,Write,Edit,Glob,Grep,Bash" \
    --model claude-sonnet-4-6 \
    2>&1 | tail -20

  echo "  Dream complete."
else
  echo "  Thresholds not met. Skipping."
fi

# Trim log to last 200 lines
if [[ -f "$LOG_FILE" ]] && [[ $(wc -l < "$LOG_FILE") -gt 200 ]]; then
  tail -100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
