---
status: accepted
date: 2026-07-20
approved-by: operator
drafted-by: operator
retire-evidence: repeated features that no repo's question fits
switch: none
binds: all repos
---
# A feature lives in the repo whose question it answers

## Context and Problem Statement

Taking the stack from "each repo works" to "the factory works" kept raising
the same question: which repo does this belong in? Without a rule, features
land twice.

## Decision Drivers

* No feature built twice, in two repos
* Two checks that look alike may judge different things

## Considered Options

* Ownership by question: what to build next and is scope satisfied (plexus); was the task done right and how agents run (heart); what happened (pulse); what do we remember (arteries); which prompt or skill fits (capillaries); learning (marrow)
* Merge plexus acceptance into heart's verify: heart judges the task, acceptance judges the goal; "heart passed, acceptance failed" is a hard negative nothing else yields
* Merge capillaries feedback into episode outcomes: one is local relevance, the other outcome; joined by `episode_id`, neither replaces the other

## Decision Outcome

Chosen option: "ownership by question", with those two near-duplicates kept on
purpose. The read side, first planned in heart, moved to pulse (2026-10-06).

### Consequences

* Good, because "where does this go" has one answer.
* Bad, because a feature spanning two questions needs a contract between repos.

### Confirmation

By review. Each repo's README states what it owns and must never own.
