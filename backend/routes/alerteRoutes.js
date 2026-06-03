'use strict';

const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/alerteController');
const { authenticate } = require('../middlewares/authMiddleware');

router.post('/',   authenticate, ctrl.create);
router.get('/',    authenticate, ctrl.list);
router.get('/non-lues', authenticate, ctrl.nonLues);
router.get('/historique', authenticate, ctrl.historique);
router.put('/lues', authenticate, ctrl.marquerLues);
router.delete('/:id', authenticate, ctrl.remove);
router.patch('/:id/toggle', authenticate, ctrl.toggle);

module.exports = router;
