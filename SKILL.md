---
name: forge
description: Multiscale AI software factory. Use when the user wants to build a complete software application, create a new project from scratch, or says "forge" followed by a command. Decomposes projects into Epics, Features, and Atoms, then executes with AI workers using full vertical context.
---

# Forge - Multiscale AI Software Factory

> *From the macroscopic vision down to the atomic unit of work — then back up to working software.*

## What This Skill Does

Forge decomposes a software project across multiple scales (Project → Epics → Features → Atoms) then executes those atoms autonomously with AI workers. Planning is interactive (human answers questions), execution is autonomous (runs until done or paused).

## When to Use Forge

Activate when the user wants to:
- Build a complete software application
- Create a new project from scratch
- Says "build [something]" / "create [an app]" / "new project"
- Says "forge [command]" explicitly
- References an existing forge project

## Command Set

```bash
forge new                         # Start a new project (intake)
forge plan <horizon>              # Plan atoms for a time horizon ("5 hours", "3 days", "1 week")
forge status                      # Show current project status
forge approve                     # Approve current plan batch and begin execution
forge decide <id> <answer>        # Answer a pending decision
forge pause                       # Pause autonomous execution
forge resume                      # Resume autonomous execution
forge skip <atom-id>              # Skip a stuck atom
forge retry <atom-id>             # Retry a failed atom
forge history                     # Show what was done today
forge budget                      # Show remaining token capacity
```

## The Two Phases

### Phase 1: PLANNING (Interactive)

Human is actively involved. This is where all the thinking happens.

1. **Intake** — User describes what to build. Forge asks 3-5 clarifying questions.
2. **Decompose** — Project → Epics → Features (with human review at each level).
3. **Set horizon** — User says "plan for 24 hours" / "plan for a week" / etc.
4. **Feature clarification** — For each feature in the horizon batch, Forge asks clarifying questions. All questions are batched during planning, not during execution.
5. **Atom generation** — Once all questions are answered, atoms are created for every feature in the batch.
6. **Approve** — User reviews the full atom plan and approves once. This is the last required human touchpoint before execution begins.

### Phase 2: EXECUTION (Autonomous)

Human is hands-off. The system runs indefinitely until the batch is complete, paused, or blocked.

1. Workers churn through atoms sequentially (or parallel when independent).
2. Each atom: compile + unit test + commit.
3. Feature boundary: integration test gate, PR created.
4. Token window exhausted: Forge naps, sets cron to auto-resume when tokens refresh.
5. **Only interrupts human for genuine blockers** (worker failed twice, external issue, low-confidence atom needing clarification).
6. Runs until batch complete or user says `forge pause`.

## The Four Scales

1. **PROJECT** (1) — The macroscopic vision. "A recipe sharing app."
   - Human input: Goals, constraints, tech stack, MVP scope

2. **EPICS** (3-8) — Major structural segments. "Authentication System."
   - Human input: Priority, scope boundaries, integration points

3. **FEATURES** (3-6 per epic) — Individual capabilities. "Email/password login."
   - Human input: UX decisions, behavior, edge cases

4. **ATOMS** (3-10 per feature) — Smallest executable units. "Create users table."
   - Human input: Only if confidence gate triggers (see below)

### Context Stack

Every worker receives the full vertical context:
- project.md (what the app is)
- epic.md (how this system fits)
- feature.md (what this capability does)
- atom.md (exact task to implement)

## Confidence Gate (Pre-Flight Check)

Before spawning a worker for each atom, the orchestrator performs an introspection step:

### Scoring
Evaluate the atom against four dimensions:
1. **Project alignment** — How well does this atom connect to the project vision?
2. **Epic fit** — How well does it fit the epic's architecture and integration points?
3. **Feature coherence** — How well does it implement the feature specification?
4. **Implementation clarity** — How clear and unambiguous are the requirements?

Each dimension: HIGH (clear, no issues) / MEDIUM (minor gaps) / LOW (vague or conflicting)

### Decision
- **All HIGH** → Execute immediately. No human interruption.
- **Any MEDIUM, no LOW** → Execute, but add concerns as notes in the worker prompt. Log the concern.
- **Any LOW** → **STOP.** Ask the human clarifying questions. Update the atom plan with their answers. Re-score. Only execute when confidence is sufficient.

### Why This Matters
Even thorough planning misses things. The confidence gate catches vagueness at the last possible moment — before a worker wastes time on a poorly-scoped task. It only interrupts the human when it genuinely needs to, not as a formality.

## Horizon-Based Planning

Instead of planning all atoms upfront or one feature at a time, Forge plans in **time-horizon batches:**

### How It Works
1. User specifies: "plan for 24 hours" (or 5 hours, 3 days, 1 week, etc.)
2. Forge estimates capacity: ~8-12 atoms per 5-hour token window
3. Forge selects features that fit the horizon (in dependency order)
4. For each feature in the batch:
   a. Read the feature spec
   b. Ask clarifying questions (batched — all questions for all features presented together or in sequence)
   c. Generate atoms after answers received
