"""
Partie 3 : 2D Packing avec rectangles
Algorithmes : NFDH, FFDH, Best-Fit 2D + Brute Force
"""

import math

class Rectangle:
    def __init__(self, width, height, rect_id):
        self.id = rect_id
        self.width = width
        self.height = height
        self.original_width = width
        self.original_height = height
        self.placed = False
        self.x = 0
        self.y = 0
        self.rotated = False

    def area(self):
        return self.width * self.height

    def rotate(self):
        self.width, self.height = self.height, self.width
        self.rotated = not self.rotated

    def reset_rotation(self):
        self.width = self.original_width
        self.height = self.original_height
        self.rotated = False

    def __repr__(self):
        return f"Rect{self.id}({self.width}x{self.height})"


class PlacedRectangle:
    def __init__(self, rect, x, y, rotated=False):
        self.id = rect.id
        self.width = rect.width
        self.height = rect.height
        self.x = x
        self.y = y
        self.rotated = rotated

    def get_bounds(self):
        return (self.x, self.y, self.x + self.width, self.y + self.height)

    def intersects(self, other):
        x1, y1, x2, y2 = self.get_bounds()
        ox1, oy1, ox2, oy2 = other.get_bounds()
        return not (x2 <= ox1 or x1 >= ox2 or y2 <= oy1 or y1 >= oy2)

    def is_inside(self, W, H):
        return self.x >= 0 and self.y >= 0 and self.x + self.width <= W and self.y + self.height <= H


def check_overlap(placed_rects, new_rect):
    for pr in placed_rects:
        if new_rect.intersects(pr):
            return True
    return False


def nfdh(rectangles, W, H, allow_rotation=False):
    if not rectangles:
        return []
    rects = [Rectangle(r.width, r.height, r.id) for r in rectangles]
    if allow_rotation:
        for r in rects:
            if r.height > r.width and r.width <= H and r.height <= W:
                if r.height > W or r.width > H:
                    r.rotate()
    rects.sort(key=lambda r: r.height, reverse=True)
    placed = []
    current_shelf_y = 0
    current_shelf_height = 0
    current_x = 0
    for rect in rects:
        if current_x + rect.width <= W and current_shelf_y + rect.height <= H:
            pr = PlacedRectangle(rect, current_x, current_shelf_y)
            if not check_overlap(placed, pr):
                placed.append(pr)
                current_x += rect.width
                current_shelf_height = max(current_shelf_height, rect.height)
        else:
            current_shelf_y += current_shelf_height
            current_shelf_height = rect.height
            current_x = 0
            if current_shelf_y + rect.height <= H and rect.width <= W:
                pr = PlacedRectangle(rect, 0, current_shelf_y)
                placed.append(pr)
                current_x = rect.width
            else:
                break
    return placed


def ffdh(rectangles, W, H, allow_rotation=False):
    if not rectangles:
        return []
    rects = [Rectangle(r.width, r.height, r.id) for r in rectangles]
    if allow_rotation:
        for r in rects:
            if r.height > r.width:
                r.rotate()
    rects.sort(key=lambda r: r.height, reverse=True)
    placed = []
    shelves = []
    for rect in rects:
        placed_rect = None
        for i, (shelf_y, shelf_height, shelf_x) in enumerate(shelves):
            if rect.height <= shelf_height and shelf_x + rect.width <= W:
                pr = PlacedRectangle(rect, shelf_x, shelf_y)
                if not check_overlap(placed, pr):
                    placed.append(pr)
                    shelves[i] = (shelf_y, shelf_height, shelf_x + rect.width)
                    placed_rect = pr
                    break
        if placed_rect is None:
            if len(shelves) == 0:
                new_y = 0
            else:
                new_y = shelves[-1][0] + shelves[-1][1]
            if new_y + rect.height <= H and rect.width <= W:
                pr = PlacedRectangle(rect, 0, new_y)
                if not check_overlap(placed, pr):
                    placed.append(pr)
                    shelves.append((new_y, rect.height, rect.width))
    return placed


