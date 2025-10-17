# Guida all'uso del Sistema DAM Drop Zone

## Sistema Globale di Drop Zone

Ora **qualsiasi campo** nell'applicazione può accettare asset dal DAM semplicemente usando i componenti forniti.

---

## 📦 Componenti Disponibili

### 1. `useDAMDropZone` Hook

Hook React per rendere qualsiasi elemento compatibile con il drop dal DAM.

```tsx
import { useDAMDropZone } from '../hooks/useDAMDropZone';

function MyComponent() {
  const { dropZoneProps, isOver } = useDAMDropZone({
    onAssetDrop: (asset) => {
      console.log('Asset ricevuto:', asset);
      // asset.thumbnail_url - URL dell'immagine
      // asset.asset_id - ID univoco
      // asset.title - Nome del file
      // asset.current_version - Versione corrente
    },
    acceptTypes: ['image/*'], // Opzionale: filtra per tipo MIME
  });

  return (
    <div {...dropZoneProps}>
      {isOver ? 'Rilascia qui!' : 'Trascina un asset qui'}
    </div>
  );
}
```

---

### 2. `DAMDropZone` Component

Wrapper generico per rendere qualsiasi elemento drop-compatible.

```tsx
import { DAMDropZone } from '../components/DAMDropZone';

// Esempio: Campo immagine personalizzato
<DAMDropZone
  onAssetDrop={(asset) => setImageUrl(asset.thumbnail_url)}
  acceptTypes={['image/*']}
>
  <img src={imageUrl} alt="Product" />
</DAMDropZone>

// Esempio: Editor di testo
<DAMDropZone
  onAssetDrop={(asset) => insertImageInEditor(asset.thumbnail_url)}
>
  <textarea value={content} onChange={...} />
</DAMDropZone>

// Esempio: Qualsiasi div
<DAMDropZone
  onAssetDrop={(asset) => handleAsset(asset)}
  showIndicator={true}  // Mostra "Drop asset here" quando in hover
>
  <div className="my-custom-field">
    Content here
  </div>
</DAMDropZone>
```

---

### 3. `DAMImageField` Component

Campo immagine pronto all'uso con drop zone integrato.

```tsx
import { DAMImageField } from '../components/DAMDropZone';

function ProductForm() {
  const [productImage, setProductImage] = useState('');

  return (
    <DAMImageField
      value={productImage}
      onChange={(url, asset) => {
        setProductImage(url);
        console.log('Asset dropped:', asset);
      }}
      alt="Product image"
      placeholder="Drop product image here"
    />
  );
}
```

---

### 4. `DAMTextField` Component

Campo di testo con drop zone per URL asset.

```tsx
import { DAMTextField } from '../components/DAMDropZone';

function LinkForm() {
  const [fileUrl, setFileUrl] = useState('');

  return (
    <DAMTextField
      value={fileUrl}
      onChange={(url, asset) => {
        setFileUrl(url);
        if (asset) {
          console.log('Asset ID:', asset.asset_id);
        }
      }}
      placeholder="Drop an asset or paste URL"
      acceptTypes={['image/*', 'video/*', 'application/pdf']}
    />
  );
}
```

---

## 🎯 Esempi di Utilizzo Reali

### Email Client - Inserire immagini nelle email

```tsx
// File: app-communications-client/src/components/EmailComposer.tsx

import { useDAMDropZone } from '@/hooks/useDAMDropZone';

function EmailComposer() {
  const [emailBody, setEmailBody] = useState('');
  const editorRef = useRef<HTMLTextAreaElement>(null);

  const { dropZoneProps, isOver } = useDAMDropZone({
    onAssetDrop: (asset) => {
      // Inserisci l'immagine nel corpo dell'email
      const imageTag = `<img src="${asset.thumbnail_url}" alt="${asset.title}" />`;
      const currentContent = emailBody;
      setEmailBody(currentContent + imageTag);

      // Registra l'uso dell'asset (snapshot reference per email)
      registerAssetUsage({
        asset_id: asset.asset_id,
        reference_type: 'snapshot', // Email = snapshot (frozen)
        app_id: 'email-client',
        entity_type: 'email',
        entity_id: emailId,
      });
    },
    acceptTypes: ['image/*'],
  });

  return (
    <div {...dropZoneProps} className={isOver ? 'border-blue-500' : ''}>
      <textarea
        ref={editorRef}
        value={emailBody}
        onChange={(e) => setEmailBody(e.target.value)}
        placeholder="Write your email... (drag images from DAM)"
      />
    </div>
  );
}
```

---

### CMS Page Builder - Inserire immagini nelle pagine

```tsx
// File: app-page-builder/src/components/PageEditor.tsx

import { DAMDropZone } from '@/components/DAMDropZone';

function PageEditor() {
  const [heroImage, setHeroImage] = useState('');

  return (
    <div className="page-editor">
      <h3>Hero Section</h3>

      <DAMDropZone
        onAssetDrop={(asset) => {
          setHeroImage(asset.thumbnail_url);

          // Registra l'uso dell'asset (live reference per CMS)
          registerAssetUsage({
            asset_id: asset.asset_id,
            reference_type: 'live', // CMS = live (auto-update)
            app_id: 'page-builder',
            entity_type: 'page',
            entity_id: pageId,
            field_name: 'hero_image',
          });
        }}
        acceptTypes={['image/*']}
      >
        <div className="hero-image-container">
          {heroImage ? (
            <img src={heroImage} alt="Hero" />
          ) : (
            <div>Drop hero image here</div>
          )}
        </div>
      </DAMDropZone>
    </div>
  );
}
```

