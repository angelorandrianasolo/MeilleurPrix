import { AuthAPI, PrixAPI, API_BASE } from './api';

/**
 * Service de synchronisation hors-ligne
 * Gère la file FIFO de saisies en attente
 */

export async function syncOfflineQueue(queue, token, offline) {
  if (!queue || queue.length === 0) return { synced: 0, failed: 0 };

  const results = {
    synced: 0,
    failed: 0,
    errors: []
  };

  for (const saisie of queue) {
    if (saisie.statut === 'SYNCHRONISEE') continue;

    try {
      // Envoyer au serveur
      const response = await PrixAPI.create({
        produit_id: saisie.produit_id,
        marche_id: saisie.marche_id,
        valeur: saisie.valeur,
        unite: saisie.unite,
        date_saisie: saisie.date_saisie,
        source_saisie: 'MOBILE'
      });

      if (response.success) {
        // Marquer comme synchronisée
        await offline.markSynced(saisie.id);
        results.synced++;
      } else {
        // Marquer comme échouée
        await offline.markFailed(saisie.id, response.message || 'Erreur inconnue');
        results.failed++;
        results.errors.push({
          saisie_id: saisie.id,
          error: response.message
        });
      }
    } catch (err) {
      // Erreur réseau
      await offline.markFailed(saisie.id, err.message);
      results.failed++;
      results.errors.push({
        saisie_id: saisie.id,
        error: err.message
      });
    }
  }

  return results;
}

/**
 * Vérifier la connectivité réseau
 */
export async function checkConnectivity() {
  try {
    // Ping un endpoint de santé
    const response = await fetch(API_BASE.replace('/api/v1', '/health'), {
      method: 'GET'
    });
    return response.ok;
  } catch (err) {
    return false;
  }
}

/**
 * Mettre en cache les données principales
 */
export async function cacheMasterData(offline) {
  try {
    // Récupérer et mettre en cache les produits
    const produits = await fetch(`${API_BASE}/produits`).then(r => r.json());
    if (produits.success) {
      await offline.cacheProducts(produits.data);
    }

    // Récupérer et mettre en cache les marchés
    const marches = await fetch(`${API_BASE}/marches`).then(r => r.json());
    if (marches.success) {
      await offline.cacheMarches(marches.data);
    }

    return true;
  } catch (err) {
    console.error('Erreur caching données:', err);
    return false;
  }
}

/**
 * Formater une saisie pour l'affichage
 */
export function formatSaisie(saisie) {
  const statusLabels = {
    'EN_ATTENTE': '⏳ En attente',
    'SYNCHRONISEE': '✓ Synchronisé',
    'REJETEE': '✗ Rejeté'
  };

  return {
    ...saisie,
    status_label: statusLabels[saisie.statut] || saisie.statut,
    created_at_display: new Date(saisie.created_at).toLocaleDateString('fr-FR')
  };
}
