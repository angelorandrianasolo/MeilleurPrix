-- =============================================================
--  MEILLEUR PRIX — Script de création de la base de données
--  Étudiant  : RANDRIANASOLO Fanirina Angelo — NIE : SI20240029
--  SGBD      : PostgreSQL 16+
--  Encodage  : UTF-8 (support natif des caractères malagasy)
--  Schéma    : meilleur_prix
-- =============================================================

-- ---------------------------------------------------------------
-- 0. EXTENSIONS ET CONFIGURATION
-- ---------------------------------------------------------------

-- Extension uuid-ossp : génération d'UUID côté base (équivalent UUID() MySQL)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Extension pg_trgm : recherche floue et préfixe (remplace FULLTEXT MySQL)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Création du schéma dédié (bonne pratique PostgreSQL)
CREATE SCHEMA IF NOT EXISTS meilleur_prix;

-- Définir le schéma par défaut pour cette session
SET search_path TO meilleur_prix, public;


-- ---------------------------------------------------------------
-- 1. TYPES ÉNUMÉRÉS (ENUM PostgreSQL = TYPE natif réutilisable)
--    Avantage sur MySQL : déclarés une seule fois, réutilisables
--    dans plusieurs tables et fonctions.
-- ---------------------------------------------------------------

-- Rôles utilisateurs
DO $$ BEGIN
    CREATE TYPE t_role_utilisateur AS ENUM (
        'ACHETEUR',
        'VENDEUR',
        'COLLECTEUR',
        'ADMINISTRATEUR'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Langues de l'interface
DO $$ BEGIN
    CREATE TYPE t_langue AS ENUM ('FR', 'MG');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Statut du cycle de vie d'une saisie de prix (correspond au diagramme d'états UML)
