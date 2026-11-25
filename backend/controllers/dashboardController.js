'use strict';

const dashboardService = require('../services/dashboardService');

exports.getDashboard = async (req, res, next) => {
  try {
    const userId = req.user ? req.user.id : null;
    const data = await dashboardService.getDashboard(userId);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
};
