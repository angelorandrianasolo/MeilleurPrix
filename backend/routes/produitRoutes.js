'use strict';

const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/produitController');

router.get('/search', ctrl.search);
router.get('/categories/list', ctrl.getCategories);
router.get('/', ctrl.getAll);
router.get('/:id', ctrl.getById);

module.exports = router;
