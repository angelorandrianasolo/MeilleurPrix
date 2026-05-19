-- =============================================================
-- DONNEES DE TEST — Meilleur Prix (telephone / demo)
-- Executer APRES schema.sql :
--   psql -d meilleur_prix_db -f database/test-data-phone.sql
-- Puis : node backend/scripts/init-admin.js admin123
--        node backend/scripts/init-admin.js test123 acheteur@test.mg
-- (init-admin ne gere qu'admin — voir TEST-DONNEES.md pour les comptes)
-- =============================================================
SET search_path TO meilleur_prix, public;

-- Mot de passe pour TOUS les comptes test ci-dessous : test123
-- Hash bcrypt (12 rounds) pour "test123"
-- Apres import, vous pouvez aussi vous INSCRIRE depuis l'app mobile.

-- ---------- UTILISATEURS TEST ----------
INSERT INTO utilisateur (id, nom, email, mot_de_passe, role, langue, budget_max)
VALUES
  ('a1000001-0000-4000-8000-000000000001', 'Jean Acheteur', 'acheteur@test.mg',
   '$2b$12$bAPtJf7QdHwBZODkWWqPO.Fec1cSCkabPVohUIRj6Opvd6XS5XdEa', 'ACHETEUR', 'FR', 50000),
  ('a1000001-0000-4000-8000-000000000002', 'Rabe Vendeur', 'vendeur@test.mg',
   '$2b$12$bAPtJf7QdHwBZODkWWqPO.Fec1cSCkabPVohUIRj6Opvd6XS5XdEa', 'VENDEUR', 'MG', NULL),
  ('a1000001-0000-4000-8000-000000000003', 'Solo Collecteur', 'collecteur@test.mg',
   '$2b$12$bAPtJf7QdHwBZODkWWqPO.Fec1cSCkabPVohUIRj6Opvd6XS5XdEa', 'COLLECTEUR', 'FR', NULL)
ON CONFLICT (email) DO UPDATE SET
  mot_de_passe = EXCLUDED.mot_de_passe,
  nom = EXCLUDED.nom,
  role = EXCLUDED.role;

-- ---------- PRODUITS (UUID fixes pour copier dans l'app) ----------
INSERT INTO produit (id, categorie_id, nom_fr, nom_mg, unite, description)
SELECT v.id, c.id, v.nom_fr, v.nom_mg, v.unite, v.description
FROM (VALUES
  ('b2000001-0000-4000-8000-000000000001'::uuid, 'Céréales', 'Riz', 'Vary', 'kg', 'Riz local'),
  ('b2000001-0000-4000-8000-000000000002'::uuid, 'Céréales', 'Mais', 'Katsaka', 'kg', 'Mais'),
  ('b2000001-0000-4000-8000-000000000003'::uuid, 'Légumes', 'Tomate', 'Voatabia', 'kg', 'Tomate'),
  ('b2000001-0000-4000-8000-000000000004'::uuid, 'Légumes', 'Oignon', 'An tonga', 'kg', 'Oignon'),
  ('b2000001-0000-4000-8000-000000000005'::uuid, 'Fruits', 'Banane', 'Akondro', 'kg', 'Banane'),
  ('b2000001-0000-4000-8000-000000000006'::uuid, 'Fruits', 'Mangue', 'Manga', 'kg', 'Mangue')
) AS v(id, cat, nom_fr, nom_mg, unite, description)
JOIN categorie_produit c ON c.libelle_fr = v.cat
ON CONFLICT (nom_fr) DO UPDATE SET
  id = EXCLUDED.id,
  nom_mg = EXCLUDED.nom_mg;

-- ---------- MARCHES (UUID fixes) ----------
INSERT INTO marche (id, nom, ville, latitude, longitude)
VALUES
  ('c3000001-0000-4000-8000-000000000001', 'Analakely', 'Antananarivo', -18.9137, 47.5361),
  ('c3000001-0000-4000-8000-000000000002', 'Anosibe', 'Antananarivo', -18.9226, 47.5290),
  ('c3000001-0000-4000-8000-000000000003', 'Andravoahangy', 'Antananarivo', -18.9014, 47.5418),
  ('c3000001-0000-4000-8000-000000000004', 'Isotry', 'Antananarivo', -18.9190, 47.5180),
  ('c3000001-0000-4000-8000-000000000005', 'Bazar Kely', 'Toamasina', -18.1443, 49.3917)
ON CONFLICT (nom, ville) DO NOTHING;

-- ---------- ITINERAIRES ----------
INSERT INTO itineraire_marche (marche_depart_id, marche_arrivee_id, distance_km, cout_transport, duree_minutes)
VALUES
  ('c3000001-0000-4000-8000-000000000001', 'c3000001-0000-4000-8000-000000000002', 2.5, 500, 15),
  ('c3000001-0000-4000-8000-000000000001', 'c3000001-0000-4000-8000-000000000003', 3.0, 700, 20),
  ('c3000001-0000-4000-8000-000000000001', 'c3000001-0000-4000-8000-000000000004', 2.8, 600, 18),
  ('c3000001-0000-4000-8000-000000000002', 'c3000001-0000-4000-8000-000000000004', 2.0, 400, 12)
ON CONFLICT (marche_depart_id, marche_arrivee_id) DO NOTHING;

-- ---------- PRIX DE TEST (pour comparaison / panier / prevision) ----------
INSERT INTO saisie_prix (produit_id, marche_id, utilisateur_id, valeur, unite, statut, source_saisie, est_synchro)
SELECT p.id, m.id, u.id, v.prix, p.unite, 'SYNCHRONISEE', 'WEB', TRUE
FROM (VALUES
  ('Riz', 'Analakely', 3200),
  ('Riz', 'Anosibe', 2900),
  ('Riz', 'Andravoahangy', 3100),
  ('Tomate', 'Analakely', 4500),
  ('Tomate', 'Anosibe', 4200),
  ('Banane', 'Analakely', 1800),
  ('Banane', 'Isotry', 1650),
  ('Mangue', 'Analakely', 2500)
) AS v(produit, marche, prix)
JOIN produit p ON p.nom_fr = v.produit
JOIN marche m ON m.nom = v.marche
JOIN utilisateur u ON u.email = 'vendeur@test.mg'
WHERE NOT EXISTS (
  SELECT 1 FROM saisie_prix sp
  WHERE sp.produit_id = p.id AND sp.marche_id = m.id
    AND sp.date_saisie::date = CURRENT_DATE
);
