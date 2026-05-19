-- Donnees de demonstration — Meilleur Prix
-- Mot de passe admin : executer "node backend/scripts/init-admin.js admin123"
SET search_path TO meilleur_prix, public;

-- Les utilisateurs sont créés via l'API /auth/register
-- Les données admin sont créées au démarrage du backend

-- ===== 1. Catégories de produits =====
INSERT INTO categorie_produit (libelle_fr, libelle_mg, description)
VALUES
  ('Céréales', 'Vary sy katsaka', 'Riz, mais et autres céréales'),
  ('Légumes', 'Anana', 'Tomates, oignons, choux...'),
  ('Fruits', 'Voankazo', 'Bananes, mangues, papayes...'),
  ('Viandes', 'Hena', 'Poulet, viande bovine...'),
  ('Poissons', 'Trondro', 'Poissons frais et séchés'),
  ('Produits laitiers', 'Ronono', 'Lait, fromage, yaourt'),
  ('Épices', 'Pitraspitra', 'Sel, sucre, épices'),
  ('Produits transformés', 'Vokatra miova', 'Pâtes, huile, farine')
ON CONFLICT (libelle_fr) DO NOTHING;

-- ===== 3. Marchés à Madagascar (Antananarivo + autres villes) =====
INSERT INTO marche (nom, ville, latitude, longitude, est_actif)
VALUES
  -- Antananarivo
  ('Analakely', 'Antananarivo', -18.8792, 47.5079, TRUE),
  ('Anosibe', 'Antananarivo', -18.8833, 47.5167, TRUE),
  ('Andravoahangy', 'Antananarivo', -18.9167, 47.4833, TRUE),
  ('Isotry', 'Antananarivo', -18.8667, 47.5333, TRUE),
  ('Mahamasina', 'Antananarivo', -18.8917, 47.5083, TRUE),
  
  -- Toamasina
  ('Toamasina Central', 'Toamasina', -18.1667, 49.4167, TRUE),
  ('Toamasina Bazary', 'Toamasina', -18.1833, 49.4333, TRUE),
  
  -- Fianarantsoa
  ('Fianarantsoa Center', 'Fianarantsoa', -21.4583, 47.2917, TRUE),
  
  -- Antsirabe
  ('Antsirabe Market', 'Antsirabe', -19.8731, 46.9231, TRUE),
  
  -- Mahajanga
  ('Mahajanga Port', 'Mahajanga', -15.7167, 46.3167, TRUE)
ON CONFLICT (nom, ville) DO NOTHING;

-- ===== 4. Itinéraires entre marchés (Digraph pour Dijkstra) =====
INSERT INTO itineraire_marche (marche_depart_id, marche_arrivee_id, distance_km, cout_transport, duree_minutes)
SELECT d.id, a.id, v.dist, v.cout, v.duree
FROM (
  -- Antananarivo intra-city
  SELECT 'Analakely' AS dep, 'Anosibe' AS arr, 2.5::numeric AS dist, 500::numeric AS cout, 15 AS duree
  UNION ALL SELECT 'Analakely', 'Andravoahangy', 3.0, 700, 20
  UNION ALL SELECT 'Analakely', 'Isotry', 2.8, 600, 18
  UNION ALL SELECT 'Anosibe', 'Isotry', 2.0, 400, 12
  UNION ALL SELECT 'Anosibe', 'Mahamasina', 1.5, 300, 10
  UNION ALL SELECT 'Isotry', 'Mahamasina', 1.2, 250, 8
  UNION ALL SELECT 'Andravoahangy', 'Analakely', 3.0, 700, 20
  
  -- Inter-city (long distances)
  UNION ALL SELECT 'Analakely', 'Toamasina Central', 355.0, 15000, 420
  UNION ALL SELECT 'Toamasina Central', 'Analakely', 355.0, 15000, 420
  UNION ALL SELECT 'Analakely', 'Fianarantsoa Center', 420.0, 18000, 480
  UNION ALL SELECT 'Analakely', 'Antsirabe Market', 170.0, 8000, 180
) v
JOIN marche d ON d.nom = v.dep AND d.ville IN 
  (CASE WHEN v.dep IN ('Analakely', 'Anosibe', 'Andravoahangy', 'Isotry', 'Mahamasina') 
        THEN 'Antananarivo' 
        WHEN v.dep = 'Toamasina Central' THEN 'Toamasina'
        WHEN v.dep = 'Fianarantsoa Center' THEN 'Fianarantsoa'
        WHEN v.dep = 'Antsirabe Market' THEN 'Antsirabe'
   END)
