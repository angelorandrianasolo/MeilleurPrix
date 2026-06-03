'use strict';

const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/utilisateurController');
const { authenticate, authorize } = require('../middlewares/authMiddleware');

router.get('/',       authenticate, authorize('ADMINISTRATEUR'), ctrl.list);
router.get('/:id',    authenticate, authorize('ADMINISTRATEUR'), ctrl.getById);
router.put('/:id',    authenticate, authorize('ADMINISTRATEUR'), ctrl.update);
router.delete('/:id', authenticate, authorize('ADMINISTRATEUR'), ctrl.remove);

module.exports = router;
