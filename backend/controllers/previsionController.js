'use strict';

const previsionService = require('../services/previsionService');

exports.getPrevision = async (req, res, next) => {
  try {
    const { produitId } = req.params;
    const { marcheId, jours = 30 } = req.query;
    const result = await previsionService.calculer(
      produitId,
      marcheId || null,
      parseInt(jours, 10)
    );
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
};
