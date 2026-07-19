---
name: branch-auditor-pgpemu
description: |
  Audit a feature branch against origin/main to highlight changes, verify test coverage, and detect potential bugs.
  
  Use this skill whenever you need to:
  - Understand what changed in a branch compared to main
  - Verify all changes have corresponding unit tests
  - Detect potential bugs or regressions
  - Assess merge risk and readiness
  - Review code quality, formatting, and architecture
  - Get actionable recommendations for test coverage gaps
  
  This is pgpemu-specific: It understands the ESP32-C3 firmware architecture, the comprehensive test suite (252 assertions across 8 test modules), and code review standards from AGENTS.md. The auditor scans the entire codebase—no specificity needed, the unit tests handle verification.
compatibility: git, bash, C code analysis
---

# Branch Auditor for PGPemu

## Overview

This skill audits a feature branch against `origin/main` to:
1. **Summarize changes** — Concise breakdown organized by layer/module
2. **Verify test coverage** — Check if changes have corresponding unit tests; **prompt for test plan if missing**
3. **Flag potential bugs** — Identify threading, memory, and architecture issues
4. **Assess merge risk** — Quantified risk score (0-10) based on finding severity
5. **Code review scan** — Validate formatting, naming, and architecture compliance

## Audit Methodology

### 1. Change Inventory
- Count files changed, lines added/deleted
- Group changes by layer and module
- Identify functional impact (feature, bugfix, refactor, etc.)
- Note file deletions or major refactors

### 2. Test Coverage Analysis
Scan for test file changes matching modified source files.

The pgpemu test suite has **252 assertions** across 8 modules:
- `test_regression.c` (42) — Critical bug prevention
- `test_edge_cases.c` (71) — Boundary conditions
- `test_error_handling.c` (37) — Error recovery
- `test_settings.c` (20) — Settings logic
- `test_config_storage.c` (37) — NVS persistence
- `test_handshake_multi.c` (18) — Multi-device connections
- `test_nvs_helper.c` (23) — NVS utilities
- `cert-test.c` (4) — Certificate validation

**Coverage Check:**
- Are modified .c/.h files covered by corresponding test_ files?
- Were existing tests updated if APIs changed?
- Is there a regression test if fixing a bug?

**If no test changes found:** Prompt user to create a test plan and verification strategy.

### 3. Bug Detection (Comprehensive Codebase Scan)

Scan all modified files for patterns without targeting specific modules:

**Threading & Concurrency:**
- Mutex created but never freed (memory leak)
- Shared variable modifications without lock protection
- Race conditions in shared state access
- Deadlock potential in mutex ordering

**Memory & Allocation:**
- Dynamic allocation in tight loops or ISRs (hot paths)
- Memory allocation without corresponding deallocation
- Unbounded allocations (potential exhaustion)

**State & Logic:**
- Implicit state dependencies (banned per AGENTS.md)
- State transitions without guards
- Device settings isolation violations
- NVS key generation correctness

**BLE Correctness:**
- Protocol changes (handshake, pairing, reconnection)
- Timing modifications affecting latency targets
- Session key/cache invalidation issues
- Connection state machine corruption

**Code Organization (Architecture):**
- Functions in wrong layer (layering violations)
- New circular dependencies
- Single responsibility violations
- Module encapsulation broken

**Code Quality:**
- Formatting issues (clang-format compliance)
- Naming convention violations
- Comments that explain "what" instead of "why"
- Logs in tight loops (performance concern)

### 4. Architecture Validation

Understand the 6-layer model:
```
Layer 1: HAL — button_input.c, uart.c (hardware abstraction)
Layer 2: Communication — pgp_gap.c, pgp_bluetooth.c, pgp_cert.c (BLE setup)
Layer 3: Connection Mgmt — pgp_handshake_multi.c, pgp_gatts.c, pgp_handshake.c (connections)
Layer 4: Storage — config_storage.c, config_secrets.c, settings.c, nvs_helper.c (persistence)
Layer 5: Features — pgp_led_handler.c, pgp_autobutton.c (behaviors)
Layer 6: System — pgpemu.c, stats.c, log_tags.c (orchestration)
```

Validate:
- Each change belongs in its layer
- Dependencies respect the hierarchy
- No cross-layer shortcuts

### 5. Risk Scoring

Assign a **merge risk score (0-10)**:
- **0-2**: Low risk. Trivial changes, well-tested, no architectural impact.
- **3-4**: Low-medium risk. Changes are tested, minor concerns.
- **5-6**: Medium risk. Some test gaps or moderate complexity.
- **7-8**: High risk. Major architectural changes, significant test gaps, or critical module changes.
- **9-10**: Critical. Unresolved bugs, no tests, BLE correctness questions, or threading issues.

