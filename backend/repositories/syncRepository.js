'use strict';

const db = require('../config/db');

exports.addToQueue = async ({ utilisateur_id, saisie_prix_id, payload }) => {
  const { rows } = await db.query(
    `INSERT INTO file_synchronisation (utilisateur_id, saisie_prix_id, payload, statut)
     VALUES ($1, $2, $3, 'EN_ATTENTE')
     ON CONFLICT (saisie_prix_id) DO UPDATE SET payload = EXCLUDED.payload
     RETURNING *`,
    [utilisateur_id, saisie_prix_id, JSON.stringify(payload)]
  );
  return rows[0];
};

exports.getPendingBatch = async (limit = 50) => {
  const { rows } = await db.query(
    `SELECT * FROM file_synchronisation
     WHERE statut = 'EN_ATTENTE'
     ORDER BY ordre_envoi ASC
     LIMIT $1`,
    [limit]
  );
  return rows;
};

exports.updateQueueStatus = async (ordreEnvoi, statut, dateEnvoi = null) => {
  await db.query(
    `UPDATE file_synchronisation
     SET statut = $2, date_envoi = COALESCE($3, date_envoi), nb_tentatives = nb_tentatives + 1
     WHERE ordre_envoi = $1`,
    [ordreEnvoi, statut, dateEnvoi]
  );
};

exports.countPending = async () => {
  const { rows } = await db.query(
    `SELECT COUNT(*)::int AS n FROM file_synchronisation WHERE statut = 'EN_ATTENTE'`
  );
  return rows[0].n;
};
