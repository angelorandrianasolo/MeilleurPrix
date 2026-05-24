'use strict';
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const FenwickTree = require('../services/algorithms/fenwick');

describe('Fenwick Tree — Agregats glissants', () => {
  it('prefixSum apres une mise a jour', () => {
    const ft = new FenwickTree(10);
    ft.update(0, 5);
    assert.equal(ft.prefixSum(0), 5);
  });

  it('rangeSum sur un intervalle', () => {
    const ft = new FenwickTree(10);
    ft.update(2, 10);
    ft.update(3, 20);
    assert.equal(ft.rangeSum(2, 3), 30);
  });

  it('rangeSum avec left > right retourne 0', () => {
    const ft = new FenwickTree(5);
    ft.update(0, 100);
    assert.equal(ft.rangeSum(3, 1), 0);
  });

  it('prefixSum jusqu a un index apres updates multiples', () => {
    const ft = new FenwickTree(5);
    ft.update(0, 1);
    ft.update(1, 2);
    ft.update(2, 3);
    ft.update(3, 4);
    ft.update(4, 5);
    assert.equal(ft.prefixSum(4), 15);
  });

  it('rangeSum(0,0) apres update(0, val)', () => {
    const ft = new FenwickTree(1);
    ft.update(0, 42);
    assert.equal(ft.rangeSum(0, 0), 42);
  });

  it('gestion des grandes valeurs', () => {
    const ft = new FenwickTree(100);
    ft.update(50, 1e9);
    assert.equal(ft.prefixSum(50), 1e9);
    assert.equal(ft.rangeSum(50, 50), 1e9);
  });

  it('prefixSum avant toute mise a jour donne 0', () => {
    const ft = new FenwickTree(10);
    assert.equal(ft.prefixSum(5), 0);
  });
});
