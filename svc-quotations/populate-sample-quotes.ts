import pg from 'pg';
const { Pool } = pg;

const TENANT = '00000000-0000-0000-0000-000000000001';
const USER = '00000000-0000-0000-0000-000000000001';

async function populate() {
  const pool = new Pool({
    host: 'localhost',
    port: 5432,
    database: 'ewh_master',
    user: 'ewh',
    password: 'password'
  });

  try {
    // Crea clienti
    const customers = [
      { name: 'Mondadori Libri SpA', email: 'acquisti@mondadori.it', person: 'Marco Rossi' },
      { name: 'Feltrinelli Editore', email: 'ordini@feltrinelli.it', person: 'Laura Bianchi' },
      { name: 'Einaudi Editore', email: 'produzione@einaudi.it', person: 'Giovanni Verdi' },
      { name: 'Rizzoli Libri', email: 'progetti@rizzoli.it', person: 'Sofia Neri' }
    ];

    const customerIds = [];
    for (let i = 0; i < customers.length; i++) {
      const c = customers[i];
      const code = 'CUST-' + String(i + 1).padStart(4, '0');
      const res = await pool.query(
        'INSERT INTO quotations.customers (tenant_id, customer_code, company_name, email, contact_person, is_active) VALUES ($1, $2, $3, $4, $5, true) RETURNING id',
        [TENANT, code, c.name, c.email, c.person]
      );
      customerIds.push(res.rows[0].id);
      console.log('✓ Cliente:', c.name);
    }

    // Crea preventivi
    const quotes = [
      { 
        customer: 0, 
        title: 'Stampa 5000 copie romanzo 300 pagine',
        subtotal: 15000,
        items: [
          { desc: 'Stampa offset 4+4 colori', qty: 5000, unit: 2.20, total: 11000 },
          { desc: 'Rilegatura brossura', qty: 5000, unit: 0.60, total: 3000 },
          { desc: 'Copertina plastificata', qty: 5000, unit: 0.20, total: 1000 }
        ]
      },
      { 
        customer: 1, 
        title: 'Produzione libro illustrato 300x400mm',
        subtotal: 28000,
        items: [
          { desc: 'Stampa digitale alta qualità', qty: 2000, unit: 8.50, total: 17000 },
          { desc: 'Rilegatura cartonato', qty: 2000, unit: 4.50, total: 9000 },
          { desc: 'Sovraccoperta', qty: 2000, unit: 1.00, total: 2000 }
        ]
      },
      { 
        customer: 2, 
        title: 'Serie editoriale 3 volumi',
        subtotal: 42000,
        items: [
          { desc: 'Stampa 3000 copie vol.1', qty: 3000, unit: 4.50, total: 13500 },
          { desc: 'Stampa 3000 copie vol.2', qty: 3000, unit: 4.50, total: 13500 },
          { desc: 'Stampa 3000 copie vol.3', qty: 3000, unit: 4.50, total: 13500 },
          { desc: 'Cofanetto serie', qty: 1000, unit: 1.50, total: 1500 }
        ]
      }
    ];

    for (let i = 0; i < quotes.length; i++) {
      const q = quotes[i];
      const year = new Date().getFullYear();
      const quoteNum = 'QUO-' + year + '-' + String(i + 1).padStart(5, '0');
      
      const taxAmount = q.subtotal * 0.22;
      const total = q.subtotal + taxAmount;
      
      const validUntil = new Date();
      validUntil.setDate(validUntil.getDate() + 30);

      const quoteRes = await pool.query(
        'INSERT INTO quotations.quotes (tenant_id, quote_number, customer_id, title, subtotal, tax_rate, tax_amount, total_amount, currency, status, valid_until, created_by) VALUES ($1, $2, $3, $4, $5, 22.00, $6, $7, $8, $9, $10, $11) RETURNING id',
        [TENANT, quoteNum, customerIds[q.customer], q.title, q.subtotal, taxAmount, total, 'EUR', i === 0 ? 'sent' : 'draft', validUntil, USER]
      );

      const quoteId = quoteRes.rows[0].id;
      
      for (let j = 0; j < q.items.length; j++) {
        const item = q.items[j];
        await pool.query(
          'INSERT INTO quotations.quote_line_items (quote_id, line_number, item_type, description, quantity, unit_price, total_price) VALUES ($1, $2, $3, $4, $5, $6, $7)',
          [quoteId, j + 1, 'service', item.desc, item.qty, item.unit, item.total]
        );
      }

      console.log('✓ Preventivo:', q.title);
    }

    console.log('\n✅ Dati preventivi OUT popolati!');
  } catch (e: any) {
    console.error('❌', e.message);
  }

  await pool.end();
}

populate();
