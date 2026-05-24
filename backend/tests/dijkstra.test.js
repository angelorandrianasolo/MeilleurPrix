'use strict';
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { construireGraphe, dijkstra } = require('../services/algorithms/dijkstra');

describe('Dijkstra + MinHeap — Comparaison inter-marches', () => {
  const marches = [
    { id: 'A' }, { id: 'B' }, { id: 'C' }, { id: 'D' }
  ];

  const liens = [
    { marche_depart_id: 'A', marche_arrivee_id: 'B', cout_transport: '5' },
    { marche_depart_id: 'A', marche_arrivee_id: 'C', cout_transport: '10' },
    { marche_depart_id: 'B', marche_arrivee_id: 'C', cout_transport: '3' },
    { marche_depart_id: 'B', marche_arrivee_id: 'D', cout_transport: '8' },
    { marche_depart_id: 'C', marche_arrivee_id: 'D', cout_transport: '2' },
  ];

  it('construit un graphe correct avec listes d adjacence', () => {
    const g = construireGraphe(marches, liens);
    assert.ok(g.has('A'));
    assert.equal(g.get('A').length, 2);
  });

  it('trouve le chemin le plus court (A -> D direct vs A->B->C->D)', () => {
    const g = construireGraphe(marches, liens);
    const dist = dijkstra(g, 'A', ['A', 'B', 'C', 'D']);
    assert.equal(dist['D'].cout, 10);
    assert.deepEqual(dist['D'].chemin, ['A', 'B', 'C', 'D']);
  });

  it('distance vers la source est 0', () => {
    const g = construireGraphe(marches, liens);
    const dist = dijkstra(g, 'B', ['A', 'B', 'C']);
    assert.equal(dist['B'].cout, 0);
  });

  it('chemin vers la source contient uniquement la source', () => {
    const g = construireGraphe(marches, liens);
    const dist = dijkstra(g, 'C', ['A', 'B', 'C']);
    assert.deepEqual(dist['C'].chemin, ['C']);
  });

  it('graphe vide retourne distances infinies', () => {
    const g = construireGraphe([{ id: 'X' }], []);
    const dist = dijkstra(g, 'X', ['X']);
    assert.equal(dist['X'].cout, 0);
  });

  it('Infinity pour noeud deconnecte', () => {
    const marchesBis = [{ id: 'A' }, { id: 'Z' }];
    const g = construireGraphe(marchesBis, []);
    const dist = dijkstra(g, 'A', ['A', 'Z']);
    assert.equal(dist['Z'].cout, Infinity);
  });

  it('fonctionne avec un seul noeud', () => {
    const g = construireGraphe([{ id: 'S' }], []);
    const dist = dijkstra(g, 'S', ['S']);
    assert.equal(dist['S'].cout, 0);
  });
});
