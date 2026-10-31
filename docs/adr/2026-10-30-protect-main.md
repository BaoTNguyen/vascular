---
status: accepted
date: 2026-10-30
approved-by: operator
drafted-by: operator
retire-evidence: a change in who acts with the operator's credentials; replay is not valid evidence
switch: none
---
# GitHub enforces PR plus CI on main in the six component repos

## Context and Problem Statement

"main only through a PR with green CI" was a convention. It held only because
Claude Code's permission check refuses merges. Any other tool or agent holding
the operator's GitHub credentials could push to main directly.

## Decision Drivers

* Agents act with the operator's credentials, so an admin exemption exempts them
* The operator is the only reviewer, and GitHub won't let an author approve their own PR

## Considered Options

* Branch protection: PR required (0 approvals), required check `test`, admins included, no force push or deletion
* Keep the convention: enforced only inside Claude Code sessions
* Require 1 approval: blocks every merge, since the operator authors the PRs
* Exempt admins: exempts every agent using the operator's credentials
* Also protect vascular: its `install.yml` `bump` job pushes to main itself

## Decision Outcome

Chosen option: "branch protection", on heart, plexus, pulse, arteries,
capillaries and marrow, because it holds for every actor, not only for Claude
Code sessions.

### Consequences

* Good, because a direct push to main fails for everyone, agents included.
* Bad, because a history rewrite (like 2026-10-20) means lifting protection
  first and restoring it after.
* Bad, because vascular's main stays unprotected until `bump` gets an exemption.

### Confirmation

GitHub branch protection, read back with
`gh api repos/BaoTNguyen/<repo>/branches/main/protection`. No automated check.
