# 🧪 Guide de Test — Meilleur Prix

**Date:** 27 Mai 2026  
**Application:** Conforme CDC SI20240029

---

## 1. PRÉPARATION

### 1.1 Vérifier que le backend fonctionne
```bash
# Terminal 1: Démarrer le serveur
cd backend
npm start

# Sortie attendue:
# Connexion PostgreSQL etablie
# Backend MEILLEUR PRIX sur http://localhost:3000
```

### 1.2 Vérifier la base de données
```bash
# Terminal 2: Vérifier les données
curl http://10.162.122.155:3000/api/v1/produits | jq '.data | length'
# Résultat attendu: 41 produits

curl http://10.162.122.155:3000/api/v1/marches | jq '.data | length'
# Résultat attendu: 10 marchés
```

---

## 2. TESTS D'AUTHENTIFICATION

### 2.1 Connexion admin
```bash
curl -X POST http://10.162.122.155:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@meilleurprix.mg",
    "mot_de_passe": "admin123"
  }'

# Résultat attendu:
# {
#   "success": true,
#   "data": {
#     "token": "eyJhbGci...",
#     "utilisateur": {
#       "id": "...",
#       "email": "admin@meilleurprix.mg",
#       "role": "ADMINISTRATEUR",
#       "langue": "FR"
#     }
#   }
# }
```

### 2.2 Inscription nouveau utilisateur
```bash
curl -X POST http://10.162.122.155:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Test Acheteur",
    "email": "test.acheteur@meilleurprix.mg",
    "mot_de_passe": "Test123456",
    "role": "ACHETEUR",
    "langue": "FR"
  }'

# Résultat attendu: 201 Created avec token
```

---

## 3. TESTS RECHERCHE (TRIE)

### 3.1 Recherche simple
```bash
TOKEN="your_token_here"

# Recherche "riz"
curl "http://10.162.122.155:3000/api/v1/produits/search?q=riz" \
  -H "Authorization: Bearer $TOKEN"

# Résultat attendu: 2 résultats
# [
#   { "nom_fr": "Riz blanc", ... },
#   { "nom_fr": "Riz rouge", ... }
# ]
```

### 3.2 Recherche malagasy
```bash
# Recherche "vary" (riz en malagasy)
curl "http://10.162.122.155:3000/api/v1/produits/search?q=vary" \
  -H "Authorization: Bearer $TOKEN"

# Résultat attendu: Même résultats que "riz"
```

### 3.3 Performance < 100ms
```bash
time curl "http://10.162.122.155:3000/api/v1/produits/search?q=pa" \
  -H "Authorization: Bearer $TOKEN"

# Temps attendu: < 50ms
```

---

## 4. TESTS SAISIE DE PRIX

### 4.1 Saisie valide
```bash
TOKEN="your_token_here"
PRODUIT_ID="product_uuid_here"
MARCHE_ID="market_uuid_here"

curl -X POST http://10.162.122.155:3000/api/v1/prix \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "produit_id": "'$PRODUIT_ID'",
    "marche_id": "'$MARCHE_ID'",
    "valeur": 1850,
    "unite": "kg",
    "date_saisie": "2026-05-27",
    "source_saisie": "MOBILE"
  }'

# Résultat attendu: 201 Created
```

### 4.2 Saisie avec avertissement (prix aberrant)
```bash
# Prix anormalement bas
curl -X POST http://10.162.122.155:3000/api/v1/prix \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "produit_id": "'$PRODUIT_ID'",
    "marche_id": "'$MARCHE_ID'",
    "valeur": 50,
    "unite": "kg",
    "source_saisie": "MOBILE"
  }'

# Résultat attendu: 201 Created avec
# "warning": "Prix anormalement bas pour Légumes (min: 300)"
```

### 4.3 Saisie rejetée (prix invalide)
```bash
# Prix négatif
curl -X POST http://10.162.122.155:3000/api/v1/prix \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "produit_id": "'$PRODUIT_ID'",
    "marche_id": "'$MARCHE_ID'",
    "valeur": -1000,
    "unite": "kg"
  }'

# Résultat attendu: 400 Bad Request
# "errors": ["Le prix doit être positif"]
```

