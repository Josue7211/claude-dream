---
name: dream
description: "Memory consolidation — a reflective pass over memory files that synthesizes recent learnings into durable, well-organized memories. Supports 3 scopes: /dream (current project), /dream user (user-level memories), /dream all (every project). Use this skill whenever the user says 'dream', 'consolidate memory', 'clean up memories', 'organize memories', 'prune memory', 'memory maintenance', or any variation. Also trigger when memory files are bloated, duplicated, or stale."
---

# Dream: Memory Consolidation

You are performing a **dream** — a reflective pass over memory files. Like how the brain reorganizes during sleep: strengthen what matters, prune noise, merge fragments, resolve contradictions, and surface patterns that should become permanent knowledge.

Dreams are how memory stays useful instead of becoming a junk drawer. Without periodic consolidation, auto-memory accumulates scattered notes that contradict each other, duplicate information, or reference things that no longer exist. Research shows redundant context makes agents *worse* — fewer, higher-quality memories beat more, noisier ones.

## Determine Scope

Parse the user's invocation to determine scope. Default to `project` if no scope is specified.

| Invocation | Scope | What gets consolidated |
|---|---|---|
| `/dream` | `project` | Memory for the **current working directory's project** only |
| `/dream user` | `user` | The **user-level memory** at `~/.claude/projects/-home-<username>/memory/` |
| `/dream all` | `all` | **Every project's memory** under `~/.claude/projects/*/memory/` |

### Resolving paths

- **Project scope**: Find the current project's memory directory. It lives at `~/.claude/projects/<project-key>/memory/` where `<project-key>` is derived from the working directory path with `/` replaced by `-`. Run `ls ~/.claude/projects/` and match against the current working directory to find it. Session transcripts (JSONL files) live in the parent of the memory directory: `~/.claude/projects/<project-key>/*.jsonl`.
- **User scope**: The user-level memory is the project entry for the home directory — typically `~/.claude/projects/-home-<username>/memory/`. Transcripts are at `~/.claude/projects/-home-<username>/*.jsonl`.
- **All scope**: Iterate over every directory in `~/.claude/projects/` that contains a `memory/` subdirectory. Process each one independently, then give a combined summary.

---

## Phase 1 — Orient

Before changing anything, understand what already exists.

1. `ls` the memory directory to see all files
2. Read `MEMORY.md` (the index) to understand current structure
3. Skim each existing topic file — read enough to know what it covers so you improve rather than duplicate
4. Note any `.tmp` files (these are crashed writes — check if they contain useful content, then clean up)
5. Read all rules files in `~/.claude/rules/` and `~/.claude/CLAUDE.md` — these are the **authority**. Any memory that restates a rule is redundant.

## Phase 2 — Gather Recent Signal

Look for new information worth persisting. Sources in priority order:

1. **Session transcripts** — grep the JSONL files for narrow, specific terms. These files are large — never read them whole. Use targeted searches:
   ```bash
   grep -rn "<narrow term>" ~/.claude/projects/<key>/*.jsonl | tail -30
   ```
   Look for: corrections the user made, preferences expressed, architecture decisions, debugging breakthroughs, workflow patterns.

2. **Stale memories** — facts in memory files that contradict the current codebase or recent sessions. If a memory says "we use Express" but the project moved to Hono, fix it.

3. **Duplicate signals** — two or more memory files covering the same topic from different sessions. Merge them.

Don't exhaustively read transcripts. Search only for things you suspect matter based on the Orient phase.

## Phase 3 — Consolidate

For each thing worth remembering, write or update a memory file. Follow the auto-memory conventions from your system prompt — they are the source of truth for types, frontmatter format, and what NOT to save.

**Do:**
- Merge new signal into existing topic files rather than creating near-duplicates
- **Time anchoring** — time is linear, memories must reflect that. Convert ALL relative time references to absolute dates:
  - "yesterday" → the actual date
  - "next Friday" → the actual date
  - "last week" → "week of YYYY-MM-DD"
  - "in a few days" → "around YYYY-MM-DD"
  - "after the release" → "after vX.Y.Z release (YYYY-MM-DD)"

  A memory that says "next Friday" is permanently wrong after that Friday passes. A memory that says "2026-03-28" is always correct. When dreaming, scan every memory for relative time words (`today`, `tomorrow`, `yesterday`, `next`, `last`, `soon`, `later`, `recently`, `just`, `this week`, `this month`) and resolve them against the memory file's modification date or the transcript timestamp where they originated.
