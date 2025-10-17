# 🚀 Come Avviare EWH su Mac Studio - FACILISSIMO

## TL;DR - Il Modo Più Semplice

```bash
./easy-start.sh
```

Questo comando fa TUTTO automaticamente:
1. Verifica che sia tutto installato
2. Installa eventuali dipendenze mancanti
3. Avvia tutti i servizi
4. (Opzionale) Configura auto-start all'accensione

**Letteralmente UN SOLO COMANDO!**

---

## La Prima Volta (Setup Iniziale)

Se è la prima volta che usi questo sistema:

```bash
./easy-start.sh
```

Ti guiderà step-by-step e installerà:
- PostgreSQL 16
- Redis
- Node.js e PM2
- Tutti i servizi EWH

**Tempo stimato: 5-10 minuti**

---

## Avvii Successivi

Se hai già fatto il setup iniziale:

```bash
./scripts/master-startup-macstudio.sh
```

Oppure, se hai configurato l'auto-start, **non serve fare niente**!
I servizi partiranno automaticamente all'accensione del Mac Studio.

---

## Comandi Utili

### Vedere Lo Status

```bash
ssh fabio@192.168.1.47 'pm2 list'
```

### Vedere i Log

```bash
ssh fabio@192.168.1.47 'pm2 logs'
```

### Riavviare Tutto

```bash
ssh fabio@192.168.1.47 'pm2 restart all'
```

### Fermare Tutto

```bash
ssh fabio@192.168.1.47 'pm2 stop all'
```

---

## Accedere ai Servizi

Una volta avviati, apri il browser:

| Servizio | URL |
|----------|-----|
| API Gateway | http://192.168.1.47:4000 |
| Admin Panel | http://192.168.1.47:3200 |
| PM Frontend | http://192.168.1.47:3300 |
| Box Designer | http://192.168.1.47:3350 |
| DAM | http://192.168.1.47:3400 |
| Inventory | http://192.168.1.47:3500 |
| CMS Frontend | http://192.168.1.47:3600 |
| Media Frontend | http://192.168.1.47:3700 |

---

## Troubleshooting

### "Non riesco a connettermi!"

1. Verifica che il Mac Studio sia acceso
2. Verifica di essere sulla stessa rete WiFi
3. Prova: `ssh fabio@192.168.1.47 'echo OK'`

### "Un servizio non parte!"

```bash
# Vedi i log del servizio
ssh fabio@192.168.1.47 'pm2 logs svc-auth'

# Riavvia singolo servizio
ssh fabio@192.168.1.47 'pm2 restart svc-auth'
```

### "Tutto è down!"

```bash
# Verifica sistema
./scripts/verify-autostart-setup.sh

# Riavvia tutto
./easy-start.sh
```

---

## FAQ

**Q: Devo avviare manualmente ogni volta?**
A: No! Esegui `./easy-start.sh` e scegli di configurare l'auto-start. Da quel momento parte tutto automaticamente all'accensione.

**Q: Come faccio a sapere se tutto funziona?**
A: `ssh fabio@192.168.1.47 'pm2 list'` - se vedi servizi "online" in verde, funziona tutto.

**Q: Posso usare il Mac Studio mentre i servizi girano?**
A: Assolutamente sì! I servizi girano in background e non interferiscono.

**Q: Quanto consuma di risorse?**
A: I servizi hanno memory limit configurati. Totale circa 5-8GB RAM su 32GB+ disponibili.

**Q: Cosa succede se crasha un servizio?**
A: Si riavvia automaticamente! PM2 + auto-healing lo gestiscono per te.

**Q: Posso fermare tutto?**
A: Sì: `ssh fabio@192.168.1.47 'pm2 stop all'`

**Q: Come disabilito l'auto-start?**
A: `ssh fabio@192.168.1.47 'launchctl unload ~/Library/LaunchAgents/com.ewh.startup.plist'`

---

## Documentazione Completa

- **[AUTO_START_GUIDE.md](AUTO_START_GUIDE.md)** - Guida dettagliata completa
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Riferimento rapido comandi

---

## Supporto

Hai problemi? Segui questi step:

1. **Verifica setup**:
   ```bash
   ./scripts/verify-autostart-setup.sh
   ```

2. **Vedi i log**:
   ```bash
   ssh fabio@192.168.1.47 'pm2 logs --lines 50'
   ```

3. **Riavvio completo**:
   ```bash
   ssh fabio@192.168.1.47 'pm2 delete all'
   ./easy-start.sh
   ```

Se nulla funziona, manda:
- Output di `pm2 list`
- Ultimi 50 righe di `pm2 logs`
- Output di `./scripts/verify-autostart-setup.sh`

---

## In Sintesi

**Per iniziare:**
```bash
./easy-start.sh
```

**Per vedere status:**
```bash
ssh fabio@192.168.1.47 'pm2 list'
```

**Per accedere:**
- Apri http://192.168.1.47:3200

**È davvero così semplice! 🎉**

---

*Sistema creato per rendere l'avvio di 90+ microservizi facile quanto cliccare un bottone.*
