'use strict';
const { describe, it, before } = require('node:test');
const assert = require('node:assert/strict');

describe('PanierService — Sac a dos DP', () => {
  let panierService;

  before(async () => {
    panierService = require('../services/panierService');
  });

  it('exporte la fonction optimiser', () => {
    assert.equal(typeof panierService.optimiser, 'function');
  });
});