- Delete contradicted facts at the source — don't just add a correction alongside the old info
- Remove memories that duplicate what's already in CLAUDE.md or .claude/rules/ files
- Clean up `.tmp` files after extracting any useful content

**Don't:**
- Create memories for things derivable from code, git history, or existing docs
- Save ephemeral task details or conversation-specific context
- Add memories that are just restating what CLAUDE.md already says

## Phase 4 — Prune and Index

Update `MEMORY.md` so it stays under **200 lines**. It is an **index**, not a dump.

- Each entry: a markdown link to the memory file + a one-line description
- Remove pointers to memories that are stale, wrong, or superseded
- Add pointers to newly created or significantly updated memories
- If two files disagree, fix the wrong one — don't leave contradictions
- Group entries semantically by topic, not chronologically

## Phase 5 — Auto-Promote to Rules

This is the learning phase — patterns in project memories that should become permanent rules.

**Only runs on `all` scope.** After processing every project, look across ALL projects for feedback patterns:

1. Collect every remaining `feedback_*.md` file across all projects
2. Group by theme — if 3+ projects have feedback about the same behavior, it's a pattern
3. For each pattern found: **create a new rule file** in `~/.claude/rules/` that captures it, then delete the individual project feedback files that are now covered
4. Present new rules to the user before writing — format:
   ```
   PROMOTE TO RULE: <rule-name>.md
   Pattern found in: project-a, project-b, project-c
   Rule content: <draft>
   ```

The goal: corrections the user makes once should stick everywhere forever. If the user corrects the same behavior in 3 different projects, that's not a project preference — that's a universal rule.

## Phase 6 — Staleness Detection

Memories reference files, functions, features, and URLs. Check if they still exist.

For each memory that names a specific file path, function, or feature:
1. **File paths**: `ls` or `stat` the path — if it doesn't exist, flag the memory as potentially stale
2. **Project features**: If a memory says "feature X needs fixing" — grep the codebase to see if X still exists or was already fixed
3. **Completed work**: If a memory says "TODO: implement Y" and Y is clearly done — delete it

Don't delete aggressively — **flag** stale memories in the output so the user can decide. Only auto-delete memories about completed TODOs or features that were removed.

## Phase 7 — Cross-Project Merge

Detect duplicate project directories that represent the same project accessed from different paths.

Common patterns:
- `-home-<YOUR_USER>-Documents-projects-<name>` and `-mnt-storage-projects-<name>` (local vs NFS)
- `-mnt-storage-projects-Music` and `-mnt-storage-projects-music` (case difference)

For each detected pair:
1. Read both MEMORY.md indexes
2. Identify memories unique to each vs shared
3. **Report** which dirs are duplicates and what unique info each has — don't auto-merge without user confirmation, since this involves deleting entire directories

## Phase 8 — Missed Signal Detection

Scan recent session transcripts for corrections that were NEVER saved as memories.

Search transcripts for patterns that indicate user frustration or correction:
```bash
grep -i "don't\|stop\|wrong\|no not\|I said\|already told\|how many times" ~/.claude/projects/<key>/*.jsonl | tail -20
```

For each correction found that has NO corresponding memory or rule:
- Note it in the dream log
- Suggest whether it should become a memory or a rule

This catches the feedback that fell through the cracks — things the user said once and Claude forgot.

## Phase 9 — Dream Log

Append a summary of this dream run to `~/.claude/dream-log.md`. This tracks consolidation over time.

Format:
```markdown
## YYYY-MM-DD HH:MM — /dream <scope>

**Deleted:** X files (redundant with rules)
**Kept:** Y files
**Promoted to rules:** Z (list new rule names)
**Stale flagged:** N files
**Duplicate projects detected:** (list pairs)
**Missed signals found:** M corrections
**Cross-project patterns:** (any new patterns found)
```

Keep the log under 100 lines — when it exceeds, summarize older entries into a single "prior history" line.

## Phase 10 — Reset Autodream Counter

After a successful dream run, reset the autodream session counter so the next dream isn't triggered immediately:

```bash
bash ~/.claude/hooks/autodream-reset.sh
```

This clears the flag file and resets `sessionsSinceLastDream` to 0 in `~/.claude/autodream-state.json`.

---

## Output

Return a summary organized by phase:
1. **Cleanup** — files deleted, merged, or updated
2. **Promotions** — feedback promoted to rules (or suggested)
3. **Stale** — memories flagged as potentially outdated
4. **Duplicates** — project directory pairs detected
5. **Missed** — corrections found in transcripts without corresponding memories
6. **Trends** — comparison to last dream run if dream-log.md exists

For `all` scope, give a per-project summary, then the cross-project analysis.
