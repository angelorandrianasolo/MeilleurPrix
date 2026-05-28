"""
Partie 4 : 2D Packing avec 3 formes
- Cercle (rayon)
- Rectangle (largeur, hauteur)
- Triangle isocèle (base, hauteur)
Rotations autorisées : pi/2 et pi
"""

import math

class Shape:
    """Classe de base pour toutes les formes"""
    def __init__(self, shape_id):
        self.id = shape_id
        self.shape_type = "unknown"
        self.placed = False
        self.x = 0
        self.y = 0
        self.rotation = 0  # 0, 90, 180, 270 degrés

    def get_bounds(self):
        """Retourne (x1, y1, x2, y2) - bounding box"""
        raise NotImplementedError

    def area(self):
        raise NotImplementedError

    def rotate(self, angle_degrees):
        """Rotation de l'angle spécifié (90 ou 180 degrés)"""
        self.rotation = (self.rotation + angle_degrees) % 360

    def intersects(self, other):
        """Vérifie si cette forme intersecte une autre"""
        # Vérification par bounding box d'abord
        x1, y1, x2, y2 = self.get_bounds()
        ox1, oy1, ox2, oy2 = other.get_bounds()

        if x2 <= ox1 or x1 >= ox2 or y2 <= oy1 or y1 >= oy2:
            return False

        # Vérification plus fine selon le type
        return self._fine_intersects(other)

    def _fine_intersects(self, other):
        """Vérification fine d'intersection (à surcharger)"""
        # Par défaut, utiliser la bounding box
        return True

    def is_inside(self, W, H):
        """Vérifie si la forme est entièrement dans le conteneur"""
        x1, y1, x2, y2 = self.get_bounds()
        return x1 >= 0 and y1 >= 0 and x2 <= W and y2 <= H


class Circle(Shape):
    """Cercle défini par son rayon"""
    def __init__(self, radius, shape_id):
        super().__init__(shape_id)
        self.shape_type = "circle"
        self.radius = radius

    def get_bounds(self):
        return (self.x - self.radius, self.y - self.radius,
                self.x + self.radius, self.y + self.radius)

    def area(self):
        return math.pi * self.radius ** 2

    def _fine_intersects(self, other):
        if other.shape_type == "circle":
            dx = self.x - other.x
            dy = self.y - other.y
            distance = math.sqrt(dx**2 + dy**2)
            return distance < (self.radius + other.radius)
        else:
            # Pour rectangle et triangle, utiliser approximation par bounding box
            return True

    def __repr__(self):
        return f"Circle{self.id}(r={self.radius})"


class RectShape(Shape):
    """Rectangle défini par sa largeur et hauteur"""
    def __init__(self, width, height, shape_id):
        super().__init__(shape_id)
        self.shape_type = "rectangle"
        self.width = width
        self.height = height
        self.original_width = width
        self.original_height = height

    def get_bounds(self):
        # Selon la rotation
        if self.rotation % 180 == 90:
            w, h = self.height, self.width
        else:
            w, h = self.width, self.height
        return (self.x, self.y, self.x + w, self.y + h)

    def area(self):
        return self.width * self.height

    def rotate(self, angle_degrees):
        super().rotate(angle_degrees)
        if angle_degrees % 180 == 90:
            self.width, self.height = self.height, self.width

    def _fine_intersects(self, other):
        if other.shape_type == "rectangle":
            x1, y1, x2, y2 = self.get_bounds()
            ox1, oy1, ox2, oy2 = other.get_bounds()
            return not (x2 <= ox1 or x1 >= ox2 or y2 <= oy1 or y1 >= oy2)
        return True

    def __repr__(self):
        return f"Rect{self.id}({self.width}x{self.height})"


class IsoscelesTriangle(Shape):
    """Triangle isocèle défini par sa base"""
    def __init__(self, base, height, shape_id):
        super().__init__(shape_id)
        self.shape_type = "triangle"
        self.base = base
        self.tri_height = height
        self.original_base = base
        self.original_height = height

    def get_bounds(self):
        # Le triangle est représenté par sa bounding box
        if self.rotation % 180 == 90:
            b, h = self.tri_height, self.base
        else:
            b, h = self.base, self.tri_height
        return (self.x, self.y, self.x + b, self.y + h)

    def area(self):
        return 0.5 * self.base * self.tri_height

    def rotate(self, angle_degrees):
        super().rotate(angle_degrees)
        if angle_degrees % 180 == 90:
            self.base, self.tri_height = self.tri_height, self.base

    def get_vertices(self):
        """Retourne les 3 sommets du triangle"""
        if self.rotation % 180 == 90:
            b, h = self.tri_height, self.base
        else:
            b, h = self.base, self.tri_height

        if self.rotation == 0:
            # Base en bas, pointe en haut
            return [
                (self.x, self.y + h),
                (self.x + b/2, self.y),
                (self.x + b, self.y + h)
            ]
        elif self.rotation == 90:
            return [
                (self.x, self.y),
                (self.x + b, self.y + h/2),
                (self.x, self.y + h)
            ]
        elif self.rotation == 180:
            return [
                (self.x, self.y),
                (self.x + b/2, self.y + h),
                (self.x + b, self.y)
            ]
        else:  # 270
            return [
                (self.x + b, self.y),
                (self.x, self.y + h/2),
                (self.x + b, self.y + h)
            ]

    def _fine_intersects(self, other):
        # Simplification : utiliser bounding box
        return True

    def __repr__(self):
        return f"Tri{self.id}(base={self.base},h={self.tri_height})"


