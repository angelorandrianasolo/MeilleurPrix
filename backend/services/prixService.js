'use strict';

const prixRepo = require('../repositories/prixRepository');

exports.enregistrerPrix = async ({
  id,
  produit_id,
  marche_id,
  utilisateur_id,
  valeur,
  unite,
  source_saisie = 'WEB'
}) => {
  if (!valeur || parseFloat(valeur) <= 0) {
    const err = new Error('Le prix doit etre strictement positif.');
    err.statusCode = 400;
    throw err;
  }

  return prixRepo.insert({
    id,
    produit_id,
    marche_id,
    utilisateur_id,
    valeur: parseFloat(valeur),
    unite,
    statut: 'SYNCHRONISEE',
    source_saisie
  });
};

exports.getLastSaisies = async (limit) =>
  prixRepo.findLastSaisies(limit);

exports.getHistorique = async (produitId, marcheId = null, depuis = null) =>
  prixRepo.findHistorique(produitId, marcheId, depuis);
