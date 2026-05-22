'use strict';

const prixRepo = require('../repositories/prixRepository');

exports.optimiser = async (budget, produits) => {
  const debut = Date.now();

  const items = [];
  for (const p of produits) {
    const prix = await prixRepo.getDerniersPrixParMarche(p.id_produit);
    if (prix.length === 0) continue;

    const prixMin = Math.min(...prix.map((x) => parseFloat(x.prix)));
    const marcheMin = prix.find((x) => parseFloat(x.prix) === prixMin);

    items.push({
      id_produit: p.id_produit,
      nom: p.nom || marcheMin?.produit_nom_fr || `Produit`,
      quantite: p.quantite || 1,
      importance: p.importance || 1,
      prix_min: prixMin,
      cout: prixMin * (p.quantite || 1),
      valeur: (p.importance || 1) * 10,
      marche_id: marcheMin?.marche_id,
      marche_nom: marcheMin?.marche_nom
    });
  }

  const UNITE = 100;
  const budgetInt = Math.floor(budget / UNITE);

  const solutionNaive = items.reduce(
    (acc, item) => {
      if (acc.total + item.cout <= budget) {
        acc.items.push(item);
        acc.total += item.cout;
      }
      return acc;
    },
    { items: [], total: 0 }
  );

  const n = items.length;
  const dp = Array.from({ length: n + 1 }, () => new Array(budgetInt + 1).fill(0));

  for (let i = 1; i <= n; i++) {
    const item = items[i - 1];
    const coutInt = Math.ceil(item.cout / UNITE);

    for (let w = 0; w <= budgetInt; w++) {
      dp[i][w] = dp[i - 1][w];
      if (coutInt <= w) {
        const valAvecItem = dp[i - 1][w - coutInt] + item.valeur;
        if (valAvecItem > dp[i][w]) dp[i][w] = valAvecItem;
      }
    }
  }

  const selectionDP = [];
  let w = budgetInt;
  for (let i = n; i > 0; i--) {
    if (dp[i][w] !== dp[i - 1][w]) {
      selectionDP.push(items[i - 1]);
      w -= Math.ceil(items[i - 1].cout / UNITE);
    }
  }

  const coutDP = selectionDP.reduce((acc, item) => acc + item.cout, 0);

  return {
    solution_optimisee: {
      items: selectionDP,
      cout_total: Math.round(coutDP),
      valeur: dp[n][budgetInt],
      budget_restant: Math.round(budget - coutDP)
    },
    solution_naive: {
      items: solutionNaive.items,
      cout_total: Math.round(solutionNaive.total)
    },
    economie_realisee: Math.round(Math.max(0, solutionNaive.total - coutDP)),
    budget,
    temps_calcul_ms: Date.now() - debut
  };
};
