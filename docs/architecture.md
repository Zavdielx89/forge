# Forge — Multiscale AI Software Factory

> *"From the macroscopic vision down to the atomic unit of work — then back up to working software."*

## 1. What Forge Is

Forge is an OpenClaw skill that decomposes a software project across multiple scales — from high-level vision down to atomic implementation units — then executes those atoms with AI workers that have full vertical context through every scale. Humans refine the plan at each level of decomposition, ensuring precision increases as scope narrows.

Inspired by multiscale materials modeling: you can't simulate a bridge by modeling every atom, but you *can* model atoms within grains, grains within microstructures, microstructures within components, components within the bridge. Each scale informs the next.

## 2. The Multiscale Hierarchy

```
┌─────────────────────────────────────────────────┐
│                   PROJECT                        │
│   The macroscopic vision. What are we building?  │
│   "A recipe sharing app with social features"    │
│                                                  │
│   Output: project.md                             │
│   Human input: Goals, constraints, platform,     │
│                tech stack, MVP scope              │
├─────────────────────────────────────────────────┤
│                    EPICS                          │
│   Major structural segments of the project.      │
│   "Authentication System" / "Recipe Management"  │
│                                                  │
│   Output: epics/01-auth.md, epics/02-recipes.md  │
│   Human input: Priority, scope boundaries,       │
│                integration points, what's in/out  │
├─────────────────────────────────────────────────┤
│                   FEATURES                        │
│   Individual capabilities within an epic.        │
│   "Email/password login" / "OAuth with Google"   │
│                                                  │
│   Output: epics/01-auth/features/01-email.md     │
│   Human input: UX decisions, specific behavior,  │
│                edge cases, acceptance criteria    │
├─────────────────────────────────────────────────┤
│                    ATOMS                          │
│   The smallest executable unit of work.          │
│   "Create users table migration"                 │
│   "Implement password hashing service"           │
│   "Write login endpoint with validation"         │
│                                                  │
│   Output: epics/01-auth/features/01-email/       │
│           atoms/001-users-table.md               │
│   Human input: Clarification on ambiguities,     │
│                specific patterns, naming, etc.    │
└─────────────────────────────────────────────────┘
```

### Scale Properties

| Scale   | Count     | Scope              | Human Input Style           | Typical Size |
|---------|-----------|--------------------|-----------------------------|-------------|
| Project | 1         | Everything         | Vision, goals, constraints  | 1 document  |
| Epic    | 3-8       | Major system area  | Priorities, boundaries      | 1 doc each  |
| Feature | 3-6/epic  | Single capability  | UX, behavior, edge cases    | 1 doc each  |
| Atom    | 3-10/feat | Single code change | Clarify ambiguities         | 1 doc each  |

A typical project: 5 epics × 4 features × 6 atoms = **120 atoms**.
At ~10-15 min Claude time per atom: **~20-30 hours** of execution.
At 5 hours/day subscription: **~4-6 days** of background churning to build a full app.

## 3. The Decomposition Pipeline

### How Breakdown Works

Each level is decomposed by a **Planner agent** (sub-agent), then reviewed by the human before going deeper. This is not a one-shot process — it's iterative refinement.

```
PROJECT ──[Planner]──→ Draft Epics ──[Human Review]──→ Approved Epics
                                                            │
    ┌───────────────────────────────────────────────────────┘
    │
    ▼
EPIC 1 ──[Planner]──→ Draft Features ──[Human Review]──→ Approved Features
                                                              │
    ┌─────────────────────────────────────────────────────────┘
    │
    ▼
FEATURE 1 ──[Planner]──→ Draft Atoms ──[Human Review]──→ Approved Atoms
                                                              │
    ┌─────────────────────────────────────────────────────────┘
    │
    ▼
ATOM 1 ──[Worker]──→ Code + Tests ──[Verify]──→ Done
```

### Progressive Human-in-the-Loop

At the **Project** level, the human is asked broad questions:
> "What platforms? What's the MVP? Any tech stack preferences?"

At the **Epic** level, structural questions:
> "Should auth be its own service or part of the main API? Do you want admin roles from day one?"

At the **Feature** level, behavioral questions:
> "When a user fails login 3 times, should we lock the account or just rate-limit? Should password reset use email or SMS?"

