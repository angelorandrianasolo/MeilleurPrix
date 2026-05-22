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