**Risk factors:**
- Missing test coverage (each untested module: +1-2 points)
- Threading/concurrency issues found (+2-3 points)
- BLE/timing changes (+2 points)
- Memory leaks or allocation issues (+1-2 points)
- Architecture violations (+1-2 points)
- Code style issues (-0 to +1 points, minor)

## Output Format

Return a **Concise Audit Report** with these sections:

```markdown
# Branch Audit: <branch-name> vs origin/main

## Summary
- **Commits**: N new commits since origin/main
- **Files Changed**: M files (+X lines, -Y lines)
- **Scope**: [Low/Medium/High] — brief description of changes

## Changes by Layer
### Layer X: Module Name
- file.c: +N/-M lines (brief purpose)
- file.h: +N/-M lines (brief purpose)

(repeat for each affected layer)

## Test Coverage Analysis

✅ **Tests Found**: test_file.c updated to cover changes
- New assertions added: X
- Edge cases covered: [list key boundaries tested]

**or**

❌ **No Test Changes Detected**

Modules modified without corresponding test updates:
- config_storage.c — NVS read/write logic
- pgp_gatts.c — GATT characteristics
- settings.c — Settings persistence

**ACTION REQUIRED**: Create a test plan before merge.

Consider:
1. What are the boundaries and edge cases for your changes?
2. What regression tests catch bugs you might introduce?
3. How will you verify your changes on hardware?

(Link to test suite structure and examples in README.md)

## Issues & Findings

✅ No critical issues detected

**or**

❌ **Critical Issues** (blocking merge):
- [Issue] Description. Location: file.c:line

⚠️  **Warnings** (should fix before merge):
- [Issue] Description. Location: file.c:line

⚠️  **Notes** (consider for future):
- [Issue] Description. Location: file.c:line

## Code Quality

- **Formatting**: ✅ / ⚠️ / ❌ (against clang-format)
- **Naming Conventions**: ✅ / ⚠️ / ❌
- **Comments**: ✅ / ⚠️ / ❌ (explains why, not just what)
- **Architecture**: ✅ / ⚠️ / ❌ (respects layers)

## Merge Risk Assessment

**Risk Score: X/10**

**Risk Breakdown:**
- Test coverage gaps: ±N points
- Code complexity: ±N points
- Architecture changes: ±N points
- Critical module changes: ±N points

**Recommendation:**

✅ **Safe to merge** — All checks pass. Run `./run_tests.sh` locally to confirm.

**or**

⚠️  **Merge with caution** — Address warnings and test coverage gaps first.

**or**

❌ **Do not merge** — Resolve critical issues before proceeding.

---

**Next Steps:**
1. [Specific action items based on findings]
2. [Hardware validation if BLE-related]
3. [Test plan if coverage gaps exist]

```

## How to Use This Skill

### When to Invoke
- Before opening a pull request
- When reviewing another developer's branch
- Before merging to main
- When assessing feature complexity
- When tracking down mysterious bugs

### Input
Provide the branch name (defaults to HEAD if not specified):
```
claude audit-branch feat/per-device-settings
claude audit-branch --base main feat/reconnect
```

### What the Skill Does
1. Fetches the base branch to ensure fresh data
2. Lists all commits between base and current branch
3. Generates diff, organized by file and layer
4. Scans for test file changes
5. Analyzes code patterns in all modified files
6. Validates against AGENTS.md standards
7. Assigns risk score
8. Generates report with actionable recommendations

## Key Behaviors

### Test Coverage Gaps
If **no test changes are detected**:
- List all modified modules
- **Prompt user to create a test plan** with specific questions:
  - What are the edge cases?
  - What regressions could happen?
  - How will you verify on hardware?
- Link to test suite examples

### Comprehensive Scanning
- Scans **entire modified codebase**, not specific modules
- Detects patterns generically (threading, memory, state)
- No module-specific rules — unit tests catch that
- Reports findings by severity and location

### Risk Scoring
Risk score is **transparent and justified**:
- Each finding contributes to the score
- Scoring rationale is explained
- Actionable recommendations tied to score

## References

- AGENTS.md — Code review standards and architecture rules
- README.md — Test suite guide, 252-assertion overview
- pgpemu-esp32/.clang-format — Code style rules
- pgpemu-esp32/main/pc/ — Test suite location and examples
