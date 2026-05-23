'use strict';
const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/dashboardController');
const { authenticate, authorize } = require('../middlewares/authMiddleware');
router.get('/', authenticate, authorize('VENDEUR','COLLECTEUR','ADMINISTRATEUR'), ctrl.getDashboard);
module.exports = router;