JOIN marche a ON a.nom = v.arr AND a.ville IN 
  (CASE WHEN v.arr IN ('Analakely', 'Anosibe', 'Andravoahangy', 'Isotry', 'Mahamasina') 
        THEN 'Antananarivo' 
        WHEN v.arr = 'Toamasina Central' THEN 'Toamasina'
        WHEN v.arr = 'Fianarantsoa Center' THEN 'Fianarantsoa'
        WHEN v.arr = 'Antsirabe Market' THEN 'Antsirabe'
   END)
ON CONFLICT (marche_depart_id, marche_arrivee_id) DO NOTHING;

-- ===== 5. Produits complets =====
INSERT INTO produit (categorie_id, nom_fr, nom_mg, unite, description)
SELECT c.id, v.nom_fr, v.nom_mg, v.unite, v.description
FROM (
  -- Céréales
  VALUES
    ('Céréales', 'Riz blanc', 'Vary fotsy', 'kg', 'Riz blanc premium'),
    ('Céréales', 'Riz rouge', 'Vary mena', 'kg', 'Riz complet'),
    ('Céréales', 'Maïs sec', 'Katsaka maina', 'kg', 'Maïs sec'),
    ('Céréales', 'Maïs frais', 'Katsaka oda', 'kg', 'Maïs frais'),
    ('Céréales', 'Blé', 'Blé', 'kg', 'Farine de blé'),
    
    -- Légumes
    ('Légumes', 'Tomate', 'Voatabia', 'kg', 'Tomate fraîche'),
    ('Légumes', 'Oignon', 'Antsonga', 'kg', 'Oignon'),
    ('Légumes', 'Chou', 'Kala', 'kg', 'Chou'),
    ('Légumes', 'Carotte', 'Karota', 'kg', 'Carotte'),
    ('Légumes', 'Navet', 'Navetana', 'kg', 'Navet'),
    ('Légumes', 'Aubergine', 'Solatry', 'kg', 'Aubergine'),
    ('Légumes', 'Ail', 'Tongasoa', 'kg', 'Ail'),
    
    -- Fruits
    ('Fruits', 'Banane jaune', 'Akondro maitso', 'kg', 'Banane mûre'),
    ('Fruits', 'Banane verte', 'Akondro mena', 'kg', 'Banane verte'),
    ('Fruits', 'Mangue', 'Manga', 'kg', 'Mangue fraîche'),
    ('Fruits', 'Papaye', 'Papaya', 'kg', 'Papaye'),
    ('Fruits', 'Ananas', 'Anasy', 'kg', 'Ananas'),
    ('Fruits', 'Coco', 'Voanio', 'pièce', 'Noix de coco'),
    ('Fruits', 'Pastèque', 'Pasteka', 'kg', 'Pastèque'),
    ('Fruits', 'Citron', 'Litra', 'kg', 'Citron'),
    
    -- Viandes
    ('Viandes', 'Poulet entier', 'Akoho iray', 'kg', 'Poulet frais'),
    ('Viandes', 'Filet de poulet', 'Filet akoho', 'kg', 'Poulet sans os'),
    ('Viandes', 'Œufs', 'Atody', 'dizaine', '10 œufs'),
    ('Viandes', 'Viande bovine', 'Hena omby', 'kg', 'Viande de boeuf'),
    ('Viandes', 'Viande porcine', 'Hena kisoa', 'kg', 'Viande de porc'),
    
    -- Poissons
    ('Poissons', 'Tilapia frais', 'Tilapia oda', 'kg', 'Poisson frais'),
    ('Poissons', 'Tilapia séché', 'Tilapia maina', 'kg', 'Poisson séché'),
    ('Poissons', 'Crevette', 'Foza', 'kg', 'Crevette'),
    ('Poissons', 'Poisson sec', 'Trondro maina', 'kg', 'Poisson séché mixte'),
    
    -- Produits laitiers
    ('Produits laitiers', 'Lait frais', 'Ronono oda', 'litre', 'Lait pasteurisé'),
    ('Produits laitiers', 'Fromage', 'Fromazy', 'kg', 'Fromage local'),
    ('Produits laitiers', 'Yaourt', 'Yaourta', 'litre', 'Yaourt nature'),
    
    -- Épices
    ('Épices', 'Sel fin', 'Sira maingolo', 'kg', 'Sel cuisinier'),
    ('Épices', 'Sucre blanc', 'Siramena fotsy', 'kg', 'Sucre cristallisé'),
    ('Épices', 'Poivre', 'Pitre', 'kg', 'Poivre noir'),
    ('Épices', 'Vanille', 'Vanilla', 'kg', 'Vanille de Madagascar'),
    
    -- Produits transformés
    ('Produits transformés', 'Pâtes', 'Pata', 'kg', 'Pâtes alimentaires'),
    ('Produits transformés', 'Huile de palme', 'Menaka palmina', 'litre', 'Huile de cuisine'),
    ('Produits transformés', 'Farine de riz', 'Farina vary', 'kg', 'Farine complète'),
    ('Produits transformés', 'Sucre cassonade', 'Siramena', 'kg', 'Cassonade brune')
) AS v(categorie, nom_fr, nom_mg, unite, description)
JOIN categorie_produit c ON c.libelle_fr = v.categorie
ON CONFLICT (nom_fr) DO NOTHING;

