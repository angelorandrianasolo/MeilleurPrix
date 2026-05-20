'use strict';
 
const jwt    = require('jsonwebtoken');
const jwtCfg = require('../config/jwt');
 
/**
 * Middleware d'authentification — vérifie le Bearer token JWT
 */
const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
 
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Token d\'authentification manquant ou invalide.'
    });
  }
 
  const token = authHeader.split(' ')[1];
 
  try {
    const payload = jwt.verify(token, jwtCfg.secret, { algorithms: [jwtCfg.algorithm] });
    req.user = payload; // { id, email, role, langue }
    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      message: 'Token expiré ou invalide. Veuillez vous reconnecter.'
    });
  }
};
 
/**
 * Middleware d'autorisation par rôle
 * @param {...string} roles - Rôles autorisés
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user?.role)) {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé. Droits insuffisants.'
      });
    }
    next();
  };
};
 
module.exports = { authenticate, authorize };