At the **Atom** level, implementation questions (only when ambiguous):
> "Your schema has `created_at` — should I use the DB default or set it in the application layer? The existing codebase uses both patterns."

**Key principle:** Questions get more specific as scope narrows. The human is never overwhelmed with details at the wrong scale.

### Decomposition Rules

1. **Each level must be fully decomposed before execution begins** on that level. You don't start coding atoms for Feature 1 while Feature 2 hasn't been planned yet (within the same epic).

2. **Epics can execute independently.** Once Epic 1 is fully decomposed (all features → all atoms), execution can begin on Epic 1 while Epic 2 is still being planned. This lets the human plan and the machine execute in parallel.

3. **Atoms within a feature are ordered by dependency.** The Planner identifies which atoms depend on which and creates an execution order.

4. **No atom should take more than 30 minutes of Claude time.** If a Planner produces an atom that looks too big, it should be split further.

## 4. The Context Stack

When a worker is spawned for an atom, it receives four files — one from each scale:

```
Worker Context for Atom 003 (Write login endpoint):

1. project.md          — High-level: what the app is, tech stack, conventions
2. epics/01-auth.md    — Epic context: auth architecture, integration points
3. features/01-email.md — Feature spec: email login behavior, edge cases, UX
4. atoms/003-login-endpoint.md — Exact task: what to build, where, how, tests
```

This is the **vertical slice** — narrow but deep. The worker knows:
- What the whole app is for (project)
- How auth fits into it (epic)
- What email login should do (feature)
- Exactly what code to write right now (atom)

It does NOT need to see:
- Other epics' details
- Other features within this epic (unless dependency — then referenced)
- Other atoms (unless dependency — then referenced)

This keeps the context window small and focused while preventing hallucination about how the piece fits into the whole.

### Context Pack Structure (Atom File)

```markdown
# Atom: Create Login Endpoint

## Scale Context
- Project: Recipe Sharing App (see project.md)
- Epic: Authentication System (see epics/01-auth.md)
- Feature: Email/Password Login (see features/01-email.md)

## Task
Implement the POST /auth/login endpoint that accepts email 
and password, validates credentials, and returns a JWT token pair.

## Dependencies
- Atom 001 (users table migration) — COMPLETED ✅
- Atom 002 (password hashing service) — COMPLETED ✅

## Implementation Details
- File: src/auth/auth.controller.ts (add login method)
- File: src/auth/auth.service.ts (add validateUser, generateTokens)
- Pattern: Follow existing controller patterns in src/users/
- Validation: Use class-validator DTOs (see src/common/dto/ for examples)

## Acceptance Criteria
- [ ] POST /auth/login accepts { email, password }
- [ ] Returns 200 with { accessToken, refreshToken } on success
- [ ] Returns 401 with error message on invalid credentials
- [ ] Rate-limited to 5 attempts per minute per email
- [ ] Passwords are never logged or included in error responses

## Required Tests
- Unit test: auth.service.spec.ts — validateUser with valid/invalid creds
- Unit test: auth.service.spec.ts — token generation and structure
- E2E test: auth.e2e-spec.ts — full login flow happy path
- E2E test: auth.e2e-spec.ts — invalid credentials rejection
- E2E test: auth.e2e-spec.ts — rate limiting behavior

## Boundaries
- DO NOT modify the users table schema
- DO NOT implement registration (that's Atom 004)
- DO NOT implement password reset (that's Feature 02)
```

## 5. Execution Pipeline

### Per-Atom Pipeline

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  SPAWN   │───→│  BUILD   │───→│ COMPILE  │───→│   TEST   │
│  Worker  │    │  Code    │    │  & Fix   │    │  & Fix   │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
                                     │               │
                                     ▼               ▼
                                ┌──────────┐    ┌──────────┐
                                │  Error?  │    │  Fail?   │
                                │ Auto-fix │    │ Auto-fix │
                                │ (2 tries)│    │ (2 tries)│
                                └──────────┘    └──────────┘
                                     │               │
                                     ▼               ▼
                                ┌──────────┐    ┌──────────┐
                                │  Still   │    │  Still   │
                                │ broken?  │    │ failing? │
                                │ ESCALATE │    │ ESCALATE │
                                └──────────┘    └──────────┘

