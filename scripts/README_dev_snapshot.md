# Snapshot workspace (`dev_snapshot.sh`)

Questo script permette di:

- creare un archivio compresso dell’intera workspace EWH (tutti i repo e le dipendenze);
- ripristinare rapidamente quello stato in qualsiasi momento;
- elencare i backup disponibili.

> Il backup include le directory `.git`, i file non versionati e i sub-moduli: è un congelamento completo del filesystem sotto `~/dev/ewh`.

## Installazione

Assicurati di avere i permessi di esecuzione:

```bash
cd ~/dev/ewh/scripts
chmod +x dev_snapshot.sh
```

## Utilizzo rapido


```bash
# crea un nuovo snapshot (nome generato con timestamp)
./dev_snapshot.sh freeze

# opzionale: snapshot con etichetta personalizzata
./dev_snapshot.sh freeze hotfix-logger

# elenco degli snapshot salvati in _snapshots/
./dev_snapshot.sh list

# ripristino di uno snapshot (nome o path dell'archivio .tar.gz)
./dev_snapshot.sh restore 20250924-154500-hotfix-logger.tar.gz
```

## Bucket S3 e database (opzionali)

Lo script può salvare/ripristinare anche i bucket e i database, con i flag `--with-buckets` e `--with-db`:

```bash
# snapshot completo workspace + S3 + Postgres
SNAPSHOT_BUCKETS="ewh-staging ewh-prod" \
SNAPSHOT_DB_URLS="postgres://user:pass@localhost:5432/ewh_staging" \
  ./dev_snapshot.sh freeze nightly --with-buckets --with-db

# ripristino workspace + S3 + Postgres
SNAPSHOT_BUCKETS_FILE=infra/buckets.txt \
SNAPSHOT_DB_URLS_FILE=infra/databases.txt \
  ./dev_snapshot.sh restore 20250924-154500-nightly.tar.gz --with-buckets --with-db
```

Le variabili `SNAPSHOT_BUCKETS` e `SNAPSHOT_DB_URLS` accettano liste separate da spazi o newline; in alternativa puoi usare un file (`SNAPSHOT_BUCKETS_FILE`, `SNAPSHOT_DB_URLS_FILE`) con un elemento per riga. Durante il restore i bucket vengono sincronizzati con `aws s3 sync` e i DB ripristinati con `psql -f dump.sql`.

> Requisiti: installare `aws` CLI configurato con le credenziali corrette e i client Postgres (`pg_dump`, `psql`).

## Directory snapshot

Gli snapshot sono salvati di default in `~/dev/ewh/_snapshots/`. Puoi cambiare destinazione esportando `SNAPSHOT_DIR` prima di lanciare il comando:

```bash
SNAPSHOT_DIR=$HOME/backups/ewh ./dev_snapshot.sh freeze
```

## Ripristino sicuro

Il ripristino sovrascrive i file presenti nella workspace (e, se usi `--with-buckets` / `--with-db`, anche i bucket e i DB indicati). Prima di eseguire `restore`:

1. Verifica di non avere modifiche non salvate o non committate.
2. Facoltativo: effettua un backup aggiuntivo con `freeze`.
3. Se ripristini bucket/DB, assicurati che non ci siano processi attivi che scrivono sugli stessi target.
4. Esegui `restore` e attendi il completamento.

## Automatizzare

Puoi programmare snapshot periodici usando `cron` (macOS / Linux) o Automator. Esempio di cron job giornaliero alle 23:55:

```
55 23 * * * cd $HOME/dev/ewh/scripts && ./dev_snapshot.sh freeze nightly >> $HOME/dev/ewh/_snapshots/nightly.log 2>&1
```

## Pulizia

Gli archivi sono file `.tar.gz`. Per rimuovere quelli più vecchi puoi usare i normali comandi shell, ad esempio:

```bash
rm ~/dev/ewh/_snapshots/2025*-hotfix-logger.tar.gz
```

## Checklist post-ripristino

- Esegui `./scripts/status_all.sh` per verificare lo stato dei repo.
- Riavvia eventuali servizi locali (Docker, dev server) se necessario.
- Se il ripristino andava in staging/produzione, aggiorna i deploy dal branch corretto.

Con questa procedura puoi congelare e ripristinare lo stato di tutta la struttura con un solo comando.
