# vascular

[![install](https://github.com/BaoTNguyen/vascular/actions/workflows/install.yml/badge.svg)](https://github.com/BaoTNguyen/vascular/actions/workflows/install.yml)

The whole agent stack in one clone. Each directory here is a git submodule
pointing at its own repo. Nothing is copied, so this umbrella and the individual
repos can't drift apart: clone either way and you get the same code, in the same
sibling layout the repos already expect of each other.

| repo | what it does | needs beside it |
|---|---|---|
| [heart](https://github.com/BaoTNguyen/heart) | runs coding agents: orchestration, sandbox, verification | nothing (arteries optional) |
| [plexus](https://github.com/BaoTNguyen/plexus) | turns a goal into features and lands them through heart | heart |
| [capillaries](https://github.com/BaoTNguyen/capillaries) | retrieves the right prompt or skill for a situation | nothing (arteries optional) |
| [arteries](https://github.com/BaoTNguyen/arteries) | memory and tracing for agent sessions | capillaries |
| [marrow](https://github.com/BaoTNguyen/marrow) | RL training on heart's episodes (GPU) | heart |
| [pulse](https://github.com/BaoTNguyen/pulse) | the event journal: collects every component's events, one query API | nothing |

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

pulse is Rust, so it needs [cargo](https://rustup.rs) instead of uv:
`(cd pulse && cargo test)`.

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

## How the pieces connect

Each component's README describes only that component. What passes between
them is here.

**plexus → heart.** plexus imports heart as a library (`heart.taskspec`,
`heart.runner`, `heart.env` and more) rather than shelling out, and heart never imports plexus. While
plexus dispatches it sets `PLEXUS_GOAL_ID` and `PLEXUS_FEATURE_ID`, which
heart's `events.emit()` stamps on every event, so `heart observe goal <id>`
groups a goal's episodes. plexus's `tests/test_heart_api_pin.py` fails the
moment heart's surface moves.

**heart and arteries.** Episode worktrees carry the repo's `.vascular/arteries`
hooks and CLI hook config, so CLI agents keep their memory; heart's `api` agent
calls the repo's `observe.sh` itself. After `run`, `work` or `batch`, heart
hands the runs dir to `art episodes` when `art` is on PATH (`HEART_INGEST=off`
turns that off).

**arteries and capillaries.** They import each other in opposite directions,
at different weights. arteries imports four things from capillaries:

| Import | Where | Degrades if missing? |
| --- | --- | --- |
| `capillaries.config.paths` (`EMBED_MODEL`, `EMBED_DIM`, `EMBED_URL`, `QUERY_PREFIX`) | `config.py` | yes, to local defaults |
| `capillaries.agent.inference.DOMAIN_KEYWORDS` | `extract.py` | yes, to `evergreen.DOMAIN_KEYWORDS` |
| `capillaries.agent.gate.gate` | `eval.py` | no |
| `capillaries.find.find` | `eval.py` | no |

capillaries imports one arteries module, `arteries.memory_types` (stdlib
dataclasses, no database), and only on the memory-aware path:
`agent/api.py:_build_context_frame` imports it inside the function, and every
other reference is a string annotation, so capillaries runs without arteries.
The contract types live with the producer on purpose: they were in capillaries
until arteries could not define its own output without importing its consumer.

Neither names the other in `dependencies`, because both names are unclaimed on
PyPI and would resolve to a stranger's package. arteries pins capillaries
through its `dev` group and `[tool.uv.sources]`; capillaries' memory path needs
`uv pip install -e ../arteries` (`uv run` keeps it, a plain `uv sync` removes
it).

The embedding model and dimension are a shared contract, not either repo's
setting: both write vectors into the same Postgres. They silently disagreed
once (capillaries on Qwen3-Embedding-0.6B at 1024 dims, arteries on arctic-embed
at 768), which would have failed every embedding write, so arteries imports the
values instead of restating them.

**Everything → pulse.** Every component appends events to
`~/.vascular/spool/events` with a small vendored emitter; pulse collects,
stores and answers queries, and imports none of them. `heart observe tail` and
`episode` hand off to `pulse tail --text` and `pulse events --text` when pulse
is installed.

**heart → marrow.** marrow imports heart for patch scoring (`marrow/reward.py`),
trains on heart's export, emits training progress through `heart.events`
(`marrow/spine.py`), and serves a checkpoint back as heart's `api` agent.
arteries' decision ledger feeds marrow's stage 4, and capillaries'
prompt-optimization labels and holdout oracle live in `marrow/capillaries_opt/`,
because a holdout capillaries could enumerate is not a holdout. One round:

```bash
cd heart
heart batch tasks/ --agent api --repeat 8          # stage 0: best-of-N, the data engine
heart export --out episodes.jsonl
heart dataset sft --out sft.jsonl && heart dataset dpo --out dpo.jsonl
cd ../marrow                                       # stages 1-3: marrow's README
accelerate launch --num_processes 2 marrow/train_sft.py --data ../heart/sft.jsonl
CUDA_VISIBLE_DEVICES=0 vllm serve checkpoints/grpo --port 8000 &
cd ../heart && heart batch tasks/holdout --agent api   # the only score that counts
```

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

## Public-repo guard

Every repo here is public. [`hooks/pre-commit`](hooks/pre-commit) refuses a
commit whose added lines carry a tailnet address (CGNAT, 100.64/10), the
committer's own email, or a `/home/<user>` path. It reads the email from git
config, so the script itself holds nothing private. To install it for all the
repos at once:

```bash
mkdir -p ~/.vascular/config/git/hooks && cp hooks/pre-commit ~/.vascular/config/git/hooks/
for r in . arteries capillaries heart marrow plexus pulse; do
  git -C "$r" config core.hooksPath ~/.vascular/config/git/hooks
done
```

## What lives where

[`manifest.json`](manifest.json) lists every path each component writes under
`~/.vascular`, sorted into eight kinds (config, secrets, spool, log, state,
cache, data, backups), and the one retention rule each kind follows. Uninstall
reads it.

To take the tree away, stop the systemd units, then `python3 uninstall.py`
prints what it would do and `--yes` does it. It drains the spool into pulse
first, keeps `config/` and `backups/`, deletes `secrets/` and `data/` only
under `--purge`, and leaves your repos' `.vascular/` (the ledger) alone.
`--drop-data` dumps pulse's database to `backups/pulse/` before dropping its
tables. CI runs the whole round trip (install, emit, collect, uninstall).

Backups go to Proxmox Backup Server, client-side encrypted: see
[`backup/README.md`](backup/README.md).