Success path:
BUILD → COMPILE ✅ → TEST ✅ → COMMIT → ATOM DONE
```

**Worker instructions include:**
1. Implement the atom according to the plan
2. Attempt to compile/build the project
3. If compile fails — read the errors, fix them, retry (up to 2 attempts)
4. If still failing — stop and report with full error context
5. Run the specified unit tests
6. If tests fail — read failures, fix code or tests, retry (up to 2 attempts)
7. If still failing — stop and report
8. On success — commit with message format: `forge(epic/feature): atom description`

### Per-Feature Gate

After ALL atoms in a feature are complete:

```
┌────────────────────────────────────────────────────┐
│              FEATURE INTEGRATION CHECK              │
│                                                     │
│  1. Run full test suite (not just new tests)        │
│  2. Start the application                           │
│  3. Verify feature works end-to-end                 │
│  4. Check for regressions in other features         │
│  5. Generate integration test plan for human        │
│                                                     │
│  Output: feature-report.md with:                    │
│    - What was built                                 │
│    - Test results                                   │
│    - Integration test plan (for human to verify)    │
│    - Screenshots/logs if applicable                 │
│    - Any concerns or technical debt noted            │
└────────────────────────────────────────────────────┘
```

### Per-Epic Gate

After ALL features in an epic are complete:

```
┌────────────────────────────────────────────────────┐
│               EPIC INTEGRATION CHECK                │
│                                                     │
│  1. Full build from clean state                     │
│  2. Run entire test suite                           │
│  3. Cross-feature integration tests                 │
│  4. Performance sanity check                        │
│  5. Generate PR for the epic                        │
│  6. Present to human for review                     │
│                                                     │
│  Human decides:                                     │
│    - Approve & merge PR                             │
│    - Request changes (spawns rework atoms)           │
│    - Run integration tests themselves               │
└────────────────────────────────────────────────────┘
```

### Per-Project Gate

After ALL epics complete:

```
┌────────────────────────────────────────────────────┐
│               PROJECT COMPLETION                    │
│                                                     │
│  1. Full build + test suite                         │
│  2. Generate deployment instructions                │
│  3. Generate user documentation                     │
│  4. Create final PR to main                         │
│  5. Comprehensive test plan for human QA            │
│  6. Present final summary                           │
└────────────────────────────────────────────────────┘
```

## 6. State Machine

### Project States

```
INTAKE → PLANNING → DECOMPOSING → EXECUTING → COMPLETE
              │           │            │
              ▼           ▼            ▼
          WAITING     WAITING      WAITING
         (human)     (human)      (human)
              │           │            │
              ▼           ▼            ▼
          PLANNING   DECOMPOSING  EXECUTING
                                       │
                                       ▼
                                   PAUSED
                                  (budget/
                                   error/
                                   manual)
```

### Task States (per atom)

```
PLANNED → READY → QUEUED → RUNNING → {DONE | FAILED | BLOCKED}
                                          │       │         │
                                          ▼       ▼         ▼
                                       VERIFY   RETRY    ESCALATE
                                          │       │         │
                                          ▼       ▼         ▼
                                       DONE    RUNNING   WAITING
                                                         (human)
```

### Filesystem Structure

```
forge/projects/{project-id}/
├── project.md                          # Project-level plan
├── state.json                          # Global project state
├── epics/
│   ├── 01-auth/
│   │   ├── epic.md                     # Epic-level plan
│   │   ├── state.json                  # Epic state
│   │   ├── features/
│   │   │   ├── 01-email-login/
│   │   │   │   ├── feature.md          # Feature-level plan
│   │   │   │   ├── state.json          # Feature state
│   │   │   │   ├── atoms/
│   │   │   │   │   ├── 001-users-table.md
│   │   │   │   │   ├── 002-password-hash.md
│   │   │   │   │   ├── 003-login-endpoint.md
│   │   │   │   │   └── ...
│   │   │   │   └── report.md           # Feature integration report
│   │   │   ├── 02-oauth-google/
│   │   │   │   ├── feature.md
│   │   │   │   ├── atoms/
│   │   │   │   │   └── ...
│   │   │   │   └── ...
│   │   │   └── ...
│   │   └── report.md                   # Epic integration report
│   ├── 02-recipes/
│   │   └── ...
│   └── ...
└── reports/
    ├── daily/                          # Daily progress summaries
    └── completion.md                   # Final project report
