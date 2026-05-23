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
