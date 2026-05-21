'use strict';

class MinHeap {
  constructor() { this.data = []; }

  push(item) {
    this.data.push(item);
    this._bubbleUp(this.data.length - 1);
  }

  pop() {
    const top = this.data[0];
    const last = this.data.pop();
    if (this.data.length > 0) {
      this.data[0] = last;
      this._sinkDown(0);
    }
    return top;
  }

  isEmpty() { return this.data.length === 0; }

  _bubbleUp(i) {
    while (i > 0) {
      const parent = Math.floor((i - 1) / 2);
      if (this.data[parent][0] <= this.data[i][0]) break;
      [this.data[parent], this.data[i]] = [this.data[i], this.data[parent]];
      i = parent;
    }
  }

  _sinkDown(i) {
    const n = this.data.length;
    while (true) {
      let min = i;
      const l = 2 * i + 1;
      const r = 2 * i + 2;
      if (l < n && this.data[l][0] < this.data[min][0]) min = l;
      if (r < n && this.data[r][0] < this.data[min][0]) min = r;
      if (min === i) break;
      [this.data[min], this.data[i]] = [this.data[i], this.data[min]];
      i = min;
    }
  }
}

function construireGraphe(marches, liens) {
  const graphe = new Map();
  for (const m of marches) graphe.set(m.id, []);

  for (const lien of liens) {
    const poids = parseFloat(lien.cout_transport);
    if (graphe.has(lien.marche_depart_id)) {
      graphe.get(lien.marche_depart_id).push({
        dest: lien.marche_arrivee_id,
        poids
      });
    }
  }
  return graphe;
}

function dijkstra(graphe, source, noeuds) {
  const distances = {};
  for (const id of noeuds) {
    distances[id] = { cout: Infinity, chemin: [] };
  }
  distances[source] = { cout: 0, chemin: [source] };

  const heap = new MinHeap();
  heap.push([0, source]);

  while (!heap.isEmpty()) {
    const [cout, u] = heap.pop();
    if (cout > distances[u].cout) continue;

    for (const { dest, poids } of graphe.get(u) || []) {
      if (!distances[dest]) {
        distances[dest] = { cout: Infinity, chemin: [] };
      }
      const nouveauCout = distances[u].cout + poids;
      if (nouveauCout < distances[dest].cout) {
        distances[dest].cout = nouveauCout;
        distances[dest].chemin = [...distances[u].chemin, dest];
        heap.push([nouveauCout, dest]);
      }
    }
  }

  return distances;
}

module.exports = { construireGraphe, dijkstra };
