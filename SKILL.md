# Forge - Multiscale AI Software Factory

> *From the macroscopic vision down to the atomic unit of work — then back up to working software.*

## What This Skill Does

Forge decomposes a software project across multiple scales (Project → Epics → Features → Atoms) then executes those atoms with AI workers that have full vertical context. Humans refine the plan at each level, ensuring precision increases as scope narrows.

## When to Use Forge

Activate when the user wants to:
- Build a complete software application
- Create a new project from scratch  
- Says "build [something]" / "create [an app]" / "new project"
- Says "forge [command]" explicitly
- References an existing forge project

## Command Set

```bash
forge new                    # Start a new project (intake)
forge status                 # Show current project status  
forge plan                   # Show/review current plan at any scale
forge approve                # Approve current decomposition level
forge decide <id> <answer>   # Answer a pending decision
forge pause                  # Pause execution
forge resume                 # Resume execution  
forge skip <atom-id>         # Skip a stuck atom
forge retry <atom-id>        # Retry a failed atom
forge history               # Show what was done today
forge budget                # Show remaining capacity
```

## Architecture Overview

### The Four Scales

1. **PROJECT** (1) - The macroscopic vision
   - "A recipe sharing app with social features"
   - Human input: Goals, constraints, tech stack, MVP scope
   - Output: project.md

2. **EPICS** (3-8) - Major structural segments
   - "Authentication System" / "Recipe Management"  
   - Human input: Priority, scope boundaries, integration points
   - Output: epics/01-auth.md, etc.

3. **FEATURES** (3-6 per epic) - Individual capabilities
   - "Email/password login" / "OAuth with Google"
   - Human input: UX decisions, behavior, edge cases
   - Output: epics/01-auth/features/01-email.md

4. **ATOMS** (3-10 per feature) - Smallest executable units
   - "Create users table migration"
   - "Implement password hashing service"
   - Human input: Clarify ambiguities only
   - Output: epics/01-auth/features/01-email/atoms/001-users-table.md

### Context Stack

Every worker receives the full vertical context:
- project.md (what the app is)
- epic.md (how this system fits)
- feature.md (what this capability does)  
- atom.md (exact task to implement)

## Implementation Guide

### Command: forge new

1. Start intake conversation with user
2. Create project brief (project.md)
3. Initialize project state (state.json)
4. Set status to "intake" → "planning"

### Command: forge status  

Show current state from state.json:
- Overall progress (atoms done/total)
- Current work (epic/feature/atom)
- Active worker sessions
- Pending decisions
- Budget remaining

### Command: forge plan

Show current decomposition level:
- If project approved → show epic breakdown
- If epic approved → show feature breakdown  
- If feature approved → show atom breakdown

### Command: forge approve

Approve current decomposition level and advance:
- Project approved → start epic decomposition
- Epic approved → start feature decomposition
- Feature approved → start atom execution

### Decomposition Flow

1. Spawn planner sub-agent with appropriate prompt
2. Planner reads parent level, creates child level breakdown
3. Present breakdown to human for review
4. Human can modify or approve
5. If approved, advance to next level or execution

### Execution Flow

1. Find next ready atom (dependencies met)
2. Spawn worker sub-agent with context stack
3. Worker implements atom, compiles, tests, commits
4. Mark atom complete and advance queue
5. When feature complete → integration gate
6. When epic complete → integration gate

## State Management

### Directory Structure

```
forge/projects/{project-id}/
├── project.md                 # Project plan
├── state.json                 # Project state
├── epics/
│   ├── 01-auth/
│   │   ├── epic.md           # Epic plan
│   │   ├── state.json        # Epic state
│   │   ├── features/
│   │   │   ├── 01-email/
│   │   │   │   ├── feature.md
│   │   │   │   ├── atoms/
│   │   │   │   │   ├── 001-table.md
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
  "projectId": "recipe-app",
  "status": "executing",
  "created": "2026-02-17T10:00:00Z",
  "scales": {
    "project": "approved",
    "epics": { "total": 5, "approved": 2 },
    "features": { "total": 18, "approved": 6 },
    "atoms": { "total": 47, "done": 12, "running": 1 }
  },
  "currentWork": {
    "epic": "01-auth",
    "feature": "01-email-login", 
    "atom": "003-login-endpoint",
    "workerSession": "sub-abc123"
  },
  "git": {
    "repo": "/path/to/project",
    "baseBranch": "main",
    "forgeBranch": "forge/build"
  }
}
```

## Sub-Agent Orchestration

### Planner Sub-Agents

Spawned for decomposition with prompts from `prompts/`:
- `planner-project.md` - Project → Epics
- `planner-epic.md` - Epic → Features  
- `planner-feature.md` - Feature → Atoms

### Worker Sub-Agents

Spawned for execution with:
- `prompts/worker.md` - Standard worker instructions
- Context stack (4 files)
- Target repository path

### Reviewer Sub-Agents

Spawned for integration gates with:
- `prompts/reviewer.md` - Review instructions
- Completed work artifacts

## Communication Patterns

### Progress Updates
Send via cron or main session:
- Daily progress summaries  
- Completion milestones
- Budget alerts

### Decision Requests
Block on human input for:
- Architecture choices at epic level
- UX decisions at feature level
- Ambiguous implementation details at atom level

### Escalations
When workers fail after retries:
- Context about what failed
- Why it can't auto-resolve
- What human action is needed

## Library Functions

Use bash helpers from `lib/`:

```bash
# State management
source lib/state.sh
init_project "recipe-app"
get_state "recipe-app" "status"
set_state "recipe-app" "status" "executing"

# Queue management  
source lib/queue.sh
next_atom "recipe-app"
mark_atom "recipe-app" "001-users-table.md" "done"
```

## File Templates

All plans follow templates from `templates/`:
- `project.md` - Project level template
- `epic.md` - Epic level template
- `feature.md` - Feature level template  
- `atom.md` - Atom level template (most critical)
- `decision.md` - Human decision request template

## Success Metrics

- Projects complete end-to-end without human coding
- Each atom takes ≤30 minutes of Claude time
- Compile-test-commit cycle at every atom
- Human reviews scale-appropriate decisions only
- Budget tracking prevents overruns

---

## Quick Start Example

```
User: "I want to build a recipe sharing app"
→ forge new
→ Intake conversation (goals, tech stack, MVP)  
→ Create project.md
→ forge plan → Show epic breakdown
→ forge approve → Start feature decomposition
→ forge status → Monitor progress
```

The system handles the complexity of multiscale construction while keeping humans in the loop at the right level of detail.