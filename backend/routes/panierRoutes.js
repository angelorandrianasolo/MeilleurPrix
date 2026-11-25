'use strict';
const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/panierController');
const { authenticate, authorize } = require('../middlewares/authMiddleware');
const { validatePanier } = require('../middlewares/validate');
router.post('/optimiser', authenticate, authorize('ACHETEUR'), validatePanier, ctrl.optimiser);
module.exports = router;