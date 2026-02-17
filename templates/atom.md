# Atom: {ATOM_NAME}

## Scale Context
- **Project**: {PROJECT_NAME} (see ../../../project.md)
- **Epic**: {EPIC_NAME} (see ../../epic.md)  
- **Feature**: {FEATURE_NAME} (see ../feature.md)
- **Atom ID**: {ATOM_ID}

## Task Summary
{One-sentence description of exactly what this atom implements}

## Context Pack
Before implementing, read all context files:
1. `../../../project.md` - Overall project vision and tech stack
2. `../../epic.md` - How this epic fits in the system
3. `../feature.md` - What this feature should do
4. This file - Exact implementation task

## Dependencies

### Prerequisites (must be complete)
- [ ] Atom {PREREQUISITE_ATOM_ID}: {Brief description}
- [ ] Atom {PREREQUISITE_ATOM_ID}: {Brief description}

### Provides (for downstream atoms)
- {What this atom creates/provides}
- {Interface/data structure this exposes}

### Status
- **Status**: {PLANNED/READY/IN_PROGRESS/DONE/FAILED/BLOCKED}
- **Assigned**: {Worker session ID or UNASSIGNED}
- **Started**: {TIMESTAMP or null}
- **Completed**: {TIMESTAMP or null}

## Exact Implementation

### Files to Create/Modify
- **Create**: `{FILE_PATH}` - {Purpose}
- **Modify**: `{FILE_PATH}` - {What changes to make}
- **Create**: `{FILE_PATH}` - {Purpose}

### Code Specifications

#### File: `{FILE_PATH}`
```{LANGUAGE}
{EXACT CODE TEMPLATE OR DETAILED SPECIFICATION}
```

#### File: `{FILE_PATH}`  
```{LANGUAGE}
{EXACT CODE TEMPLATE OR DETAILED SPECIFICATION}
```

### Implementation Details
1. {Specific implementation step 1}
2. {Specific implementation step 2}
3. {Specific implementation step 3}

### Patterns to Follow
- **Error Handling**: {Follow existing pattern in codebase}
- **Logging**: {Follow existing logging conventions}
- **Testing**: {Follow existing test structure}
- **Naming**: {Follow existing naming conventions}

### Database Changes
```sql
-- If this atom requires schema changes
{DDL STATEMENTS}
```

### Configuration Changes
```{FORMAT}
# If this atom requires config changes
{CONFIGURATION UPDATES}
```

## Acceptance Criteria
- [ ] {Specific, testable criterion 1}
- [ ] {Specific, testable criterion 2}
- [ ] {Specific, testable criterion 3}
- [ ] Code compiles without errors
- [ ] All new tests pass
- [ ] No existing tests broken
- [ ] Code follows project style guide

## Required Tests

### Unit Tests
Create: `{TEST_FILE_PATH}`
```{LANGUAGE}
// Test cases to implement:
// 1. {Test case 1 description}
// 2. {Test case 2 description}  
// 3. {Test case 3 description}
```

### Integration Tests  
Create/Modify: `{TEST_FILE_PATH}`
```{LANGUAGE}
// Integration test scenarios:
// 1. {Integration scenario 1}
// 2. {Integration scenario 2}
```

### Test Data
{Any test data, fixtures, or mocks needed}

## Boundaries & Constraints

### DO
- {Thing worker should do}
- {Thing worker should do}
- {Thing worker should do}

### DO NOT
- {Thing worker should NOT do - out of scope}
- {Thing worker should NOT do - belongs in different atom}
- {Thing worker should NOT do - breaking change}

### API Contracts
{Any APIs this atom must honor}

### Data Contracts  
{Any data structures this atom must maintain}

## Build & Test Instructions

### Build Command
```bash
{BUILD_COMMAND}
```

### Test Command
```bash
{TEST_COMMAND}
```

### Expected Build Output
{What successful build should produce}

### Expected Test Output
{What successful test run should show}

## Definition of Done
- [ ] Implementation matches specification exactly
- [ ] Code compiles successfully  
- [ ] All specified tests written and passing
- [ ] No regression in existing functionality
- [ ] Code follows established patterns and conventions
- [ ] Commit message follows format: `forge({epic}/{feature}): {atom description}`
- [ ] Changes committed to feature branch

## Troubleshooting

### Common Issues
- **{Issue 1}**: {Resolution}
- **{Issue 2}**: {Resolution}

### Compilation Errors
{Specific guidance for likely compilation issues}

### Test Failures
{Specific guidance for likely test failures}

## Worker Instructions

### Implementation Process
1. Read all 4 context files (project.md, epic.md, feature.md, this file)
2. Understand the exact task and its boundaries
3. Implement according to the specifications above
4. Build and fix any compilation errors (max 2 retries)
5. Run tests and fix any failures (max 2 retries)  
6. Commit with proper message format
7. Report status: DONE, FAILED (with details), or BLOCKED (with reason)

### Auto-Retry Rules
- **Compilation Failure**: Read error, fix code, retry (up to 2 attempts)
- **Test Failure**: Read failure, fix code or test, retry (up to 2 attempts)
- **Still Failing**: Stop and report FAILED with full error context

### Escalation Conditions
- Cannot understand requirements (ambiguous specification)
- Missing dependencies not marked as prerequisites
- Breaking changes required to meet acceptance criteria
- External service/system issues beyond code control

---

**Created**: {TIMESTAMP}
**Last Updated**: {TIMESTAMP}
**Estimated Effort**: {X minutes}
**Complexity**: {LOW/MEDIUM/HIGH}

## Implementation Log
{Worker should update this during implementation}

### {TIMESTAMP} - Implementation Started
- Worker: {SESSION_ID}
- Approach: {Implementation approach chosen}

### {TIMESTAMP} - Progress Update
- Status: {Current status}
- Challenges: {Any issues encountered}
- Next Steps: {What's next}

### {TIMESTAMP} - Implementation Complete
- Final Status: {DONE/FAILED/BLOCKED}
- Commit Hash: {GIT_COMMIT_HASH}
- Duration: {X minutes}
- Notes: {Any final notes}

## Quality Checklist
{Worker should verify before marking done}

- [ ] All acceptance criteria met
- [ ] All required tests implemented and passing
- [ ] Code follows project conventions  
- [ ] No unnecessary changes outside scope
- [ ] Proper error handling implemented
- [ ] Documentation updated if needed
- [ ] Commit message follows format
- [ ] Build succeeds
- [ ] No regressions introduced