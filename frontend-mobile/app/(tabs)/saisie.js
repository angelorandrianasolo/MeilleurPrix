import { useEffect, useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet,
  Alert, ScrollView, ActivityIndicator
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Picker } from '@react-native-picker/picker';
import { PrixAPI, MarchesAPI, ProduitsAPI } from '../../src/services/api';
import { useLanguage, useOffline } from '../../src/context';
import { syncOfflineQueue } from '../../src/services/syncService';
import { COLORS, SPACING, FONT, RADIUS } from '../../src/utils/theme';

export default function SaisieScreen() {
  const { t } = useLanguage();
  const { queue, addToQueue, markSynced, markFailed, isOnline } = useOffline();
  const [produitId, setProduitId] = useState('');
  const [produitNom, setProduitNom] = useState('');
  const [marcheId, setMarcheId] = useState('');
  const [marcheNom, setMarcheNom] = useState('');
  const [prix, setPrix] = useState('');
  const [unite, setUnite] = useState('kg');
  const [produits, setProduits] = useState([]);
  const [marches, setMarches] = useState([]);
  const [loading, setLoading] = useState(false);

  const pendingCount = queue.filter(s => s.statut !== 'SYNCHRONISEE').length;

  useEffect(() => {
    (async () => {
      try {
        const [pRes, mRes] = await Promise.all([
          ProduitsAPI.list(),
          MarchesAPI.list()
        ]);
        setProduits(pRes.data || []);
        setMarches(mRes.data || []);
        const saved = await AsyncStorage.getItem('mp_produit');
        if (saved) {
          const parsed = JSON.parse(saved);
          setProduitId(parsed.id);
          setProduitNom(parsed.nom_fr || parsed.nom_mg || '');
        }
        if (pRes.data?.[0] && !produitId) {
          setProduitId(pRes.data[0].id);
          setProduitNom(pRes.data[0].nom_fr || pRes.data[0].nom_mg || '');
        }
        if (mRes.data?.[0]) {
          setMarcheId(mRes.data[0].id);
          setMarcheNom(mRes.data[0].nom);
        }
      } catch { /* offline */ }
    })();
  }, []);

  const enregistrer = async () => {
    const montant = parseFloat(prix);
    if (!produitId || !marcheId || !montant || montant <= 0) {
      Alert.alert('Erreur', 'Produit, marche et prix positif requis.');
      return;
    }

    const payload = {
      produit_id: produitId,
      produit_nom: produitNom,
      marche_id: marcheId,
      marche_nom: marcheNom,
      valeur: montant,
      unite,
      date_saisie: new Date().toISOString().split('T')[0]
    };

    setLoading(true);
    try {
      await PrixAPI.create({ ...payload, prix: montant, source_saisie: 'MOBILE' });
      Alert.alert('Succes', 'Prix synchronise.');
      setPrix('');
    } catch {
      await addToQueue(payload);
      const n = queue.filter(s => s.statut !== 'SYNCHRONISEE').length + 1;
      Alert.alert(
        'Hors-ligne',
        `Saisie mise en file (${n} en attente). Synchronisez quand le reseau revient.`
      );
      setPrix('');
    } finally {
      setLoading(false);
    }
  };

  const synchroniser = async () => {
    setLoading(true);
    try {
      const token = await AsyncStorage.getItem('mp_token');
      const results = await syncOfflineQueue(queue, token, { markSynced, markFailed });
      Alert.alert('Sync', `${results.synced} saisie(s) envoyee(s), ${results.failed} echec(s).`);
    } catch (err) {
      Alert.alert('Sync', err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ padding: SPACING.md }}>
      <Text style={styles.badge}>{pendingCount} en attente (FIFO)</Text>
      <Text style={styles.label}>{t('product') || 'Produit'}</Text>
      <View style={styles.pickerWrap}>
        <Picker selectedValue={produitId} onValueChange={(val) => {
          setProduitId(val);
          const p = produits.find(x => x.id === val);
          if (p) setProduitNom(p.nom_fr || p.nom_mg || '');
        }}>
          {produits.map((p) => (
            <Picker.Item key={p.id} label={`${p.nom_fr || p.nom_mg || p.id}`} value={p.id} />
          ))}
        </Picker>
      </View>
      <Text style={styles.label}>{t('market') || 'Marche'}</Text>
      <View style={styles.pickerWrap}>
        <Picker selectedValue={marcheId} onValueChange={(val) => {
          setMarcheId(val);
          const m = marches.find(x => x.id === val);
          if (m) setMarcheNom(m.nom);
        }}>
          {marches.map((m) => (
            <Picker.Item key={m.id} label={`${m.nom} (${m.ville})`} value={m.id} />
          ))}
        </Picker>
      </View>
      <Text style={styles.label}>Prix (Ar)</Text>
      <TextInput style={styles.input} value={prix} onChangeText={setPrix} keyboardType="decimal-pad" />
      <Text style={styles.label}>Unite</Text>
      <TextInput style={styles.input} value={unite} onChangeText={setUnite} />
      <TouchableOpacity style={styles.btn} onPress={enregistrer} disabled={loading}>
        {loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.btnText}>Enregistrer</Text>}
      </TouchableOpacity>
      {pendingCount > 0 && (
        <TouchableOpacity style={[styles.btn, styles.btnSec]} onPress={synchroniser}>
          <Text style={styles.btnTextSec}>Synchroniser ({pendingCount})</Text>
        </TouchableOpacity>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.bg },
  badge: { backgroundColor: '#FEF3C7', padding: SPACING.sm, borderRadius: RADIUS.sm, marginBottom: SPACING.md, textAlign: 'center' },
  label: { fontWeight: '600', marginBottom: SPACING.xs },
  input: { borderWidth: 1.5, borderColor: COLORS.border, borderRadius: RADIUS.md, padding: SPACING.md, backgroundColor: '#fff', marginBottom: SPACING.md },
  pickerWrap: { borderWidth: 1.5, borderColor: COLORS.border, borderRadius: RADIUS.md, marginBottom: SPACING.md, backgroundColor: '#fff' },
  btn: { backgroundColor: COLORS.primary, padding: SPACING.md, borderRadius: RADIUS.md, alignItems: 'center', marginBottom: SPACING.sm },
  btnSec: { backgroundColor: 'transparent', borderWidth: 2, borderColor: COLORS.primary },
  btnText: { color: '#fff', fontWeight: '700' },
  btnTextSec: { color: COLORS.primary, fontWeight: '700' }
});
