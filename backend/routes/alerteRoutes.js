'use strict';

const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/alerteController');
const { authenticate, authorize } = require('../middlewares/authMiddleware');

router.post('/',   authenticate, authorize('ACHETEUR'), ctrl.create);
router.get('/',    authenticate, authorize('ACHETEUR'), ctrl.list);
router.get('/non-lues', authenticate, authorize('ACHETEUR'), ctrl.nonLues);
router.get('/historique', authenticate, authorize('ACHETEUR'), ctrl.historique);
router.put('/lues', authenticate, authorize('ACHETEUR'), ctrl.marquerLues);
router.delete('/:id', authenticate, authorize('ACHETEUR'), ctrl.remove);
router.patch('/:id/toggle', authenticate, authorize('ACHETEUR'), ctrl.toggle);

module.exports = router;
