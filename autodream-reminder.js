#!/usr/bin/env node
// autodream-reminder.js — checks if dream is due and injects a reminder
//
// Runs as a SessionStart hook AFTER autodream-tracker.js.
// If the flag file exists, outputs a reminder that Claude will see.

const fs = require('fs');
const path = require('path');

const FLAG_FILE = path.join(process.env.HOME, '.claude', 'autodream-due.flag');

try {
  if (fs.existsSync(FLAG_FILE)) {
    const flag = JSON.parse(fs.readFileSync(FLAG_FILE, 'utf8'));
    // Output goes to stderr which Claude sees as hook output
    console.error(`[autodream] Memory consolidation is due (${flag.reason}). Run /dream ${flag.scope} to consolidate.`);
  }
} catch {
  // Silent — don't break session start
}
