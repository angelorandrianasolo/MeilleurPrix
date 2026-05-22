'use strict';

const db = require('../config/db');

exports.findAllForTrie = async () => {
  const { rows } = await db.query(
    `SELECT p.id, p.nom_fr, p.nom_mg, p.unite, p.description,
            c.libelle_fr AS categorie_fr, c.libelle_mg AS categorie_mg
     FROM produit p
     JOIN categorie_produit c ON c.id = p.categorie_id
     WHERE p.est_actif = TRUE
     ORDER BY p.nom_fr`
  );
  return rows;
};

exports.findAll = async (categorieId) => {
  let sql = `
    SELECT p.id, p.nom_fr, p.nom_mg, p.unite, p.description,
           c.libelle_fr AS categorie_fr, c.libelle_mg AS categorie_mg
    FROM produit p
    JOIN categorie_produit c ON c.id = p.categorie_id
    WHERE p.est_actif = TRUE`;
  const params = [];
  if (categorieId) {
    sql += ' AND p.categorie_id = $1';
    params.push(categorieId);
  }
  sql += ' ORDER BY c.libelle_fr, p.nom_fr';
  const { rows } = await db.query(sql, params);
  return rows;
};

exports.findById = async (id) => {
  const { rows } = await db.query(
    `SELECT p.*, c.libelle_fr AS categorie_fr, c.libelle_mg AS categorie_mg
     FROM produit p
     JOIN categorie_produit c ON c.id = p.categorie_id
     WHERE p.id = $1 AND p.est_actif = TRUE LIMIT 1`,
    [id]
  );
  return rows[0] || null;
};

exports.findCategories = async () => {
  const { rows } = await db.query(
    'SELECT id, libelle_fr, libelle_mg FROM categorie_produit ORDER BY libelle_fr'
  );
  return rows;
};