def best_fit_2d(rectangles, W, H, allow_rotation=False):
    if not rectangles:
        return []
    rects = [Rectangle(r.width, r.height, r.id) for r in rectangles]
    rects.sort(key=lambda r: r.area(), reverse=True)
    placed = []
    for rect in rects:
        best_position = None
        best_score = float("inf")
        best_rotated = False
        orientations = [(rect.width, rect.height, False)]
        if allow_rotation:
            orientations.append((rect.height, rect.width, True))
        for w, h, rotated in orientations:
            candidates = [(0, 0)]
            for pr in placed:
                candidates.append((pr.x + pr.width, pr.y))
                candidates.append((pr.x, pr.y + pr.height))
                candidates.append((pr.x + pr.width, pr.y + pr.height))
            for x, y in candidates:
                if x + w <= W and y + h <= H:
                    pr = PlacedRectangle(rect, x, y, rotated)
                    pr.width = w
                    pr.height = h
                    if not check_overlap(placed, pr):
                        score = y * W + x
                        if score < best_score:
                            best_score = score
                            best_position = (x, y, w, h, rotated)
        if best_position:
            x, y, w, h, rotated = best_position
            pr = PlacedRectangle(rect, x, y, rotated)
            pr.width = w
            pr.height = h
            placed.append(pr)
    return placed


def brute_force_2d(rectangles, W, H, allow_rotation=False):
    if not rectangles:
        return []
    n = len(rectangles)
    best_placed = []
    best_count = 0
    def backtrack(index, placed, remaining):
        nonlocal best_placed, best_count
        if len(placed) > best_count:
            best_count = len(placed)
            best_placed = [PlacedRectangle(
                Rectangle(p.width, p.height, p.id), p.x, p.y, p.rotated
            ) for p in placed]
        if index >= len(remaining):
            return
        rect = remaining[index]
        rotations = [(rect.width, rect.height, False)]
        if allow_rotation:
            rotations.append((rect.height, rect.width, True))
        for w, h, rotated in rotations:
            candidates = [(0, 0)]
            for p in placed:
                candidates.append((p.x + p.width, p.y))
                candidates.append((p.x, p.y + p.height))
            for x, y in candidates:
                if x + w <= W and y + h <= H:
                    pr = PlacedRectangle(rect, x, y, rotated)
                    pr.width = w
                    pr.height = h
                    if not check_overlap(placed, pr):
                        placed.append(pr)
                        backtrack(index + 1, placed, remaining)
                        placed.pop()
        backtrack(index + 1, placed, remaining)
    from itertools import permutations
    max_perms = min(6, n)
    perms = list(permutations(rectangles[:max_perms]))
    if len(perms) > 120:
        perms = perms[:120]
    for perm in perms:
        remaining = list(perm) + rectangles[max_perms:]
        backtrack(0, [], remaining)
    return best_placed


def calculate_utilization(placed, W, H):
    total_area = W * H
    used_area = sum(p.width * p.height for p in placed)
    return used_area / total_area if total_area > 0 else 0


if __name__ == "__main__":
    rects = [
        Rectangle(4, 3, 1), Rectangle(4, 3, 2),
        Rectangle(3, 2, 3), Rectangle(3, 2, 4),
        Rectangle(2, 2, 5)
    ]
    W, H = 10, 10
    print("=== Test 2D Packing ===")
    print(f"Conteneur : {W}x{H}")
    print(f"Rectangles : {rects}")
    placed = nfdh(rects, W, H)
    print(f"NFDH : {len(placed)}/{len(rects)} places")
    print(f"Utilisation : {calculate_utilization(placed, W, H):.2%}")
    for p in placed:
        print(f"  Rect{p.id} at ({p.x},{p.y}) size {p.width}x{p.height}")
