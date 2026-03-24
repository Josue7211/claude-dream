# claude-dream

Memory consolidation skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — replicate Anthropic's unreleased `/dream` and `/autodream` features.

## What is this?

Claude Code's auto-memory saves notes as you work, but over time those notes become a mess: duplicates, contradictions, stale references, scattered fragments. Sound familiar? It's the same problem your brain solves every night during sleep — consolidating short-term memories into long-term knowledge, pruning what doesn't matter, strengthening what does.

**`/dream` is sleep for Claude's memory.**

Anthropic has an unreleased auto-dream feature in Claude Code's codebase. These skills replicate it today using Claude Code's existing skill and hook system.

### Why bother?

Research on LLM context management shows that **redundant and contradictory context degrades agent performance**. Fewer, higher-quality memories beat more, noisier ones. A context file full of duplicated notes from 30 sessions is actively worse than a clean, consolidated set of 10 well-organized memories. Dream fixes this.

## Skills

### `/dream` — Manual Memory Consolidation

A 10-phase reflective pass over memory files:

| Phase | What it does |
|---|---|
| **1. Orient** | Read all existing memory files and rules to understand current state |
| **2. Gather** | Search session transcripts for corrections, preferences, decisions worth saving |
| **3. Consolidate** | Merge duplicates, resolve contradictions, anchor relative dates to absolute dates |
| **4. Prune & Index** | Update MEMORY.md index, keep it under 200 lines |
| **5. Auto-Promote** | Detect feedback patterns across 3+ projects → promote to permanent rules |
| **6. Staleness** | Check if referenced files/functions/features still exist in the codebase |
| **7. Cross-Project Merge** | Detect duplicate project dirs (same project accessed from different paths) |
| **8. Missed Signals** | Find user corrections in transcripts that were never saved as memories |
| **9. Dream Log** | Append a summary to `~/.claude/dream-log.md` for tracking over time |
| **10. Reset** | Reset the autodream counter so the next auto-dream isn't triggered immediately |

**Scopes:**
- `/dream` — current project only
- `/dream user` — user-level memories
- `/dream all` — every project (includes cross-project analysis)

### `/autodream` — Automatic Consolidation

Runs `/dream` automatically so you never have to remember. Two modes:

**Scheduled triggers** (preferred): Uses Claude Code's remote agent cron to run dreams at 3 AM daily/weekly.

**Hook-based fallback**: If scheduled triggers aren't available, uses Claude Code hooks to:
1. Track session count (PostSessionEnd hook)
2. Check thresholds on session start (SessionStart hook)
3. Remind Claude to run `/dream` when thresholds are met

Default thresholds (matching Anthropic's unreleased defaults):
- **minSessions**: 5 sessions since last dream
- **minHours**: 24 hours since last dream

Both must be met before a dream triggers.

## Files

```
dream-SKILL.md          # /dream skill definition (copy to ~/.claude/skills/dream/SKILL.md)
autodream-SKILL.md      # /autodream skill definition (copy to ~/.claude/skills/autodream/SKILL.md)
autodream-tracker.js    # SessionStart hook — increments counter, checks thresholds
autodream-reminder.js   # SessionStart hook — shows reminder if dream is due
autodream-cron.sh       # Cron script — runs dream non-interactively at scheduled times
autodream-reset.sh      # Resets session counter after a successful dream
```

## Installation

### 1. Copy skill files

```bash
mkdir -p ~/.claude/skills/dream ~/.claude/skills/autodream
cp dream-SKILL.md ~/.claude/skills/dream/SKILL.md
cp autodream-SKILL.md ~/.claude/skills/autodream/SKILL.md
```

### 2. Copy hook files

```bash
mkdir -p ~/.claude/hooks
cp autodream-tracker.js ~/.claude/hooks/
cp autodream-reminder.js ~/.claude/hooks/
cp autodream-cron.sh ~/.claude/hooks/
cp autodream-reset.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/autodream-cron.sh ~/.claude/hooks/autodream-reset.sh
```

### 3. Configure hooks in settings.json

Add the hooks to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "node ~/.claude/hooks/autodream-tracker.js"
          },
          {
            "type": "command",
            "command": "node ~/.claude/hooks/autodream-reminder.js"
          }
        ]
      }
    ]
  }
}
```

### 4. (Optional) Set up cron for fully automatic dreams

```bash
# Edit your crontab
crontab -e

# Add this line (runs at 3 AM daily):
0 3 * * * $HOME/.claude/hooks/autodream-cron.sh >> $HOME/.claude/dream-cron.log 2>&1
```

### 5. Initialize state

```bash
cat > ~/.claude/autodream-state.json << 'EOF'
{
  "lastDream": "1970-01-01T00:00:00Z",
  "sessionsSinceLastDream": 0,
  "scope": "all",
  "frequency": "daily",
  "minSessions": 5,
  "minHours": 24,
  "enabled": true
}
EOF
```

### 6. Test it

Start a new Claude Code session and type `/dream` to run your first consolidation.

## How the sleep metaphor works

| Brain during sleep | Dream during consolidation |
|---|---|
| Replays important experiences | Searches session transcripts for corrections and decisions |
| Prunes weak synapses | Deletes memories that duplicate rules or reference deleted code |
| Strengthens repeated patterns | Promotes feedback that appears in 3+ projects to permanent rules |
| Consolidates short-term → long-term | Merges scattered session notes into organized topic files |
| Detects anomalies (nightmares) | Finds user corrections that were never saved as memories |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Node.js (for hook scripts)
- Python 3 (for cron script threshold checks)
- `xprintidle` (optional, for cron idle detection on Linux)

## License

MIT
