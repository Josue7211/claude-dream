#!/usr/bin/env node
// autodream-tracker.js — tracks sessions and signals when it's time to dream
//
// Runs as a SessionStart hook. Increments session count and checks if
// enough sessions or time have passed since the last dream.
// When thresholds are met, writes a flag file that gets picked up
// as a reminder in the next session's context.

const fs = require('fs');
const path = require('path');

const STATE_FILE = path.join(process.env.HOME, '.claude', 'autodream-state.json');
const FLAG_FILE = path.join(process.env.HOME, '.claude', 'autodream-due.flag');

const DEFAULTS = {
  minSessions: 5,
  minHours: 24,
  scope: 'all',
  enabled: true,
  lastDream: new Date().toISOString(),
  sessionsSinceLastDream: 0
};

function loadState() {
  try {
    return { ...DEFAULTS, ...JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')) };
  } catch {
    return { ...DEFAULTS };
  }
}

function saveState(state) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

const state = loadState();

if (!state.enabled) process.exit(0);

// Increment session counter
state.sessionsSinceLastDream++;
saveState(state);

// Check if dream is due
const hoursSinceLastDream = (Date.now() - new Date(state.lastDream).getTime()) / (1000 * 60 * 60);
const sessionsDue = state.sessionsSinceLastDream >= state.minSessions;
const timeDue = hoursSinceLastDream >= state.minHours;

if (sessionsDue && timeDue) {
  // Write flag file — Claude's rules/instructions can check for this
  fs.writeFileSync(FLAG_FILE, JSON.stringify({
    reason: `${state.sessionsSinceLastDream} sessions, ${Math.round(hoursSinceLastDream)}h since last dream`,
    scope: state.scope,
    due_since: new Date().toISOString()
  }));
}
