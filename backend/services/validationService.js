'use strict';

/**
 * Validation des saisies de prix
 * Filtrage des valeurs aberrantes, validation de format
 */

// Règles de validation globales
const RULES = {
  prix: {
    min: 0.01,
    max: 1000000,
    regex: /^\d+(\.\d{1,2})?$/
  },
  
  // Prix normaux par catégorie (pour détection d'aberrances)
  categories: {
    'Céréales': { min: 500, max: 5000 },
    'Légumes': { min: 300, max: 8000 },
    'Fruits': { min: 500, max: 6000 },
    'Viandes': { min: 2000, max: 25000 },
    'Poissons': { min: 1500, max: 15000 },
    'Produits laitiers': { min: 800, max: 10000 },
    'Épices': { min: 1000, max: 50000 },
    'Produits transformés': { min: 800, max: 15000 }
  }
};

function validateFormat(saisie) {
  const errors = [];
  
  // Prix requis et numérique
  if (!saisie.valeur || saisie.valeur <= 0) {
    errors.push('Le prix doit être positif');
  }
  
  if (!Number.isFinite(saisie.valeur)) {
    errors.push('Le prix doit être un nombre');
  }
  
  // Produit requis
  if (!saisie.produit_id) {
    errors.push('Produit requis');
  }
  
  // Marché requis
  if (!saisie.marche_id) {
    errors.push('Marché requis');
  }
  
  // Unité requise
  if (!saisie.unite) {
    errors.push('Unité requise');
  }
  
  return { valid: errors.length === 0, errors };
}

function detectOutliers(valeur, categorieNom, historique = []) {
  const categoryRules = RULES.categories[categorieNom] || { min: 100, max: 100000 };
  
  // Vérifier si dans les limites habituelles
  if (valeur < categoryRules.min) {
    return {
      isOutlier: true,
      reason: `Prix anormalement bas pour ${categorieNom} (min: ${categoryRules.min})`,
      severity: 'warning'
    };
  }
  
  if (valeur > categoryRules.max) {
    return {
      isOutlier: true,
      reason: `Prix anormalement élevé pour ${categorieNom} (max: ${categoryRules.max})`,
      severity: 'warning'
    };
  }
  
  // Comparaison avec historique (si disponible)
  if (historique.length >= 3) {
    const moyenne = historique.reduce((a, b) => a + b, 0) / historique.length;
    const deviation = Math.sqrt(
      historique.reduce((sum, x) => sum + Math.pow(x - moyenne, 2), 0) / historique.length
    );
    
    // Écart-type > 3 sigma = aberrance
    if (Math.abs(valeur - moyenne) > 3 * deviation) {
      return {
        isOutlier: true,
        reason: `Écart important par rapport à l'historique (moyenne: ${Math.round(moyenne)})`,
        severity: 'error',
        expected: moyenne
      };
    }
    
    // Avertissement pour 2 sigma
    if (Math.abs(valeur - moyenne) > 2 * deviation) {
      return {
        isOutlier: false,
        reason: `Prix différent de l'historique (moyenne: ${Math.round(moyenne)})`,
        severity: 'warning',
        expected: moyenne
      };
    }
  }
  
  return {
    isOutlier: false,
    reason: null,
    severity: 'ok'
  };
}

function interpolateData(historique) {
  if (!historique || historique.length < 2) return historique;
  
  const result = [...historique];
  
  // Trouver les trous
  for (let i = 1; i < result.length - 1; i++) {
    if (result[i] === null || result[i] === undefined || Number.isNaN(result[i])) {
      // Interpolation linéaire
      let debut = i - 1;
      let fin = i + 1;
      
      while (fin < result.length && (result[fin] === null || Number.isNaN(result[fin]))) {
        fin++;
      }
      
      if (fin < result.length && result[debut] !== null) {
        const pente = (result[fin] - result[debut]) / (fin - debut);
        for (let j = debut + 1; j < fin; j++) {
          result[j] = result[debut] + pente * (j - debut);
        }
      }
    }
  }
  
  return result;
}

module.exports = {
  validateFormat,
  detectOutliers,
  interpolateData,
  RULES
};