5. Present complete atom plan for the batch
6. User approves once → execution begins autonomously

### Estimation
- Simple atom (create file, add config): ~5-10 min
- Medium atom (implement function + tests): ~10-20 min
- Complex atom (multi-file feature + integration): ~20-30 min
- Per 5-hour token window: ~8-12 atoms
- Per 24 hours (multiple windows): ~30-50 atoms
- Per week: ~150-250 atoms

## Execution Infrastructure

### Cron-Driven Orchestration
Forge execution is powered by a **cron job** that fires every 3 minutes. This is the core resilience mechanism:

- **Created automatically** when the user runs `forge approve` — not pre-installed
- **Survives compaction** — cron is OpenClaw infrastructure, not session state
- **Self-healing** — if the main session loses context, cron keeps dispatching workers
- **Reports to main** — uses `sessions_send` to push status updates back to the human's session

When implementing `forge approve`, create the cron with:
```
cron add:
  name: "forge-executor"
  schedule: { kind: "every", everyMs: 180000 }
  sessionTarget: "isolated"
  payload: { kind: "agentTurn", message: "<executor prompt>", timeoutSeconds: 420 }
```

The executor prompt must include:
1. The main session key (for `sessions_send` callbacks)
2. The project root path
3. The full execution state machine (steps below)
4. The atom execution order with completion status
5. Feature boundary map (which atom is last per feature)

When implementing `forge pause`, disable the cron. `forge resume` re-enables it.
When implementing `forge status`, read state.json and format a progress report.

### Cron Executor State Machine
Each cron tick follows this sequence:
1. **Read state.json** — ground truth for pipeline state
2. **Check status** — paused/awaiting-integration/rate-limited/executing
3. **Check active workers** — if worker running, exit quietly (no spam)
4. **Verify last atom** — check git log, update completedAtoms
5. **Feature boundary check** — if last atom of feature, run tests, notify main, pause for integration
6. **Determine next atom** — from queue, or completion if done
7. **Confidence gate** — score 4 dimensions, escalate LOW to human via main session
8. **Spawn worker** — sub-agent with full vertical context
9. **Status update** — brief progress line to main session

### Main Session Integration
The cron executor communicates with the human via `sessions_send` to the main session:
- **Progress updates**: After spawning each worker
- **Feature gates**: "Feature X complete, tests passing. Continue or test manually?"
- **Decision needed**: LOW confidence gate or worker failure
- **Completion**: All atoms done, project complete

The main session handles:
- `forge continue` / `forge approve` — resume after feature gate
- `forge decide <id> <answer>` — answer confidence gate questions
- `forge pause` / `forge resume` — manual pipeline control
- `forge status` — on-demand progress report

### Per-Atom Flow
```
CONFIDENCE GATE → SPAWN WORKER → BUILD → COMPILE → TEST → COMMIT → DONE
                                           ↓ fail      ↓ fail
                                        FIX (2x)    FIX (2x)
                                           ↓ still      ↓ still
                                        ESCALATE    ESCALATE
```

### Per-Feature Gate
After all atoms in a feature complete:
- Run full test suite
- Notify main session with results
- Set status to 'awaiting-integration'
- **Wait for human** to say `forge continue` or `forge skip-test`
- Human can optionally test manually before continuing

### Per-Epic Gate
After all features in an epic complete:
- Full build from clean state
- Cross-feature integration tests
- Summary report to human

### Token Budget Management
- Track token consumption per rolling 5-hour window
- When rate-limited: pause execution, set cron job to auto-resume when window resets
- Never start an atom that can't be completed in remaining budget
- Runs 24/7 with naps — not 9-to-5 with hard stops

## State Management

### Directory Structure
```
forge/projects/{project-id}/
├── project.md
├── state.json
├── epics/
│   ├── 01-{epic}/
│   │   ├── epic.md
│   │   ├── features/
│   │   │   ├── 01-{feature}/
│   │   │   │   ├── feature.md
│   │   │   │   ├── atoms/
│   │   │   │   │   ├── 001-{atom}.md
│   │   │   │   │   └── ...
│   │   │   │   └── report.md
│   │   │   └── ...
│   │   └── report.md
│   └── ...
└── reports/
    ├── daily/
    └── completion.md
```

### State JSON Schema
```jsonc
{
  "projectId": "measure-calc",
  "status": "executing",
  "created": "2026-02-17T10:00:00Z",
  "horizon": {
    "requested": "24 hours",
    "featuresPlanned": 9,
    "atomsPlanned": 22,
    "approvedAt": "2026-02-17T11:00:00Z"
  },
  "scales": {
    "project": "approved",
    "epics": { "total": 4, "approved": 4 },
    "features": { "total": 9, "planned": 9, "done": 3 },
    "atoms": { "total": 22, "done": 12, "running": 1, "failed": 0, "blocked": 0, "queued": 9 }
  },
  "currentWork": {
    "epic": "02-engine",
    "feature": "01-fraction-types",
    "atom": "003-add-subtract",
    "workerSession": "sub-abc123",
    "confidenceScore": { "project": "HIGH", "epic": "HIGH", "feature": "HIGH", "implementation": "HIGH" }
  },
  "tokenBudget": {
    "currentWindowStart": "2026-02-17T10:00:00Z",
    "estimatedTokensUsed": 850000,
    "rateLimited": false,
    "resumeAt": null
  },
  "git": {
    "repo": "/home/zavdielx/code/measure-calc",
    "baseBranch": "main",
    "forgeBranch": "forge/build"
  }
}
```

