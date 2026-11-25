'use strict';

const marcheService = require('../services/marcheService');

exports.getAll = async (req, res, next) => {
  try {
    const marches = await marcheService.getAll();
    res.json({ success: true, data: marches });
  } catch (err) {
    next(err);
  }
};

exports.getById = async (req, res, next) => {
  try {
    const marche = await marcheService.getById(req.params.id);
    if (!marche)
      return res.status(404).json({ success: false, message: 'Marche introuvable.' });
    res.json({ success: true, data: marche });
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const { nom, ville, latitude, longitude, photo_url } = req.body;
    if (!nom || !ville || latitude === undefined || longitude === undefined)
      return res.status(400).json({ success: false, message: 'nom, ville, latitude, longitude obligatoires.' });
    const m = await marcheService.creer({ nom, ville, latitude, longitude, photo_url });
    res.status(201).json({ success: true, data: m });
  } catch (err) { next(err); }
};

exports.update = async (req, res, next) => {
  try {
    const m = await marcheService.modifier(req.params.id, req.body);
    res.json({ success: true, data: m });
  } catch (err) { next(err); }
};

exports.remove = async (req, res, next) => {
  try {
    await marcheService.supprimer(req.params.id);
    res.json({ success: true, message: 'Marche desactive.' });
  } catch (err) { next(err); }
};

exports.comparer = async (req, res, next) => {
  try {
    const { produitId, departId } = req.query;
    if (!produitId || !departId)
      return res.status(400).json({
        success: false,
        message: 'produitId et departId sont obligatoires.'
      });

    const resultat = await marcheService.trouverMeilleureOption(departId, produitId);
    res.json({ success: true, data: resultat });
  } catch (err) {
    next(err);
  }
};