```

### State JSON Schema

```jsonc
// project state.json
{
  "projectId": "recipe-app",
  "status": "executing",
  "created": "2026-02-17T10:00:00Z",
  "scales": {
    "project": "approved",              // drafted | review | approved
    "epics": {
      "total": 5,
      "decomposed": 3,                  // how many have been broken into features
      "approved": 2                     // how many the human has approved
    },
    "features": {
      "total": 18,
      "decomposed": 8,
      "approved": 6
    },
    "atoms": {
      "total": 47,                      // grows as decomposition continues
      "done": 12,
      "running": 1,
      "failed": 0,
      "blocked": 0,
      "queued": 34
    }
  },
  "currentWork": {
    "epic": "01-auth",
    "feature": "01-email-login",
    "atom": "003-login-endpoint",
    "workerSession": "sub-abc123"
  },
  "decisions": [
    {
      "id": "d-004",
      "scale": "feature",
      "path": "epics/02-recipes/features/03-image-upload",
      "question": "Image storage: local, S3/R2, or Firebase?",
      "status": "waiting",
      "askedAt": "2026-02-17T14:30:00Z"
    }
  ],
  "budget": {
    "atomsCompletedToday": 4,
    "estimatedAtomsRemaining": 35,
    "estimatedDaysRemaining": 5
  },
  "git": {
    "repo": "/home/zavdielx/code/recipe-app",
    "baseBranch": "main",
    "forgeBranch": "forge/build",
    "lastCommit": "abc123"
  }
}
```

## 7. Communication Patterns

### Decomposition Review (sent per scale)

```
🔥 Forge — Epic Breakdown Ready for Review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Project: Recipe Sharing App

I've broken the project into 5 epics:

1. 🔐 Authentication — Email/password + OAuth, JWT tokens, 
   session management
2. 📝 Recipe Management — CRUD, categories, ingredients, 
   rich text instructions
3. 👥 Social Features — Follow users, like/save recipes, 
   activity feed
4. 🔍 Search & Discovery — Full-text search, filters, 
   trending, recommendations
5. 📱 App Shell — Navigation, theming, settings, 
   offline support

Questions for you:
• Should Search be its own epic or part of Recipe Management?
• Do you want notifications (push/email) as a 6th epic 
  or skip for MVP?
• Any of these feel wrong or missing?

Reply with adjustments or "approved" to continue decomposition.
```

### Progress Update (periodic via cron)

```
🔥 Forge Daily Summary — Recipe App
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Day 3 | 34/120 atoms complete (28%)

Today:
  ✅ 8 atoms completed
  🔨 Currently: Recipe CRUD endpoints
  ⏱️ ~5 days remaining at current pace

Epic Progress:
  🔐 Auth ████████████░░ 85% (2 atoms left)
  📝 Recipes ████░░░░░░░░ 30% (working)
  👥 Social ░░░░░░░░░░░░ 0% (planned)
  🔍 Search ░░░░░░░░░░░░ 0% (not yet decomposed)
  📱 Shell  ░░░░░░░░░░░░ 0% (not yet decomposed)

No decisions pending. Pipeline flowing.
```

### Escalation

```
⚠️ Forge — Worker Stuck
━━━━━━━━━━━━━━━━━━━━━━━
Epic: Auth | Feature: OAuth | Atom: Google callback handler

Failed twice with:
  "Google OAuth redirect URI mismatch — expected 
   http://localhost:3000/auth/google/callback but 
   received http://127.0.0.1:3000/auth/google/callback"

This is a Google Cloud Console config issue, not a code issue.
I can't fix this — you'll need to:
1. Add http://127.0.0.1:3000/auth/google/callback to your 
   Google OAuth redirect URIs
2. Reply "done" and I'll retry

Or reply "skip" to move this atom to the end and continue 
with other work.
```

### Feature Gate Report

```
🔥 Forge — Feature Complete: Email/Password Login
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Epic: Authentication

Atoms completed: 6/6 ✅
Tests: 14 passing, 0 failing
Build: Clean compilation ✅

