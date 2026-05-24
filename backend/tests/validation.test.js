'use strict';
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { validateFormat, detectOutliers, interpolateData } = require('../services/validationService');

describe('ValidationService — Validation des saisies', () => {
  describe('validateFormat', () => {
    it('valide une saisie correcte', () => {
      const r = validateFormat({ valeur: 1500, produit_id: 'uuid', marche_id: 'uuid', unite: 'kg' });
      assert.ok(r.valid);
      assert.equal(r.errors.length, 0);
    });

    it('rejette prix <= 0', () => {
      const r = validateFormat({ valeur: -5, produit_id: 'uuid', marche_id: 'uuid', unite: 'kg' });
      assert.ok(!r.valid);
    });

    it('rejette si produit_id manquant', () => {
      const r = validateFormat({ valeur: 100, marche_id: 'uuid', unite: 'kg' });
      assert.ok(!r.valid);
    });

    it('rejette si marche_id manquant', () => {
      const r = validateFormat({ valeur: 100, produit_id: 'uuid', unite: 'kg' });
      assert.ok(!r.valid);
    });

    it('rejette si unite manquante', () => {
      const r = validateFormat({ valeur: 100, produit_id: 'uuid', marche_id: 'uuid' });
      assert.ok(!r.valid);
    });

    it('rejette valeur non numerique', () => {
      const r = validateFormat({ valeur: NaN, produit_id: 'uuid', marche_id: 'uuid', unite: 'kg' });
      assert.ok(!r.valid);
    });

    it('accepte valeur = 0.01 (minimum valide)', () => {
      const r = validateFormat({ valeur: 0.01, produit_id: 'uuid', marche_id: 'uuid', unite: 'kg' });
      assert.ok(r.valid);
    });
  });

  describe('detectOutliers', () => {
    it('detecte un prix anormalement bas pour les cereales', () => {
      const r = detectOutliers(50, 'Céréales');
      assert.ok(r.isOutlier);
      assert.equal(r.severity, 'warning');
    });

    it('detecte un prix anormalement eleve pour les legumes', () => {
      const r = detectOutliers(50000, 'Légumes');
      assert.ok(r.isOutlier);
    });

    it('accepte un prix normal', () => {
      const r = detectOutliers(2000, 'Céréales');
      assert.ok(!r.isOutlier);
    });

    it('detecte aberration 3-sigma (hors categorie → warning)', () => {
      const r = detectOutliers(99999, 'Céréales', [2000, 2100, 1900, 2050, 1950]);
      assert.ok(r.isOutlier);
      assert.equal(r.severity, 'warning');
    });

    it('detecte aberration 3-sigma dans les limites categorie', () => {
      const r = detectOutliers(2500, 'Céréales', [2000, 2100, 1900, 2050, 1950]);
      assert.ok(r.isOutlier);
      assert.equal(r.severity, 'error');
    });

    it('emet un warning pour 2-sigma', () => {
      const r = detectOutliers(2150, 'Céréales', [2000, 2100, 1900, 2050, 1950]);
      assert.ok(!r.isOutlier);
      assert.equal(r.severity, 'warning');
    });
  });

  describe('interpolateData', () => {
    it('interpole les valeurs manquantes lineairement', () => {
      const r = interpolateData([10, null, null, 40]);
      assert.equal(r[1], 20);
      assert.equal(r[2], 30);
    });

    it('retourne inchangé si pas de trous', () => {
      const r = interpolateData([10, 20, 30]);
      assert.deepEqual(r, [10, 20, 30]);
    });

    it('retourne vide si tableau vide', () => {
      assert.deepEqual(interpolateData([]), []);
    });

    it('retourne inchangé si < 2 elements', () => {
      assert.deepEqual(interpolateData([10]), [10]);
    });

    it('ignore les trous en debut/fin (pas d interpolation possible)', () => {
      const r = interpolateData([null, 10, 20, null]);
      assert.equal(r[0], null);
      assert.equal(r[1], 10);
      assert.equal(r[2], 20);
      assert.equal(r[3], null);
    });
  });
});
