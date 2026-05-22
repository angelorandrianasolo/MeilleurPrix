'use strict';

const { v4: uuidv4 } = require('uuid');
const prixRepo = require('../repositories/prixRepository');
const syncRepo = require('../repositories/syncRepository');

/**
 * Traite les saisies hors-ligne en ordre FIFO.
 */
exports.synchroniserBatch = async (utilisateurId, saisies) => {
  const synchronisees = [];
  const erreurs = [];

  for (const saisie of saisies) {
    try {
      const {
        id,
        produit_id,
        marche_id,
        valeur,
        prix,
        unite,
        source_saisie = 'MOBILE'
      } = saisie;

      const montant = parseFloat(valeur ?? prix);
      if (!produit_id || !marche_id || !montant || montant <= 0) {
        erreurs.push({ saisie, raison: 'Donnees invalides (prix > 0 requis)' });
        continue;
      }

      const saisieId = id || uuidv4();

      await syncRepo.addToQueue({
        utilisateur_id: utilisateurId,
        saisie_prix_id: saisieId,
        payload: saisie
      });

      const enregistree = await prixRepo.insert({
        id: saisieId,
        produit_id,
        marche_id,
        utilisateur_id: utilisateurId,
        valeur: montant,
        unite: unite || 'kg',
        statut: 'SYNCHRONISEE',
        source_saisie
      });

      synchronisees.push(enregistree);
    } catch (e) {
      erreurs.push({ saisie, raison: e.message });
    }
  }

  return { synchronisees, erreurs };
};

exports.getFileStats = async () => ({
  en_attente: await syncRepo.countPending()
});
