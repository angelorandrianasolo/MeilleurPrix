'use strict';

const produitService = require('../services/produitService');

exports.search = async (req, res, next) => {
  try {
    const { q = '' } = req.query;
    const debut = Date.now();
    const produits = await produitService.rechercher(q);
    res.json({
      success: true,
      data: produits,
      temps_ms: Date.now() - debut
    });
  } catch (err) {
    next(err);
  }
};

exports.getAll = async (req, res, next) => {
  try {
    const { categorie } = req.query;
    const produits = await produitService.getAll(categorie || null);
    res.json({ success: true, data: produits });
  } catch (err) {
    next(err);
  }
};

exports.getCategories = async (req, res, next) => {
  try {
    const categories = await produitService.getCategories();
    res.json({ success: true, data: categories });
  } catch (err) {
    next(err);
  }
};

exports.getById = async (req, res, next) => {
  try {
    const produit = await produitService.getById(req.params.id);
    if (!produit)
      return res.status(404).json({ success: false, message: 'Produit introuvable.' });
    res.json({ success: true, data: produit });
  } catch (err) {
    next(err);
  }
};
