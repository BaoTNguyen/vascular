---
status: accepted
date: 2026-10-30
approved-by: operator
drafted-by: operator
retire-evidence: authoring friction (ADRs skipped, or growing past the cap)
switch: none
---
# Record decisions as trimmed MADR 4, one file per decision

## Context and Problem Statement

Why the stack is shaped the way it is lived in design docs, cleanup reports
and a private roadmap, mixed with specs and history, with nothing saying what
still holds. Agents can read the code; they can't read the alternatives that
were rejected.

## Decision Drivers

* Parallel plexus features land at once, so one shared file conflicts
* Agents draft these, and invented "alternatives considered" are the main risk
* Any decision may be revisited; what differs is which evidence may retire it

## Considered Options

* MADR 4, trimmed: front matter plus Context, Drivers, Options, Outcome, Confirmation
* One decision-log file per repo: merge conflicts between parallel landings
* MADR 4 in full: pros and cons per option push records past 100 lines
* Two kinds of record (invariant, steering): the boundary is fuzzy and invites "never question this"

## Decision Outcome

Chosen option: "MADR 4, trimmed", because its section names are what tools and
agents already know, its `Confirmation` section names what enforces a decision,
and front matter lets an index be generated rather than kept by hand.

Rules:
* One file per decision, named `YYYY-MM-DD-topic.md`; never edited except its status.
* A decision lives in the repo whose code enforces it. Contracts between repos
  live here, and each affected repo's index points to them.
* At most 40 non-blank lines below the front matter, and at least one rejected option. Rejected options come
  from the spec, the review or the operator, never from an agent after the fact.
* `retire-evidence` says what may retire the decision. Replay ablation is not
  valid evidence for a guardrail: the replay set has no adversarial tasks.
* A `switch` must be out of agents' reach (operator env, not repo config).

### Consequences

* Good, because each record stays small and the in-force set stays readable.
* Bad, because the folder grows forever; superseded records stay as history.

### Confirmation

Manual for now: `template.md` beside this file. A CI check for the length cap,
the rejected option and the paths named under Confirmation is not built yet.
