'use strict';

const db = require('../config/db');

exports.findAll = async () => {
  const { rows } = await db.query(
    'SELECT id, nom, ville, latitude, longitude, photo_url FROM marche WHERE est_actif = TRUE ORDER BY ville, nom'
  );
  return rows;
};

exports.findById = async (id) => {
  const { rows } = await db.query(
    'SELECT * FROM marche WHERE id = $1 AND est_actif = TRUE LIMIT 1',
    [id]
  );
  return rows[0] || null;
};

exports.findLiens = async () => {
  const { rows } = await db.query(
    `SELECT id, marche_depart_id, marche_arrivee_id, distance_km, cout_transport
     FROM itineraire_marche`
  );
  return rows;
};

exports.create = async ({ nom, ville, latitude, longitude, photo_url }) => {
  const { v4: uuidv4 } = require('uuid');
  const { rows } = await db.query(
    `INSERT INTO marche (id, nom, ville, latitude, longitude, photo_url)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
    [uuidv4(), nom, ville, parseFloat(latitude), parseFloat(longitude), photo_url || null]
  );
  return rows[0];
};

exports.update = async (id, { nom, ville, latitude, longitude, photo_url, est_actif }) => {
  const fields = []; const params = []; let i = 1;
  if (nom !== undefined) { fields.push(`nom = $${i++}`); params.push(nom); }
  if (ville !== undefined) { fields.push(`ville = $${i++}`); params.push(ville); }
  if (latitude !== undefined) { fields.push(`latitude = $${i++}`); params.push(parseFloat(latitude)); }
  if (longitude !== undefined) { fields.push(`longitude = $${i++}`); params.push(parseFloat(longitude)); }
  if (photo_url !== undefined) { fields.push(`photo_url = $${i++}`); params.push(photo_url); }
  if (est_actif !== undefined) { fields.push(`est_actif = $${i++}`); params.push(est_actif); }
  if (fields.length === 0) return null;
  fields.push('updated_at = NOW()');
  params.push(id);
  const { rows } = await db.query(
    `UPDATE marche SET ${fields.join(', ')} WHERE id = $${i} RETURNING *`,
    params
  );
  return rows[0] || null;
};

exports.remove = async (id) => {
  const { rowCount } = await db.query(
    `UPDATE marche SET est_actif = FALSE, updated_at = NOW() WHERE id = $1`,
    [id]
  );
  return rowCount > 0;
};

exports.findAllAdmin = async () => {
  const { rows } = await db.query(
    'SELECT * FROM marche ORDER BY ville, nom'
  );
  return rows;
};
