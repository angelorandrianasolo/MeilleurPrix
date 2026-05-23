'use strict';

const dashboardService = require('../services/dashboardService');

exports.getDashboard = async (req, res, next) => {
  try {
    const data = await dashboardService.getDashboard();
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
};
