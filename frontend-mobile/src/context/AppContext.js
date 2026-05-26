import { createContext, useContext, useEffect, useState } from 'react';
import { Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import translations from '../utils/i18n';

let SQLite;
if (Platform.OS !== 'web') {
  const sqlitePackage = 'expo-sqlite';
  SQLite = require(sqlitePackage);
}

// Context Langue
const LanguageContext = createContext(null);

export function LanguageProvider({ children }) {
  const [langue, setLangue] = useState('FR');

  useEffect(() => {
    (async () => {
      const saved = await AsyncStorage.getItem('mp_langue');
      if (saved) setLangue(saved);
    })();
  }, []);

  const changeLangue = async (newLang) => {
    await AsyncStorage.setItem('mp_langue', newLang);
    setLangue(newLang);
  };

  const t = (key) => translations[langue]?.[key] || key;

  return (
    <LanguageContext.Provider value={{ langue, changeLangue, t }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  const context = useContext(LanguageContext);
  if (!context) throw new Error('useLanguage hors du LanguageProvider');
  return context;
}

// Context Offline (SQLite + Queue)
const OfflineContext = createContext(null);

export function OfflineProvider({ children }) {
  const [db, setDb] = useState(null);
  const [queue, setQueue] = useState([]);
  const [isOnline, setIsOnline] = useState(true);

  // Initialiser la BD hors-ligne (SQLite)
  useEffect(() => {
    if (!SQLite) return;

    (async () => {
      try {
        const database = await SQLite.openDatabaseAsync('meilleur_prix.db');
        
        // Créer les tables
        await database.execAsync(`
          CREATE TABLE IF NOT EXISTS saisie_locale (
            id TEXT PRIMARY KEY,
            produit_id TEXT,
            produit_nom TEXT,
            marche_id TEXT,
            marche_nom TEXT,
            valeur REAL,
            unite TEXT,
            date_saisie TEXT,
            created_at TEXT,
            statut TEXT DEFAULT 'EN_ATTENTE',
            erreur_message TEXT
          );

          CREATE TABLE IF NOT EXISTS produit_cache (
            id TEXT PRIMARY KEY,
            nom_fr TEXT,
            nom_mg TEXT,
            categorie_id TEXT,
            unite TEXT
          );

          CREATE TABLE IF NOT EXISTS marche_cache (
            id TEXT PRIMARY KEY,
            nom TEXT,
            ville TEXT,
            latitude REAL,
            longitude REAL
          );

          CREATE TABLE IF NOT EXISTS prix_cache (
            id TEXT PRIMARY KEY,
            produit_id TEXT,
            marche_id TEXT,
            prix REAL,
            date_jour TEXT
          );
        `);

        setDb(database);
        await loadQueue(database);
      } catch (err) {
        console.error('Erreur SQLite:', err);
      }
    })();
  }, []);

  // Charger la queue du stockage persistant
  const loadQueue = async (database) => {
    try {
      const results = await database.getAllAsync(
        'SELECT * FROM saisie_locale WHERE statut != ?',
        ['SYNCHRONISEE']
      );
      setQueue(results || []);
    } catch (err) {
      console.error('Erreur chargement queue:', err);
    }
  };

  // Ajouter une saisie à la queue hors-ligne
  const addToQueue = async (saisie) => {
    if (!db) return false;
    
    try {
      const id = `${Date.now()}-${Math.random()}`;
      await db.runAsync(
        `INSERT INTO saisie_locale 
        (id, produit_id, produit_nom, marche_id, marche_nom, valeur, unite, date_saisie, created_at, statut)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          id,
          saisie.produit_id,
          saisie.produit_nom,
          saisie.marche_id,
          saisie.marche_nom,
          saisie.valeur,
          saisie.unite,
          saisie.date_saisie || new Date().toISOString().split('T')[0],
          new Date().toISOString(),
          isOnline ? 'EN_ATTENTE' : 'EN_ATTENTE'
        ]
      );

      await loadQueue(db);
      return true;
    } catch (err) {
      console.error('Erreur ajout queue:', err);
      return false;
    }
  };

  // Marquer comme synchronisée
  const markSynced = async (saisieId) => {
    if (!db) return;
    try {
      await db.runAsync(
        'UPDATE saisie_locale SET statut = ? WHERE id = ?',
        ['SYNCHRONISEE', saisieId]
      );
      await loadQueue(db);
    } catch (err) {
      console.error('Erreur marquer synced:', err);
    }
  };

  // Marquer comme échouée
  const markFailed = async (saisieId, erreur) => {
    if (!db) return;
    try {
      await db.runAsync(
        'UPDATE saisie_locale SET statut = ?, erreur_message = ? WHERE id = ?',
        ['REJETEE', erreur, saisieId]
      );
      await loadQueue(db);
    } catch (err) {
      console.error('Erreur marquer failed:', err);
    }
  };

  // Mettre en cache les produits
  const cacheProducts = async (products) => {
    if (!db) return;
    try {
      for (const p of products) {
        await db.runAsync(
          `INSERT OR REPLACE INTO produit_cache 
          (id, nom_fr, nom_mg, categorie_id, unite)
          VALUES (?, ?, ?, ?, ?)`,
          [p.id, p.nom_fr, p.nom_mg, p.categorie_id, p.unite]
        );
      }
    } catch (err) {
      console.error('Erreur cache produits:', err);
    }
  };

  // Mettre en cache les marchés
  const cacheMarches = async (marches) => {
    if (!db) return;
    try {
      for (const m of marches) {
        await db.runAsync(
          `INSERT OR REPLACE INTO marche_cache 
          (id, nom, ville, latitude, longitude)
          VALUES (?, ?, ?, ?, ?)`,
          [m.id, m.nom, m.ville, m.latitude, m.longitude]
        );
      }
    } catch (err) {
      console.error('Erreur cache marchés:', err);
    }
  };

  // Récupérer les produits en cache
  const getCachedProducts = async () => {
    if (!db) return [];
    try {
      return await db.getAllAsync('SELECT * FROM produit_cache');
    } catch (err) {
      console.error('Erreur récup produits cache:', err);
      return [];
    }
  };

  // Récupérer les marchés en cache
  const getCachedMarches = async () => {
    if (!db) return [];
    try {
      return await db.getAllAsync('SELECT * FROM marche_cache');
    } catch (err) {
      console.error('Erreur récup marchés cache:', err);
      return [];
    }
  };

  return (
    <OfflineContext.Provider
      value={{
        db,
        queue,
        isOnline,
        setIsOnline,
        addToQueue,
        markSynced,
        markFailed,
        cacheProducts,
        cacheMarches,
        getCachedProducts,
        getCachedMarches,
        loadQueue
      }}
    >
      {children}
    </OfflineContext.Provider>
  );
}

export function useOffline() {
  const context = useContext(OfflineContext);
  if (!context) throw new Error('useOffline hors du OfflineProvider');
  return context;
}
