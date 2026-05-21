'use strict';

/**
 * Fenwick Tree (Binary Indexed Tree) — requetes de somme sur intervalle O(log n).
 */
class FenwickTree {
  constructor(size) {
    this.n = size;
    this.tree = new Array(size + 1).fill(0);
  }

  update(index, delta) {
    let i = index + 1;
    while (i <= this.n) {
      this.tree[i] += delta;
      i += i & -i;
    }
  }

  prefixSum(index) {
    let sum = 0;
    let i = index + 1;
    while (i > 0) {
      sum += this.tree[i];
      i -= i & -i;
    }
    return sum;
  }

  rangeSum(left, right) {
    if (right < left) return 0;
    return this.prefixSum(right) - (left > 0 ? this.prefixSum(left - 1) : 0);
  }
}

module.exports = FenwickTree;
