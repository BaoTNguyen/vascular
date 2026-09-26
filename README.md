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

```text
plexus ──> heart ··> arteries <──> capillaries
marrow ──> heart
           ──> required   ··> optional
```

## Quick start

Python 3.11+ and git. That's all the tests need. (plexus needs 3.11; the other
four run on 3.10 on their own.)

```bash
git clone --recursive https://github.com/BaoTNguyen/vascular && cd vascular
python3 -m venv .venv && . .venv/bin/activate
pip install -e capillaries -e arteries -e heart -e plexus pytest
for r in heart plexus arteries capillaries marrow; do (cd $r && python -m pytest -q) || echo "^ $r failed"; done
```

Forgot `--recursive`? Run `git submodule update --init`.

marrow's tests need only heart. Training needs `pip install -e marrow` (torch,
bitsandbytes, a CUDA GPU), so that step is left out above.

The repos that ship a `uv.lock` (arteries, plexus) also work with `uv sync`
from their own directory, because their `../sibling` path sources resolve here
exactly as they do in a standalone clone.

## Taking just one piece

Clone what the table says it needs into the same parent directory, then follow
that repo's README:

```bash
mkdir stack && cd stack
git clone https://github.com/BaoTNguyen/heart
git clone https://github.com/BaoTNguyen/plexus    # plexus needs heart next to it
```

None of these packages is on PyPI. `pip install heart` fetches somebody
else's project, so always install from the checkout (`pip install -e ./heart`).

## What the tests skip, and what running for real needs

Tests pass on a bare machine. What they can't reach, they skip:

- **Postgres 14+ with pgvector**: arteries' and capillaries' live paths. Setup is
  in the capillaries README; its `db` tests run once `DB_*` points at a database.
- **An embedding endpoint**: capillaries retrieval (`EMBED_URL`).
- **Docker and an agent CLI** (claude, codex, ...): heart runs agents in a
  sandbox. `plexus doctor` lists what this box is still missing.
- **GPUs**: marrow training only.

## Both layouts on one machine

Harmless as long as each venv points at one set. An editable install records
its path, and the last `pip install -e` wins. Check which copy you're getting:

```bash
python -c "import heart; print(heart.__file__)"
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
