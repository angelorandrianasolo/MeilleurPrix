'use strict';

const marcheRepo = require('../repositories/marcheRepository');
const prixRepo = require('../repositories/prixRepository');
const { construireGraphe, dijkstra } = require('./algorithms/dijkstra');

exports.getAll = async () => marcheRepo.findAll();

exports.getById = async (id) => marcheRepo.findById(id);

exports.trouverMeilleureOption = async (departId, produitId) => {
  const debut = Date.now();

  const marches = await marcheRepo.findAll();
  const liens = await marcheRepo.findLiens();
  const prixDispo = await prixRepo.getDerniersPrixParMarche(produitId);

  const graphe = construireGraphe(marches, liens);

  const prixParMarche = {};
  for (const p of prixDispo) {
    prixParMarche[p.marche_id] = parseFloat(p.prix);
  }

  const distances = dijkstra(graphe, departId, marches.map((m) => m.id));

  let meilleurMarche = null;
  let meilleurCoutTotal = Infinity;
  let meilleurChemin = [];

  for (const marche of marches) {
    if (prixParMarche[marche.id] === undefined) continue;
    const transportCost = distances[marche.id]?.cout ?? Infinity;
    if (transportCost === Infinity) continue;

    const coutTotal = transportCost + prixParMarche[marche.id];
    if (coutTotal < meilleurCoutTotal) {
      meilleurCoutTotal = coutTotal;
      meilleurMarche = marche;
      meilleurChemin = distances[marche.id]?.chemin ?? [];
    }
  }

  const comparatif = marches
    .filter((m) => prixParMarche[m.id] !== undefined && distances[m.id]?.cout !== Infinity)
    .map((m) => ({
      marche: m,
      prix_produit: prixParMarche[m.id],
      cout_transport: distances[m.id]?.cout ?? 0,
      cout_total: (distances[m.id]?.cout ?? 0) + prixParMarche[m.id],
      chemin: distances[m.id]?.chemin ?? []
    }))
    .sort((a, b) => a.cout_total - b.cout_total);

  return {
    marche_optimal: meilleurMarche,
    cout_total: meilleurCoutTotal === Infinity ? null : meilleurCoutTotal,
    prix_produit: meilleurMarche ? prixParMarche[meilleurMarche.id] : null,
    cout_transport: meilleurMarche
      ? meilleurCoutTotal - prixParMarche[meilleurMarche.id]
      : null,
    chemin: meilleurChemin,
    comparatif,
    temps_calcul_ms: Date.now() - debut
  };
};
