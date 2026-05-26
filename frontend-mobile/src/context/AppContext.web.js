import { createContext, useContext, useEffect, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import translations from '../utils/i18n';

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

const OfflineContext = createContext(null);

const STORAGE_KEYS = {
  QUEUE: 'mp_saisie_locale_queue',
  PRODUIT_CACHE: 'mp_produit_cache',
  MARCHE_CACHE: 'mp_marche_cache'
};

export function OfflineProvider({ children }) {
  const [queue, setQueue] = useState([]);
  const [isOnline, setIsOnline] = useState(true);

  useEffect(() => {
    loadQueue();
  }, []);

  const saveQueue = async (nextQueue) => {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.QUEUE, JSON.stringify(nextQueue));
      setQueue(nextQueue);
    } catch (err) {
      console.error('Erreur sauvegarde queue:', err);
    }
  };

  const loadQueue = async () => {
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEYS.QUEUE);
      setQueue(raw ? JSON.parse(raw) : []);
    } catch (err) {
      console.error('Erreur chargement queue:', err);
      setQueue([]);
    }
  };

  const addToQueue = async (saisie) => {
    try {
      const id = `${Date.now()}-${Math.random()}`;
      const nextQueue = [
        ...queue,
        {
          id,
          produit_id: saisie.produit_id,
          produit_nom: saisie.produit_nom,
          marche_id: saisie.marche_id,
          marche_nom: saisie.marche_nom,
          valeur: saisie.valeur,
          unite: saisie.unite,
          date_saisie: saisie.date_saisie || new Date().toISOString().split('T')[0],
          created_at: new Date().toISOString(),
          statut: 'EN_ATTENTE',
          erreur_message: null
        }
      ];
      await saveQueue(nextQueue);
      return true;
    } catch (err) {
      console.error('Erreur ajout queue:', err);
      return false;
    }
  };

  const markSynced = async (saisieId) => {
    try {
      const nextQueue = queue.map((item) =>
        item.id === saisieId ? { ...item, statut: 'SYNCHRONISEE' } : item
      );
      await saveQueue(nextQueue);
    } catch (err) {
      console.error('Erreur marquer synced:', err);
    }
  };

  const markFailed = async (saisieId, erreur) => {
    try {
      const nextQueue = queue.map((item) =>
        item.id === saisieId
          ? { ...item, statut: 'REJETEE', erreur_message: erreur }
          : item
      );
      await saveQueue(nextQueue);
    } catch (err) {
      console.error('Erreur marquer failed:', err);
    }
  };

  const cacheProducts = async (products) => {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.PRODUIT_CACHE, JSON.stringify(products));
    } catch (err) {
      console.error('Erreur cache produits:', err);
    }
  };

  const cacheMarches = async (marches) => {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.MARCHE_CACHE, JSON.stringify(marches));
    } catch (err) {
      console.error('Erreur cache marchés:', err);
    }
  };

  const getCachedProducts = async () => {
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEYS.PRODUIT_CACHE);
      return raw ? JSON.parse(raw) : [];
    } catch (err) {
      console.error('Erreur récup produits cache:', err);
      return [];
    }
  };

  const getCachedMarches = async () => {
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEYS.MARCHE_CACHE);
      return raw ? JSON.parse(raw) : [];
    } catch (err) {
      console.error('Erreur récup marchés cache:', err);
      return [];
    }
  };

  return (
    <OfflineContext.Provider
      value={{
        db: null,
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
