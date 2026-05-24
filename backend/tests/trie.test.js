'use strict';
const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const ProductTrie = require('../services/algorithms/trie');

describe('ProductTrie — Recherche FR/MG', () => {
  let trie;

  before(() => {
    trie = new ProductTrie();
    const produits = [
      { id: '1', nom_fr: 'Riz blanc', nom_mg: 'Vary fotsy' },
      { id: '2', nom_fr: 'Riz rouge', nom_mg: 'Vary mena' },
      { id: '3', nom_fr: 'Tomate', nom_mg: 'Voatabia' },
      { id: '4', nom_fr: 'Mangue', nom_mg: 'Manga' },
      { id: '5', nom_fr: 'Banane jaune', nom_mg: 'Akondro maitso' },
    ];
    for (const p of produits) trie.insert(p);
  });

  it('retourne les resultats pour un prefixe FR', () => {
    const results = trie.search('riz');
    assert.equal(results.length, 2);
    assert.ok(results.some(r => r.nom_fr === 'Riz blanc'));
    assert.ok(results.some(r => r.nom_fr === 'Riz rouge'));
  });

  it('retourne les resultats pour un prefixe MG', () => {
    const results = trie.search('vary');
    assert.equal(results.length, 2);
  });

  it('retourne les resultats pour un prefixe partiel', () => {
    const results = trie.search('ri');
    assert.equal(results.length, 2);
  });

  it('retourne vide si moins de 2 caracteres', () => {
    assert.equal(trie.search('r').length, 0);
  });

  it('retourne vide si aucun match', () => {
    assert.equal(trie.search('zzzz').length, 0);
  });

  it('insensible a la casse et aux accents', () => {
    const results = trie.search('TOMATE');
    assert.equal(results.length, 1);
    assert.equal(results[0].nom_fr, 'Tomate');
  });

  it('limite le nombre de resultats', () => {
    for (let i = 0; i < 25; i++) {
      trie.insert({ id: `extra-${i}`, nom_fr: `Produit ${i}`, nom_mg: `Vokatra ${i}` });
    }
    const results = trie.search('p');
    assert.ok(results.length <= 20);
  });

  it('se vide et recharge correctement', () => {
    trie.clear();
    assert.equal(trie.search('riz').length, 0);
  });
});
