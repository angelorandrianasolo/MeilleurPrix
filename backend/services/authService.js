'use strict';

const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const jwtCfg = require('../config/jwt');
const utilisateurRepo = require('../repositories/utilisateurRepository');

const SALT_ROUNDS = 12;

exports.register = async ({ nom, email, mot_de_passe, role = 'ACHETEUR', langue = 'FR' }) => {
  const existant = await utilisateurRepo.findByEmail(email);
  if (existant) {
    const err = new Error('Un compte avec cet email existe deja.');
    err.statusCode = 409;
    throw err;
  }

  const hash = await bcrypt.hash(mot_de_passe, SALT_ROUNDS);
  const user = await utilisateurRepo.save({ nom, email, mot_de_passe: hash, role, langue });
  const token = genererToken(user);
  return { token, utilisateur: sanitize(user) };
};

exports.login = async (email, mot_de_passe) => {
  const user = await utilisateurRepo.findByEmail(email);

  if (!user) {
    const err = new Error('Email ou mot de passe incorrect.');
    err.statusCode = 401;
    throw err;
  }

  if (!user.est_actif) {
    const err = new Error('Compte desactive. Contactez l\'administrateur.');
    err.statusCode = 403;
    throw err;
  }

  const valide = await bcrypt.compare(mot_de_passe, user.mot_de_passe);
  if (!valide) {
    const err = new Error('Email ou mot de passe incorrect.');
    err.statusCode = 401;
    throw err;
  }

  const token = genererToken(user);
  return { token, utilisateur: sanitize(user) };
};

exports.getById = async (id) => {
  const user = await utilisateurRepo.findById(id);
  if (!user) {
    const err = new Error('Utilisateur introuvable.');
    err.statusCode = 404;
    throw err;
  }
  return sanitize(user);
};

function genererToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email, role: user.role, langue: user.langue },
    jwtCfg.secret,
    { expiresIn: jwtCfg.expiresIn, algorithm: jwtCfg.algorithm }
  );
}

function sanitize(user) {
  const { mot_de_passe, ...safe } = user;
  return safe;
}
