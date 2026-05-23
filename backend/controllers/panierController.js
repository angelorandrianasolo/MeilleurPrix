'use strict';
const panierService = require('../services/panierService');
 
exports.optimiser = async (req, res, next) => {
  try {
    const { budget, produits } = req.body;
    const resultat = await panierService.optimiser(parseFloat(budget), produits);
    res.json({ success: true, data: resultat });
  } catch (err) { next(err); }
};