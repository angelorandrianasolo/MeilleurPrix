'use strict';
 
const authService = require('../services/authService');
 
/**
 * POST /api/v1/auth/register
 */
exports.register = async (req, res, next) => {
  try {
    const { nom, email, mot_de_passe, role, langue } = req.body;
    const result = await authService.register({ nom, email, mot_de_passe, role, langue });
    res.status(201).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
};
 
/**
 * POST /api/v1/auth/login
 */
exports.login = async (req, res, next) => {
  try {
    const { email, mot_de_passe } = req.body;
    if (!email || !mot_de_passe)
      return res.status(400).json({ success: false, message: 'Email et mot de passe obligatoires.' });
 
    const result = await authService.login(email, mot_de_passe);
    res.status(200).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
};
 
/**
 * GET /api/v1/auth/me
 */
exports.getMe = async (req, res, next) => {
  try {
    const user = await authService.getById(req.user.id);
    res.status(200).json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
};