---

## 5. TESTS COMPARAISON MARCHÉS (DIJKSTRA)

### 5.1 Trouver le meilleur marché
```bash
TOKEN="your_token_here"
PRODUIT_ID="product_uuid"
DEPART_ID="analakely_uuid"

curl "http://10.162.122.155:3000/api/v1/marches/comparer?produitId=$PRODUIT_ID&departId=$DEPART_ID" \
  -H "Authorization: Bearer $TOKEN"

# Résultat attendu:
# {
#   "success": true,
#   "data": {
#     "marche_optimal": {
#       "id": "...",
#       "nom": "Analakely",
#       "prix_produit": 1850
#     },
#     "cout_total": 1850,
#     "temps_calcul_ms": 5,
#     "comparatif": [
#       { "marche": {...}, "cout_total": 1850, ... },
#       { "marche": {...}, "cout_total": 2350, ... }
#     ]
#   }
# }
```

---

## 6. TESTS PANIER (SAC À DOS)

### 6.1 Optimiser les achats
```bash
curl -X POST http://10.162.122.155:3000/api/v1/panier/optimiser \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 10000,
    "produits": [
      {"id": "'$PRODUIT_ID_1'", "valeur": 10, "cout": 1850},
      {"id": "'$PRODUIT_ID_2'", "valeur": 8, "cout": 2500},
      {"id": "'$PRODUIT_ID_3'", "valeur": 7, "cout": 1200}
    ]
  }'

# Résultat attendu:
# {
#   "success": true,
#   "data": {
#     "solution_optimisee": {
#       "items": [...],
#       "cout_total": 5550,
#       "valeur": 25,
#       "budget_restant": 4450
#     },
#     "solution_naive": {
#       "items": [...],
#       "cout_total": 5550,
#       "valeur": 18
#     }
#   }
# }
```

---

## 7. TESTS PRÉVISIONS (MOYENNE MOBILE PONDÉRÉE)

### 7.1 Prévisions 30 jours
```bash
PRODUIT_ID="product_uuid"
MARCHE_ID="market_uuid"

curl "http://10.162.122.155:3000/api/v1/previsions/$PRODUIT_ID?marcheId=$MARCHE_ID" \
  -H "Authorization: Bearer $TOKEN"

# Résultat attendu:
# {
#   "success": true,
#   "data": {
#     "historique": [
#       {"date": "2026-04-27", "valeur": 1850},
#       ...
#     ],
#     "dates_futures": ["2026-05-28", "2026-05-29", ...],
#     "prevision_simple": [1920, 1920, ...],
#     "prevision_optimisee": [1850, 1860, 1870, ...],
#     "comparaison": {
#       "erreur_simple": 0.15,
#       "erreur_optimisee": 0.08,
#       "methode_recommandee": "optimisee"
#     }
#   }
# }
```

---

## 8. TESTS TABLEAU DE BORD (FENWICK TREE)

### 8.1 Statistiques et tendances
```bash
curl http://10.162.122.155:3000/api/v1/dashboard \
  -H "Authorization: Bearer $TOKEN"

# Résultat attendu:
# {
#   "success": true,
#   "data": {
#     "statistiques": {
#       "nb_saisies": 30,
#       "nb_produits": 41,
#       "nb_marches": 10,
#       "prix_moyen_global": 1850,
#       "prix_min_global": 300,
#       "prix_max_global": 50000
#     },
#     "top_produits": [
#       {"nom_fr": "Riz blanc", "saisies": 12},
#       ...
#     ],
#     "top_marches": [
#       {"nom": "Analakely", "saisies": 8},
#       ...
#     ],
#     "tendance_30j": [
#       {"date_jour": "2026-04-27", "prix_moyen": 1850, "cumul_fenwick": 1850},
#       ...
#     ]
#   }
# }
```

---

## 9. TESTS MODE HORS-LIGNE (MOBILE)

### 9.1 Saisie offline
1. **Étapes:**
   - Ouvrir l'app Expo
   - Désactiver Wi-Fi/données mobile
   - Aller sur l'écran "Saisie Prix"
   - Remplir le formulaire
   - Cliquer "Enregistrer prix"

