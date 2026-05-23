'use strict';
const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/panierController');
const { authenticate } = require('../middlewares/authMiddleware');
const { validatePanier } = require('../middlewares/validate');
router.post('/optimiser', authenticate, validatePanier, ctrl.optimiser);
module.exports = router;