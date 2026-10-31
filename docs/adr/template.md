---
status: proposed            # proposed | accepted | superseded by <file> | retired
date: YYYY-MM-DD            # when it was decided; never updated
approved-by: operator
drafted-by: operator        # or the plexus episode id that drafted it
retire-evidence: ""         # what may retire this: "replay ablation", or a threat/requirement change
switch: none                # the operator-only switch that turns it off, or none
---
# {short title: the problem and the chosen solution}

## Context and Problem Statement

{2–3 sentences}

## Decision Drivers

* {driver; if it stops holding, this decision is up for review}

## Considered Options

* {chosen option}
* {rejected option}: {why, one line}

## Decision Outcome

Chosen option: "{option}", because {justification}.

### Consequences

* Good, because …
* Bad, because …

### Confirmation

{what enforces it}: {path::symbol}. Proven by {tests/path::test_name}.
