'use strict';

const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');

exports.insert = async ({
  id,
  produit_id,
  marche_id,
  utilisateur_id,
  valeur,
  unite,
  statut = 'SYNCHRONISEE',
  source_saisie = 'WEB'
}) => {
  const saisieId = id || uuidv4();
  const { rows } = await db.query(
    `INSERT INTO saisie_prix
       (id, produit_id, marche_id, utilisateur_id, valeur, unite, statut, source_saisie, est_synchro)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
     RETURNING *`,
    [
      saisieId,
      produit_id,
      marche_id,
      utilisateur_id,
      valeur,
      unite,
      statut,
      source_saisie,
      statut === 'SYNCHRONISEE'
    ]
  );
  return rows[0];
};

exports.updateStatut = async (id, statut, raison_rejet = null) => {
  const { rows } = await db.query(
    `UPDATE saisie_prix
     SET statut = $2, raison_rejet = $3, est_synchro = ($2 = 'SYNCHRONISEE'), updated_at = NOW()
     WHERE id = $1 RETURNING *`,
    [id, statut, raison_rejet]
  );
  return rows[0];
};

exports.findHistorique = async (produitId, marcheId = null, depuis = null) => {
  let sql = `
    SELECT date_jour, prix_min, prix_max, prix_moyen, nb_saisies, marche_id
    FROM historique_prix
    WHERE produit_id = $1`;
  const params = [produitId];
  let i = 2;

  if (marcheId) {
    sql += ` AND marche_id = $${i++}`;
    params.push(marcheId);
  }
  if (depuis) {
    sql += ` AND date_jour >= $${i++}`;
    params.push(depuis);
  }
  sql += ' ORDER BY date_jour ASC LIMIT 365';
  const { rows } = await db.query(sql, params);
  return rows;
};

exports.getDerniersPrixParMarche = async (produitId) => {
  const { rows } = await db.query(
    `SELECT marche_id, prix_actuel AS prix, marche_nom, ville, date_prix
     FROM v_prix_actuel
     WHERE produit_id = $1`,
    [produitId]
  );
  return rows;
};

exports.countSaisies = async () => {
  const { rows } = await db.query(
    `SELECT COUNT(*)::int AS total FROM saisie_prix WHERE statut = 'SYNCHRONISEE'`
  );
  return rows[0].total;
};
