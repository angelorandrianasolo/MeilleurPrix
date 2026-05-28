'use strict';

/**
 * Initialise le mot de passe admin : node scripts/init-admin.js [motdepasse]
 */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const bcrypt = require('bcrypt');
const db = require('../config/db');

const password = process.argv[2] || 'admin123';

async function main() {
  const hash = await bcrypt.hash(password, 12);
  await db.query(
    `UPDATE utilisateur SET mot_de_passe = $1 WHERE email = 'admin@meilleurprix.mg'`,
    [hash]
  );
  console.log('Mot de passe admin mis a jour pour admin@meilleurprix.mg');
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
