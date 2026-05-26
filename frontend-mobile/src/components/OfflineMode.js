import React, { useEffect, useState } from 'react';
import { View, Text, TouchableOpacity, ScrollView, StyleSheet, Alert } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useLanguage, useOffline } from '../context';
import { syncOfflineQueue, checkConnectivity } from '../services/syncService';
import { COLORS, SPACING, FONT, RADIUS } from '../utils/theme';

export function OfflineIndicator() {
  const { t } = useLanguage();
  const { isOnline, setIsOnline, queue } = useOffline();
  const [lastChecked, setLastChecked] = useState(Date.now());

  // Vérifier la connectivité toutes les 30 secondes
  useEffect(() => {
    const interval = setInterval(async () => {
      const online = await checkConnectivity();
      setIsOnline(online);
      setLastChecked(Date.now());
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  if (isOnline) return null;

  return (
    <View style={styles.container}>
      <Text style={styles.icon}>📡</Text>
      <View style={styles.content}>
        <Text style={styles.title}>{t('offline_mode')}</Text>
        <Text style={styles.subtitle}>
          {queue.length > 0
            ? `${queue.length} ${t('offline_pending')}`
            : t('offline_title')}
        </Text>
      </View>
    </View>
  );
}

export function OfflineQueueScreen() {
  const { t } = useLanguage();
  const { queue, markSynced, markFailed, isOnline, setIsOnline, loadQueue } = useOffline();
  const [syncing, setSyncing] = useState(false);
  const [syncResults, setSyncResults] = useState(null);

  const handleSync = async () => {
    setSyncing(true);
    try {
      const token = await AsyncStorage.getItem('mp_token');
      const results = await syncOfflineQueue(queue, token, { markSynced, markFailed });

      setSyncResults(results);
      await loadQueue();

      Alert.alert(
        t('offline_sync_now'),
        `${t('offline_synced')}: ${results.synced}\n${t('offline_failed')}: ${results.failed}`
      );
    } catch (err) {
      Alert.alert(t('error'), err.message);
    } finally {
      setSyncing(false);
    }
  };

  return (
    <ScrollView style={styles.screenContainer} contentContainerStyle={{ padding: SPACING.md }}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>{t('offline_title')}</Text>
        <Text style={styles.headerSubtitle}>
          {isOnline ? '🟢 En ligne' : '🔴 Hors ligne'}
        </Text>
      </View>

      {queue.length === 0 ? (
        <View style={styles.emptyState}>
          <Text style={styles.emptyIcon}>✓</Text>
          <Text style={styles.emptyText}>Aucune saisie en attente</Text>
        </View>
      ) : (
        <>
          <View style={styles.card}>
            <Text style={styles.cardTitle}>{t('offline_queue')}</Text>
            {queue.map((saisie, idx) => (
              <View key={saisie.id} style={[styles.queueItem, idx > 0 && styles.borderTop]}>
                <View style={styles.queueRow}>
                  <Text style={styles.queueProduct}>{saisie.produit_nom}</Text>
                  <Text style={[styles.queueStatus, getStatusStyle(saisie.statut)]}>
                    {getStatusLabel(saisie.statut, t)}
                  </Text>
                </View>
                <Text style={styles.queueDetails}>
                  {saisie.marche_nom} • {saisie.valeur} {saisie.unite}
                </Text>
                {saisie.erreur_message && (
                  <Text style={styles.errorMsg}>{saisie.erreur_message}</Text>
                )}
              </View>
            ))}
          </View>

          <TouchableOpacity
            style={[styles.syncBtn, syncing && styles.syncBtnDisabled]}
            onPress={handleSync}
            disabled={syncing || !isOnline}
          >
            <Text style={styles.syncBtnText}>
              {syncing ? '⏳ Synchronisation...' : '🔄 ' + t('offline_sync_now')}
            </Text>
          </TouchableOpacity>

          {syncResults && (
            <View style={styles.results}>
              <Text style={styles.resultsTitle}>Résultats</Text>
              <Text style={styles.resultsText}>✓ Synchronisés: {syncResults.synced}</Text>
              <Text style={styles.resultsText}>✗ Échoués: {syncResults.failed}</Text>
            </View>
          )}
        </>
      )}
    </ScrollView>
  );
}

function getStatusLabel(status, t) {
  const labels = {
    'EN_ATTENTE': '⏳ ' + t('offline_pending'),
    'SYNCHRONISEE': '✓ ' + t('offline_synced'),
    'REJETEE': '✗ ' + t('offline_failed')
  };
  return labels[status] || status;
}

function getStatusStyle(status) {
  switch (status) {
    case 'SYNCHRONISEE':
      return { color: COLORS.success };
    case 'REJETEE':
      return { color: COLORS.danger };
    default:
      return { color: COLORS.textMuted };
  }
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.danger,
    padding: SPACING.sm,
    borderRadius: RADIUS.sm
  },
  icon: { fontSize: 20, marginRight: SPACING.sm },
  content: { flex: 1 },
  title: { color: '#fff', fontWeight: '700', fontSize: FONT.sm },
  subtitle: { color: '#fff', fontSize: FONT.xs, marginTop: 2 },

  screenContainer: { flex: 1, backgroundColor: COLORS.bg },
  header: { marginBottom: SPACING.lg },
  headerTitle: { fontSize: FONT.xl, fontWeight: '800', color: COLORS.primary },
  headerSubtitle: { fontSize: FONT.sm, color: COLORS.textMuted, marginTop: 4 },

  card: {
    backgroundColor: COLORS.card,
    borderRadius: RADIUS.md,
    padding: SPACING.md,
    marginBottom: SPACING.md,
    borderWidth: 1,
    borderColor: COLORS.border
  },
  cardTitle: { fontWeight: '700', fontSize: FONT.base, marginBottom: SPACING.sm },

  queueItem: { paddingVertical: SPACING.sm },
  borderTop: { borderTopWidth: 1, borderTopColor: COLORS.border },
  queueRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  queueProduct: { fontWeight: '600', color: COLORS.text, fontSize: FONT.sm },
  queueStatus: { fontWeight: '600', fontSize: FONT.xs },
  queueDetails: { fontSize: FONT.xs, color: COLORS.textMuted, marginTop: 2 },
  errorMsg: { fontSize: FONT.xs, color: COLORS.danger, marginTop: 4, fontStyle: 'italic' },

  syncBtn: {
    backgroundColor: COLORS.primary,
    padding: SPACING.md,
    borderRadius: RADIUS.md,
    alignItems: 'center',
    marginBottom: SPACING.lg
  },
  syncBtnDisabled: { opacity: 0.5 },
  syncBtnText: { color: '#fff', fontWeight: '700', fontSize: FONT.base },

  results: {
    backgroundColor: '#f0fdf4',
    borderRadius: RADIUS.md,
    padding: SPACING.md,
    borderLeftWidth: 4,
    borderLeftColor: COLORS.success
  },
  resultsTitle: { fontWeight: '700', color: COLORS.text, marginBottom: SPACING.sm },
  resultsText: { color: COLORS.text, fontSize: FONT.sm, marginVertical: 2 },

  emptyState: { alignItems: 'center', justifyContent: 'center', paddingVertical: SPACING.xl },
  emptyIcon: { fontSize: 48, marginBottom: SPACING.md },
  emptyText: { color: COLORS.textMuted, fontSize: FONT.base }
});
