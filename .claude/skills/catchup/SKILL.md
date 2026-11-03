---
name: catchup
description: "Catch the user up on what changed in a repository over a time range or for one scope (a feature, an area), grouped by feature and described as the state on the default branch today, in plain words and small visuals. List every item waiting on them with what they need to decide it from the reply alone. Use for /catchup, 'what changed since last week', 'catch me up on replication'."
disable-model-invocation: true
argument-hint: "A time range or a scope, e.g. 'since last week', 'on feature replication', 'on custom dictionaries'"
---

# Catchup

Catch the user up on what changed in this repository for the range or scope they gave after `/catchup`, and help them understand each change, not only where it stands. Then lay out every call waiting on them so they can make it from your reply alone. Assume the user remembers nothing about the period.

Say what changed for the user, not how you did it. Say "the tests pass", not "CI is green". Leave out hashes, file paths, commands, build numbers, and test counts unless the user needs one to act. Call each PR, branch, or feature by a name the user would know, not by a label you invented. If a fact needs context to make sense, give the context or leave the fact out.

## Resolve the request

The argument has one of three shapes:

- **Time range**: "since last week", "last 10 days", "since the 15th".
- **Scope**: "on feature replication", "on custom dictionaries". With no dates, the window is the last 30 days. Say so in one clause.
- **Both**: "replication since October". Apply the scope inside the range.

With no argument, use the last 7 days. Convert relative dates before you query, and never type today's date from memory: run `date +%F`. When a phrase has two readings ("last week"), take the last 7 days and say so in one clause. State the resolved window at the top of the reply.

## Gather what changed

Keep this turn read-only. Make visuals only from what you already have: do not change code, start an app or a job, or post anything. Work in the current repository and read the default branch, not the local checkout:

```bash
git fetch origin --quiet
base=$(git symbolic-ref --short refs/remotes/origin/HEAD)
git log "$base" --since="<start>" --no-merges --format='%h %s'
```

For a scope, find the directories that own it, then list the PRs that touched them (`git log "$base" --since="<start>" --format='%h %s' -- <dirs>`). Add PRs that match by title or body but touch other paths:

```bash
gh pr list --state merged --search "<scope> in:title,body merged:>=<start>" --json number,title,labels,mergedAt,author
gh pr view <n> --json title,body,labels,author,mergedAt,files
```

Run `gh pr view` only for PRs that matter. A label such as `epic:...` names the feature the team already uses: prefer it over a name you invent. Skip release, bump, and dependency PRs unless the user asked.

Group by feature, never by date. Cluster changes by shared scope, epic label, files, or PRs that reference each other. Order features by impact on the user, biggest first. Only the final state counts: read the code or docs on `$base` as they are now (`git show "$base:<path>"`) and describe that. A feature built Sunday and refactored Monday is one feature, described as Monday left it. Never report a change a later PR undid. Drop a feature that changed nothing the user can see (pure refactors, test-only, CI). Name any feature whose final state you could not confirm, and say what you could not check. When `gh` fails, fall back to `git log` and say the PR context is missing.

An action item is a call or step only the user can take, such as a product choice, an approval, a review, an irreversible action, or access you lack. Include any open PR on this range or scope that waits on the user, such as one that asks for their review. Work you can still do yourself is not an action item. Never make up a call to fill the reply. A step the user did not ask for and the work does not need is not an action item, unless it is irreversible and waiting on the user: give it one line and no visual.

One call can cover many items, such as each PR in a set awaiting merge. For each item, collect its link, what it changes for users, the evidence behind your pick, its risk, and your pick. Write "unknown" for a fact the call needs that you do not know. Leave out a link you do not have.

## Write the reply

Spend words on the calls, not on the story. Keep each feature to about 60 words: what it is now, what changed against the old behavior, and who to ask when the user may want to. Give each action item about 30 words. The reply grows with the number of features and items: two items need well under 150 words in all, not counting pictures, and thirty need far more. Never cut items or shrink them to stay under a word count: no count in place of a list, and no link in place of an item. A link can add depth, but the reply alone must be enough to decide.

Open with one short sentence that names what waits on the user, or says nothing does. The action items give the detail. If nothing changed and nothing waits on the user, say so and stop.

Then show what changed, pictures first. Embed inline any screenshot or video a PR shows for a visible change, then any diagram that explains a change. Then sum up in one short bullet per feature: its final state, and a risk only when there is one (a breaking change, a flag that is off by default, a migration). Write each line the way you would say it out loud: "Search is faster since the index now skips empty fields", not "Search: perf PR merged". Each line must stay true when read alone. Never mark something done that still waits on the user, and leave out anything the action items say. Under the summary, give at most three short lines that change what the user knows or must do, such as a feature you could not confirm. Then name in one line any work left that you can do yourself.

Then list the action items. Ask the call the user owns, such as merge, approve, or pick, and give your pick. A step you would take first goes in your pick. So does anything that must happen first, and anything that cannot be undone. Give the number or link of each PR, issue, or branch a call is about, also in a call between options.

Fit the shape to the call. A call about one item is one bullet: the call, your pick, what it changes for users, the evidence behind your pick, and its risk, with the item named once. When items share a call, write the call and your pick once, then give each item its own bullet, riskiest first: its link and name, what it changes for users, the evidence behind your pick, and its risk. Name an item's pick only where it differs from the call's. Give each item's risk even when it is low, such as "Low risk: only the colors change." Say what waiting costs only when it is more than a delay, such as a deadline or lost data.

For a call between options, give every option the work weighed, each with what it gets the user and what it costs, and the current state when there is one. Those costs are the call's risk, so add no separate risk line.

## Visuals

A visual is a picture: a screenshot, a video, a Mermaid diagram, a chart or diagram from `clidraw`, or a generated image. A Markdown table is not a visual, even with before and after columns.

When something is easier to grasp as a picture than as sentences, draw it: how a feature or system works, a PR stack or dependency chain with each PR's state, a before and after of a change, or options side by side. Never draw a status list, a timeline of PRs, a list of action items, or boxes with nothing connecting them. Never give a fact twice, in text or across visuals.

Keep each visual small enough to read at a glance: at most six boxes, with at most eight words in each. Write labels as plain words a person would say, not tags like "Tests: pass". A fact that needs a sentence belongs in the text, or nowhere.

Embed screenshots and videos inline when the change is visible, not only as links. Draw diagrams and charts from facts you have: a Mermaid diagram for how things connect and a `clidraw` chart for numbers. Never invent a number, and never draw or generate a picture of a screen you did not capture. Link only artifacts that exist.
