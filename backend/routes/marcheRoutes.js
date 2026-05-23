'use strict';
const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/marcheController');
const { authenticate } = require('../middlewares/authMiddleware');
 
router.get('/comparer', authenticate, ctrl.comparer);  // Dijkstra — nécessite auth
router.get('/',         ctrl.getAll);
router.get('/:id',      ctrl.getById);
 
module.exports = router;