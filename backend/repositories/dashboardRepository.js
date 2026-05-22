'use strict';

const db = require('../config/db');

exports.getTopProduits = async (limit = 5) => {
  const { rows } = await db.query(
    `SELECT p.id, p.nom_fr, COUNT(sp.id)::int AS nb_saisies,
            ROUND(AVG(sp.valeur), 0) AS prix_moyen
     FROM saisie_prix sp
     JOIN produit p ON p.id = sp.produit_id
     WHERE sp.statut = 'SYNCHRONISEE'
     GROUP BY p.id, p.nom_fr
     ORDER BY nb_saisies DESC
     LIMIT $1`,
    [limit]
  );
  return rows;
};

exports.getTopMarches = async (limit = 5) => {
  const { rows } = await db.query(
    `SELECT m.nom, m.ville, m.photo_url, COUNT(sp.id)::int AS nb_saisies
     FROM saisie_prix sp
     JOIN marche m ON m.id = sp.marche_id
     WHERE sp.statut = 'SYNCHRONISEE'
     GROUP BY m.nom, m.ville, m.photo_url
     ORDER BY nb_saisies DESC
     LIMIT $1`,
    [limit]
  );
  return rows;
};

exports.getStats = async () => {
  const { rows } = await db.query(`
    SELECT
      (SELECT COUNT(*)::int FROM produit WHERE est_actif = TRUE) AS nb_produits,
      (SELECT COUNT(*)::int FROM marche WHERE est_actif = TRUE) AS nb_marches,
      (SELECT COUNT(*)::int FROM utilisateur WHERE est_actif = TRUE) AS nb_utilisateurs,
      (SELECT COUNT(*)::int FROM saisie_prix WHERE statut = 'SYNCHRONISEE') AS nb_saisies_total,
      (SELECT COUNT(*)::int FROM file_synchronisation WHERE statut = 'EN_ATTENTE') AS nb_sync_attente,
      (SELECT ROUND(COALESCE(AVG(valeur),0)) FROM saisie_prix WHERE statut = 'SYNCHRONISEE') AS prix_moyen
  `);
  return rows[0];
};

exports.getRepartitionCategories = async () => {
  const { rows } = await db.query(`
    SELECT COALESCE(cp.libelle_fr, 'General') AS categorie,
           COUNT(sp.id)::int AS nb_saisies
    FROM saisie_prix sp
    JOIN produit p ON p.id = sp.produit_id
    LEFT JOIN categorie_produit cp ON cp.id = p.categorie_id
    WHERE sp.statut = 'SYNCHRONISEE'
    GROUP BY cp.libelle_fr
    ORDER BY nb_saisies DESC
  `);
  return rows;
};

exports.getTendance30j = async () => {
  const { rows } = await db.query(
    `SELECT date_jour, ROUND(AVG(prix_moyen), 0) AS prix_moyen_global
     FROM historique_prix
     WHERE date_jour >= CURRENT_DATE - INTERVAL '30 days'
     GROUP BY date_jour
     ORDER BY date_jour ASC`
  );
  return rows;
};
