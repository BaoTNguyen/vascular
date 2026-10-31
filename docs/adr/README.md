# Decisions

Why the stack is shaped the way it is: one file per decision, in trimmed
[MADR 4](https://github.com/adr/madr) (`template.md`; the rules are in
`2026-10-30-adr-format.md`). This folder holds decisions that span repos; a
decision one repo's code enforces lives in that repo's `docs/adr/`.

The "In force" table is generated from each record's front matter: run
`python3 docs/adr/index.py` after adding or superseding one. CI fails when the
table is stale.

## In force

<!-- adr-index:start -->
| Decision | Date | Binds |
|---|---|---|
| [GitHub enforces PR plus CI on main in the six component repos](2026-10-30-protect-main.md) | 2026-10-30 | heart, plexus, pulse, arteries, capillaries, marrow |
| [Plan text reaches pulse as artifacts on the existing plan events](2026-10-30-planning-data-in-pulse.md) | 2026-10-30 | plexus, pulse |
| [Record decisions as trimmed MADR 4, one file per decision](2026-10-30-adr-format.md) | 2026-10-30 | all repos |
| [A spec is a proposal; at landing it splits into truth and planning data](2026-10-29-spec-model.md) | 2026-10-29 | plexus |
<!-- adr-index:end -->

## In each repo

| Repo | Decision | Date |
|---|---|---|
| heart | [A sandboxed verifier gets HEART_PULSE and no credential](https://github.com/BaoTNguyen/heart/blob/main/docs/adr/2026-10-28-verifier-env.md) | 2026-10-28 |
| plexus | [Refuse unless HEART_SANDBOX is docker-sbx or off](https://github.com/BaoTNguyen/plexus/blob/main/docs/adr/2026-10-13-refuse-unsandboxed-runs.md) | 2026-10-13 |
