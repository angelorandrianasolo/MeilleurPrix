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

exports.create = async ({ nom_fr, nom_mg, categorie_id, unite, description }) => {
  const { v4: uuidv4 } = require('uuid');
  const { rows } = await db.query(
    `INSERT INTO produit (id, nom_fr, nom_mg, categorie_id, unite, description)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
    [uuidv4(), nom_fr, nom_mg, categorie_id, unite, description || null]
  );
  return rows[0];
};

exports.update = async (id, { nom_fr, nom_mg, categorie_id, unite, description, est_actif }) => {
  const fields = []; const params = []; let i = 1;
  if (nom_fr !== undefined) { fields.push(`nom_fr = $${i++}`); params.push(nom_fr); }
  if (nom_mg !== undefined) { fields.push(`nom_mg = $${i++}`); params.push(nom_mg); }
  if (categorie_id !== undefined) { fields.push(`categorie_id = $${i++}`); params.push(categorie_id); }
  if (unite !== undefined) { fields.push(`unite = $${i++}`); params.push(unite); }
  if (description !== undefined) { fields.push(`description = $${i++}`); params.push(description); }
  if (est_actif !== undefined) { fields.push(`est_actif = $${i++}`); params.push(est_actif); }
  if (fields.length === 0) return null;
  fields.push('updated_at = NOW()');
  params.push(id);
  const { rows } = await db.query(
    `UPDATE produit SET ${fields.join(', ')} WHERE id = $${i} RETURNING *`,
    params
  );
  return rows[0] || null;
};

exports.remove = async (id) => {
  const { rowCount } = await db.query(
    `UPDATE produit SET est_actif = FALSE, updated_at = NOW() WHERE id = $1`,
    [id]
  );
  return rowCount > 0;
};
