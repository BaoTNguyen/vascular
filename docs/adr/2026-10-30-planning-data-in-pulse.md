---
status: accepted
date: 2026-10-30
approved-by: operator
drafted-by: operator
retire-evidence: storage cost, or a privacy finding in captured plans
switch: none
---
# Plan text reaches pulse as artifacts on the existing plan events

## Context and Problem Statement

`plan.created` carried feature ids and titles; `plan.amended` carried only the
names of changed fields. `plexus amend` rewrites the plan file, so the planner's
version of an amended spec was lost. The difference between the two is where
the planner was wrong.

## Decision Drivers

* What is lost now can't be recovered later; capture before anything uses it
* Events stay small; pulse already stores content-addressed blobs
* Nothing about planning should land in the repo (2026-10-29-spec-model.md)

## Considered Options

* Artifact hashes on the existing events, through `heart.events.artifact`
* Spec text inline in the event payload: large events, and pulse already has a blob store
* Archive specs in each repo under `docs/archive/`: the pile-up the spec model avoids

## Decision Outcome

Chosen option: "artifact hashes on the existing events". `plan.created` carries
`prompt_artifact`, `output_artifact`, `plan_artifact` and `spec_artifact`;
`plan.amended` carries `before_artifact` and `after_artifact`. Pulse's catalog
classes them as `content`.

### Consequences

* Good, because every plan and amendment from 2026-10-30 is kept, linked by goal and feature.
* Bad, because whatever first exports artifact bodies must scan them for secrets and
  hold out evaluation data; `pulse export` carries events only.

### Confirmation

plexus `src/plexus/plan.py::make_plan` and `::amend`; pulse
`contract/catalog.json`. Proven by plexus
`tests/test_vascular_state_dir.py::test_plan_text_reaches_pulse_as_artifacts`.
