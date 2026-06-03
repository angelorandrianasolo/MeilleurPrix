'use strict';

const alerteService = require('../services/alerteService');

exports.create = async (req, res, next) => {
  try {
    const { produit_id, marche_id, prix_seuil, type_seuil } = req.body;
    const result = await alerteService.creer({
      utilisateur_id: req.user.id,
      produit_id,
      marche_id,
      prix_seuil,
      type_seuil
    });
    res.status(201).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
};

exports.list = async (req, res, next) => {
  try {
    const alertes = await alerteService.lister(req.user.id);
    res.json({ success: true, data: alertes });
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    await alerteService.supprimer(req.params.id, req.user.id);
    res.json({ success: true, message: 'Alerte supprimee.' });
  } catch (err) {
    next(err);
  }
};

exports.toggle = async (req, res, next) => {
  try {
    const alerte = await alerteService.basculerActif(req.params.id, req.user.id);
    res.json({ success: true, data: alerte });
  } catch (err) {
    next(err);
  }
};

exports.historique = async (req, res, next) => {
  try {
    const data = await alerteService.getHistorique(req.user.id);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
};

exports.nonLues = async (req, res, next) => {
  try {
    const nb = await alerteService.getNonLues(req.user.id);
    res.json({ success: true, data: { nb } });
  } catch (err) {
    next(err);
  }
};

exports.marquerLues = async (req, res, next) => {
  try {
    await alerteService.marquerLues(req.user.id);
    res.json({ success: true, message: 'Notifications marquees comme lues.' });
  } catch (err) {
    next(err);
  }
};
