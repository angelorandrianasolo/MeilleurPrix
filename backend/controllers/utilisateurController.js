'use strict';

const utilisateurRepo = require('../repositories/utilisateurRepository');
const db = require('../config/db');

exports.list = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT id, nom, email, role, langue, est_actif, budget_max,
              code_vendeur, marche_principal_id, zone_collecte, created_at
       FROM meilleur_prix.utilisateur
       ORDER BY created_at DESC`
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    next(err);
  }
};

exports.getById = async (req, res, next) => {
  try {
    const user = await utilisateurRepo.findById(req.params.id);
    if (!user) return res.status(404).json({ success: false, message: 'Utilisateur introuvable.' });
    res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const { nom, role, langue, est_actif } = req.body;
    const fields = [];
    const params = [];
    let i = 1;

    if (nom !== undefined) { fields.push(`nom = $${i++}`); params.push(nom); }
    if (role !== undefined) { fields.push(`role = $${i++}`); params.push(role); }
    if (langue !== undefined) { fields.push(`langue = $${i++}`); params.push(langue); }
    if (est_actif !== undefined) { fields.push(`est_actif = $${i++}`); params.push(est_actif); }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'Aucun champ a mettre a jour.' });
    }

    fields.push(`updated_at = NOW()`);
    params.push(req.params.id);

    const { rows } = await db.query(
      `UPDATE meilleur_prix.utilisateur SET ${fields.join(', ')}
       WHERE id = $${i}
       RETURNING id, nom, email, role, langue, est_actif, created_at`,
      params
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Utilisateur introuvable.' });
    }

    res.json({ success: true, data: rows[0] });
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM meilleur_prix.utilisateur WHERE id = $1`,
      [req.params.id]
    );
    if (rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Utilisateur introuvable.' });
    }
    res.json({ success: true, message: 'Utilisateur supprime.' });
  } catch (err) {
    next(err);
  }
};