def check_overlap_3shapes(placed_shapes, new_shape):
    """Vérifie si new_shape chevauche une forme déjà placée"""
    for ps in placed_shapes:
        if new_shape.intersects(ps):
            return True
    return False


def heuristic_3shapes(shapes, W, H, allow_rotation=False):
    """
    Algorithme heuristique pour 3 formes.

    Stratégie :
    1. Trier par aire décroissante
    2. Pour chaque forme, essayer différentes positions et rotations
    3. Choisir la position qui minimise l'espace perdu
    """
    if not shapes:
        return []

    # Créer des copies
    shape_copies = []
    for s in shapes:
        if s.shape_type == "circle":
            shape_copies.append(Circle(s.radius, s.id))
        elif s.shape_type == "rectangle":
            shape_copies.append(RectShape(s.width, s.height, s.id))
        elif s.shape_type == "triangle":
            shape_copies.append(IsoscelesTriangle(s.base, s.tri_height, s.id))

    # Trier par aire décroissante
    shape_copies.sort(key=lambda s: s.area(), reverse=True)

    placed = []

    for shape in shape_copies:
        best_position = None
        best_score = float('inf')
        best_rotation = 0

        # Orientations possibles
        rotations = [0]
        if allow_rotation:
            rotations = [0, 90, 180, 270]

        for rot in rotations:
            # Créer une copie avec la rotation
            test_shape = None
            if shape.shape_type == "circle":
                test_shape = Circle(shape.radius, shape.id)
            elif shape.shape_type == "rectangle":
                test_shape = RectShape(shape.original_width, shape.original_height, shape.id)
                test_shape.rotate(rot)
            elif shape.shape_type == "triangle":
                test_shape = IsoscelesTriangle(shape.original_base, shape.original_height, shape.id)
                test_shape.rotate(rot)

            # Générer des positions candidates
            candidates = [(0, 0)]
            for ps in placed:
                x1, y1, x2, y2 = ps.get_bounds()
                candidates.append((x2, y1))
                candidates.append((x1, y2))
                candidates.append((x2, y2))

            for x, y in candidates:
                test_shape.x = x
                test_shape.y = y

                if test_shape.is_inside(W, H) and not check_overlap_3shapes(placed, test_shape):
                    score = y * W + x  # privilégier le bas
                    if score < best_score:
                        best_score = score
                        best_position = (x, y)
                        best_rotation = rot

        if best_position:
            shape.x = best_position[0]
            shape.y = best_position[1]
            if shape.shape_type != "circle":
                shape.rotation = best_rotation
                if best_rotation % 180 == 90:
                    if shape.shape_type == "rectangle":
                        shape.width, shape.height = shape.height, shape.width
                    elif shape.shape_type == "triangle":
                        shape.base, shape.tri_height = shape.tri_height, shape.base
            placed.append(shape)

    return placed


def brute_force_3shapes(shapes, W, H, allow_rotation=False):
    """
    Brute force pour 3 formes avec backtracking.
    """
    if not shapes:
        return []

    n = len(shapes)
    best_placed = []
    best_count = 0

    def backtrack(index, placed, remaining):
        nonlocal best_placed, best_count

        if len(placed) > best_count:
            best_count = len(placed)
            best_placed = placed.copy()

        if index >= len(remaining):
            return

        shape = remaining[index]

        # Orientations possibles
        rotations = [0]
        if allow_rotation and shape.shape_type != "circle":
            rotations = [0, 90, 180, 270]

        for rot in rotations:
            test_shape = None
            if shape.shape_type == "circle":
                test_shape = Circle(shape.radius, shape.id)
            elif shape.shape_type == "rectangle":
                test_shape = RectShape(shape.original_width, shape.original_height, shape.id)
                test_shape.rotate(rot)
            elif shape.shape_type == "triangle":
                test_shape = IsoscelesTriangle(shape.original_base, shape.original_height, shape.id)
                test_shape.rotate(rot)

            candidates = [(0, 0)]
            for ps in placed:
                x1, y1, x2, y2 = ps.get_bounds()
                candidates.append((x2, y1))
                candidates.append((x1, y2))
                candidates.append((x2, y2))

            for x, y in candidates:
                test_shape.x = x
                test_shape.y = y

                if test_shape.is_inside(W, H) and not check_overlap_3shapes(placed, test_shape):
                    placed.append(test_shape)
                    backtrack(index + 1, placed, remaining)
                    placed.pop()

        # Ne pas placer cette forme
        backtrack(index + 1, placed, remaining)

    # Limiter les permutations pour la performance
    from itertools import permutations
    max_perms = min(5, n)
    perms = list(permutations(shapes[:max_perms]))
    if len(perms) > 60:
        perms = perms[:60]

    for perm in perms:
        remaining = list(perm) + shapes[max_perms:]
        backtrack(0, [], remaining)

    return best_placed


def calculate_utilization_3shapes(placed, W, H):
    """Calcule le taux d'utilisation"""
    total_area = W * H
    used_area = sum(p.area() for p in placed)
    return used_area / total_area if total_area > 0 else 0


if __name__ == "__main__":
    # Test
    shapes = [
        Circle(2, 1),
        RectShape(4, 3, 2),
        IsoscelesTriangle(4, 3, 3),
        Circle(1.5, 4),
        RectShape(3, 2, 5)
    ]
    W, H = 15, 15

    print("=== Test 3 Shapes Packing ===")
    placed = heuristic_3shapes(shapes, W, H, allow_rotation=True)
    print(f"Placés : {len(placed)}/{len(shapes)}")
    print(f"Utilisation : {calculate_utilization_3shapes(placed, W, H):.2%}")
    for p in placed:
        print(f"  {p} at ({p.x:.1f},{p.y:.1f})")
