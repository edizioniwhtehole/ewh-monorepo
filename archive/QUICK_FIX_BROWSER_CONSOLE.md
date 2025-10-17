# 🔧 Quick Fix - Pulire Token Invalido

## Problema
Il token nel localStorage è invalido/scaduto e causa errori 401.

## Soluzione Rapida (30 secondi)

### Opzione 1: Via Console Browser (PIÙ VELOCE)

1. **Aprire** http://localhost:3150

2. **Premere F12** per aprire Developer Tools

3. **Andare su "Console"** tab

4. **Copiare e incollare** questo comando:

```javascript
// Pulire tutto il localStorage
localStorage.clear();

// Ricaricare la pagina
location.reload();
```

5. **Premere INVIO**

6. La pagina si ricarica e ti chiede di fare login

7. **Login** con:
   - Email: `fabio.polosa@gmail.com`
   - Password: `password123`

8. **DONE!** Il toggle "Edit" dovrebbe apparire nel footer! ✅

---

### Opzione 2: Via UI (Più Lenta)

1. Aprire http://localhost:3150

2. Cliccare avatar utente (alto a destra)

3. Cliccare "Logout"

4. Login di nuovo

---

## Verifica Successo

Dopo login, controlla:

### Console (F12):
```
✅ NO errori 401
✅ NO errori "Failed to fetch"
```

### Footer (angolo destro):
```
✅ Vedi "🔒 Edit" accanto a "Help & Support"
```

### Test Rapido:
1. Click su "Edit" → diventa "✏️ Edit ON" (blu)
2. Hover su TopBar → appare bordo blu e matita
3. Click matita → si apre modal editor
4. **FUNZIONA!** 🎉

---

## Se Ancora Non Funziona

Eseguire nella console:

```javascript
// Check se i permessi sono stati caricati
console.log('Permessi:', localStorage.getItem('visual_editing_permissions'));

// Check token
const token = localStorage.getItem('shell_token');
console.log('Token presente:', !!token);
console.log('Token primi 50 char:', token?.substring(0, 50));
```

Se vedi `Permessi: null` → il backend non sta restituendo i permessi.

Inviami l'output e posso debuggare ulteriormente!
