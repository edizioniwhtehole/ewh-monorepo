# EWH – Script multi-repo

Questa cartella contiene vari script Bash per gestire in blocco tutti i repo EWH.

---

## 1. Installazione iniziale

1. Vai nella cartella `scripts`:
   ```bash
   cd ~/dev/ewh/scripts
   ```

2. Rendi eseguibili gli script (solo la prima volta):
   ```bash
   chmod +x *.sh
   ```

3. (Opzionale) aggiungi la cartella al tuo PATH (`~/.zshrc` o `~/.bashrc`):
   ```bash
   export PATH=$PATH:$HOME/dev/ewh/scripts
   ```
   poi ricarica:
   ```bash
   source ~/.zshrc
   ```

---

## 2. Script disponibili

### 2.1 `bootstrap_all.sh`
- Clona i repo mancanti dall’organizzazione.
- Se la cartella esiste ma non è repo, aggiunge il remote.
- Fa `git fetch --all --prune`.

Esegui:
```bash
./bootstrap_all.sh
```

---

### 2.2 `pull_all.sh`
- Aggiorna tutti i repo con `git pull --ff-only`.
- Utile da lanciare ogni mattina.

Esegui:
```bash
./pull_all.sh
```

---

### 2.3 `status_all.sh`
- Mostra lo stato git di tutti i repo nella root (segnala i repo modificati, altrimenti conferma che tutto è pulito).

Esegui:
```bash
./status_all.sh
```

---

### 2.4 `push_all.sh`
- Fa commit automatici (`chore: sync local changes`) e pusha sul ramo corrente.

Esegui:
```bash
./push_all.sh
```

---

### 2.5 `merge_sync_prs.sh`
- Cerca PR aperte con `chore/sync-master-prompt`.
- Le mergea su `main` con `--squash` e cancella il branch.

Esegui:
```bash
./merge_sync_prs.sh
```

---

## 3. Routine consigliata

1. `./pull_all.sh` → ogni mattina.  
2. Lavora sui repo che ti servono.  
3. `./status_all.sh` → prima di cambiare branch o aprire PR.  
4. `./push_all.sh` → se vuoi sincronizzare modifiche locali.  
5. `./merge_sync_prs.sh` → per consolidare i file sincronizzati su `main`.

---

---

### 2.6 `dev_snapshot.sh`
- Congela lo stato corrente dell’intera workspace (tutti i repo e le dipendenze).
- Opzionalmente include bucket S3 (`--with-buckets`) e dump Postgres (`--with-db`).
- Ripristina un backup con un solo comando.
- L’elenco dei backup è salvato in `_snapshots/` (configurabile con `SNAPSHOT_DIR`).

Esegui:
```bash
# crea un backup completo con timestamp
./dev_snapshot.sh freeze

# elenca i backup disponibili
./dev_snapshot.sh list

# ripristina un backup (nome completo o file nel _snapshots/)
./dev_snapshot.sh restore 20250924-154500.tar.gz

# con bucket/DB (richiede aws CLI e pg_dump/psql e variabili SNAPSHOT_*)
SNAPSHOT_BUCKETS="ewh-staging" SNAPSHOT_DB_URLS="postgres://..." \
  ./dev_snapshot.sh freeze nightly --with-buckets --with-db
```

⚠️ Durante il restore i file esistenti vengono sovrascritti: assicurati di aver salvato o committato le modifiche locali prima di procedere.

---

✅ Con questi script e questa guida, gestire tutti i repo EWH diventa comodo e uniforme.
