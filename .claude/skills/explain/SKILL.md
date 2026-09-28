---
name: explain
description: Explain any topic as one illustrated Obsidian note in the spirit of The Way Things Work - the principle, the machine opened up, and trusted sources to go further.
disable-model-invocation: true
argument-hint: "A topic, concept, commit hash, PR/commit URL, file, or directory"
---

Write one Markdown note in the user's Obsidian vault. It explains one subject the way
David Macaulay's *The Way Things Work* explains a machine. Macaulay starts from the
**principle**: the one physical idea that makes the machine possible. Then he draws the
**machine** opened up, with every part numbered. Then he shows the other machines that
use the same principle.

The reader is the user: a software engineer and a tinkerer. They know their own field
and nothing about this subject. They read the note on their phone, away from a keyboard.
They want the **idea**. The implementation is someone else's problem.

The note is done when:

- The reader can draw the principle from memory and say why it works.
- The reader can predict what the machine does with an input the note never showed.
- The reader can name where the machine strains, and which trusted source to open next.
- `python3 check.py <note>` in this skill's folder prints `ok`.

## The order of the note

A Diátaxis *explanation*: it serves understanding, so it holds no setup steps and no
reference tables. Use these `##` sections in this order. The heading names are fixed,
because `check.py` reads them.

1. **Title and one line.** `# <Subject>`, then one sentence in plain words: what the
   subject is and what it is for. Positive: say what it *is*.
2. **The problem.** The thing that breaks, or the job nobody can do, before this subject
   exists. Use an everyday scene. No term from the subject appears yet.
