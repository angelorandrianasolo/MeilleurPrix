'use strict';

const dashboardRepo = require('../repositories/dashboardRepository');
const FenwickTree = require('./algorithms/fenwick');

exports.getDashboard = async () => {
  const [stats, topProduits, topMarches, tendance, categories] = await Promise.all([
    dashboardRepo.getStats(),
    dashboardRepo.getTopProduits(5),
    dashboardRepo.getTopMarches(5),
    dashboardRepo.getTendance30j(),
    dashboardRepo.getRepartitionCategories()
  ]);

  const fenwick = new FenwickTree(tendance.length);
  tendance.forEach((t, i) => fenwick.update(i, parseFloat(t.prix_moyen_global) || 0));

  const tendanceAvecCumul = tendance.map((t, i) => ({
    ...t,
    cumul_fenwick: Math.round(fenwick.prefixSum(i))
  }));

  return {
    statistiques: stats,
    top_produits: topProduits,
    top_marches: topMarches,
    tendance_30j: tendanceAvecCumul,
    repartition_categories: categories
  };
};
