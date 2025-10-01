# EWH Dev Dashboard

Piccola dashboard web (FastAPI + frontend minimal) per eseguire e monitorare gli script nella cartella `scripts/`.

## Funzionalità
- **Rilevamento script automatico**: ogni file `*.sh` presente nella cartella configurata viene mostrato nella tabella, con la prima riga commentata utilizzata come descrizione.
- **Esecuzione interattiva**: pulsante “Esegui” per lanciare lo script direttamente dall'interfaccia. L’output (`stdout` e `stderr`) viene catturato e reso visibile nel riquadro dei risultati.
- **Storico immediato dell’esecuzione**: per ogni run vengono mostrati nome script, exit code (verde se 0, rosso in caso di errore) ed eventuali messaggi d’errore.
- **Knowledge base integrata**: tab dedicata che legge/salva note nel file `app/data/knowledge.json` (annotazioni su flow, script, checklist). È possibile aggiungere nuove voci via UI.
- **Status board**: tab “Stato servizi” che interroga i repository git, i container Docker, Scalingo e – se configurati – bucket S3 e database Postgres. Ogni voce mostra un semaforo (`🟢/🟡/🔴/⚪`) e dettagli testuali con eventuali suggerimenti per la risoluzione.
- **Monitor bucket/DB**: se definisci `STATUS_BUCKETS` / `STATUS_BUCKETS_FILE` e `STATUS_DB_URLS` / `STATUS_DB_URLS_FILE`, la dashboard prova ad effettuare `aws s3 ls` e `psql ... -c 'SELECT 1'` per ogni voce, evidenziando eventuali errori.
- **API REST**:
  - `GET /api/scripts`, `POST /api/scripts/{name}/run`
  - `GET /api/knowledge`, `POST /api/knowledge`
  - `GET /api/status`
- **CORS abilitato**: l’API può essere consumata da tool esterni (gestire opportuna autenticazione se esposta oltre la rete locale).
- **Configurabile**: `SCRIPTS_ROOT` può puntare a qualunque directory, consentendo di organizzare gli script in sottocartelle differenti.

## Requisiti
- Docker e Docker Compose installati.
- Repo EWH presente sul filesystem (la dashboard viene eseguita come container e monta la cartella corrente).
- Per la tab “Stato servizi”:
  - il `docker.sock` dell’host viene montato automaticamente (`/var/run/docker.sock`), quindi vedrai i container locali se il tuo utente ha permessi sul socket.
  - per Scalingo fornisci `SCALINGO_API_TOKEN` (o lascia montata la config locale `~/.config/scalingo/config.json`): la dashboard usa le API ufficiali e, in fallback, prova la CLI installata nel container. Se non imposti il token vedrai un avviso su come farlo.
  - per il controllo bucket serve l’AWS CLI configurata (es. `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION` – il template `.env` è già pronto con i campi da riempire) e per i database il client `psql` (già presente nel container) con le stringhe d’accesso valide (`STATUS_DB_URLS`).

Puoi passare le variabili tramite `docker compose` (sono già dichiarate nel file) oppure creando un file `.env` nella cartella `tools/dev-dashboard/`, ad esempio:

```
SCALINGO_API_TOKEN=xxxxxxxx
SCALINGO_REGION=osc-fr1
STATUS_BUCKETS="ewh-staging ewh-prod"
STATUS_DB_URLS_FILE=infra/databases.txt
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=eu-west-2
```

## Avvio rapido

1. Copia i file segnaposto:

   ```bash
   cd tools/dev-dashboard
   cp .env.template .env
   ```

2. Apri `.env` e inserisci i valori reali (token Scalingo, bucket, DB, credenziali Wasabi/AWS). Nella cartella `config/` trovi già i segnaposto:
   - `buckets_placeholder.txt` → contiene tutti i bucket noti (`ewh-prod-static`, `ewh-prod-ugc`, `ewh-staging-static`, `ewh-staging-ugc`). Modificalo se aggiungi bucket nuovi.
   - `databases_placeholder.txt` → aggiungi qui le connessioni Postgres manuali (se vuoi testare con `psql`).
   - `scalingo_config_placeholder.json` → esempio di config locale se non vuoi usare il token.

3. Avvia la dashboard:

   ```bash
   docker compose up --build
   ```

La UI sarà disponibile su <http://localhost:8000>.

## Variabili
- `SCRIPTS_ROOT` (default `/workspace/scripts`): directory dal punto di vista del container in cui cercare gli script.

## Note
- Gli script vengono eseguiti dentro il container ma operano sulla cartella montata `/workspace` (che punta alla root del repo sul tuo host).
- Per modificare o aggiungere nuovi script basta lavorare nella cartella `scripts/`: la dashboard si aggiornerà al prossimo refresh.
- L’interfaccia è pensata per uso interno: non esporre la porta 8000 pubblicamente senza adeguate protezioni.

## API
- `GET /api/scripts` → lista degli script (nome, path, descrizione).
- `POST /api/scripts/{name}/run` → esegue lo script e restituisce `exit_code`, `stdout`, `stderr`.
- `GET /api/knowledge` → elenco note della knowledge base.
- `POST /api/knowledge` → aggiunge una nota (`{"title", "description", "tags"}`).
- `GET /api/status` → ritorna gli output dei comandi locali (`status_all.sh`, `docker ps`, `scalingo apps`).

Buon lavoro! 🛠️
