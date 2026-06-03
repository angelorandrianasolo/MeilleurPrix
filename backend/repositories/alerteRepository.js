'use strict';

const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

exports.create = async ({ utilisateur_id, produit_id, marche_id, prix_seuil, type_seuil }) => {
  const { rows } = await db.query(
    `INSERT INTO meilleur_prix.alerte_prix (id, utilisateur_id, produit_id, marche_id, prix_seuil, type_seuil)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
    [uuidv4(), utilisateur_id, produit_id, marche_id, prix_seuil, type_seuil]
  );
  return rows[0];
};

exports.findByUser = async (utilisateur_id) => {
  const { rows } = await db.query(
    `SELECT a.*, p.nom_fr AS produit_nom, p.nom_mg AS produit_nom_mg, m.nom AS marche_nom, m.ville AS marche_ville
     FROM meilleur_prix.alerte_prix a
     JOIN meilleur_prix.produit p ON p.id = a.produit_id
     LEFT JOIN meilleur_prix.marche m ON m.id = a.marche_id
     WHERE a.utilisateur_id = $1
     ORDER BY a.date_creation DESC`,
    [utilisateur_id]
  );
  return rows;
};

exports.findById = async (id) => {
  const { rows } = await db.query(
    `SELECT a.*, p.nom_fr AS produit_nom, m.nom AS marche_nom
     FROM meilleur_prix.alerte_prix a
     JOIN meilleur_prix.produit p ON p.id = a.produit_id
     LEFT JOIN meilleur_prix.marche m ON m.id = a.marche_id
     WHERE a.id = $1 LIMIT 1`,
    [id]
  );
  return rows[0] || null;
};

exports.delete = async (id, utilisateur_id) => {
  const { rowCount } = await db.query(
    `DELETE FROM meilleur_prix.alerte_prix WHERE id = $1 AND utilisateur_id = $2`,
    [id, utilisateur_id]
  );
  return rowCount > 0;
};

exports.toggleActif = async (id, utilisateur_id) => {
  const { rows } = await db.query(
    `UPDATE meilleur_prix.alerte_prix SET est_actif = NOT est_actif, updated_at = NOW()
     WHERE id = $1 AND utilisateur_id = $2 RETURNING *`,
    [id, utilisateur_id]
  );
  return rows[0] || null;
};

exports.findAlertesDeclenchables = async (produit_id, marche_id, nouveau_prix) => {
  const { rows } = await db.query(
    `SELECT a.*, u.email AS utilisateur_email, u.nom AS utilisateur_nom
     FROM meilleur_prix.alerte_prix a
     JOIN meilleur_prix.utilisateur u ON u.id = a.utilisateur_id
     WHERE a.produit_id = $1
       AND (a.marche_id IS NULL OR a.marche_id = $2)
       AND a.est_actif = TRUE
       AND (
         (a.type_seuil = 'INFERIEUR' AND $3 <= a.prix_seuil)
         OR
         (a.type_seuil = 'SUPERIEUR' AND $3 >= a.prix_seuil)
       )`,
    [produit_id, marche_id, nouveau_prix]
  );
  return rows;
};

exports.insererHistorique = async ({ alerte_id, utilisateur_id, produit_id, marche_id, prix_actuel, prix_seuil, type_seuil }) => {
  const { rows } = await db.query(
    `INSERT INTO meilleur_prix.historique_alerte (id, alerte_id, utilisateur_id, produit_id, marche_id, prix_actuel, prix_seuil, type_seuil)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
    [uuidv4(), alerte_id, utilisateur_id, produit_id, marche_id, prix_actuel, prix_seuil, type_seuil]
  );
  return rows[0];
};

exports.marquerDeclenchement = async (alerte_id) => {
  await db.query(
    `UPDATE meilleur_prix.alerte_prix SET date_dernier_declenchement = NOW(), updated_at = NOW()
     WHERE id = $1`,
    [alerte_id]
  );
};

exports.getHistoriqueByUser = async (utilisateur_id, limite = 20) => {
  const { rows } = await db.query(
    `SELECT h.*, p.nom_fr AS produit_nom, m.nom AS marche_nom, m.ville AS marche_ville
     FROM meilleur_prix.historique_alerte h
     JOIN meilleur_prix.produit p ON p.id = h.produit_id
     LEFT JOIN meilleur_prix.marche m ON m.id = h.marche_id
     WHERE h.utilisateur_id = $1
     ORDER BY h.date_declenchement DESC
     LIMIT $2`,
    [utilisateur_id, limite]
  );
  return rows;
};

exports.compterNonLues = async (utilisateur_id) => {
  const { rows } = await db.query(
    `SELECT COUNT(*)::int AS nb FROM meilleur_prix.historique_alerte
     WHERE utilisateur_id = $1 AND est_lue = FALSE`,
    [utilisateur_id]
  );
  return rows[0].nb;
};

exports.marquerLues = async (utilisateur_id) => {
  await db.query(
    `UPDATE meilleur_prix.historique_alerte SET est_lue = TRUE
     WHERE utilisateur_id = $1 AND est_lue = FALSE`,
    [utilisateur_id]
  );
};
