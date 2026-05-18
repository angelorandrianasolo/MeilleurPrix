# Meilleur Prix — Projet transversal L2 SIO

**Etudiant :** RANDRIANASOLO Fanirina Angelo — **NIE :** SI20240029

Systeme de collecte, analyse et prevision des prix dans les marches malgaches (bazary).

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Backend | Node.js 20 + Express 5 (API REST) |
| Frontend web | JSP 2.3 + HTML/CSS/JS (Apache Tomcat 9) |
| Frontend mobile | React Native (Expo SDK 54) |
| Base de donnees | PostgreSQL 16+ |

## Architecture 3-tiers

```
frontend-web/     → JSP (presentation)
frontend-mobile/  → React Native (mobile)
backend/          → routes → controllers → services → repositories
database/         → schema.sql + seed.sql
```

## Fonctionnalites (CDC)

| # | Fonctionnalite | Algorithme | Statut |
|---|---|---|---|
| 1 | Recherche produits FR/MG | Trie | ✅ teste |
| 2 | Saisie/collecte prix | Validation + FIFO sync | ✅ teste |
| 3 | Carte interactive (OpenStreetMap) | Leaflet | ✅ |
| 4 | Comparaison inter-marches | Dijkstra + MinHeap | ✅ teste |
| 5 | Optimisation panier | Sac a dos DP (0/1 Knapsack) | ✅ |
| 6 | Prevision des prix | Moyenne ponderee + DP | ✅ |
| 7 | Tableau de bord admin | Fenwick Tree | ✅ teste |
| 8 | Synchronisation hors-ligne | File FIFO | ✅ |

## Tests

```bash
cd backend
npm test          # 41 tests — algorithmes + validation
```

Tests couvrent : Trie (8), Dijkstra (7), Fenwick (7), Panier (1), Validation (18).

## Installation rapide (Docker)

```bash
docker compose up -d
# API → http://localhost:3000
# Admin : admin@meilleurprix.mg / admin123
```

### 1. PostgreSQL

```bash
createdb meilleur_prix_db
psql -d meilleur_prix_db -f database/schema.sql
psql -d meilleur_prix_db -f database/seed.sql
```

### 2. Backend

```bash
cd backend
cp .env.example .env   # editer si besoin
npm install
node scripts/init-admin.js admin123
npm start               # http://localhost:3000
```

Compte admin : `admin@meilleurprix.mg` / `admin123`

### 3. Frontend web (JSP + Tomcat 9)

Deployer `frontend-web/` dans `TOMCAT9/webapps/meilleur-prix/` (voir `frontend-web/DEPLOI-TOMCAT9.md`).

- URL : `http://localhost:8080/meilleur-prix/pages/login.jsp`
- API : configurer `apiBaseUrl` dans `WEB-INF/web.xml`

### 4. Mobile (Expo SDK 54)

```bash
cd frontend-mobile
npm install
npx expo install --fix
cp .env.example .env   # editer API_URL
npx expo start
```

Emulateur Android : `API_URL=http://10.0.2.2:3000/api/v1`

## Endpoints API

| Methode | Route | Auth | Description |
|---------|-------|------|-------------|
| POST | `/api/v1/auth/login` | - | Connexion JWT |
| POST | `/api/v1/auth/register` | - | Inscription |
| GET | `/api/v1/produits/search?q=` | - | Recherche Trie |
| GET | `/api/v1/produits` | - | Tous produits |
| GET | `/api/v1/produits/:id` | - | Detail produit |
| GET | `/api/v1/marches` | - | Tous marches |
| GET | `/api/v1/marches/comparer?produitId=&marcheIds[]=` | - | Dijkstra |
| POST | `/api/v1/prix` | Oui | Saisie prix |
| GET | `/api/v1/prix/produit/:id` | - | Historique prix |
| POST | `/api/v1/panier/optimiser` | Oui | Sac a dos DP |
| GET | `/api/v1/previsions/:produitId` | - | Prevision 30j |
| GET | `/api/v1/dashboard` | Oui | Fenwick stats |
| POST | `/api/v1/sync` | Oui | FIFO sync offline |
| GET | `/health` | - | Health check |

## Bugs corriges (audit)

1. `frontend-mobile/app/(tabs)/comparer.js` : `border: 1` → `borderWidth: 1`, `paddingTopVertical` → `paddingVertical`
2. `frontend-mobile/src/services/syncService.js` : IP hardcodee (`10.162.122.155:3000`) → `API_BASE` depuis `api.js`
3. `database/schema.sql` : `uuid_generate_v4()` → UUIDs stables pour categories/marches ; categories alignees avec validationService
4. `database/seed.sql` : Prix contraints par categorie (500-9000 Ar) pour eviter faux positifs outliers

## Audit complet

Voir `docs_extracted/cdc.txt` pour le CDC original.
