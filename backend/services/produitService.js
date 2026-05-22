'use strict';

const produitRepo = require('../repositories/produitRepository');
const ProductTrie = require('./algorithms/trie');

const trie = new ProductTrie();
let trieLoaded = false;
let trieLoadedAt = 0;
const TRIE_TTL_MS = 5 * 60 * 1000;

async function ensureTrie() {
  const now = Date.now();
  if (trieLoaded && now - trieLoadedAt < TRIE_TTL_MS) return;

  const produits = await produitRepo.findAllForTrie();
  trie.clear();
  for (const p of produits) trie.insert(p);
  trieLoaded = true;
  trieLoadedAt = now;
}

exports.rechercher = async (query) => {
  if (!query || query.trim().length < 2) return [];
  await ensureTrie();
  return trie.search(query.trim(), 20);
};

exports.getAll = async (categorieId) => produitRepo.findAll(categorieId);

exports.getById = async (id) => produitRepo.findById(id);

exports.getCategories = async () => produitRepo.findCategories();

exports.refreshIndex = async () => {
  trieLoaded = false;
  await ensureTrie();
};
