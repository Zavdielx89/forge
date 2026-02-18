# Forge - Multiscale AI Software Factory 🔥

> *From the macroscopic vision down to the atomic unit of work — then back up to working software.*

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FF5F5F?style=for-the-badge&logo=buy-me-a-coffee&logoColor=white)](https://www.buymeacoffee.com/zavdielx)

Forge is an [OpenClaw](https://github.com/openclaw/openclaw) skill that decomposes software projects across multiple scales (Project → Epics → Features → Atoms) then executes those atoms autonomously with AI worker sub-agents. Planning is interactive. Execution is autonomous.

## How It Works

```
User: "Build a measurement calculator"
  → Forge asks clarifying questions (batched)
  → Decomposes into Epics → Features → Atoms
  → User approves once
  → Autonomous execution begins
  → Progress updates arrive via Slack/Telegram/etc.
  → Pauses at feature boundaries for integration testing
  → Naps during token cooldowns, auto-resumes
  → Project complete.
```

**Target: 80% unsupervised execution.** Humans make architectural and UX decisions upfront. Machines execute.

## The Four Scales

| Scale | Count | What | Human Input |
|-------|-------|------|-------------|
| **Project** | 1 | The macroscopic vision | Goals, constraints, tech stack |
| **Epics** | 3-8 | Major structural segments | Priority, scope, integration points |
| **Features** | 3-6 per epic | Individual capabilities | UX decisions, behavior, edge cases |
| **Atoms** | 3-10 per feature | Smallest executable units | Only if confidence gate triggers |

### Vertical Context Stack
Every AI worker receives exactly 4 files — narrow but deep:
- `project.md` — what the app is
- `epic.md` — how this system fits
- `feature.md` — what this capability does
- `atom.md` — exact task to implement

## Key Features

### Horizon-Based Planning
Instead of planning everything upfront or one feature at a time, Forge plans in time horizons:

```
forge plan 5 hours    → estimates ~8-12 atoms
forge plan 3 days     → estimates ~100-150 atoms
forge plan 1 week     → estimates ~200+ atoms
```

All clarifying questions are batched upfront. One approval. Then autonomous execution.

### Confidence Gate
Before each atom, the orchestrator scores 4 dimensions:

1. **Project alignment** — does this connect to the vision?
2. **Epic fit** — does it fit the system architecture?
3. **Feature coherence** — does it implement the spec?
4. **Implementation clarity** — are requirements unambiguous?

Each: HIGH / MEDIUM / LOW

- **All HIGH** → Execute immediately
- **Any MEDIUM** → Execute with notes logged
- **Any LOW** → Stop. Ask the human. Resume after answer.

### Cron-Driven Orchestration (Self-Healing)
Execution is powered by an OpenClaw cron job that fires every 3 minutes:

- **Survives session compaction** — cron is infrastructure, not session state
- **Self-healing** — if the main session loses context, cron keeps dispatching workers
- **Self-disabling** — disables its own cron job on pipeline completion (zero token leak)
- **Reports to human** — pushes status updates to Slack/Telegram/etc.
- **Created automatically** by `forge approve` — each project gets its own cron

```
┌─────────────────────────────────────────────┐
│  Cron (every 3 min)                         │
│  ├─ Read state.json                         │
│  ├─ If complete → self-disable, notify, stop│
│  ├─ Check for active workers                │
│  ├─ Verify last atom committed              │
│  ├─ Feature/epic boundary gates             │
│  ├─ Completion detection → self-disable     │
│  ├─ Confidence gate on next atom            │
│  ├─ Spawn worker sub-agent                  │
│  ├─ Update FORGE_STATUS.md                  │
│  └─ Status update → human                   │
└─────────────────────────────────────────────┘
```

### FORGE_STATUS.md — Compaction Persistence
The main session loses all context on compaction. `FORGE_STATUS.md` bridges the gap:

- **Written by the cron executor** after every state change
- **Read by the main session** on startup (listed in AGENTS.md)
- **State machine**: `idle` → `active` → `complete` | `error` | `awaiting-integration` | `needs-decision` | `paused`

When the cron executor detects completion (all atoms done, queue empty), it:
1. Sets `status: complete` in state.json
2. Updates FORGE_STATUS.md
3. Disables its own cron job via `cron update` with `{ enabled: false }`
4. Sends final notification to the human
5. No more ticks until re-enabled via `forge resume` or `forge new`

### Integration Gates

Feature and epic boundaries trigger gates before continuing:

**Gate Types:**
- `auto` — unit tests + build only, no pause (for backend/engine code with no UI)
- `manual` — full integration test plan presented to human, execution pauses

At **manual gates**, the human receives:
- Test scenarios for the current feature (3-6 specific steps)
- Test scenarios for all features in the epic (at epic boundaries)
- Cross-feature interaction tests
- Regression checklist for previously completed features
- Say `forge continue` to resume

### Token Budget Management
- Tracks consumption per rolling 5-hour window (Claude Max)
- When rate-limited: pauses, sets cron to auto-resume when window resets
- Won't start an atom that can't finish in remaining budget
- Runs 24/7 with naps — not 9-to-5 with hard stops

## Commands

```bash
# Project Lifecycle
forge new                         # Start a new project (intake)
forge plan <horizon>              # Plan atoms for a time horizon
forge approve                     # Approve plan, begin execution
forge status                      # Show current progress

# Execution Control
forge pause                       # Pause autonomous execution
forge resume                      # Resume execution
forge continue                    # Continue past integration gate
forge skip <atom-id>              # Skip a stuck atom
forge retry <atom-id>             # Retry a failed atom
forge heartbeat <minutes>         # Set check interval (default: 3 min)
forge silence <hours>             # Mute notifications for N hours (execution continues)

# Decision Support
forge decide <id> <answer>        # Answer a pending decision

# Information
forge history                     # Show what was done today
forge budget                      # Show remaining token capacity
```

## Installation

### As an OpenClaw Skill

1. Clone into your OpenClaw workspace skills directory:
   ```bash
   cd ~/.openclaw/workspace/skills
   git clone https://github.com/yourusername/forge.git
   ```

2. Restart OpenClaw:
   ```bash
   openclaw gateway restart
   ```

3. Verify it loaded:
   ```bash
   openclaw status
   # Should show: forge ✓ ready
   ```

4. Start building:
   ```
   > Let's build a calculator app
   ```

### Requirements
- [OpenClaw](https://github.com/openclaw/openclaw) installed and configured
- A messaging channel (Slack, Telegram, etc.) for progress updates
- Claude API access (Claude Max recommended for autonomous execution)

## Directory Structure

```
forge/
├── SKILL.md               # OpenClaw skill definition (the brain)
├── README.md              # This file
├── templates/             # Plan file templates
│   ├── project.md
│   ├── epic.md
│   ├── feature.md
│   ├── atom.md
│   └── decision.md
├── prompts/               # Sub-agent system prompts
│   ├── planner-project.md
│   ├── planner-epic.md
│   ├── planner-feature.md
│   ├── worker.md
│   └── reviewer.md
├── lib/                   # Helper libraries
│   ├── state.sh
│   └── queue.sh
└── projects/              # Project data (gitignored)
    └── {project-id}/
        ├── project.md
        ├── state.json     # Single source of truth
        ├── epics/
        │   └── {nn}-{name}/
        │       ├── epic.md
        │       └── features/
        │           └── {nn}-{name}/
        │               ├── feature.md
        │               └── atoms/
        │                   └── {nnn}-{name}.md
        └── reports/
```

## State Machine

```
planning → approved → executing ←──────────────┐
                         │                      │
                    ┌────┴────┐                 │
                    ▼         ▼                 │
            awaiting-     needs-        forge continue /
            integration   decision      forge decide
                    │         │                 │
                    └────┬────┘                 │
                         └──────────────────────┘
                         
executing → rate-limited → (auto-resume after cooldown)
executing → complete (all atoms done → cron self-disables)
executing → paused (forge pause) → executing (forge resume)
```

### state.json Schema
```jsonc
{
  "projectId": "measure-calc",
  "status": "executing",           // See state machine above
  "scales": {
    "epics": { "total": 4, "done": 2 },
    "features": { "total": 11, "done": 9 },
    "atoms": { "total": 26, "done": 21, "running": 1 }
  },
  "completedAtoms": ["E01-F01-001", ...],
  "completedFeatures": ["E01-F01", ...],
  "completedEpics": ["01-scaffolding", ...],
  "currentWork": {
    "atom": "E04-F01-001",
    "workerLabel": "worker-E04-F01-001"
  },
  "featureBoundaries": {           // Last atom → feature ID
    "E01-F01-003": "E01-F01"
  },
  "epicBoundaries": {              // Last atom → epic ID
    "E02-F04-003": "02-engine"
  },
  "gateType": {                    // auto = no pause, manual = pause + test plan
    "E01-F01": "auto",
    "E04-F01": "manual"
  }
}
```

## Sub-Agent Architecture

```
┌─────────────────────────────────────────────────────┐
│  Main Session (human conversation)                   │
│  ├─ Receives progress updates from cron              │
│  ├─ Handles forge commands                           │
│  └─ Integration gate decisions                       │
├──────────────────────────────────────────────────────┤
│  Cron Executor (isolated, every 3 min)               │
│  ├─ Reads state.json                                 │
│  ├─ Runs confidence gates                            │
│  ├─ Spawns workers                                   │
│  ├─ Detects boundaries                               │
│  └─ sessions_send → main session                     │
├──────────────────────────────────────────────────────┤
│  Worker Sub-Agents (isolated, per atom)              │
│  ├─ Receive full context stack                       │
│  ├─ Implement → test → commit                        │
│  └─ Auto-retry up to 2x on failure                   │
├──────────────────────────────────────────────────────┤
│  Planner Sub-Agents (isolated, per decomposition)    │
│  └─ Break one scale into the next                    │
└─────────────────────────────────────────────────────┘
```

## Design Principles

1. **Files over databases** — everything is markdown and JSON on disk
2. **Vertical context, not horizontal** — workers see their full stack, nothing else
3. **Humans refine, machines execute** — decisions at the right scale only
4. **Fail small** — atom failures don't cascade
5. **Compile-test-commit** — every atom leaves working code
6. **Self-healing** — cron-driven, survives session loss
7. **Resumable** — everything persisted to state.json
8. **Budget-aware** — track and respect token limits, nap and resume

## Example: MeasureCalc

Forge's first test project — a Vue 3 measurement calculator with fraction math, unit conversions, and PEMDAS expression evaluation:

- **4 epics**: Scaffolding, Engine, Calculator UI, Integration
- **11 features**: From Vite setup to keyboard shortcuts
- **26 atoms**: Each independently testable and committable
- **~2 hours** from approval to 21/26 atoms complete (autonomous)

## Contributing

Forge is early. Things to improve:
- Parallel atom execution (currently sequential)
- Smarter token budget estimation
- Better error recovery patterns
- More gate types (automated E2E, visual regression)
- Multi-project support

PRs welcome. File issues for bugs or feature requests.

## License

MIT. Part of the [OpenClaw](https://github.com/openclaw/openclaw) ecosystem.

---

*Forge: Multiscale software construction. From vision to atoms and back to working code.* 🔥
