'use strict';

const db = require('../config/db');

exports.findByEmail = async (email) => {
  const { rows } = await db.query(
    `SELECT id, nom, email, mot_de_passe, role, langue, est_actif,
            budget_max, code_vendeur, marche_principal_id, zone_collecte
     FROM utilisateur WHERE email = $1 LIMIT 1`,
    [email]
  );
  return rows[0] || null;
};

exports.findById = async (id) => {
  const { rows } = await db.query(
    `SELECT id, nom, email, role, langue, est_actif, budget_max,
            code_vendeur, marche_principal_id, zone_collecte, created_at
     FROM utilisateur WHERE id = $1 LIMIT 1`,
    [id]
  );
  return rows[0] || null;
};

exports.save = async ({ nom, email, mot_de_passe, role, langue }) => {
  const { rows } = await db.query(
    `INSERT INTO utilisateur (nom, email, mot_de_passe, role, langue)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, nom, email, role, langue, est_actif, created_at`,
    [nom, email, mot_de_passe, role, langue]
  );
  return rows[0];
};
