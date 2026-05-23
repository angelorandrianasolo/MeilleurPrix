'use strict';

const syncService = require('../services/syncService');

exports.syncOfflineData = async (req, res, next) => {
  try {
    const { saisies } = req.body;
    if (!Array.isArray(saisies) || saisies.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Aucune saisie a synchroniser.'
      });
    }

    const { synchronisees, erreurs } = await syncService.synchroniserBatch(
      req.user.id,
      saisies
    );

    res.json({
      success: true,
      message: `${synchronisees.length} saisie(s) synchronisee(s).`,
      synchronisees: synchronisees.length,
      data: synchronisees,
      erreurs
    });
  } catch (err) {
    next(err);
  }
};

exports.getStats = async (req, res, next) => {
  try {
    const stats = await syncService.getFileStats();
    res.json({ success: true, data: stats });
  } catch (err) {
    next(err);
  }
};
