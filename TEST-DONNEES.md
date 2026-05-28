# Donnees de test — Application mobile (telephone)

## 1. Charger les donnees dans PostgreSQL

```powershell
cd c:\Users\PC\meilleur_prix
psql -U postgres -d meilleur_prix_db -f database\schema.sql
psql -U postgres -d meilleur_prix_db -f database\test-data-phone.sql
cd backend
node scripts\init-admin.js admin123
```

## 2. Configurer le telephone

Dans `frontend-mobile\.env` (remplacez par l'IP de votre PC sur le Wi-Fi) :

```
EXPO_PUBLIC_API_URL=http://192.168.X.X:3000/api/v1
```

Trouver votre IP : `ipconfig` → adresse IPv4 (ex. `192.168.1.25`).

Le backend doit tourner : `cd backend` puis `npm start`.

---

## 3. Comptes de connexion

| Role | Email | Mot de passe |
|------|-------|--------------|
| Administrateur | `admin@meilleurprix.mg` | `admin123` (apres `init-admin.js`) |
| Acheteur | `acheteur@test.mg` | `test123` |
| Vendeur | `vendeur@test.mg` | `test123` |
| Collecteur | `collecteur@test.mg` | `test123` |

**Ou** creez un compte depuis l'app : **Creer un compte** → role Acheteur / Vendeur / Collecteur.

---

## 4. Produits (recherche : tapez 2 lettres)

| Nom FR | Nom MG | Unite | UUID (si besoin manuel) |
|--------|--------|-------|-------------------------|
| Riz | Vary | kg | `b2000001-0000-4000-8000-000000000001` |
| Mais | Katsaka | kg | `b2000001-0000-4000-8000-000000000002` |
| Tomate | Voatabia | kg | `b2000001-0000-4000-8000-000000000003` |
| Oignon | An tonga | kg | `b2000001-0000-4000-8000-000000000004` |
| Banane | Akondro | kg | `b2000001-0000-4000-8000-000000000005` |
| Mangue | Manga | kg | `b2000001-0000-4000-8000-000000000006` |

**Test recherche :** tapez `ri`, `va`, `tom`, `ako` → suggestions instantanees.

---

## 5. Marches

| Marché | Ville | UUID |
|--------|-------|------|
| Analakely | Antananarivo | `c3000001-0000-4000-8000-000000000001` |
| Anosibe | Antananarivo | `c3000001-0000-4000-8000-000000000002` |
| Andravoahangy | Antananarivo | `c3000001-0000-4000-8000-000000000003` |
| Isotry | Antananarivo | `c3000001-0000-4000-8000-000000000004` |
| Bazar Kely | Toamasina | `c3000001-0000-4000-8000-000000000005` |

---

## 6. Prix deja en base (apres test-data-phone.sql)

| Produit | Marché | Prix (Ar) |
|---------|--------|-----------|
| Riz | Analakely | 3 200 |
| Riz | Anosibe | 2 900 |
| Riz | Andravoahangy | 3 100 |
| Tomate | Analakely | 4 500 |
| Tomate | Anosibe | 4 200 |
| Banane | Analakely | 1 800 |
| Banane | Isotry | 1 650 |
| Mangue | Analakely | 2 500 |

---

## 7. Scenarios de test sur le telephone

### A — Acheteur (`acheteur@test.mg` / `test123`)

1. **Recherche** : taper `riz` → selectionner Riz (enregistre le produit pour les autres ecrans).
2. **Comparer** : marché depart = Analakely → voir le marché le moins cher (Dijkstra).
3. **Panier** : budget `50000`, importance `3` → optimiser.
4. **Connexion vendeur** non requise pour la lecture des prix.

### B — Vendeur / Collecteur (`vendeur@test.mg` ou `collecteur@test.mg` / `test123`)

1. **Saisie** : choisir un marché dans la liste, prix ex. `3500`, unité `kg`.
2. Produit ID pre-rempli si vous avez choisi un produit dans Recherche.
3. **Hors-ligne** : coupez le Wi-Fi → saisie → message file d'attente → reconnectez → **Synchroniser**.

Exemples de saisie manuelle :

| Produit | Marché | Prix (Ar) | Unité |
|---------|--------|-----------|-------|
| Riz | Analakely | 3300 | kg |
| Tomate | Isotry | 4100 | kg |

### C — Panier (Acheteur)

- Budget : **50000** Ar  
- Produit : Riz (selectionne avant)  
- Importance : **3**

### D — Comparaison (Acheteur)

- Produit : Riz (`b2000001-0000-4000-8000-000000000001`)  
- Depart : Analakely (`c3000001-0000-4000-8000-000000000001`)  
- Resultat attendu : Anosibe souvent moins cher (riz 2900 + transport 500).

---

## 8. Verifier que l'API repond (PC)

```powershell
curl http://localhost:3000/health
curl "http://localhost:3000/api/v1/produits/search?q=riz"
```

---

## 9. Si les UUID ne correspondent pas

Votre base a peut-etre deja des produits avec d'autres ID. Executez :

```sql
SET search_path TO meilleur_prix, public;
SELECT id, nom_fr, nom_mg FROM produit ORDER BY nom_fr;
SELECT id, nom, ville FROM marche ORDER BY ville, nom;
```

Utilisez les ID affiches dans l'app, ou reimportez `test-data-phone.sql` sur une base vide.
