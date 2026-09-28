# When the input is code, a commit, a PR, or a path

The code is evidence. The note explains the idea behind it: the rate limiter behind a
retry loop, the write-ahead log behind a crash fix. Keep file names, line numbers, and
ticket keys out of the note.

Run `git` and `gh` read operations only. A write (push, comment, review, label) makes you
a participant in the history you read.

## Find the idea

1. Read the code, then the commit messages, PR body, and review threads. Reviewers often
   name the idea, or the rejected alternative.

   ```bash
   gh pr view N --json title,body,commits
   gh api repos/OWNER/REPO/pulls/N/comments   # inline review threads
   gh api repos/OWNER/REPO/commits/SHA/pulls  # the PR a commit landed through
   git log --follow <path>                    # the commits that shaped a file
   ```

2. Name the principle in the field's words: *token bucket*, *two-phase commit*,
   *copy-on-write*. That name is the subject and the search term.
3. Find the paper, RFC, or article that owns that name, per
   [Sources](SKILL.md#sources).

## Where the code shows up on the note

- **The machine**: draw the machine as this code builds it. Label parts "buffer" or
  "retry timer", not with struct or function names.
- **Same principle, elsewhere**: name this code in one line: "Your upload path uses this
  to cap memory at 64 MB."
- **Where it strains**: state a limit the code hits as behavior with a number, not as a
  code location.

The code departs from the textbook idea: say how in one line under **The machine**. That
difference is often why the user asked.
