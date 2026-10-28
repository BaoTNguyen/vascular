#!/usr/bin/env bash
# Prove the newest snapshot restores (DIRECTION A10): pull its database dumps
# into scratch databases and its ledgers into a temp dir, then compare them
# with the live ones. A backup nobody has restored is a hope, not a backup.
#
#   backup/restore-test.sh
set -euo pipefail
home=${VASCULAR_HOME:-$HOME/.vascular}
projects=${VASCULAR_PROJECTS:-$HOME/Coding/Projects}
pg=${PG_SOCKET:-host=/var/run/postgresql}
set -a; . "$home/secrets/pbs/env"; set +a
key=(--keyfile "$home/secrets/pbs/encryption.key")
snap=$(proxmox-backup-client snapshot list --output-format json "host/vascular-$(hostname)" |
       python3 -c "import datetime,json,sys; s=max(json.load(sys.stdin), key=lambda s: s['backup-time']); t=datetime.datetime.fromtimestamp(s['backup-time'], datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'); print(f\"{s['backup-type']}/{s['backup-id']}/{t}\")")
echo "snapshot: $snap"
out=$(mktemp -d "$home/cache/restore-test.XXXX")
trap 'rm -rf "$out"; for db in capillaries pulse; do dropdb --if-exists -h /var/run/postgresql "restore_check_$db"; done' EXIT
proxmox-backup-client restore "$snap" db.pxar "$out/db" "${key[@]}"
proxmox-backup-client restore "$snap" ledgers.pxar "$out/ledgers" "${key[@]}"
fail=0
for db in capillaries pulse; do
  # pgvector is untrusted: only a superuser can create it, so the scratch
  # database comes from a template that already has it (README, once), and
  # the dump's own CREATE/COMMENT EXTENSION entries are skipped
  createdb -h /var/run/postgresql -T vascular_restore_template "restore_check_$db"
  pg_restore -l "$out/db/$db.dump" | grep -vE 'EXTENSION - vector|COMMENT - EXTENSION vector' > "$out/$db.list"
  pg_restore --no-owner --exit-on-error -L "$out/$db.list" -d "$pg dbname=restore_check_$db" "$out/db/$db.dump"
  t=$(psql -d "$pg dbname=restore_check_$db" -Atc "select count(*) from information_schema.tables where table_schema not in ('pg_catalog','information_schema')")
  echo "$db: restored $t tables"
  [ "$t" -gt 0 ] || fail=1
done
r=$(psql -d "$pg dbname=restore_check_pulse" -Atc "select count(*) from events")
l=$(psql -d "$pg dbname=pulse" -Atc "select count(*) from events")
echo "pulse events: restored $r, live $l"
[ "$r" -gt 0 ] && [ "$r" -le "$l" ] || fail=1
for d in "$out"/ledgers/*/; do
  name=$(basename "$d")
  if cmp -s "$d/ledger.jsonl" <(head -c "$(stat -c %s "$d/ledger.jsonl")" "$projects/$name/.vascular/plexus/ledger.jsonl"); then
    echo "ledger $name: restored copy is a prefix of the live one"
  else
    echo "ledger $name: DIFFERS"; fail=1
  fi
done
[ "$fail" = 0 ] && echo "restore test: OK" || { echo "restore test: FAILED"; exit 1; }