What was built:
• Users table with email, hashed password, timestamps
• Registration endpoint with email validation
• Login endpoint with JWT token pair
• Password hashing with bcrypt (12 rounds)
• Rate limiting (5 attempts/min/email)
• Refresh token rotation

Integration test plan for you:
1. Register a new account → should receive tokens
2. Login with correct password → should work
3. Login with wrong password → should get 401
4. Login 6 times quickly → should get rate-limited
5. Use refresh token → should get new token pair

Want to test this yourself, or should I proceed to 
the next feature (OAuth/Google)?
```

## 8. OpenClaw Integration

### Primitives Used

| Forge needs...              | OpenClaw provides...                        |
|-----------------------------|---------------------------------------------|
| Planner agents              | `sessions_spawn` with planner prompt        |
| Worker agents               | `sessions_spawn` with worker prompt + context stack |
| Track active workers        | `subagents list`                            |
| Kill stuck workers          | `subagents kill`                            |
| Redirect workers            | `subagents steer`                           |
| Progress updates            | `cron` (periodic) or main session messages  |
| Decision requests           | Main session chat (Slack/Signal/etc.)       |
| State persistence           | Workspace filesystem (JSON + markdown)      |
| Code execution              | `exec` (git, build, test commands)          |
| Memory across sessions      | `memory/` files + state.json                |
| Build/test verification     | `exec` (compile, run test suites)           |

### Skill Entry Point (SKILL.md triggers)

Forge activates when:
- User says "build [something]" / "create [an app]" / "new project"
- User says "forge [command]" explicitly
- User references an existing forge project

### Commands

```
forge new                    — Start a new project (intake)
forge status                 — Show current project status
forge plan                   — Show/review current plan at any scale
forge approve                — Approve current decomposition level
forge decide <id> <answer>   — Answer a pending decision
forge pause                  — Pause execution
forge resume                 — Resume execution
forge skip <atom-id>         — Skip a stuck atom
forge retry <atom-id>        — Retry a failed atom
forge history                — Show what was done today
forge budget                 — Show remaining capacity
```

## 9. Build Plan for Forge Itself

### Phase 1: Foundation
1. Skill scaffolding — SKILL.md, directory structure, templates
2. Project state manager — read/write state.json at all scales
3. Intake flow — conversational project brief creation
4. Plan file templates — standardized markdown for each scale

### Phase 2: Decomposition Engine
5. Planner prompts — system prompts for breaking each scale down
6. Decomposition flow — Project → Epics → Features → Atoms pipeline
7. Human review gates — present plans, collect approvals
8. Dependency ordering — topological sort of atoms within features

### Phase 3: Execution Engine
9. Worker launcher — assemble context stack, spawn sub-agent
10. Worker prompt template — standard instructions for atom execution
11. Auto-advance — pick next atom after completion
12. Compile/test loop — verify worker output, retry on failure

### Phase 4: Quality Gates
13. Feature integration check — run after all atoms in a feature
14. Epic integration check — run after all features in an epic
15. Test plan generation — create human-readable test plans
16. PR creation — generate PRs at epic boundaries

### Phase 5: Communication & Polish
17. Progress cron job — periodic status updates
18. Decision queue — proper blocking/unblocking flow
19. Budget tracking — estimate remaining capacity
20. Daily summaries — what was accomplished, what's next

## 10. Design Principles

1. **Files over databases.** Everything is markdown and JSON in the workspace. Inspectable, editable, version-controllable.

2. **Vertical context, not horizontal.** Workers see their full stack (project → epic → feature → atom) but not sibling atoms or other features. Narrow and deep beats wide and shallow.

3. **Humans refine, machines execute.** Every decomposition level gets human eyes. Once approved, execution is autonomous.

4. **Fail small.** If an atom fails, only that atom is affected. The pipeline continues with independent work. Failures are contained to the smallest possible scope.

5. **Compile-test-commit at every atom.** No "big bang" integration. Every atom leaves the project in a buildable, testable state.

6. **Budget-aware.** Forge knows how much Claude time is left and plans accordingly. It won't start an atom it can't finish.

7. **Resumable.** Everything is serialized to disk. If OpenClaw restarts, Forge picks up exactly where it left off.

---

*Forge: Multiscale software construction. From vision to atoms and back to working code.*
