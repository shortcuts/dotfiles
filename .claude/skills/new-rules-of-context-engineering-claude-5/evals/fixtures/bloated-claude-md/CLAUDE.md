# CLAUDE.md

This repository is a TypeScript project. It uses Node.js. The source code is
located in the `src/` directory. Tests are located in the `tests/` directory.
The project uses npm as its package manager. Configuration files are in the
root directory.

## Code Style Rules

- NEVER write comments in code. Comments are forbidden.
- Leave documentation where appropriate so future readers understand the code.
- ALWAYS use arrow functions. NEVER use the `function` keyword.
- You MUST run prettier after every single file edit, no exceptions.
- NEVER use `any` type. ALWAYS use strict types.
- ALWAYS write descriptive variable names. NEVER abbreviate.

## Important Gotcha

All shared types MUST live in `src/types/index.ts` and nowhere else — the
codegen step reads only that file, and types defined elsewhere silently break
the generated client.

## How to use the database MCP server

The db MCP server has a `query` tool. To use it, call `query` with a `sql`
parameter containing your SQL string. For example:
`query({sql: "SELECT * FROM users"})`. It also has an `insert` tool which
takes a `table` parameter and a `values` parameter. Always use the `query`
tool for reads and the `insert` tool for writes. The server also exposes a
`migrate` tool for running migrations, which takes a `direction` parameter
that can be "up" or "down".

## Code Review Procedure

When reviewing code, follow these steps exactly:

1. First, read every changed file in full.
2. Second, check each function for missing error handling.
3. Third, verify all new code has tests.
4. Fourth, check for security issues: SQL injection, XSS, secrets in code.
5. Fifth, verify naming conventions match the style guide.
6. Sixth, check imports are sorted alphabetically.
7. Seventh, write up findings ordered by severity.
8. Eighth, suggest fixes for each finding.

## Memory

At the end of every session, remember to save important context to this file
using the # hotkey so it persists. Update the "Learnings" section below with
anything you discovered.

## Learnings

- (add learnings here)

## Testing

Run tests with `npm test`. Tests use vitest. Test files end in `.test.ts`.
To run a single test file use `npm test -- path/to/file.test.ts`. Write tests
for all new code. Tests should be comprehensive and cover edge cases. Good
tests are important for code quality.

## Expected search behavior

The search feature should return results ranked by relevance. Exact title
matches come first, then partial title matches, then body matches. Results
from archived documents rank below all non-archived results. Ties break by
most recently updated. (See also `tests/search-ranking.test.ts` which covers
all of these cases.)