3. **The principle.** One to three principles, each under its own `###` heading. Each
   principle gets:
   - one bold sentence: cause, effect, and the property that makes the link hold;
   - its **mammoth** (see [The mammoth](#the-mammoth));
   - a plate that shows the principle alone, before any machine uses it;
   - one sentence on what the principle costs.
4. **The machine.** The subject itself, drawn as a cutaway plate with numbered callouts
   and a key. Then **One trip through**: follow one real input part by part, citing
   the callout numbers, with small real values. A reader who follows one case owns the
   mechanism.
5. **Same principle, elsewhere.** Two to four other machines built on the same principle,
   one line each: the machine, and which part of it plays which role. This section
   turns one idea into a pattern the reader recognizes everywhere.
6. **Where it strains.** The limits and tradeoffs, each with a number or a named case:
   the input that breaks it, the size where it slows, the alternative that wins there.
7. **Where it came from.** Who proposed it, when, what it replaced, and what problem
   forced it. Three to five lines, taken from the papers.
8. **Words.** The glossary. Each term the note introduced, with a one-line definition.
9. **Check yourself.** Three questions that make the reader predict or explain, never
   recall a word. Keep each question under 15 words. Put each answer in a folded callout, so the phone shows the question
   alone:

   ```markdown
   > [!question]- What happens if two keys hash to one slot?
   > The second key goes to the next free slot (plate 2, callout 4).
   ```

10. **Go further.** Three open questions the note did not answer. Each one points to
    the section of a source in **Sources** that answers it.
11. **Sources.** See [Sources](#sources).

## Words that carry meaning

Every sentence carries one claim the reader can check or picture. A sentence that would
read the same in a note about another subject carries nothing: cut it.

- **Physical verbs.** Write the action a reader can picture: *copies*, *sorts*, *waits*,
  *counts*, *hashes*, *drops*, *splits*. A verb earns its place when the reader could
  draw it. *Handles*, *manages*, *orchestrates*, and *leverages* draw nothing: replace
  each one with the action it hides.
- **One idea per sentence, under 20 words.** Short common words beat long exact-sounding
  ones.
- **Earn every term.** A term appears only after the note needs it. Define it in one
  clause at first use, add it to **Words**, and reuse the same word to the end. A
  synonym reads as a second concept.
- **Concrete units.** "Every 100 ms", "4 KB pages", "1 in 10⁶ keys" — never
  "often", "large", "most". Take each number from a source, or mark it as your own
  arithmetic on the same line.
- **Keep a claim as strong as its source.** When the sources disagree, say so on the
  line and name both.

Then run the drafted prose through the `no-ai-slop` skill in Edit mode. Give it the
audience up front: a software engineer new to this subject, reading on a phone to learn
the idea. Cut rather than smooth. Keep quotes from papers verbatim, and keep the note's
fixed formats as they are: key entries, captions, source entries, and `Breaks down at:`.
Skip the pass over plates, code, and identifiers.

## The mammoth

In Macaulay's book, a woolly mammoth shows each principle. A lever lifts it, a pulley
hoists it, a wedge splits its ice. The reader remembers the principle because they saw it
act on something large and physical.

Each principle gets one mammoth: a physical scene that obeys the same principle. One scene
can serve several principles, with a new mapping for each. A
mammoth is more than a loose likeness. It must map part to part:

| In the scene | In the subject |
|---|---|
| The coat-check ticket | The hash |
| The numbered hook | The bucket |

Give the mapping, then one line on where the scene stops matching:
`Breaks down at: two coats never share a hook, but two keys can share a bucket.` That
line is often the most useful sentence in the section.

## Plates

Plates carry the idea. Prose supports them. Each principle gets a plate, and the machine
gets a cutaway. Pick the form that shows the idea fastest:

| Idea to show | Plate |
|---|---|
| The parts of one thing and how they fit | Cutaway with numbered callouts |
| Layers, or a format read from byte 0 | Exploded view, stacked in reading order |
| One small part that matters | Enlargement: a circle zooming out of the cutaway |
| An input moving through the machine | Strip of numbered frames, left to right, wrapping down |
| Before and after, or two options | Side-by-side pair with one difference marked |

Draw plates as inline SVG. Use a Mermaid diagram for boxes-and-arrows flow, and a small
table for a finite set of cases. [`PLATES.md`](PLATES.md) holds the SVG rules that keep a
plate legible on a phone in both themes, plus a template. Read it before you draw the
first plate.

Show only the parts the idea needs. A plate that shows everything shows nothing.

## Sources

The note is a starting point. **Sources** is where the reader continues alone, so each
entry must be worth the tap. Every claim on the note traces to one of them. A note
written from memory sounds sure and can be wrong, and the reader cannot tell.

Take sources only from these kinds:

- The primary source: the paper that introduced the idea, the RFC, or the specification.
- Peer-reviewed papers, and preprints on arXiv.
- Wikipedia, for general concepts and history. Follow its references to the papers.
- Articles written by the inventors, the maintainers, or recognized practitioners.

Search with `WebSearch`, read each page with `WebFetch`, and open every link before you
cite it. `WebFetch` returns a PDF as raw bytes: download it with `curl -L` into the
scratchpad and read it with `Read`. When a publisher blocks the fetch, cite the authors'
own copy or a university mirror. For a general idea that no single source owns, read two independent sources.

Format each entry as a link followed by one line: what it covers and when to open it.
Put **the one best read** first, and say why it is the one. That link also goes into the
`source:` frontmatter.

```markdown
- [Karger et al., 1997 — Consistent Hashing and Random Trees](https://…) The paper that
  names the idea. Read sections 1–2 for the ring; skip the proofs.
```

## Resolving the input

| Input | Meaning |
|---|---|
| Anything not listed below | A concept, tool, protocol, format, practice, or idea |
| Bare commit hash | A commit of the repo in the current directory |
| GitHub commit or PR URL | That change, in that repo |
| A path | That code as it stands |

A bare word can be a concept or a directory. Ask which, and ask nothing else.

For code, a commit, a PR, or a path, the code is evidence. The subject is the idea the
code embodies. Read [`SOURCE-CODE.md`](SOURCE-CODE.md) to find that idea.

## Writing the file

Read [`VAULT.md`](VAULT.md) for the vault path, frontmatter, tags, and where the note
goes. Write the note, then run `python3 check.py <note>` from this skill's folder. Fix
every line it prints until it prints `ok`. Then open the note and stop.

A follow-up question about one part gets its answer in the conversation, with a plate or
a Mermaid diagram. Regenerate the note only when the user asks.
