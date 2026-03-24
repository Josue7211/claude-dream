#!/usr/bin/env bash
# Called by /dream after a successful consolidation to reset the autodream counter
STATE_FILE="$HOME/.claude/autodream-state.json"
FLAG_FILE="$HOME/.claude/autodream-due.flag"

# Reset counter and update last dream time
if [[ -f "$STATE_FILE" ]]; then
  python3 -c "
import json
with open('$STATE_FILE') as f: s = json.load(f)
s['sessionsSinceLastDream'] = 0
s['lastDream'] = __import__('datetime').datetime.utcnow().isoformat() + 'Z'
with open('$STATE_FILE', 'w') as f: json.dump(s, f, indent=2)
"
fi

# Remove the flag
rm -f "$FLAG_FILE"
echo "Autodream counter reset."
