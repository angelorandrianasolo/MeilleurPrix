'use strict';

const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/prixController');
const { authenticate, authorize } = require('../middlewares/authMiddleware');
const { validatePrix } = require('../middlewares/validate');

router.get('/produit/:produitId', ctrl.getByProduit);

router.post(
  '/',
  authenticate,
  authorize('VENDEUR', 'COLLECTEUR', 'ADMINISTRATEUR'),
  validatePrix,
  ctrl.create
);

module.exports = router;
