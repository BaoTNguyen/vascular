---
status: accepted
date: 2026-07-20
approved-by: operator
drafted-by: operator
retire-evidence: a seam breaking in production that no contract test covers
switch: none
binds: heart, plexus, pulse, arteries, capillaries, marrow
---
# Seams are pinned by contract tests in each repo, not a shared library

## Context and Problem Statement

The repos meet at seams: the event spine, plexus importing heart, the env a
role receives, ingest. A change in one breaks another at run time.

## Decision Drivers

* A refactor must fail the consumer's suite, not a goal run
* No package boundary that every repo must release against

## Considered Options

* Contract tests per seam, owned by the consumer or the contract owner, run in each repo's suite, plus one stack smoke ("same id in four places")
* A shared library: the dependency every repo would release against, deliberately not built

## Decision Outcome

Chosen option: "contract tests per seam". Spine conformance (heart), the heart
API pin (plexus), env propagation (heart), and `stack-smoke.sh` end to end.

### Consequences

* Good, because each repo stays installable alone, and a seam break fails CI.
* Bad, because a new seam needs someone to write its test.

### Confirmation

heart `tests/test_spine.py`, `contrib/stack-smoke.sh`; plexus `tests/test_heart_api_pin.py`.
