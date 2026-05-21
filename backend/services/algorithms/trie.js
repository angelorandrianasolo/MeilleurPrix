'use strict';

/**
 * Trie (prefix tree) — implementation manuelle pour recherche FR/MG.
 * Chaque noeud : { children: Map, ids: Set }
 */
class TrieNode {
  constructor() {
    this.children = new Map();
    this.ids = new Set();
  }
}

class ProductTrie {
  constructor() {
    this.root = new TrieNode();
    this.products = new Map();
  }

  _normalize(text) {
    return (text || '')
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '');
  }

  insert(product) {
    const id = product.id;
    this.products.set(id, product);
    for (const field of [product.nom_fr, product.nom_mg]) {
      const key = this._normalize(field);
      let node = this.root;
      for (const ch of key) {
        if (!node.children.has(ch)) node.children.set(ch, new TrieNode());
        node = node.children.get(ch);
        node.ids.add(id);
      }
    }
  }

  search(prefix, limit = 20) {
    const key = this._normalize(prefix);
    if (key.length < 2) return [];

    let node = this.root;
    for (const ch of key) {
      if (!node.children.has(ch)) return [];
      node = node.children.get(ch);
    }

    const results = [];
    const seen = new Set();
    this._collect(node, results, seen, limit);
    return results;
  }

  _collect(node, results, seen, limit) {
    if (results.length >= limit) return;
    for (const id of node.ids) {
      if (seen.has(id) || results.length >= limit) continue;
      seen.add(id);
      const p = this.products.get(id);
      if (p) results.push(p);
    }
    for (const child of node.children.values()) {
      this._collect(child, results, seen, limit);
      if (results.length >= limit) break;
    }
  }

  clear() {
    this.root = new TrieNode();
    this.products.clear();
  }
}

module.exports = ProductTrie;
