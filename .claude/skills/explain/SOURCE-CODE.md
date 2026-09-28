# When the input is code, a commit, a PR, or a path

The code is evidence. The note explains the idea the code embodies: the rate limiter
behind a retry loop, the write-ahead log behind a crash fix, the columnar layout behind
a file reader. The reader wants that idea, so the note names concepts and leaves file
names, line numbers, and ticket keys in the repository.

Use `git` and `gh` read operations only. Any write (push, comment, review, label) makes
you a participant in a history you are here to read.

## Find the idea

1. Read the change or the code, then the words around it: commit messages, the PR body,
   and the review threads. Reviewers often name the idea, or the rejected alternative.

   ```bash
   gh pr view N --json title,body,commits
   gh api repos/OWNER/REPO/pulls/N/comments   # inline review threads
   gh api repos/OWNER/REPO/commits/SHA/pulls  # the PR a commit landed through
   git log --follow <path>                    # the commits that shaped a file
   ```

2. Name the principle in the field's own words: *token bucket*, *two-phase commit*,
   *copy-on-write*. That name is the note's subject, and the search term for its sources.
3. Find the paper, RFC, or article that owns that name. Use those as the sources, per
   [Sources](SKILL.md#sources).

## Where the code shows up on the note

- **The machine**: draw the machine as this code builds it, in concepts. Label parts
  "buffer" or "retry timer", not the struct or function names.
- **Same principle, elsewhere**: this code is often the reader's first example. Name it
  in one plain line: "Your upload path uses this to cap memory at 64 MB."
- **Where it strains**: a limit the code hits is a good case. State it as behavior with
  a number, not as a code location.

When the code departs from the textbook idea, say how in one line under **The machine**.
That difference is often why the user asked.
