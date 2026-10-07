# vascular

[![install](https://github.com/BaoTNguyen/vascular/actions/workflows/install.yml/badge.svg)](https://github.com/BaoTNguyen/vascular/actions/workflows/install.yml)

The whole agent stack in one clone. Each directory here is a git submodule
pointing at its own repo. Nothing is copied, so this umbrella and the individual
repos can't drift apart: clone either way and you get the same code, in the same
sibling layout the repos already expect of each other.

| repo | what it does | needs beside it |
|---|---|---|
| [heart](https://github.com/BaoTNguyen/heart) | runs coding agents: orchestration, sandbox, reward | nothing (arteries optional) |
| [plexus](https://github.com/BaoTNguyen/plexus) | turns a goal into features and lands them through heart | heart |
| [capillaries](https://github.com/BaoTNguyen/capillaries) | retrieves the right prompt or skill for a situation | nothing (arteries optional) |
| [arteries](https://github.com/BaoTNguyen/arteries) | memory and tracing for agent sessions | capillaries |
| [marrow](https://github.com/BaoTNguyen/marrow) | RL training on heart's episodes (GPU) | heart |
| [pulse](https://github.com/BaoTNguyen/pulse) | the event journal: collects every component's events, one query API | nothing (design only; no code yet) |

```text
plexus ──> heart ··> arteries <──> capillaries
marrow ──> heart
pulse  <·· every component appends events to ~/.vascular/spool/events; pulse imports none of them
           ──> required   ··> optional
```

## Quick start

[uv](https://docs.astral.sh/uv/) and git. uv fetches a suitable Python itself
(plexus needs 3.11+; the other four run on 3.10).

```bash
git clone --recursive https://github.com/BaoTNguyen/vascular && cd vascular
for r in heart plexus arteries capillaries; do (cd $r && uv sync && uv run pytest -q) || echo "^ $r failed"; done
(cd marrow && uv run --only-group dev pytest -q)
```

Forgot `--recursive`? Run `git submodule update --init`.

Each repo gets its own `.venv`. Its siblings come from `../<name>` through
`[tool.uv.sources]`, which resolves here exactly as it does in a standalone
clone, so the commands are the same in both layouts. marrow's tests need only
heart; plain `uv sync` there also pulls the training stack (torch,
bitsandbytes, a CUDA GPU), so the quick start skips it.

For the commands on your PATH, to use from any repo:

```bash
uv tool install --editable heart --with-editable arteries
uv tool install --editable plexus --with-editable heart
```

## Taking just one piece

Clone what the table says it needs into the same parent directory, then follow
that repo's README:

```bash
mkdir stack && cd stack
git clone https://github.com/BaoTNguyen/heart
git clone https://github.com/BaoTNguyen/plexus    # plexus needs heart next to it
```

None of these packages is on PyPI. `uv add heart` or `uv tool install heart`
fetches somebody else's project, so always install from the checkout.

## What the tests skip, and what running for real needs

Tests pass on a bare machine. What they can't reach, they skip:

- **Postgres 14+ with pgvector**: arteries' and capillaries' live paths. Setup is
  in the capillaries README; its `db` tests run once `DB_*` points at a database.
- **An embedding endpoint**: capillaries retrieval (`EMBED_URL`).
- **Docker and an agent CLI** (claude, codex, ...): heart runs agents in a
  sandbox. `plexus doctor` lists what this box is still missing.
- **GPUs**: marrow training only.

## Both layouts on one machine

They can't interfere: every checkout keeps its own `.venv`. The one shared
thing is `uv tool install`, where the last install wins. To see which checkout
your `heart` command runs:

```bash
"$(uv tool dir)/heart/bin/python" -c "import heart; print(heart.__file__)"
```

## Updating

```bash
git pull --recurse-submodules        # the versions this umbrella pins
git submodule update --remote        # or: every repo's latest main
```

The pins move themselves. [`install.yml`](.github/workflows/install.yml) runs
daily: the quick start above against both the pins and every repo's latest
main, plus each repo cloned alone with only the siblings in the table. When all
of that passes, it commits the new pins. A red badge means one of those routes
broke for a new user; the job name says which.
