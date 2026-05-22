'use strict';

const prixRepo = require('../repositories/prixRepository');

const FENETRE_PAR_DEFAUT = 7;

exports.calculer = async (produitId, marcheId = null, joursPrevu = 30) => {
  const historique = await prixRepo.findHistorique(produitId, marcheId);

  if (historique.length < 3) {
    return {
      message: 'Donnees insuffisantes pour calculer une prevision.',
      historique: []
    };
  }

  const serie = historique.map((h) => ({
    date: h.date_jour,
    valeur: parseFloat(h.prix_moyen)
  }));

  const valeurs = serie.map((s) => s.valeur);
  const valeursClean = interpolerManquants(valeurs);

  const prevSimple = moyenneSimple(valeursClean, joursPrevu);
  const prevDP = moyenneMobileDP(valeursClean, joursPrevu, FENETRE_PAR_DEFAUT);

  const dernierDate = new Date(serie[serie.length - 1].date);
  const datesFutures = [];
  for (let i = 1; i <= joursPrevu; i++) {
    const d = new Date(dernierDate);
    d.setDate(d.getDate() + i);
    datesFutures.push(d.toISOString().split('T')[0]);
  }

  return {
    historique: serie,
    dates_futures: datesFutures,
    prevision_simple: prevSimple,
    prevision_optimisee: prevDP,
    comparaison: {
      erreur_simple: evaluerErreur(valeursClean, FENETRE_PAR_DEFAUT, 'simple'),
      erreur_optimisee: evaluerErreur(valeursClean, FENETRE_PAR_DEFAUT, 'dp'),
      methode_recommandee: 'optimisee'
    }
  };
};

function moyenneSimple(valeurs, nbJours) {
  const moyenne = valeurs.reduce((a, b) => a + b, 0) / valeurs.length;
  return Array(nbJours).fill(Math.round(moyenne));
}

function moyenneMobileDP(valeurs, nbJours, fenetre) {
  const n = valeurs.length;
  if (n < fenetre) return moyenneSimple(valeurs, nbJours);

  const poids = Array.from({ length: fenetre }, (_, k) => k + 1);
  const somPoids = poids.reduce((a, b) => a + b, 0);

  let serie = [...valeurs];
  const previsions = [];

  for (let j = 0; j < nbJours; j++) {
    const fenData = serie.slice(serie.length - fenetre);
    let mmp = 0;
    for (let k = 0; k < fenetre; k++) {
      mmp += fenData[k] * poids[k];
    }
    mmp = Math.round(mmp / somPoids);
    previsions.push(mmp);
    serie.push(mmp);
  }

  return previsions;
}

function interpolerManquants(valeurs) {
  const res = [...valeurs];
  for (let i = 1; i < res.length - 1; i++) {
    if (res[i] === null || res[i] === undefined || Number.isNaN(res[i])) {
      let debut = i - 1;
      let fin = i + 1;
      while (fin < res.length && (res[fin] === null || Number.isNaN(res[fin]))) fin++;
      if (fin < res.length) {
        res[i] = res[debut] + ((res[fin] - res[debut]) * (i - debut)) / (fin - debut);
      }
    }
  }
  return res;
}

function evaluerErreur(valeurs, fenetre, methode) {
  if (valeurs.length < fenetre + 2) return null;
  const testSize = Math.min(5, Math.floor(valeurs.length * 0.2));
  const train = valeurs.slice(0, valeurs.length - testSize);
  const test = valeurs.slice(valeurs.length - testSize);

  const previsions =
    methode === 'simple'
      ? moyenneSimple(train, testSize)
      : moyenneMobileDP(train, testSize, fenetre);

  const mae = previsions.reduce((acc, p, i) => acc + Math.abs(p - test[i]), 0) / testSize;
  return Math.round(mae);
}
