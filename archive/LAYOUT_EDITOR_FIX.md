# BUG CRITICO: Layout Editor non salva correttamente

## Problema
Quando l'utente modifica i valori numerici e salva, il sistema salva `{ panels: PanelConfig[] }` invece del formato corretto `LayoutData` di rc-dock, causando il crash dell'interfaccia al ricaricamento.

## Formato Corretto rc-dock LayoutData
```typescript
{
  dockbox: {
    mode: 'horizontal' | 'vertical',
    children: [
      {
        mode: 'vertical',
        size: 200,
        tabs: [
          { id: 'asset-browser', title: 'Assets', content: <Component /> }
        ]
      }
    ]
  }
}
```

## Formato Sbagliato che salviamo ora
```typescript
{
  panels: [
    { id: 'asset-browser', name: 'Assets', position: { left: 0, top: 0, width: 25, height: 100 } }
  ]
}
```

## Soluzione
Invece di convertire LayoutData → PanelConfig[], lasciare che l'utente modifichi DIRETTAMENTE i valori del LayoutData originale, oppure creare una funzione `convertPanelConfigsToLayoutData()` che ricostruisce il formato corretto.

## Alternativa SEMPLICE
Disabilitare il salvataggio fino a quando non implementiamo la conversione corretta. Permettere solo la VISUALIZZAZIONE dei valori.