-- ===== 6. Saisies de prix initiales (admin comme collecteur, 30 derniers jours) =====
INSERT INTO saisie_prix (produit_id, marche_id, utilisateur_id, valeur, unite, date_saisie, statut, source_saisie, est_synchro)
SELECT
  p.id,
  m.id,
  u.id,
  (CASE c.libelle_fr
    WHEN 'Céréales' THEN 1500 + (random() * 2000)
    WHEN 'Légumes' THEN 500 + (random() * 1500)
    WHEN 'Fruits' THEN 1000 + (random() * 2500)
    WHEN 'Viandes' THEN 4000 + (random() * 5000)
    WHEN 'Poissons' THEN 3000 + (random() * 4000)
    WHEN 'Produits laitiers' THEN 1500 + (random() * 2000)
    WHEN 'Épices' THEN 2000 + (random() * 3000)
    ELSE 1500 + (random() * 2000)
  END)::numeric(12,2),
  p.unite,
  (CURRENT_DATE - (FLOOR(random() * 30)::int) * interval '1 day')::date,
  'SYNCHRONISEE'::t_statut_saisie,
  'COLLECTEUR'::t_source_saisie,
  TRUE
FROM (SELECT * FROM produit LIMIT 30) p
JOIN categorie_produit c ON c.id = p.categorie_id
JOIN (SELECT * FROM marche WHERE ville = 'Antananarivo' LIMIT 5) m ON TRUE
JOIN (SELECT id FROM utilisateur WHERE email = 'admin@meilleurprix.mg' LIMIT 1) u ON TRUE
WHERE NOT EXISTS (
  SELECT 1 FROM saisie_prix sp
  WHERE sp.produit_id = p.id AND sp.marche_id = m.id
);

-- ===== 7. Historique des prix (agrégats journaliers) =====
INSERT INTO historique_prix (produit_id, marche_id, date_jour, prix_min, prix_max, prix_moyen, nb_saisies)
SELECT
  p.id,
  m.id,
  jours.date_jour,
  ROUND((base + (random() * vari))::numeric, 0) AS prix_min,
  ROUND((base + vari + (random() * vari))::numeric, 0) AS prix_max,
  ROUND((base + vari * 0.5 + (random() * vari * 0.5))::numeric, 0) AS prix_moyen,
  (3 + FLOOR(random() * 7))::int AS nb_saisies
FROM (SELECT * FROM produit LIMIT 20) p
JOIN categorie_produit c ON c.id = p.categorie_id
CROSS JOIN (SELECT * FROM marche WHERE ville = 'Antananarivo' LIMIT 5) m
CROSS JOIN LATERAL (
  SELECT generate_series(CURRENT_DATE - 30, CURRENT_DATE, '1 day')::date AS date_jour
) jours
CROSS JOIN LATERAL (
  SELECT CASE c.libelle_fr
    WHEN 'Céréales' THEN 1500 WHEN 'Légumes' THEN 800
    WHEN 'Fruits' THEN 1200 WHEN 'Viandes' THEN 5000
    WHEN 'Poissons' THEN 3500 WHEN 'Produits laitiers' THEN 2000
    WHEN 'Épices' THEN 2500 WHEN 'Produits transformés' THEN 2000
    ELSE 1500
  END AS base,
  CASE c.libelle_fr
    WHEN 'Céréales' THEN 500 WHEN 'Légumes' THEN 400
    WHEN 'Fruits' THEN 600 WHEN 'Viandes' THEN 2000
    WHEN 'Poissons' THEN 1500 WHEN 'Produits laitiers' THEN 800
    WHEN 'Épices' THEN 1000 WHEN 'Produits transformés' THEN 600
    ELSE 500
  END AS vari
) params
ON CONFLICT (produit_id, marche_id, date_jour) DO NOTHING;

