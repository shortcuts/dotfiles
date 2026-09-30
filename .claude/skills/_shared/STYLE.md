# Writing style for explanation skills

`explain` and `onboard` both write Diátaxis *explanations* for an engineer who knows the
field, not the subject. This file holds the voice they share. Each skill owns its own
output format and structure.

## Writing style

Write in Simplified Technical English, per
[`../../output-styles/ste.md`](../../output-styles/ste.md). Add these rules:

- **Each sentence carries one claim** the reader can check or picture. A sentence that
  fits a text on another subject carries nothing: cut it.
- **Physical verbs.** *Copies*, *sorts*, *waits*, *drops*, *splits*. Replace *handles*,
  *manages*, *orchestrates*, *leverages* with the action they hide.
- **Earn every term.** Introduce a term only when the text needs it. Define it in one
  clause, add it to the skill's word list, and never use a synonym.
- **Concrete units.** "Every 100 ms", "4 KB pages", never "often" or "large". Take each
  number from a source, or mark it as your own arithmetic.
- **Keep a claim as strong as its source.** When sources disagree, name both on the line.

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

## Examples stay in the field

Every scene, mammoth, and example comes from the subject's field. Never use shops,
restaurants, coat checks, or other everyday stand-ins.

- **Code, a commit, a PR, or a path:** use the repository's domain objects. In a job
  scheduler: jobs, runs, workers, queues.
- **A concept:** use a system from the same field. Explain a hash table with a DNS
  cache, not a coat check.

## Review passes

Run both passes on the finished prose, in this order. Skip diagrams, code, and
identifiers. Keep verbatim quotes and the fixed formats the skill names.

1. **`documentation` skill.** Review the text as a Diátaxis *explanation*: it gives
   understanding, never steps to follow or tables to look up. Move how-to or reference
   material out, or cut it.
2. **`no-ai-slop` skill, Edit mode.** Tell it the audience: an engineer new to the
   subject, reading on the output's medium (the skill names it).