## Sub-Agent Orchestration

### Worker Sub-Agents
Spawned for each atom with:
- `prompts/worker.md` system prompt
- Context stack (project + epic + feature + atom files)
- Target repository path
- Timeout sized to atom complexity (10-30 min)

### Reviewer Sub-Agents
Spawned at feature integration gates with:
- `prompts/reviewer.md` system prompt
- All completed atom artifacts
- Test results

## Communication Patterns

### During Planning (interactive)
- Clarifying questions per feature
- Plan summary for approval
- Decision requests for ambiguous architecture choices

### During Execution (minimal interruption)
- Progress updates via cron (every 30-60 min or at milestones)
- Feature completion notifications with PR link
- **Only interrupt for:** confidence gate LOW scores, worker failures after 2 retries, external blockers

### Progress Update Format
```
🔥 Forge — Progress Update
━━━━━━━━━━━━━━━━━━━━━━━━━━
12/22 atoms done (55%) | Feature 3/9
Currently: Recipe CRUD endpoints
Next pause: Feature integration gate (~20 min)
Token budget: 60% remaining this window
No decisions needed. Pipeline flowing.
```

## Human Touchpoints Summary

1. **Intake** — Describe what to build, answer clarifying questions
2. **Plan review** — Approve epics, features (interactive)
3. **Set horizon** — "Plan for X time"
4. **Feature clarification** — Answer questions for each feature in batch
5. **Approve batch** — One approval, then hands-off
6. **Confidence gate interrupts** — Only when an atom is genuinely unclear
7. **Integration testing** — Optional, at feature PR boundaries
8. **Blockers** — Only genuine failures

Everything else is autonomous.

## Command Implementation (Main Session)

When the user issues a forge command in the main session, handle it directly:

### `forge continue` / `forge approve`
1. Read state.json
2. If status is 'awaiting-integration': set status to 'executing', write state.json
3. Reply: "Forge resumed. Next atom will be picked up within 3 minutes."

### `forge pause`
1. Read state.json, set status to 'paused', write state.json
2. Reply with current progress summary

### `forge resume`
1. Read state.json, set status to 'executing', write state.json
2. Reply: "Forge resumed."

### `forge status`
1. Read state.json
2. Format progress report: atoms done/total, current work, features/epics done, queue remaining

### `forge decide <id> <answer>`
1. Read state.json, find the pending decision
2. Update the relevant atom/feature file with the answer
3. Set status back to 'executing', write state.json

### `forge skip <atom-id>`
1. Add atom to completedAtoms (mark as skipped), advance to next
2. Write state.json

### `forge retry <atom-id>`
1. Set the atom as currentWork, status to 'executing'
2. Write state.json — cron will pick it up

### `forge heartbeat <minutes>`
1. Update the forge-executor cron job's `schedule.everyMs` to `minutes * 60000`
2. Use `cron update` with the job ID and patch `{ "schedule": { "kind": "every", "everyMs": <ms> } }`
3. Reply: "Forge heartbeat set to every {minutes} minutes."
4. Default is 3 minutes. Useful for dialing back to 10-15 min during long runs.

### `forge silence <hours>`
1. Disable the forge-executor cron: `cron update` with patch `{ "enabled": false }`
2. Create a one-shot cron to re-enable it after the specified hours:
   - `cron add` with `schedule: { kind: "at", at: "<ISO timestamp now + hours>" }`
   - payload: `{ kind: "agentTurn", message: "Re-enable the forge-executor cron job. Use cron list to find the forge-executor job, then cron update with patch { enabled: true }. Send a Slack message to user:U08TGBKN163: '🔥 Forge silence period ended. Resuming notifications.'" }`
3. Reply: "Forge silenced for {hours} hours. Execution continues, notifications paused. Will resume at {time}."
4. Note: execution still runs during silence — only Slack notifications are suppressed. Workers still spawn and commit.

## Quick Start

```
User: "Let's build a calculator app"
→ forge new → intake questions → project.md created
→ Epics presented → approved
→ Features presented → approved
→ "forge plan 24 hours" → clarifying questions for each feature
→ User answers all questions
→ Atoms generated for entire batch
→ "forge approve" → execution begins
→ [autonomous from here — atoms churn, features complete, PRs created]
→ Progress updates arrive periodically
→ Forge naps during token cooldowns, auto-resumes
→ "Batch complete!" or "forge plan" for next horizon
```
