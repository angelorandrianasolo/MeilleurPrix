'use strict';

const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/previsionController');
const { authenticate } = require('../middlewares/authMiddleware');

router.get('/:produitId', authenticate, ctrl.getPrevision);

module.exports = router;
