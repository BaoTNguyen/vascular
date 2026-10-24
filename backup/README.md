# Backups to Proxmox Backup Server

`backup.sh` dumps the `capillaries` and `pulse` databases, stages every
repo's `.vascular/plexus` (the ledgers), and uploads them with `config/` and
`data/pulse/` as one client-side-encrypted snapshot. `restore-test.sh` pulls
the newest snapshot back into scratch databases and checks it against live.
`secrets/` is never backed up.

## Once, on PBS (web UI, port 8007)

1. **Datastore**: on the separate disk (exists).
2. **User and token**: Configuration → Access Control. Add a user `vascular@pbs`
   and an API token for it, then give the token **DatastoreBackup** on the
   datastore: it can add snapshots and read its own, but not delete or prune.
3. **Prune and verify jobs**: Datastore → Prune & GC (e.g. keep 14 daily, 8
   weekly, 12 monthly) and Verify Jobs (weekly). Pruning is PBS's job, so a
   compromised VM can't erase history.

## Once, in this VM

```bash
# the client: Proxmox's static build runs on Ubuntu
sudo install -d /etc/apt/keyrings
sudo wget -qO /etc/apt/keyrings/proxmox.gpg https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg
echo "deb [signed-by=/etc/apt/keyrings/proxmox.gpg] http://download.proxmox.com/debian/pbs-client bookworm main" |
  sudo tee /etc/apt/sources.list.d/pbs-client.list
sudo apt update && sudo apt install proxmox-backup-client-static

# credentials (0700 dir, 0600 files)
install -d -m 700 ~/.vascular/secrets/pbs
cat > ~/.vascular/secrets/pbs/env <<'ENV'
PBS_REPOSITORY=vascular@pbs!<token-name>@<pbs-address>:<datastore>
PBS_PASSWORD=<token secret>
PBS_FINGERPRINT=<the server's sha256 fingerprint>
ENV
chmod 600 ~/.vascular/secrets/pbs/env

# the encryption key, and a paper copy of it kept off this disk
proxmox-backup-client key create ~/.vascular/secrets/pbs/encryption.key --kdf none
proxmox-backup-client key paperkey ~/.vascular/secrets/pbs/encryption.key --output-format text

# first run, then prove it restores
backup/backup.sh && backup/restore-test.sh

# daily at 03:30
cp backup/systemd/vascular-backup.* ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now vascular-backup.timer
```

The off-site third copy (both copies share one chassis) is still to choose:
PBS can sync this datastore to S3-compatible storage or to a remote PBS.
