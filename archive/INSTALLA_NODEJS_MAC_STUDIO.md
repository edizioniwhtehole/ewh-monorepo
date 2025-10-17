# 📦 Installazione Node.js sul Mac Studio

## Problema
Node.js non è installato sul Mac Studio e serve per eseguire i servizi.

## Soluzione - 3 Metodi

### ✅ METODO 1: Installer Ufficiale (PIÙ SEMPLICE - 2 minuti)

**Sul Mac Studio:**

1. Apri browser
2. Vai su: https://nodejs.org/en/download/
3. Scarica "macOS Installer (.pkg)" - versione LTS (consigliata)
4. Apri il file .pkg scaricato
5. Segui la procedura guidata (Next, Next, Install)
6. Inserisci password quando richiesto

7. **Verifica installazione** - Apri Terminal e digita:
   ```bash
   node --version
   npm --version
   ```
   Dovrebbe mostrare qualcosa tipo:
   ```
   v20.x.x
   10.x.x
   ```

8. **Dimmi "fatto"** e continuo con il deploy!

---

### METODO 2: Homebrew (se già ce l'hai)

**Sul Mac Studio, nel Terminal:**

```bash
# Se hai già Homebrew installato
brew install node

# Verifica
node --version
npm --version
```

---

### METODO 3: NVM (Node Version Manager) - Per sviluppatori

**Sul Mac Studio, nel Terminal:**

```bash
# Installa NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Riavvia Terminal o fai:
source ~/.zshrc

# Installa Node.js
nvm install --lts

# Verifica
node --version
npm --version
```

---

## ⏭️ Dopo l'Installazione

Una volta installato Node.js, **dimmi "fatto"** nel chat e proseguo automaticamente con:

1. ✅ Installazione PM2 (process manager)
2. ✅ Avvio servizi EWH
3. ✅ Port forwarding
4. ✅ Test completo

---

## 💡 Consiglio

**Usa il Metodo 1** (Installer Ufficiale) - È il più veloce e semplice!

Tempo totale: ~2 minuti
