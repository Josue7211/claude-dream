---
name: autodream
description: "Configure automatic memory consolidation (auto-dream). Sets up a scheduled trigger or hook that periodically runs /dream to consolidate memories — mimicking Anthropic's unreleased auto-dream feature. Use when the user says 'autodream', 'auto dream', 'automatic memory consolidation', 'schedule dreaming', 'dream on a schedule', 'set up auto dream', or wants memories to consolidate automatically without manual /dream invocations."
---

# Autodream: Automatic Memory Consolidation

Autodream replicates Anthropic's unreleased auto-dream feature — it runs `/dream` automatically so the user never has to remember to consolidate manually.

## How It Works

Autodream uses Claude Code's **scheduled triggers** (remote agents on a cron schedule) to periodically run dream consolidation. The official unreleased feature uses these defaults:

| Parameter | Default | Meaning |
|---|---|---|
| `minHours` | 24 | Minimum hours between dream runs |
| `minSessions` | 5 | Minimum sessions since last dream before triggering |

## Setup Flow

When the user invokes `/autodream`, walk them through configuration:

### 1. Choose scope

Ask which memories to auto-consolidate:

- **project** — only the current project's memory (most common)
- **user** — user-level memory at `~/.claude/projects/-home-<username>/memory/`
- **all** — every project's memory (thorough but token-heavy)

Default: `project`

### 2. Choose frequency

Suggest sensible defaults based on their usage:

- **Daily** (recommended for active projects) — runs once per day
- **Weekly** — runs every Sunday night
- **Custom** — let them specify a cron expression

Default: `daily`

### 3. Create the scheduled trigger

Use the `/schedule` skill to create a remote trigger. The trigger should run a claude session with:

```
claude -p "Run /dream <scope>. Consolidate memories, prune stale entries, merge duplicates. Be thorough but concise." --allowedTools "Read,Write,Edit,Glob,Grep,Bash(ls:*),Bash(grep:*),Bash(cat:*)" --project-dir <project-dir>
```

Map frequency to cron:
- Daily: `0 3 * * *` (3 AM)
- Weekly: `0 3 * * 0` (Sunday 3 AM)
- Custom: whatever they specify

### 4. Create tracking file

Create `~/.claude/autodream-state.json` to track when dreams last ran:

```json
{
  "lastDream": "2026-03-24T03:00:00Z",
  "sessionsSinceLastDream": 0,
  "scope": "project",
  "frequency": "daily",
  "triggerId": "<the-trigger-id>"
}
```

### 5. Confirm setup

Tell the user:
- What was configured
- When the first auto-dream will run
- How to check status: `/autodream status`
- How to disable: `/autodream off`
- How to run immediately: `/dream <scope>`

## Subcommands

Parse the user's input for these variations:

| Input | Action |
|---|---|
| `/autodream` | Run setup flow (or show status if already configured) |
| `/autodream on` | Enable autodream (run setup if not configured) |
| `/autodream off` | Disable the scheduled trigger, keep config |
| `/autodream status` | Show last dream time, sessions since, next scheduled run |
| `/autodream now` | Trigger an immediate dream run (equivalent to `/dream` with configured scope) |
| `/autodream config` | Re-run setup to change scope or frequency |

## If Scheduled Triggers Are Unavailable

If the user's environment doesn't support scheduled triggers (no `/schedule` skill, no remote agent capability), fall back to a **hook-based approach**:

1. Create a `PostSessionEnd` hook in settings.json that increments a session counter
2. When the counter reaches the threshold (default 5), the hook appends a flag file
3. On next session start, an `InstructionsLoaded` hook checks the flag and reminds Claude to run `/dream`

This is less automatic but still reduces the burden of remembering to consolidate.

## Important Notes

- Auto-dream is a convenience layer over `/dream` — it doesn't change what dream does, just when it runs
- Token cost: each dream run uses ~5-15k tokens depending on memory size. Daily runs for one project are cheap. `/dream all` across 20 projects is heavier — suggest weekly for `all` scope
- The user can always run `/dream` manually regardless of autodream config
