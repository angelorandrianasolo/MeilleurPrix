'use strict';
 
const express        = require('express');
const router         = express.Router();
const authController = require('../controllers/authController');
const { authenticate }    = require('../middlewares/authMiddleware');
const { validateRegister } = require('../middlewares/validate');
 
router.post('/register', validateRegister, authController.register);
router.post('/login',                      authController.login);
router.get ('/me',       authenticate,     authController.getMe);
 
module.exports = router;