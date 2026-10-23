#!/usr/bin/env python3
"""Uninstall the stack's tree, kind by kind (TREE_PLAN phase 6).

    python3 uninstall.py                  # print what would happen; touch nothing
    python3 uninstall.py --yes            # do it
    python3 uninstall.py --yes --purge    # secrets/ and data/ too
    python3 uninstall.py --yes --drop-data   # dump pulse's DB to backups/pulse/, then drop its tables

The tree is $VASCULAR_HOME (default ~/.vascular). manifest.json says what each
top-level kind is and what uninstall does with it; a directory that is not a
kind is reported and left alone. The spool is drained through pulse before it
goes: events nothing has read are the one thing no other copy holds.
Repos' own .vascular/ dirs (the ledger) and the CLIs' credentials are never
touched. Stop pulse.service and the other units first; this does not.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

MANIFEST = json.loads((Path(__file__).resolve().parent / "manifest.json").read_text())
PULSE_TABLES = ["events", "contexts", "artifacts", "checkpoints", "quarantine"]


def home() -> Path:
    return Path(os.environ.get("VASCULAR_HOME") or Path.home() / ".vascular")


def pulse(*args: str, **kw) -> subprocess.CompletedProcess:
    return subprocess.run(["pulse", *args], capture_output=True, text=True, **kw)


def lag() -> int | None:
    """Unread spool bytes per the running collector, or None if none answers."""
    try:
        got = pulse("health", timeout=10)
        return int(json.loads(got.stdout)["lag_bytes"]) if got.returncode == 0 else None
    except (OSError, ValueError, KeyError, subprocess.TimeoutExpired):
        return None


def spool_bytes(root: Path) -> int:
    spool = root / "spool"
    return sum(p.stat().st_size for p in spool.rglob("*") if p.is_file()) if spool.exists() else 0


def drain(root: Path, act: bool) -> None:
    """Leave nothing in the spool that pulse has not stored."""
    if not spool_bytes(root):
        return
    if not shutil.which("pulse"):
        sys.exit("uninstall: the spool holds events and `pulse` is not on PATH to drain them")
    if lag() is not None:
        print("drain: a collector is running; waiting for it to catch up")
        if act:
            wait(None)
            sys.exit("uninstall: drained; now stop pulse.service and run this again")
        return
    print("drain: starting a collector until the spool is read")
    if not act:
        return
    collector = subprocess.Popen(["pulse", "collect", "--interval", "1"],
                                 stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
    try:
        wait(collector)
    finally:
        collector.terminate()
        collector.wait(10)


def wait(collector, timeout: float = 300) -> None:
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        if collector is not None and collector.poll() is not None:
            sys.exit(f"uninstall: the collector exited: {collector.stderr.read().strip()}")
        if lag() == 0:
            return
        time.sleep(1)
    sys.exit("uninstall: the spool did not drain; nothing deleted")


def drop_data(root: Path, act: bool) -> None:
    url = os.environ.get("PULSE_DATABASE_URL", "host=/var/run/postgresql dbname=pulse")
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    dump = root / "backups" / "pulse" / f"pulse-{stamp}.dump"
    print(f"drop-data: dump {url!r} to {dump}, then drop {', '.join(PULSE_TABLES)}")
    if not act:
        return
    dump.parent.mkdir(parents=True, exist_ok=True)
    if subprocess.run(["pg_dump", "-Fc", "-f", str(dump), "-d", url]).returncode:
        sys.exit("uninstall: pg_dump failed; nothing dropped or deleted")
    sql = "DROP VIEW IF EXISTS spans; " + "".join(f"DROP TABLE IF EXISTS {t} CASCADE; " for t in PULSE_TABLES)
    if subprocess.run(["psql", "-q", "-v", "ON_ERROR_STOP=1", "-d", url, "-c", sql]).returncode:
        sys.exit(f"uninstall: dropping pulse's tables failed; the dump is at {dump}")


def plan(root: Path, purge: bool) -> tuple[list[Path], list[str]]:
    gone, kept = [], []
    for entry in sorted(root.iterdir()) if root.exists() else []:
        rule = MANIFEST["kinds"].get(entry.name, {}).get("uninstall")
        if rule in ("delete", "drain-then-delete") or (rule == "purge-only" and purge):
            gone.append(entry)
        else:
            kept.append(f"{entry.name}/ ({rule or 'not a kind: left alone'})")
    return gone, kept


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--yes", action="store_true", help="act; without it, only print")
    p.add_argument("--purge", action="store_true", help="delete secrets/ and data/ too")
    p.add_argument("--drop-data", action="store_true",
                   help="dump pulse's database to backups/pulse/, then drop its tables")
    a = p.parse_args(argv)
    root = home()
    if not root.exists():
        print(f"{root} does not exist; nothing to do")
        return 0
    drain(root, a.yes)
    if a.drop_data:
        drop_data(root, a.yes)
    gone, kept = plan(root, a.purge)
    for path in gone:
        print(f"{'delete' if a.yes else 'would delete'}: {path}")
        if a.yes:
            shutil.rmtree(path) if path.is_dir() and not path.is_symlink() else path.unlink()
    for k in kept:
        print(f"keep: {k}")
    if not a.yes:
        print("dry run: pass --yes to do it")
    return 0


if __name__ == "__main__":
    sys.exit(main())
