'use strict';

const prixService = require('../services/prixService');
const validationService = require('../services/validationService');
const alerteService = require('../services/alerteService');

exports.create = async (req, res, next) => {
  try {
    const { produit_id, marche_id, prix, valeur, unite, id } = req.body;
    const montant = parseFloat(valeur ?? prix);
    
    // 1. Valider le format
    const formatCheck = validationService.validateFormat({
      valeur: montant,
      produit_id,
      marche_id,
      unite
    });
    
    if (!formatCheck.valid) {
      return res.status(400).json({
        success: false,
        message: 'Validation échouée',
        errors: formatCheck.errors
      });
    }
    
    // 2. Détecter les aberrances
    const outlierCheck = validationService.detectOutliers(
      montant,
      req.body.categorie || 'Général'
    );
    
    if (outlierCheck.isOutlier && outlierCheck.severity === 'error') {
      return res.status(400).json({
        success: false,
        message: 'Prix aberrant détecté',
        reason: outlierCheck.reason,
        expected: outlierCheck.expected
      });
    }
    
    // Avertissement pour warning (mais on continue)
    const warning = outlierCheck.severity === 'warning' ? outlierCheck.reason : null;
    
    // 3. Enregistrer
    const result = await prixService.enregistrerPrix({
      id,
      produit_id,
      marche_id,
      utilisateur_id: req.user.id,
      valeur: montant,
      unite,
      source_saisie: req.body.source_saisie || 'WEB'
    });
    
    let alertesDeclenchees = [];
    try {
      alertesDeclenchees = await alerteService.verifierEtDeclencher({
        produit_id,
        marche_id,
        nouveau_prix: montant
      });
    } catch (_) {}

    res.status(201).json({
      success: true,
      data: result,
      message: 'Prix enregistré avec succès.',
      warning: warning || undefined,
      alertes_declenchees: alertesDeclenchees.length > 0 ? alertesDeclenchees : undefined
    });
  } catch (err) {
    next(err);
  }
};

exports.getByProduit = async (req, res, next) => {
  try {
    const { produitId } = req.params;
    const { marcheId, depuis } = req.query;
    const data = await prixService.getHistorique(produitId, marcheId || null, depuis || null);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
};
