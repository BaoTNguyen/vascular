---
status: accepted
date: 2026-10-29
approved-by: operator
drafted-by: operator
retire-evidence: the landing split costing more operator time than the truth layer saves
switch: none
binds: plexus
---
# A spec is a proposal; at landing it splits into truth and planning data

## Context and Problem Statement

A plexus goal's spec holds a whole feature's worth of decisions. Kept as
documents, specs pile up (one per feature) and nothing marks which still hold.
Planning also needs them: a spec next to its outcome is what learning to plan
reads.

## Decision Drivers

* Proposal quality and documentation quality must be separately attributable
* The repo must not grow by one file per feature
* Planning data must keep the planner's version, not only the final one

## Considered Options

* C: the spec is a proposal; at landing, what still holds goes to READMEs, the architecture map, ADRs and tests, and the spec goes to pulse
* A, a new spec per feature, kept forever: decisions buried in hundreds of files (warp keeps about 50 a month)
* B, one living spec per area: in-flight edits reach the truth before they are judged

## Decision Outcome

Chosen option: "C", because only C keeps the plan and the truth separate, and
storing specs as planning data in pulse keeps them out of the repo.

### Consequences

* Good, because the repo holds only what is true now; specs stay as data, tied to outcomes.
* Bad, because the landing split is a new step, and it isn't built yet.

### Confirmation

Planning capture is live (2026-10-30-planning-data-in-pulse.md). The landing
split and its docs check are not built.