DO $$ BEGIN
    CREATE TYPE t_statut_saisie AS ENUM (
        'LOCALE',        -- stockée uniquement en SQLite local
        'EN_ATTENTE',    -- dans la file FIFO, connexion absente
        'SYNCHRONISEE',  -- reçue et validée par le serveur
        'REJETEE'        -- refusée par le serveur (valeur invalide…)
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Source de saisie
DO $$ BEGIN
    CREATE TYPE t_source_saisie AS ENUM ('WEB', 'MOBILE', 'COLLECTEUR');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Statut de la file de synchronisation hors-ligne
DO $$ BEGIN
    CREATE TYPE t_statut_sync AS ENUM (
        'EN_ATTENTE',
        'EN_COURS',
        'ENVOYE',
        'ECHEC'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Méthode de prévision algorithmique
DO $$ BEGIN
    CREATE TYPE t_methode_prevision AS ENUM (
        'MOYENNE_SIMPLE',
        'MOYENNE_MOBILE_PONDEREE'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ---------------------------------------------------------------
-- 2. TABLE : categorie_produit
--    Paquetage UML : catalogue
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categorie_produit (
    id          UUID            NOT NULL DEFAULT uuid_generate_v4(),
    libelle_fr  VARCHAR(100)    NOT NULL,
    libelle_mg  VARCHAR(100)    NOT NULL,
    description VARCHAR(255),
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_categorie_produit     PRIMARY KEY (id),
    CONSTRAINT uq_categorie_libelle_fr  UNIQUE      (libelle_fr),
    CONSTRAINT uq_categorie_libelle_mg  UNIQUE      (libelle_mg)
);

COMMENT ON TABLE  categorie_produit             IS 'Catégories de produits (légume, fruit, céréale...)';
COMMENT ON COLUMN categorie_produit.libelle_fr  IS 'Nom de la catégorie en français';
COMMENT ON COLUMN categorie_produit.libelle_mg  IS 'Nom de la catégorie en malagasy';


-- ---------------------------------------------------------------
-- 3. TABLE : produit
--    Paquetage UML : catalogue
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS produit (
    id              UUID            NOT NULL DEFAULT uuid_generate_v4(),
    categorie_id    UUID            NOT NULL,
    nom_fr          VARCHAR(150)    NOT NULL,
    nom_mg          VARCHAR(150)    NOT NULL,
    unite           VARCHAR(30)     NOT NULL,   -- kg, litre, pièce…
    description     VARCHAR(500),
    est_actif       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_produit           PRIMARY KEY (id),
    CONSTRAINT uq_produit_nom_fr    UNIQUE      (nom_fr),
    CONSTRAINT uq_produit_nom_mg    UNIQUE      (nom_mg),
    CONSTRAINT fk_produit_categorie FOREIGN KEY (categorie_id)
        REFERENCES categorie_produit(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

COMMENT ON TABLE  produit           IS 'Catalogue des produits (ex : Vary/Riz, Akondro/Banane)';
COMMENT ON COLUMN produit.nom_fr    IS 'Nom du produit en français';
COMMENT ON COLUMN produit.nom_mg    IS 'Nom du produit en malagasy';
COMMENT ON COLUMN produit.unite     IS 'Unité de mesure associée au prix';

-- Index B-tree pour recherche par préfixe (simulation Trie)
CREATE INDEX IF NOT EXISTS idx_produit_nom_fr       ON produit (nom_fr);
CREATE INDEX IF NOT EXISTS idx_produit_nom_mg       ON produit (nom_mg);
CREATE INDEX IF NOT EXISTS idx_produit_categorie    ON produit (categorie_id);

-- Index GIN pour recherche floue bilingue (pg_trgm — remplace FULLTEXT MySQL)
CREATE INDEX IF NOT EXISTS idx_produit_trgm_fr  ON produit USING GIN (nom_fr gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_produit_trgm_mg  ON produit USING GIN (nom_mg gin_trgm_ops);


-- ---------------------------------------------------------------
-- 4. TABLE : marche
--    Paquetage UML : catalogue
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marche (
    id          UUID            NOT NULL DEFAULT uuid_generate_v4(),
    nom         VARCHAR(150)    NOT NULL,
    ville       VARCHAR(100)    NOT NULL,   -- Antananarivo, Toamasina…
    latitude    NUMERIC(10, 7)  NOT NULL,
    longitude   NUMERIC(10, 7)  NOT NULL,
    est_actif   BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_marche            PRIMARY KEY (id),
    CONSTRAINT uq_marche_nom_ville  UNIQUE (nom, ville)
);

COMMENT ON TABLE  marche            IS 'Marchés malgaches (bazary) avec localisation GPS';
COMMENT ON COLUMN marche.latitude   IS 'Coordonnée GPS latitude';
COMMENT ON COLUMN marche.longitude  IS 'Coordonnée GPS longitude';

CREATE INDEX IF NOT EXISTS idx_marche_ville     ON marche (ville);
CREATE INDEX IF NOT EXISTS idx_marche_coords    ON marche (latitude, longitude);


-- ---------------------------------------------------------------
-- 5. TABLE : itineraire_marche
--    Paquetage UML : catalogue
--    Arêtes du graphe orienté utilisé par l'algorithme de Dijkstra
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS itineraire_marche (
    id                  UUID            NOT NULL DEFAULT uuid_generate_v4(),
    marche_depart_id    UUID            NOT NULL,
    marche_arrivee_id   UUID            NOT NULL,
    distance_km         NUMERIC(8, 2)   NOT NULL CHECK (distance_km  > 0),
    cout_transport      NUMERIC(12, 2)  NOT NULL CHECK (cout_transport >= 0),
    duree_minutes       INT                      CHECK (duree_minutes  > 0),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_itineraire            PRIMARY KEY (id),
    CONSTRAINT uq_itineraire_trajet     UNIQUE (marche_depart_id, marche_arrivee_id),
    CONSTRAINT ck_itineraire_different  CHECK  (marche_depart_id <> marche_arrivee_id),
    CONSTRAINT fk_itineraire_depart     FOREIGN KEY (marche_depart_id)
        REFERENCES marche(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_itineraire_arrivee    FOREIGN KEY (marche_arrivee_id)
        REFERENCES marche(id) ON UPDATE CASCADE ON DELETE CASCADE
);

COMMENT ON TABLE itineraire_marche IS 'Arêtes du graphe de marchés pour l''algorithme Dijkstra';

CREATE INDEX IF NOT EXISTS idx_itineraire_depart    ON itineraire_marche (marche_depart_id);
CREATE INDEX IF NOT EXISTS idx_itineraire_arrivee   ON itineraire_marche (marche_arrivee_id);


-- ---------------------------------------------------------------
-- 6. TABLE : utilisateur
--    Paquetage UML : utilisateurs
--    Stratégie STI (Single Table Inheritance) : Acheteur, Vendeur,
--    Collecteur, Administrateur dans une seule table (colonne role).
--    Colonnes NULL selon le rôle.
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS utilisateur (
    id                  UUID                    NOT NULL DEFAULT uuid_generate_v4(),
    nom                 VARCHAR(150)            NOT NULL,
    email               VARCHAR(200)            NOT NULL,
    mot_de_passe        VARCHAR(255)            NOT NULL,   -- Hash bcrypt
    role                t_role_utilisateur      NOT NULL DEFAULT 'ACHETEUR',
    langue              t_langue                NOT NULL DEFAULT 'FR',
    -- Attributs spécifiques Acheteur (NULL si autre rôle)
    budget_max          NUMERIC(12, 2)          CHECK (budget_max >= 0),
    -- Attributs spécifiques Vendeur
    code_vendeur        VARCHAR(50),
    marche_principal_id UUID,
    -- Attributs spécifiques Collecteur
    zone_collecte       VARCHAR(150),
    date_last_sync      TIMESTAMPTZ,
    -- Communs
    est_actif           BOOLEAN                 NOT NULL DEFAULT TRUE,
    token_refresh       TEXT,                   -- Refresh token JWT
    created_at          TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ             NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_utilisateur       PRIMARY KEY (id),
    CONSTRAINT uq_utilisateur_email UNIQUE      (email),
    CONSTRAINT fk_utilisateur_marche FOREIGN KEY (marche_principal_id)
        REFERENCES marche(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

COMMENT ON TABLE  utilisateur               IS 'Tous les utilisateurs (STI : rôle dans la colonne role)';
COMMENT ON COLUMN utilisateur.mot_de_passe  IS 'Hash bcrypt — jamais en clair';
COMMENT ON COLUMN utilisateur.token_refresh IS 'Refresh token JWT pour renouvellement';

CREATE INDEX IF NOT EXISTS idx_utilisateur_role     ON utilisateur (role);
CREATE INDEX IF NOT EXISTS idx_utilisateur_email    ON utilisateur (email);


-- ---------------------------------------------------------------
-- 7. TABLE : saisie_prix
--    Paquetage UML : prix
--    Entrée unitaire de prix — cœur du système.
--    Le champ statut correspond exactement au diagramme d'états UML.
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS saisie_prix (
    id              UUID                NOT NULL DEFAULT uuid_generate_v4(),
    produit_id      UUID                NOT NULL,
    marche_id       UUID                NOT NULL,
    utilisateur_id  UUID                NOT NULL,
    valeur          NUMERIC(12, 2)      NOT NULL,
    unite           VARCHAR(30)         NOT NULL,
    date_saisie     TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    -- Gestion du cycle de vie hors-ligne (diagramme d'états)
    statut          t_statut_saisie     NOT NULL DEFAULT 'LOCALE',
    source_saisie   t_source_saisie     NOT NULL DEFAULT 'MOBILE',
    est_synchro     BOOLEAN             NOT NULL DEFAULT FALSE,
    raison_rejet    VARCHAR(255),
    created_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_saisie_prix           PRIMARY KEY (id),
    CONSTRAINT ck_saisie_valeur_positive CHECK (valeur > 0),
    CONSTRAINT fk_saisie_produit        FOREIGN KEY (produit_id)
        REFERENCES produit(id)      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_saisie_marche         FOREIGN KEY (marche_id)
        REFERENCES marche(id)       ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_saisie_utilisateur    FOREIGN KEY (utilisateur_id)
        REFERENCES utilisateur(id)  ON UPDATE CASCADE ON DELETE RESTRICT
);

COMMENT ON TABLE  saisie_prix           IS 'Saisies de prix individuelles — supporte le mode hors-ligne';
COMMENT ON COLUMN saisie_prix.valeur    IS 'Prix en Ariary (MGA)';
COMMENT ON COLUMN saisie_prix.statut    IS 'LOCALE→EN_ATTENTE→SYNCHRONISEE ou REJETEE';

CREATE INDEX IF NOT EXISTS idx_saisie_produit       ON saisie_prix (produit_id);
CREATE INDEX IF NOT EXISTS idx_saisie_marche        ON saisie_prix (marche_id);
CREATE INDEX IF NOT EXISTS idx_saisie_date          ON saisie_prix (date_saisie);
CREATE INDEX IF NOT EXISTS idx_saisie_statut        ON saisie_prix (statut);
-- Index composite pour requêtes de tendance (produit + marché + date)
CREATE INDEX IF NOT EXISTS idx_saisie_tendance      ON saisie_prix (produit_id, marche_id, date_saisie);


-- ---------------------------------------------------------------
-- 8. TABLE : historique_prix
--    Paquetage UML : prix
--    Agrégat journalier (min/max/moyenne) calculé depuis les saisies.
--    Optimisé avec Fenwick Tree côté applicatif Node.js.
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS historique_prix (
    id              UUID            NOT NULL DEFAULT uuid_generate_v4(),
    produit_id      UUID            NOT NULL,
    marche_id       UUID            NOT NULL,
    date_jour       DATE            NOT NULL,
    prix_min        NUMERIC(12, 2)  NOT NULL,
    prix_max        NUMERIC(12, 2)  NOT NULL,
    prix_moyen      NUMERIC(12, 2)  NOT NULL,
    nb_saisies      INT             NOT NULL DEFAULT 0 CHECK (nb_saisies >= 0),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_historique            PRIMARY KEY (id),
    CONSTRAINT uq_historique_jour       UNIQUE  (produit_id, marche_id, date_jour),
    CONSTRAINT ck_historique_min_max    CHECK   (prix_min <= prix_max),
    CONSTRAINT ck_historique_moyen      CHECK   (prix_moyen >= prix_min AND prix_moyen <= prix_max),
    CONSTRAINT fk_historique_produit    FOREIGN KEY (produit_id)
        REFERENCES produit(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_historique_marche     FOREIGN KEY (marche_id)
        REFERENCES marche(id)  ON UPDATE CASCADE ON DELETE CASCADE
);

COMMENT ON TABLE  historique_prix           IS 'Agrégats journaliers de prix par produit et par marché';
COMMENT ON COLUMN historique_prix.date_jour IS 'Date de l''agrégat (un seul enregistrement par produit+marché+jour)';

CREATE INDEX IF NOT EXISTS idx_historique_produit_marche ON historique_prix (produit_id, marche_id);
CREATE INDEX IF NOT EXISTS idx_historique_date           ON historique_prix (date_jour);
-- Index composite pour les requêtes de tendance sur fenêtre glissante
CREATE INDEX IF NOT EXISTS idx_historique_tendance       ON historique_prix (produit_id, marche_id, date_jour);


-- ---------------------------------------------------------------
-- 9. TABLE : prevision
--    Paquetage UML : prix / algorithmes
--    Résultat du calcul prédictif (moyenne mobile pondérée / DP).
--    valeurs_prevues stocké en JSONB (plus performant que JSON en PG).
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS prevision (
    id              UUID                    NOT NULL DEFAULT uuid_generate_v4(),
    produit_id      UUID                    NOT NULL,
    marche_id       UUID                    NOT NULL,
    date_calcul     TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    horizon_jours   INT                     NOT NULL DEFAULT 30 CHECK (horizon_jours > 0),
    methode         t_methode_prevision     NOT NULL DEFAULT 'MOYENNE_MOBILE_PONDEREE',
    -- JSONB : plus performant que JSON, supporte les index GIN
    -- Format : [{"date": "2025-07-01", "valeur": 1200.00}, ...]
    valeurs_prevues JSONB                   NOT NULL,
    erreur_mape     NUMERIC(6, 2),          -- Mean Absolute Percentage Error
    created_at      TIMESTAMPTZ             NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_prevision         PRIMARY KEY (id),
    CONSTRAINT fk_prevision_produit FOREIGN KEY (produit_id)
        REFERENCES produit(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_prevision_marche  FOREIGN KEY (marche_id)
        REFERENCES marche(id)  ON UPDATE CASCADE ON DELETE CASCADE
);

COMMENT ON TABLE  prevision                 IS 'Prévisions d''évolution des prix calculées par l''algorithme DP';
COMMENT ON COLUMN prevision.valeurs_prevues IS 'Série JSON : [{"date":"YYYY-MM-DD","valeur":0.00},...]';
COMMENT ON COLUMN prevision.erreur_mape     IS 'Erreur MAPE (%) — qualité de la prévision';

CREATE INDEX IF NOT EXISTS idx_prevision_produit_marche ON prevision (produit_id, marche_id);
CREATE INDEX IF NOT EXISTS idx_prevision_date           ON prevision (date_calcul);
-- Index GIN pour interroger le JSONB (ex: filtrer par date de prévision)
CREATE INDEX IF NOT EXISTS idx_prevision_jsonb          ON prevision USING GIN (valeurs_prevues);


-- ---------------------------------------------------------------
-- 10. TABLE : file_synchronisation
--     Paquetage UML : infrastructure
--     File FIFO pour les saisies hors-ligne en attente d'envoi.
--     ordre_envoi utilise BIGSERIAL (PostgreSQL) au lieu de
--     AUTO_INCREMENT MySQL — BIGSERIAL est une vraie séquence.
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS file_synchronisation (
    -- ordre_envoi est la clé primaire FIFO (BIGSERIAL = BIGINT + SEQUENCE)
    ordre_envoi     BIGSERIAL               NOT NULL,
    id              UUID                    NOT NULL DEFAULT uuid_generate_v4(),
    utilisateur_id  UUID                    NOT NULL,
    -- UUID de la saisie générée hors-ligne côté mobile (SQLite)
    saisie_prix_id  UUID                    NOT NULL,
    -- Données complètes sérialisées pour reconstruction côté serveur
    payload         JSONB                   NOT NULL,
    statut          t_statut_sync           NOT NULL DEFAULT 'EN_ATTENTE',
    nb_tentatives   INT                     NOT NULL DEFAULT 0 CHECK (nb_tentatives >= 0),
    date_creation   TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    date_envoi      TIMESTAMPTZ,

    CONSTRAINT pk_file_sync         PRIMARY KEY (ordre_envoi),
    CONSTRAINT uq_file_sync_id      UNIQUE      (id),
    CONSTRAINT uq_saisie_ref        UNIQUE      (saisie_prix_id),
    CONSTRAINT fk_file_utilisateur  FOREIGN KEY (utilisateur_id)
        REFERENCES utilisateur(id) ON UPDATE CASCADE ON DELETE CASCADE
);

COMMENT ON TABLE  file_synchronisation              IS 'File FIFO de synchronisation hors-ligne';
COMMENT ON COLUMN file_synchronisation.ordre_envoi  IS 'Clé FIFO — BIGSERIAL garantit l''ordre d''insertion';
COMMENT ON COLUMN file_synchronisation.payload      IS 'Saisie complète sérialisée en JSONB pour replay';

CREATE INDEX IF NOT EXISTS idx_file_statut      ON file_synchronisation (statut);
CREATE INDEX IF NOT EXISTS idx_file_utilisateur ON file_synchronisation (utilisateur_id);
-- Index partiel : uniquement les entrées non encore envoyées (très sélectif)
CREATE INDEX IF NOT EXISTS idx_file_en_attente
    ON file_synchronisation (ordre_envoi)
    WHERE statut = 'EN_ATTENTE';


-- ---------------------------------------------------------------
-- 11. TABLE : session_jwt
--     Paquetage UML : infrastructure
--     Blacklist des tokens JWT pour la révocation (Node.js).
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS session_jwt (
    id              UUID        NOT NULL DEFAULT uuid_generate_v4(),
    utilisateur_id  UUID        NOT NULL,
    jti             VARCHAR(255) NOT NULL,  -- JWT ID (claim "jti")
    date_expiration TIMESTAMPTZ NOT NULL,
    est_revoque     BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_session_jwt           PRIMARY KEY (id),
    CONSTRAINT uq_session_jti           UNIQUE      (jti),
    CONSTRAINT fk_session_utilisateur   FOREIGN KEY (utilisateur_id)
        REFERENCES utilisateur(id) ON UPDATE CASCADE ON DELETE CASCADE
);

COMMENT ON TABLE  session_jwt               IS 'Blacklist JWT pour la révocation de tokens';
COMMENT ON COLUMN session_jwt.jti           IS 'JWT ID unique (claim jti du token)';
COMMENT ON COLUMN session_jwt.est_revoque   IS 'TRUE = token invalidé avant expiration';

CREATE INDEX IF NOT EXISTS idx_session_utilisateur  ON session_jwt (utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_session_expiration   ON session_jwt (date_expiration);
-- Index partiel sur les tokens révoqués (lookup fréquent dans le middleware Auth)
CREATE INDEX IF NOT EXISTS idx_session_revoque
    ON session_jwt (jti)
    WHERE est_revoque = TRUE;


-- =============================================================
-- FONCTION updated_at AUTOMATIQUE
-- PostgreSQL ne supporte pas ON UPDATE CURRENT_TIMESTAMP de MySQL.
-- On utilise un trigger générique attaché à chaque table.
-- =============================================================

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION fn_set_updated_at IS 'Trigger générique : met à jour updated_at avant chaque UPDATE';

-- Attacher le trigger à toutes les tables ayant updated_at
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'categorie_produit',
        'produit',
        'marche',
        'itineraire_marche',
        'utilisateur',
        'saisie_prix',
        'historique_prix',
        'file_synchronisation'
    ]
    LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_set_updated_at ON %I;
             CREATE TRIGGER trg_set_updated_at
             BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();',
            t, t
        );
    END LOOP;
END;
$$;


-- =============================================================
-- TRIGGER : mise à jour automatique de l'historique
-- Déclenché après chaque passage d'une saisie au statut SYNCHRONISEE
-- Correspond au trigger trg_after_saisie_sync du diagramme UML
-- =============================================================

CREATE OR REPLACE FUNCTION fn_maj_historique_apres_sync()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
BEGIN
    -- Seulement si la saisie vient de passer à SYNCHRONISEE
    IF NEW.statut = 'SYNCHRONISEE' AND OLD.statut <> 'SYNCHRONISEE' THEN
        INSERT INTO historique_prix
            (id, produit_id, marche_id, date_jour,
             prix_min, prix_max, prix_moyen, nb_saisies)
        SELECT
            uuid_generate_v4(),
            NEW.produit_id,
            NEW.marche_id,
            NEW.date_saisie::DATE,
            MIN(valeur),
            MAX(valeur),
            ROUND(AVG(valeur), 2),
            COUNT(*)
        FROM saisie_prix
        WHERE produit_id = NEW.produit_id
          AND marche_id  = NEW.marche_id
          AND date_saisie::DATE = NEW.date_saisie::DATE
          AND statut = 'SYNCHRONISEE'
        -- INSERT … ON CONFLICT : upsert PostgreSQL (équivalent ON DUPLICATE KEY MySQL)
        ON CONFLICT (produit_id, marche_id, date_jour)
        DO UPDATE SET
            prix_min   = EXCLUDED.prix_min,
            prix_max   = EXCLUDED.prix_max,
            prix_moyen = EXCLUDED.prix_moyen,
            nb_saisies = EXCLUDED.nb_saisies,
            updated_at = NOW();
    END IF;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION fn_maj_historique_apres_sync IS
    'Recalcule l''agrégat journalier dans historique_prix dès qu''une saisie est synchronisée';

DROP TRIGGER IF EXISTS trg_after_saisie_sync ON saisie_prix;
CREATE TRIGGER trg_after_saisie_sync
AFTER UPDATE OF statut ON saisie_prix
FOR EACH ROW
EXECUTE FUNCTION fn_maj_historique_apres_sync();


-- =============================================================
-- VUES
-- =============================================================

-- Vue : dernier prix validé par produit et par marché
CREATE OR REPLACE VIEW v_prix_actuel AS
SELECT DISTINCT ON (sp.produit_id, sp.marche_id)
    sp.produit_id,
    p.nom_fr        AS produit_nom_fr,
    p.nom_mg        AS produit_nom_mg,
    p.unite,
    sp.marche_id,
    m.nom           AS marche_nom,
    m.ville,
    sp.valeur       AS prix_actuel,
    sp.date_saisie  AS date_prix
FROM saisie_prix sp
JOIN produit p ON p.id = sp.produit_id
JOIN marche  m ON m.id = sp.marche_id
WHERE sp.statut = 'SYNCHRONISEE'
-- DISTINCT ON + ORDER BY = requête de "dernière valeur par groupe" idiomatique PostgreSQL
ORDER BY sp.produit_id, sp.marche_id, sp.date_saisie DESC;

COMMENT ON VIEW v_prix_actuel IS 'Dernier prix synchronisé par produit et par marché';


-- Vue : tendance sur les 30 derniers jours
CREATE OR REPLACE VIEW v_tendance_30j AS
SELECT
    h.produit_id,
    p.nom_fr        AS produit_nom_fr,
    h.marche_id,
    m.nom           AS marche_nom,
    h.date_jour,
    h.prix_min,
    h.prix_max,
    h.prix_moyen,
    h.nb_saisies
FROM historique_prix h
JOIN produit p ON p.id = h.produit_id
JOIN marche  m ON m.id = h.marche_id
WHERE h.date_jour >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY h.produit_id, h.marche_id, h.date_jour;

COMMENT ON VIEW v_tendance_30j IS 'Agrégats journaliers des 30 derniers jours';


-- Vue : marché le moins cher par produit
CREATE OR REPLACE VIEW v_marche_moins_cher AS
SELECT DISTINCT ON (pa.produit_id)
    pa.produit_id,
    pa.produit_nom_fr,
    pa.marche_id,
    pa.marche_nom,
    pa.ville,
    pa.prix_actuel
FROM v_prix_actuel pa
ORDER BY pa.produit_id, pa.prix_actuel ASC;

COMMENT ON VIEW v_marche_moins_cher IS 'Marché proposant le prix le plus bas pour chaque produit';


-- =============================================================
-- FONCTIONS MÉTIER (remplacent les procédures stockées MySQL)
-- PostgreSQL utilise des FUNCTION avec RETURNS VOID plutôt que
-- des PROCEDURE quand il n'y a pas de gestion de transaction propre.
-- =============================================================

-- Fonction : Traiter un batch de la file de synchronisation (50 entrées FIFO)
CREATE OR REPLACE FUNCTION fn_traiter_file_sync()
RETURNS INT
LANGUAGE plpgsql AS
$$
DECLARE
    nb_traites INT;
BEGIN
    -- Sélectionner les 50 premières entrées EN_ATTENTE dans l'ordre FIFO
    -- et les passer EN_COURS de façon atomique (FOR UPDATE SKIP LOCKED
    -- évite les deadlocks en environnement concurrent Node.js)
    WITH batch AS (
        SELECT ordre_envoi
        FROM file_synchronisation
        WHERE statut = 'EN_ATTENTE'
        ORDER BY ordre_envoi ASC
        LIMIT 50
        FOR UPDATE SKIP LOCKED
    )
    UPDATE file_synchronisation fs
    SET statut = 'EN_COURS'
    FROM batch
    WHERE fs.ordre_envoi = batch.ordre_envoi;

    GET DIAGNOSTICS nb_traites = ROW_COUNT;
    RETURN nb_traites;
END;
$$;

COMMENT ON FUNCTION fn_traiter_file_sync IS
    'Passe 50 entrées EN_ATTENTE à EN_COURS — FOR UPDATE SKIP LOCKED pour sécurité concurrentielle';


-- Fonction : Recalcul manuel de l'historique pour un produit/marché/jour donné
-- Utile pour la reprise après incident ou import en masse
CREATE OR REPLACE FUNCTION fn_recalculer_historique(
    p_produit_id    UUID,
    p_marche_id     UUID,
    p_date_jour     DATE
)
RETURNS VOID
LANGUAGE plpgsql AS
$$
BEGIN
    INSERT INTO historique_prix
        (id, produit_id, marche_id, date_jour,
         prix_min, prix_max, prix_moyen, nb_saisies)
    SELECT
        uuid_generate_v4(),
        p_produit_id,
        p_marche_id,
        p_date_jour,
        MIN(valeur),
        MAX(valeur),
        ROUND(AVG(valeur), 2),
        COUNT(*)
    FROM saisie_prix
    WHERE produit_id          = p_produit_id
      AND marche_id           = p_marche_id
      AND date_saisie::DATE   = p_date_jour
      AND statut              = 'SYNCHRONISEE'
    ON CONFLICT (produit_id, marche_id, date_jour)
    DO UPDATE SET
        prix_min   = EXCLUDED.prix_min,
        prix_max   = EXCLUDED.prix_max,
        prix_moyen = EXCLUDED.prix_moyen,
        nb_saisies = EXCLUDED.nb_saisies,
        updated_at = NOW();
END;
$$;

COMMENT ON FUNCTION fn_recalculer_historique IS
    'Upsert de l''agrégat journalier — utilisable pour import en masse ou reprise après incident';


-- =============================================================
-- DONNÉES D'INITIALISATION (données de référence)
-- =============================================================

-- Catégories de produits (bilingue FR/MG) — alignées avec seed.sql
INSERT INTO categorie_produit (id, libelle_fr, libelle_mg) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Céréales',             'Vary sy katsaka'),
    ('a0000000-0000-0000-0000-000000000002', 'Légumes',              'Anana'),
    ('a0000000-0000-0000-0000-000000000003', 'Fruits',               'Voankazo'),
    ('a0000000-0000-0000-0000-000000000004', 'Viandes',              'Hena'),
    ('a0000000-0000-0000-0000-000000000005', 'Poissons',             'Trondro'),
    ('a0000000-0000-0000-0000-000000000006', 'Produits laitiers',    'Ronono'),
    ('a0000000-0000-0000-0000-000000000007', 'Épices',               'Pitraspitra'),
    ('a0000000-0000-0000-0000-000000000008', 'Produits transformés', 'Vokatra miova')
ON CONFLICT (libelle_fr) DO NOTHING;

-- Marchés principaux avec coordonnées GPS réelles
INSERT INTO marche (id, nom, ville, latitude, longitude) VALUES
    ('b0000000-0000-0000-0000-000000000001', 'Analakely',     'Antananarivo', -18.9137,  47.5361),
    ('b0000000-0000-0000-0000-000000000002', 'Anosibe',       'Antananarivo', -18.9226,  47.5290),
    ('b0000000-0000-0000-0000-000000000003', 'Andravoahangy', 'Antananarivo', -18.9014,  47.5418),
    ('b0000000-0000-0000-0000-000000000004', 'Isotry',        'Antananarivo', -18.9190,  47.5180),
    ('b0000000-0000-0000-0000-000000000005', 'Bazar Kely',    'Toamasina',    -18.1443,  49.3917),
    ('b0000000-0000-0000-0000-000000000006', 'Anjoma',        'Fianarantsoa', -21.4522,  47.0860)
ON CONFLICT (nom, ville) DO NOTHING;

-- Administrateur système (mot de passe à changer — placeholder bcrypt)
INSERT INTO utilisateur (id, nom, email, mot_de_passe, role, langue)
VALUES (
    uuid_generate_v4(),
    'Administrateur Système',
    'admin@meilleurprix.mg',
    '$2b$12$PLACEHOLDER_HASH_A_REMPLACER_PAR_NODE',
    'ADMINISTRATEUR',
    'FR'
)
ON CONFLICT (email) DO NOTHING;


-- =============================================================
-- FIN DU SCRIPT
-- Version   : 2.0 — PostgreSQL — Projet Meilleur Prix — L2 SIO ESMIA
-- Testé sur : PostgreSQL 16
-- =============================================================