# Forge - Multiscale AI Software Factory

> *From the macroscopic vision down to the atomic unit of work — then back up to working software.*

Forge is an OpenClaw skill that decomposes software projects across multiple scales (Project → Epics → Features → Atoms) then executes those atoms with AI workers that have full vertical context through every scale.

## What Forge Does

- **Decomposes projects** into manageable atomic units of work
- **Provides context stacks** so AI workers understand how their work fits into the bigger picture
- **Manages execution pipelines** with automated build/test/commit cycles
- **Gates integration** at feature and epic boundaries
- **Keeps humans in the loop** for architectural and UX decisions at appropriate scales

## The Four Scales

1. **PROJECT** (1) - The macroscopic vision
   - "A recipe sharing app with social features"
   - Output: `project.md`

2. **EPICS** (3-8) - Major structural segments  
   - "Authentication System" / "Recipe Management"
   - Output: `epics/01-auth.md`, etc.

3. **FEATURES** (3-6 per epic) - Individual capabilities
   - "Email/password login" / "OAuth with Google"
   - Output: `epics/01-auth/features/01-email.md`

4. **ATOMS** (3-10 per feature) - Smallest executable units
   - "Create users table migration"
   - "Implement password hashing service"
   - Output: `epics/01-auth/features/01-email/atoms/001-users-table.md`

## How It Works

### Context Stack
Every AI worker receives the full vertical context:
- **project.md** - What the app is, tech stack, conventions
- **epic.md** - How this system fits into the larger architecture
- **feature.md** - What user value this capability provides
- **atom.md** - Exact implementation task

### Human-in-the-Loop
- **Project level**: Goals, constraints, tech stack choices
- **Epic level**: Architecture decisions, integration patterns
- **Feature level**: UX workflows, business logic decisions  
- **Atom level**: Implementation ambiguities (rare)

### Execution Pipeline
```
Atom → Worker → Build → Test → Commit → Next Atom
     ↓
   [2 auto-retries for compilation/test failures]
     ↓
   [Escalate if still failing]
```

## Getting Started

### Installation
Forge is an OpenClaw skill. Once installed in your workspace, use:

```bash
forge new                    # Start a new project
forge status                 # Check current progress
forge plan                   # Review current decomposition
forge approve               # Approve and proceed to next level
```

### Example Workflow

1. **Project Intake**
   ```
   User: "I want to build a recipe sharing app"
   → forge new
   → Intake conversation (goals, tech stack, MVP scope)
   → Creates project.md
   ```

2. **Epic Decomposition**  
   ```
   → forge plan  # Shows proposed epic breakdown
   → Human reviews and approves epic boundaries
   → forge approve
   ```

3. **Feature Decomposition**
   ```
   → forge plan  # Shows features for first epic
   → Human reviews UX workflows and decisions
   → forge approve
   ```

4. **Atom Execution**
   ```
   → Forge spawns workers to implement atoms
   → Automated build/test/commit cycle
   → Progress updates via cron
   → Integration gates at feature boundaries
   ```

## Directory Structure

```
forge/
├── SKILL.md               # OpenClaw skill definition
├── README.md              # This file
├── .gitignore            # Git ignore patterns
├── templates/            # Plan file templates
│   ├── project.md
│   ├── epic.md
│   ├── feature.md
│   ├── atom.md
│   └── decision.md
├── prompts/              # Sub-agent system prompts
│   ├── planner-project.md
│   ├── planner-epic.md
│   ├── planner-feature.md
│   ├── worker.md
│   └── reviewer.md
├── lib/                  # Bash helper libraries
│   ├── state.sh          # State management functions
│   └── queue.sh          # Task queue management
└── projects/            # Where project data lives (gitignored)
    └── {project-id}/
        ├── project.md
        ├── state.json
        ├── epics/
        │   ├── 01-auth/
        │   │   ├── epic.md
        │   │   ├── features/
        │   │   │   ├── 01-email/
        │   │   │   │   ├── feature.md
        │   │   │   │   └── atoms/
        │   │   │   │       ├── 001-table.md
        │   │   │   │       └── ...
        │   │   │   └── ...
        │   │   └── ...
        │   └── ...
        └── reports/
            └── daily/
```

## Key Files

### Templates (`templates/`)
Define the standard format for plans at each scale. The **atom template** is most critical - it must include:
- Full context stack references
- Exact implementation details
- Acceptance criteria  
- Required tests
- Clear boundaries

### System Prompts (`prompts/`)
Instructions for AI sub-agents:
- **Planner prompts** - Decompose one scale into the next
- **Worker prompt** - Execute an atom with context stack
- **Reviewer prompt** - Verify integration at feature/epic boundaries

### State Management (`lib/`)
Bash functions for:
- Reading/writing JSON state files
- Managing atom queue status
- Finding next ready work
- Tracking dependencies and completion

## State Management

All project state is stored in JSON files alongside markdown plans:

```jsonc
// project/state.json
{
  "projectId": "recipe-app",
  "status": "executing", 
  "scales": {
    "project": "approved",
    "epics": { "total": 5, "approved": 2 },
    "atoms": { "total": 47, "done": 12, "running": 1 }
  },
  "currentWork": {
    "epic": "01-auth",
    "atom": "003-login-endpoint", 
    "workerSession": "sub-abc123"
  }
}
```

## Commands Reference

```bash
# Project Management
forge new                    # Create new project
forge status                 # Show current state
forge plan                   # Show current decomposition level
forge approve                # Approve and advance to next level

# Queue Management  
forge pause                  # Pause execution
forge resume                 # Resume execution
forge skip <atom-id>         # Skip stuck atom
forge retry <atom-id>        # Retry failed atom

# Information
forge history               # Show recent progress
forge budget               # Show remaining capacity
forge decide <id> <answer> # Answer pending decision
```

## Sub-Agent Architecture

Forge orchestrates multiple types of AI sub-agents:

### Planner Agents
- **Project Planner**: Breaks project into epics
- **Epic Planner**: Breaks epic into features  
- **Feature Planner**: Breaks feature into atoms

### Execution Agents
- **Worker**: Implements individual atoms
- **Reviewer**: Verifies integration at boundaries

### Communication Flow
```
Main Agent ←→ Human (decisions, progress)
     ↓
Planner Agents (decomposition)
     ↓
Worker Agents (implementation) 
     ↓
Reviewer Agents (integration gates)
```

## Design Principles

1. **Files over databases** - Everything is markdown and JSON
2. **Vertical context, not horizontal** - Workers see their full stack
3. **Humans refine, machines execute** - Human decisions at right scale
4. **Fail small** - Atom failures don't cascade
5. **Compile-test-commit** - Every atom leaves working code
6. **Budget-aware** - Track and respect Claude time limits
7. **Resumable** - Everything persisted to disk

## Success Metrics

- **End-to-end completion** without human coding
- **Atomic granularity** - each atom ≤30 minutes Claude time
- **Quality gates** - compile/test/commit at every atom
- **Appropriate human involvement** - decisions at right scale only
- **Budget management** - no overruns, predictable capacity

## Contributing

To extend Forge:

1. **Templates** - Modify templates to fit your project patterns
2. **Prompts** - Adjust system prompts for your architectural style  
3. **State management** - Extend JSON schemas for additional tracking
4. **Integration** - Add hooks for your CI/CD, notification systems

## License

Part of the OpenClaw ecosystem. See main OpenClaw license.

---

*Forge: Multiscale software construction. From vision to atoms and back to working code.*