'use strict';

const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isUuid(value) {
  return typeof value === 'string' && UUID_REGEX.test(value);
}

const validateRegister = (req, res, next) => {
  const { nom, email, mot_de_passe, role } = req.body;
  const erreurs = [];

  if (!nom || nom.trim().length < 2)
    erreurs.push('Le nom doit contenir au moins 2 caracteres.');

  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
    erreurs.push('L\'adresse email est invalide.');

  if (!mot_de_passe || mot_de_passe.length < 6)
    erreurs.push('Le mot de passe doit contenir au moins 6 caracteres.');

  const rolesValides = ['ACHETEUR', 'VENDEUR', 'COLLECTEUR', 'ADMINISTRATEUR'];
  if (role && !rolesValides.includes(role))
    erreurs.push(`Role invalide. Valeurs : ${rolesValides.join(', ')}.`);

  if (erreurs.length > 0)
    return res.status(400).json({ success: false, message: erreurs.join(' ') });

  next();
};

const validatePrix = (req, res, next) => {
  const { produit_id, marche_id, prix, valeur, unite } = req.body;
  const erreurs = [];

  const pid = produit_id;
  const mid = marche_id;

  if (!isUuid(pid)) erreurs.push('produit_id (UUID) est obligatoire.');
  if (!isUuid(mid)) erreurs.push('marche_id (UUID) est obligatoire.');

  const montant = parseFloat(valeur ?? prix);
  if (Number.isNaN(montant) || montant <= 0)
    erreurs.push('Le prix doit etre un nombre positif.');

  if (!unite || unite.trim().length === 0)
    erreurs.push('L\'unite est obligatoire (ex: kg, litre).');

  if (erreurs.length > 0)
    return res.status(400).json({ success: false, message: erreurs.join(' ') });

  next();
};

const validatePanier = (req, res, next) => {
  const { budget, produits } = req.body;
  const erreurs = [];

  const budgetNum = parseFloat(budget);
  if (Number.isNaN(budgetNum) || budgetNum <= 0)
    erreurs.push('Le budget doit etre un nombre positif.');

  if (!Array.isArray(produits) || produits.length === 0)
    erreurs.push('La liste de produits est obligatoire.');

  for (const p of produits || []) {
    if (!isUuid(p.id_produit))
      erreurs.push('Chaque produit doit avoir un id_produit (UUID) valide.');
  }

  if (erreurs.length > 0)
    return res.status(400).json({ success: false, message: erreurs.join(' ') });

  next();
};

module.exports = { validateRegister, validatePrix, validatePanier, isUuid };