---

### Document Editor - Inserire documenti/PDF

```tsx
// File: app-writer/src/components/DocumentEditor.tsx

import { useDAMDropZone } from '@/hooks/useDAMDropZone';

function DocumentEditor() {
  const [attachments, setAttachments] = useState<string[]>([]);

  const { dropZoneProps } = useDAMDropZone({
    onAssetDrop: (asset) => {
      // Aggiungi l'asset agli allegati
      setAttachments([...attachments, asset.thumbnail_url]);

      // Registra l'uso
      registerAssetUsage({
        asset_id: asset.asset_id,
        reference_type: 'snapshot', // Document = snapshot
        app_id: 'document-editor',
        entity_type: 'document',
        entity_id: documentId,
        field_name: 'attachments',
      });
    },
    acceptTypes: ['image/*', 'video/*', 'application/pdf'],
  });

  return (
    <div>
      <div {...dropZoneProps} className="attachments-area">
        <p>Drop files here to attach</p>
        {attachments.map((url, i) => (
          <div key={i}>{url}</div>
        ))}
      </div>
    </div>
  );
}
```

---

### Form Builder - Campi immagine dinamici

```tsx
// File: app-forms/src/components/FormField.tsx

import { DAMImageField } from '@/components/DAMDropZone';

function FormField({ field }) {
  const [value, setValue] = useState('');

  if (field.type === 'image') {
    return (
      <DAMImageField
        value={value}
        onChange={(url, asset) => {
          setValue(url);
          // Salva nel form
          updateFieldValue(field.id, url);
        }}
        alt={field.label}
      />
    );
  }

  // Altri tipi di campi...
}
```

---

## 🔧 Funzione Helper per Registrare l'Uso

Crea questa utility per registrare l'uso degli asset:

```tsx
// File: app-shell-frontend/src/utils/damAssetTracking.ts

export async function registerAssetUsage(params: {
  asset_id: string;
  reference_type: 'live' | 'snapshot';
  app_id: string;
  entity_type: string;
  entity_id: string;
  field_name?: string;
}) {
  const { asset_id, reference_type, app_id, entity_type, entity_id, field_name } = params;

  try {
    const response = await fetch(`http://localhost:4003/dam/assets/${asset_id}/usage`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        tenant_id: getTenantId(),
        reference_type,
        app_id,
        entity_type,
        entity_id,
        field_name,
        inserted_by: getCurrentUserId(),
      }),
    });

    if (!response.ok) {
      throw new Error(`Failed to register asset usage: ${response.statusText}`);
    }

    const data = await response.json();
    console.log('✅ Asset usage registered:', data);
    return data;
  } catch (error) {
    console.error('❌ Failed to register asset usage:', error);
    throw error;
  }
}

function getTenantId(): string {
  return localStorage.getItem('tenant_id') || '00000000-0000-0000-0000-000000000001';
}

function getCurrentUserId(): string {
  return localStorage.getItem('user_id') || '00000000-0000-0000-0000-000000000001';
}
```

---

## 📋 Checklist Integrazione

Per integrare il DAM drop zone in una nuova app:

1. ✅ Importa il componente/hook appropriato
2. ✅ Aggiungi `onAssetDrop` handler
3. ✅ Specifica `acceptTypes` se necessario (es. solo immagini)
4. ✅ Chiama `registerAssetUsage()` dopo il drop
5. ✅ Scegli `reference_type`:
   - `'snapshot'` per contenuti immutabili (email, PDF, documenti finali)
   - `'live'` per contenuti dinamici (homepage, template, pagine CMS)

---

## 🎨 Tipi MIME Comuni

```tsx
acceptTypes: [
  'image/*',              // Tutte le immagini
  'image/jpeg',           // Solo JPEG
  'image/png',            // Solo PNG
  'video/*',              // Tutti i video
  'application/pdf',      // PDF
  'text/plain',           // File di testo
  'application/zip',      // Archive
]
```

---

## ✨ Caratteristiche

- ✅ **Universale**: Funziona con qualsiasi tipo di campo
- ✅ **Indicatore visivo**: Mostra quando un asset è in hover
- ✅ **Type filtering**: Accetta solo i tipi di file specificati
- ✅ **Versioning-aware**: Integrato con il sistema di versioning
- ✅ **Usage tracking**: Registra automaticamente dove vengono usati gli asset
- ✅ **Live vs Snapshot**: Supporta entrambi i tipi di riferimento

---

## 🚀 Prossimi Passi

1. Integrare in `app-communications-client` (email)
2. Integrare in `app-page-builder` (CMS)
3. Integrare in `app-writer` (document editor)
4. Aggiungere preview modale quando si fa hover su un asset
5. Implementare il sistema di sync per i live references

---

**Il sistema è pronto!** Ogni sviluppatore può ora aggiungere drop zone DAM nei propri componenti semplicemente importando e usando questi componenti.
