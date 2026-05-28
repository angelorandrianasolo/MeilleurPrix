'use strict';

require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT || '5432', 10),
  database: process.env.DB_NAME     || 'meilleur_prix_db',
  user:     process.env.DB_USER     || 'postgres',
  password: process.env.DB_PASSWORD || 'angelo',
  connectionTimeoutMillis: 5000
});

async function executeSQLFile(filePath) {
  try {
    const sql = fs.readFileSync(filePath, 'utf-8');
    console.log(`Exécution du fichier: ${path.basename(filePath)}`);
    
    // Exécuter le fichier SQL complet en une seule requête
    // PostgreSQL accepte les blocs $$ sans division
    try {
      await pool.query(sql);
    } catch (err) {
      // Ignorer certaines erreurs attendues
      if (!err.message.includes('already exists') && 
          !err.message.includes('duplicate object') &&
          !err.message.includes('already been defined')) {
        console.error('Erreur SQL:', err.message.substring(0, 200));
      }
    }
    console.log(`✓ ${path.basename(filePath)} complété\n`);
  } catch (err) {
    console.error(`✗ Erreur lors de l'exécution de ${filePath}:`, err.message);
    throw err;
  }
}

async function main() {
  try {
    // Tester la connexion
    const client = await pool.connect();
    console.log('✓ Connexion PostgreSQL établie\n');
    client.release();

    // Exécuter le schéma
    await executeSQLFile(path.join(__dirname, '../..', 'database', 'schema.sql'));

    // Exécuter les données de test de base
    await executeSQLFile(path.join(__dirname, '../..', 'database', 'seed.sql'));

    // Charger les données de démonstration mobile si présentes
    const mobileTestData = path.join(__dirname, '../..', 'database', 'test-data-phone.sql');
    if (fs.existsSync(mobileTestData)) {
      await executeSQLFile(mobileTestData);
    }

    console.log('✓ Base de données initialisée avec succès!');
    process.exit(0);
  } catch (err) {
    console.error('✗ Erreur fatale:', err.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

main();
