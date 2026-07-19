# Branch Auditor Skill

A comprehensive branch auditing skill for pgpemu that scans feature branches against `origin/main` to identify changes, verify test coverage, detect bugs, and assess merge risk.

## Features

- **Change Inventory** — Organized by architectural layer
- **Test Coverage Analysis** — Identifies gaps and prompts for test plans
- **Comprehensive Bug Detection** — Threading, memory, state, architecture patterns
- **Code Quality Validation** — Formatting, naming, comments
- **Risk Scoring** — 0-10 merge risk assessment with justification
- **Actionable Recommendations** — Clear next steps

## Quick Start

```bash
# Audit current branch
claude --skill branch-auditor

# Audit specific branch against main
claude --skill branch-auditor feat/my-feature

# Audit against different base
claude --skill branch-auditor feat/my-feature --base develop
```

## Audit Report Includes

1. **Summary** — Commits, files, scope
2. **Changes by Layer** — Organized by the 6-layer architecture
3. **Test Coverage** — ✅ Tests found OR ❌ Gaps with prompted action items
4. **Issues & Findings** — Critical (blocking), warnings, and notes
5. **Code Quality** — Formatting, naming, comments, architecture
6. **Risk Score (0-10)** — With breakdown explanation
7. **Recommendations** — Safe to merge / Merge with caution / Do not merge

## Test Coverage Gaps

When no test changes are detected, the auditor:
1. Lists all modified modules
2. **Prompts you to create a test plan** with specific questions:
   - What are the edge cases?
   - What regressions could your changes introduce?
   - How will you verify on hardware?
3. Links to test suite examples

## Risk Scoring

**0-2**: Low — Trivial, well-tested, no architectural impact
**3-4**: Low-Medium — Tested, minor concerns
**5-6**: Medium — Some test gaps or moderate complexity
**7-8**: High — Major changes, test gaps, critical modules
**9-10**: Critical — Unresolved bugs, no tests, threading issues

## Architecture

The skill understands pgpemu's 6-layer architecture:

- **Layer 1: HAL** — Hardware abstraction (GPIO, UART)
- **Layer 2: Communication** — BLE setup (GAP, advertising)
- **Layer 3: Connection Mgmt** — GATT, handshake, multi-device
- **Layer 4: Storage** — NVS, settings, session keys
- **Layer 5: Features** — LED handling, button automation
- **Layer 6: System** — Main, stats, orchestration

## Test Suite

The skill references the comprehensive test suite:
- **252 total assertions** across 8 test modules
- Regression, edge cases, error handling, settings, storage, multi-device, utilities, certificates

## Usage Tips

1. Before opening a PR — Get a risk score
2. During code review — Validate architecture compliance
3. Before merging — Confirm test coverage
4. When diagnosing bugs — Check for pattern violations

## See Also

- `AGENTS.md` — Code review standards
- `README.md` — Test suite guide
- `.clang-format` — Code style rules
