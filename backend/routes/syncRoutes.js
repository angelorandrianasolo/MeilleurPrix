'use strict';

const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/syncController');
const { authenticate } = require('../middlewares/authMiddleware');

router.post('/', authenticate, ctrl.syncOfflineData);
router.get('/stats', authenticate, ctrl.getStats);

module.exports = router;
