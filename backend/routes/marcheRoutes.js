'use strict';
const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/marcheController');
const { authenticate, authorize } = require('../middlewares/authMiddleware');
 
router.get('/comparer', authenticate, ctrl.comparer);
router.get('/',         ctrl.getAll);
router.get('/:id',      ctrl.getById);

router.post('/',       authenticate, authorize('ADMINISTRATEUR'), ctrl.create);
router.put('/:id',     authenticate, authorize('ADMINISTRATEUR'), ctrl.update);
router.delete('/:id',  authenticate, authorize('ADMINISTRATEUR'), ctrl.remove);
 
module.exports = router;