'use strict';

const alerteRepo = require('../repositories/alerteRepository');

exports.creer = async ({ utilisateur_id, produit_id, marche_id, prix_seuil, type_seuil }) => {
  if (!produit_id || !prix_seuil || prix_seuil <= 0) {
    const err = new Error('produit_id et prix_seuil (>0) sont obligatoires.');
    err.statusCode = 400;
    throw err;
  }
  const valide = ['INFERIEUR', 'SUPERIEUR'];
  if (!valide.includes(type_seuil)) {
    const err = new Error('type_seuil doit etre INFERIEUR ou SUPERIEUR.');
    err.statusCode = 400;
    throw err;
  }
  return alerteRepo.create({ utilisateur_id, produit_id, marche_id: marche_id || null, prix_seuil, type_seuil });
};

exports.lister = async (utilisateur_id) => {
  return alerteRepo.findByUser(utilisateur_id);
};

exports.supprimer = async (id, utilisateur_id) => {
  const ok = await alerteRepo.delete(id, utilisateur_id);
  if (!ok) {
    const err = new Error('Alerte introuvable ou acces refuse.');
    err.statusCode = 404;
    throw err;
  }
  return true;
};

exports.basculerActif = async (id, utilisateur_id) => {
  const alerte = await alerteRepo.toggleActif(id, utilisateur_id);
  if (!alerte) {
    const err = new Error('Alerte introuvable ou acces refuse.');
    err.statusCode = 404;
    throw err;
  }
  return alerte;
};

exports.verifierEtDeclencher = async ({ produit_id, marche_id, nouveau_prix }) => {
  const alertes = await alerteRepo.findAlertesDeclenchables(produit_id, marche_id, nouveau_prix);
  const declenchees = [];
  for (const alerte of alertes) {
    await alerteRepo.insererHistorique({
      alerte_id: alerte.id,
      utilisateur_id: alerte.utilisateur_id,
      produit_id,
      marche_id,
      prix_actuel: nouveau_prix,
      prix_seuil: parseFloat(alerte.prix_seuil),
      type_seuil: alerte.type_seuil
    });
    await alerteRepo.marquerDeclenchement(alerte.id);
    declenchees.push({
      alerte_id: alerte.id,
      utilisateur_id: alerte.utilisateur_id,
      utilisateur_email: alerte.utilisateur_email,
      utilisateur_nom: alerte.utilisateur_nom
    });
  }
  return declenchees;
};

exports.getHistorique = async (utilisateur_id) => {
  return alerteRepo.getHistoriqueByUser(utilisateur_id);
};

exports.getNonLues = async (utilisateur_id) => {
  return alerteRepo.compterNonLues(utilisateur_id);
};

exports.marquerLues = async (utilisateur_id) => {
  return alerteRepo.marquerLues(utilisateur_id);
};
