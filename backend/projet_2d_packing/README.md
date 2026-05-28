# Projet 2D Packing

Projet algorithmique de placement bidimensionnel (2D Packing).

## Structure

- `main.py` - Point d'entree
- `gui.py` - Interface graphique Tkinter
- `packing_1d.py` - Algorithmes 1D (FF, BF, WF, Brute Force)
- `packing_2d.py` - Algorithmes 2D (NFDH, FFDH, Best-Fit, Brute Force)
- `packing_3shapes.py` - Algorithmes 3 formes (heuristique + brute force)

## Lancement

```bash
python main.py
```

## Fonctionnalites

### Onglet 1D Packing
- Saisie de la capacite et des objets
- Execution de FF, BF, WF
- Brute force pour trouver l'optimal
- Comparaison de tous les algorithmes
- Contre-exemples predefinis

### Onglet 2D Packing (Rectangles)
- Saisie du conteneur et des rectangles
- NFDH, FFDH, Best-Fit 2D
- Brute force avec rotation pi/2
- Visualisation graphique
- Generation aleatoire

### Onglet 3 Formes
- Cercles, rectangles, triangles isoceles
- Heuristique de placement
- Brute force
- Rotations pi/2 et pi
- Visualisation graphique

## Regles respectees
- Aucune librairie externe pour les algorithmes
- Interface graphique pour saisie et resultats
- Brute force implemente
- Rotations supportees
