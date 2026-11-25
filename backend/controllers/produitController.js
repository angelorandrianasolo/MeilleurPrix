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

exports.create = async (req, res, next) => {
  try {
    const { nom_fr, nom_mg, categorie_id, unite, description } = req.body;
    if (!nom_fr || !nom_mg || !categorie_id || !unite)
      return res.status(400).json({ success: false, message: 'nom_fr, nom_mg, categorie_id et unite obligatoires.' });
    const p = await produitService.creer({ nom_fr, nom_mg, categorie_id, unite, description });
    res.status(201).json({ success: true, data: p });
  } catch (err) { next(err); }
};

exports.update = async (req, res, next) => {
  try {
    const p = await produitService.modifier(req.params.id, req.body);
    res.json({ success: true, data: p });
  } catch (err) { next(err); }
};

exports.remove = async (req, res, next) => {
  try {
    await produitService.supprimer(req.params.id);
    res.json({ success: true, message: 'Produit desactive.' });
  } catch (err) { next(err); }
};
