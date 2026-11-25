'use strict';

const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/previsionController');
const { authenticate, authorize } = require('../middlewares/authMiddleware');

router.get('/:produitId', authenticate, authorize('ACHETEUR','VENDEUR'), ctrl.getPrevision);

module.exports = router;
