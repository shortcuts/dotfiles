---
name: explain
description: Explain any topic as one illustrated Obsidian note in the spirit of The Way Things Work - the principle, the machine opened up, and trusted sources to go further.
disable-model-invocation: true
argument-hint: "A topic, concept, commit hash, PR/commit URL, file, or directory"
---

Write one Markdown note in the user's Obsidian vault. The note follows David Macaulay's
*The Way Things Work*:

1. The **principle**: the one idea that makes the machine possible.
2. The **machine**: the subject, opened up, with numbered parts.
3. Other machines that use the same principle.

**The reader** is the user: a software engineer who knows the field, not this subject.
They read on a phone. They want the idea, not the implementation.

**The note is done when:**

- The reader can draw the principle from memory and say why it works.
- The reader can predict the machine's output for an input the note never showed.
- The reader can name where the machine strains, and which source to open next.
- `python3 check.py <note>` in this skill's folder prints `ok`.

## The order of the note

The note is a Diátaxis *explanation*: no setup steps, no reference tables. Use these `##`
sections in this order. `check.py` reads the heading names, so keep them exact.

1. **Title and one line.** `# <Subject>`, then one sentence: what the subject is and
   what it is for.
2. **The problem.** What breaks before the subject exists. Show it as a scene from the
   field (see [Examples stay in the field](#examples-stay-in-the-field)). Use no term
   from the subject yet.
3. **The principle.** One to three principles, each under a `###` heading. Each gets:
   - one bold sentence: the cause, the effect, and why the link holds;
   - its [mammoth](#the-mammoth);
   - a plate that shows the principle before any machine uses it;
   - one sentence on what the principle costs.
4. **The machine.** A cutaway plate with numbered callouts and a key. Then **One trip
   through**: follow one real input part by part, with small real values. Cite the
   callout numbers.
5. **Same principle, elsewhere.** Two to four other machines, one line each: the machine,
   and which part plays which role.
6. **Where it strains.** Each limit gets a number or a named case: the input that breaks
   it, the size where it slows, the alternative that wins there.
7. **Where it came from.** Three to five lines from the papers: who, when, what it
   replaced, and why.
8. **Words.** Each term the note introduced, with a one-line definition.
9. **Check yourself.** Three questions, each under 15 words. Each question asks the reader
   to predict or explain, never to recall a word. Fold each answer, so the phone shows
   the question alone:

   ```markdown
   > [!question]- What happens if two keys hash to one slot?
   > The second key goes to the next free slot (plate 2, callout 4).
   ```

10. **Go further.** Three questions the note did not answer. Each points to the section
    of a **Sources** entry that answers it.
11. **Sources.** See [Sources](#sources).

## Writing style

Write the note in Simplified Technical English, per
[`../../output-styles/ste.md`](../../output-styles/ste.md). Add these rules:

- **Each sentence carries one claim** the reader can check or picture. A sentence that
  fits a note on another subject carries nothing: cut it.
- **Physical verbs.** *Copies*, *sorts*, *waits*, *drops*, *splits*. Replace *handles*,
  *manages*, *orchestrates*, *leverages* with the action they hide.
- **Earn every term.** Introduce a term only when the note needs it. Define it in one
  clause, add it to **Words**, and never use a synonym.
- **Concrete units.** "Every 100 ms", "4 KB pages", never "often" or "large". Take each
  number from a source, or mark it as your own arithmetic.
- **Keep a claim as strong as its source.** When sources disagree, name both on the line.

Then run the prose through the `no-ai-slop` skill in Edit mode. Tell it the audience: an
engineer new to the subject, reading on a phone. Keep verbatim quotes and the fixed
formats: key entries, captions, source entries, `Breaks down at:`. Skip plates, code,
and identifiers.

## The mammoth

Macaulay shows each principle acting on a woolly mammoth, so the reader remembers it.
Here, each principle gets one mammoth: a concrete scene that obeys the principle. One
scene can serve several principles, with a new mapping for each.

Map the scene part to part:

| In the scene | In the subject |
|---|---|
| The job ID | The hash |
| The worker shard the job lands on | The bucket |

Then write one line on where the scene stops matching. It is often the most useful line:

`Breaks down at: a job has one fixed shard, but two keys can share a bucket.`

### Examples stay in the field

Every scene, mammoth, example, and **One trip through** input comes from the subject's
field. Never use shops, restaurants, coat checks, or other everyday stand-ins.

- **Code, a commit, a PR, or a path:** use the repository's domain objects. In a job
  scheduler: jobs, runs, workers, queues.
- **A concept:** use a system from the same field. Explain a hash table with a DNS
  cache, not a coat check.

## Plates

Plates carry the idea. Prose supports them. Show only the parts the idea needs.

| Idea to show | Plate |
|---|---|
| The parts of one thing | Cutaway with numbered callouts |
| Layers, or a format read from byte 0 | Exploded view, in reading order |
| One small part that matters | Enlargement circle out of the cutaway |
| An input moving through the machine | Strip of numbered frames |
| Before and after, or two options | Side-by-side pair, one difference marked |

Draw plates as inline SVG. Use Mermaid for boxes-and-arrows flow, and a small table for a
finite set of cases. Read [`PLATES.md`](PLATES.md) before the first plate.

## Sources

Every claim traces to a source. A note from memory can be wrong, and the reader cannot
tell. Accept only:

- the primary source: the paper, RFC, or specification;
- peer-reviewed papers and arXiv preprints;
- Wikipedia, for general concepts and history, then its references;
- articles by the inventors, maintainers, or recognized practitioners.

How to read them:

- Search with `WebSearch`. Open every link with `WebFetch` before you cite it.
- For a PDF, `curl -L` it into the scratchpad and `Read` it. `WebFetch` returns raw bytes.
- A publisher blocks the fetch: cite the authors' copy or a university mirror.
- A general idea with no single owner: read two independent sources.

Format each entry as a link, then one line: what it covers and when to open it. Put the
one best read first and say why. Put that link in the `source:` frontmatter too.

```markdown
- [Karger et al., 1997 — Consistent Hashing and Random Trees](https://…) The paper that
  names the idea. Read sections 1–2 for the ring; skip the proofs.
```

## Resolving the input

| Input | Meaning |
|---|---|
| Bare commit hash | A commit of the repo in the current directory |
| GitHub commit or PR URL | That change, in that repo |
| A path | That code as it stands |
| Anything else | A concept, tool, protocol, format, practice, or idea |

A bare word can be a concept or a directory: ask which, nothing else.

For code, read [`SOURCE-CODE.md`](SOURCE-CODE.md). The code is evidence. The subject is
the idea it embodies.

## Writing the file

1. Read [`VAULT.md`](VAULT.md) for the vault path, frontmatter, tags, and note location.
2. Write the note.
3. Run `python3 check.py <note>` from this skill's folder. Fix each line until it prints
   `ok`.
4. Open the note and stop.

A follow-up question about one part gets its answer in the conversation, with a plate or
a Mermaid diagram. Regenerate the note only when the user asks.
