"""
Partie 2 : 1D Packing
Algorithmes : First-Fit, Best-Fit, Worst-Fit + Brute Force
"""

class Bin1D:
    def __init__(self, capacity, bin_id):
        self.id = bin_id
        self.capacity = capacity
        self.items = []
        self.remaining = capacity

    def can_fit(self, size):
        return self.remaining >= size

    def add_item(self, size):
        if self.can_fit(size):
            self.items.append(size)
            self.remaining -= size
            return True
        return False

    def __repr__(self):
        return f"Bin{self.id}(items={self.items}, remaining={self.remaining})"


def first_fit(items, bin_capacity):
    bins = []
    bin_counter = 1
    for size in items:
        placed = False
        for b in bins:
            if b.can_fit(size):
                b.add_item(size)
                placed = True
                break
        if not placed:
            new_bin = Bin1D(bin_capacity, bin_counter)
            new_bin.add_item(size)
            bins.append(new_bin)
            bin_counter += 1
    return bins


def best_fit(items, bin_capacity):
    bins = []
    bin_counter = 1
    for size in items:
        best_bin = None
        min_remaining = float("inf")
        for b in bins:
            if b.can_fit(size):
                remaining_after = b.remaining - size
                if remaining_after < min_remaining:
                    min_remaining = remaining_after
                    best_bin = b
        if best_bin is not None:
            best_bin.add_item(size)
        else:
            new_bin = Bin1D(bin_capacity, bin_counter)
            new_bin.add_item(size)
            bins.append(new_bin)
            bin_counter += 1
    return bins


def worst_fit(items, bin_capacity):
    bins = []
    bin_counter = 1
    for size in items:
        worst_bin = None
        max_remaining = -1
        for b in bins:
            if b.can_fit(size):
                remaining_after = b.remaining - size
                if remaining_after > max_remaining:
                    max_remaining = remaining_after
                    worst_bin = b
        if worst_bin is not None:
            worst_bin.add_item(size)
        else:
            new_bin = Bin1D(bin_capacity, bin_counter)
            new_bin.add_item(size)
            bins.append(new_bin)
            bin_counter += 1
    return bins


def brute_force_1d(items, bin_capacity):
    n = len(items)
    if n == 0:
        return []
    best_solution = None
    best_num_bins = float("inf")
    def backtrack(index, bins):
        nonlocal best_solution, best_num_bins
        if len(bins) >= best_num_bins:
            return
        if index == n:
            if len(bins) < best_num_bins:
                best_num_bins = len(bins)
                best_solution = [Bin1D(bin_capacity, i+1) for i in range(len(bins))]
                for i, b in enumerate(bins):
                    best_solution[i].items = b.items.copy()
                    best_solution[i].remaining = b.remaining
            return
        size = items[index]
        for i, b in enumerate(bins):
            if b.can_fit(size):
                b.add_item(size)
                backtrack(index + 1, bins)
                b.items.pop()
                b.remaining += size
        new_bin = Bin1D(bin_capacity, len(bins) + 1)
        new_bin.add_item(size)
        bins.append(new_bin)
        backtrack(index + 1, bins)
        bins.pop()
    backtrack(0, [])
    return best_solution


def get_counterexample_ff():
    return {
        "name": "First-Fit non optimal",
        "capacity": 10,
        "items": [6, 6, 3, 3, 3, 3, 2, 2],
        "optimal_bins": 3,
        "description": "FF utilise 4 bacs au lieu de 3"
    }


def get_counterexample_bf():
    return {
        "name": "Best-Fit non optimal",
        "capacity": 10,
        "items": [5, 7, 5, 4, 2, 2],
        "optimal_bins": 3,
        "description": "BF utilise 4 bacs au lieu de 3"
    }


def get_counterexample_wf():
    return {
        "name": "Worst-Fit non optimal",
        "capacity": 10,
        "items": [6, 6, 4, 4, 4, 4],
        "optimal_bins": 3,
        "description": "WF utilise 4 bacs au lieu de 3"
    }


if __name__ == "__main__":
    items = [6, 6, 3, 3, 3, 3, 2, 2]
    capacity = 10
    print("=== Test 1D Packing ===")
    print(f"Objets : {items}")
    print(f"Capacite : {capacity}")
    ff_bins = first_fit(items, capacity)
    print(f"First-Fit : {len(ff_bins)} bacs")
    for b in ff_bins:
        print(f"  {b}")
    bf_bins = best_fit(items, capacity)
    print(f"Best-Fit : {len(bf_bins)} bacs")
    for b in bf_bins:
        print(f"  {b}")
    wf_bins = worst_fit(items, capacity)
    print(f"Worst-Fit : {len(wf_bins)} bacs")
    for b in wf_bins:
        print(f"  {b}")
    print("=== Brute Force ===")
    opt = brute_force_1d(items, capacity)
    print(f"Optimal : {len(opt)} bacs")
    for b in opt:
        print(f"  {b}")