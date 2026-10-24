#!/usr/bin/env bash
# Back the stack up to Proxmox Backup Server (DIRECTION A10, TREE_PLAN backup).
#
#   backup/backup.sh            dump, then upload one encrypted snapshot
#   backup/backup.sh --dry-run  dump into the staging dir and stop
#
# What goes: the `capillaries` database (arteries' and capillaries' memory,
# which nothing can regenerate) and `pulse` as pg_dump archives, data/pulse/
# (artifacts, dataset snapshots), config/ (never secrets/), and every repo's
# .vascular/plexus (the ledgers, plexus's system of record). Test and trial
# databases do not.
#
# Credentials: $VASCULAR_HOME/secrets/pbs/env sets PBS_REPOSITORY,
# PBS_PASSWORD (an API token secret whose role can add backups but not delete
# them) and PBS_FINGERPRINT; proxmox-backup-client reads those itself. The
# encryption key is secrets/pbs/encryption.key, made with
# `proxmox-backup-client key create`. Lose it and every snapshot is noise:
# keep its paper key somewhere that is not this disk.
set -euo pipefail
home=${VASCULAR_HOME:-$HOME/.vascular}
projects=${VASCULAR_PROJECTS:-$HOME/Coding/Projects}
stage=$home/backups/pbs-staging
dbs=(capillaries pulse)
pg=${PG_SOCKET:-host=/var/run/postgresql}

rm -rf "$stage" && mkdir -p "$stage/db" "$stage/ledgers"
for db in "${dbs[@]}"; do
  pg_dump -Fc -f "$stage/db/$db.dump" -d "$pg dbname=$db"
done
for d in "$projects"/*/.vascular/plexus; do
  [ -d "$d" ] && cp -a "$d" "$stage/ledgers/$(basename "$(dirname "$(dirname "$d")")")"
done
du -sh "$stage"/* | sed 's/^/staged: /'
[ "${1:-}" = "--dry-run" ] && { echo "dry run: nothing uploaded"; exit 0; }

set -a; . "$home/secrets/pbs/env"; set +a
args=(db.pxar:"$stage/db" ledgers.pxar:"$stage/ledgers" config.pxar:"$home/config")
[ -d "$home/data/pulse" ] && args+=(data-pulse.pxar:"$home/data/pulse")
proxmox-backup-client backup "${args[@]}" \
  --keyfile "$home/secrets/pbs/encryption.key" \
  --backup-type host --backup-id "vascular-$(hostname)"
rm -rf "$stage"
