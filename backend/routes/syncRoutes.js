'use strict';

const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/syncController');
const { authenticate, authorize } = require('../middlewares/authMiddleware');

router.post('/', authenticate, authorize('COLLECTEUR','ADMINISTRATEUR'), ctrl.syncOfflineData);
router.get('/stats', authenticate, authorize('COLLECTEUR','ADMINISTRATEUR'), ctrl.getStats);

module.exports = router;