2. **Résultat attendu:**
   - ✓ Badge "📡 Mode hors ligne" en haut
   - ✓ Message "Hors ligne - Prix enregistré localement"
   - ✓ Saisie visible dans "Offline Queue"

### 9.2 Synchronisation auto
1. **Étapes:**
   - Laisser l'app ouverte en offline
   - Réactiver connexion
   - Attendre 30 secondes

2. **Résultat attendu:**
   - ✓ Badge passe à "🟢 En ligne"
   - ✓ Sync auto se lance
   - ✓ État: "⏳ En attente" → "✓ Synchronisé"

### 9.3 Sync manuel
1. **Étapes:**
   - Aller dans "Offline Queue"
   - Cliquer "🔄 Synchroniser maintenant"

2. **Résultat attendu:**
   - ✓ Affiche "⏳ Synchronisation..."
   - ✓ Compteur: "✓ Synchronisés: X"
   - ✓ Queue se vide

---

## 10. TESTS MULTILINGUE (FR/MG)

### 10.1 Changer la langue
1. **Étapes:**
   - Aller dans "Profil"
   - Cliquer sur "Langue"
   - Sélectionner "Malagasy (MG)"

2. **Résultat attendu:**
   - ✓ Navigation: "Fitadiavana" (Recherche)
   - ✓ Boutons: "Hiditra" (Connexion)
   - ✓ Messages: "Mitadiava vokatra..." (Chercher un produit)

### 10.2 Persistance langue
1. **Étapes:**
   - Changer de langue
   - Fermer l'app
   - Rouvrir l'app

2. **Résultat attendu:**
   - ✓ Langue conservée (sauvegardée en AsyncStorage)

---

## 11. TESTS PERFORMANCE

### 11.1 Recherche < 100ms
```bash
# Avec chronométrage
time curl "http://10.162.122.155:3000/api/v1/produits/search?q=var" \
  -H "Authorization: Bearer $TOKEN"

# Temps attendu: < 50ms
```

### 11.2 Dashboard (Fenwick) rapide
```bash
time curl http://10.162.122.155:3000/api/v1/dashboard \
  -H "Authorization: Bearer $TOKEN"

# Temps attendu: < 100ms
```

### 11.3 Dijkstra < 500ms
```bash
time curl "http://10.162.122.155:3000/api/v1/marches/comparer?produitId=$PRODUIT_ID&departId=$DEPART_ID" \
  -H "Authorization: Bearer $TOKEN"

# Temps attendu: < 200ms
```

---

## 12. TESTS DE SÉCURITÉ

### 12.1 JWT expiré
```bash
# Attendre 24h ou modifier le token
curl http://10.162.122.155:3000/api/v1/auth/me \
  -H "Authorization: Bearer expired_token"

# Résultat attendu: 401 Unauthorized
```

### 12.2 CORS
```bash
curl -i "http://10.162.122.155:3000/api/v1/produits" \
  -H "Origin: https://autre-domaine.com" \
  | grep "Access-Control"

# Résultat attendu: Access-Control-Allow-Origin: *
```

### 12.3 Validation entrées
```bash
# SQL injection test
curl "http://10.162.122.155:3000/api/v1/produits/search?q='; DROP TABLE produit; --" \
  -H "Authorization: Bearer $TOKEN"

# Résultat attendu: Pas d'erreur DB, recherche échouée normalement
```

---

## 📋 Checklist finale

- [ ] Backend démarre sans erreurs
- [ ] Admin peut se connecter
- [ ] 41 produits visibles
- [ ] 10 marchés en BD
- [ ] Trie < 100ms
- [ ] Saisie prix valide
- [ ] Avertissement aberrance détecté
- [ ] Dijkstra retourne bon marché
- [ ] Panier DP optimise
- [ ] Prévisions générées
- [ ] Dashboard affiche stats
- [ ] Interface FR/MG
- [ ] Mode offline fonctionne
- [ ] Sync auto se lance
- [ ] Performance acceptable

---

**Tous les tests doivent passer pour la conformité CDC!** ✅
