import { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ScrollView, Alert } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { PanierAPI } from '../../src/services/api';
import { COLORS, SPACING, FONT, RADIUS } from '../../src/utils/theme';

export default function PanierScreen() {
  const [budget, setBudget] = useState('50000');
  const [produitId, setProduitId] = useState('');
  const [importance, setImportance] = useState('3');
  const [result, setResult] = useState(null);

  const loadProduit = async () => {
    const saved = await AsyncStorage.getItem('mp_produit');
    if (saved) setProduitId(JSON.parse(saved).id);
  };

  const optimiser = async () => {
    if (!produitId) {
      Alert.alert('Erreur', 'Selectionnez un produit (ecran Recherche).');
      return;
    }
    try {
      const res = await PanierAPI.optimiser(parseFloat(budget), [{
        id_produit: produitId,
        importance: parseInt(importance, 10),
        quantite: 1
      }]);
      setResult(res.data);
    } catch (err) {
      Alert.alert('Panier', err.message);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ padding: SPACING.md }}>
      <Text style={styles.info}>Sac a dos 0/1 — programmation dynamique</Text>
      <TouchableOpacity onPress={loadProduit}>
        <Text style={styles.link}>Charger produit selectionne</Text>
      </TouchableOpacity>
      <TextInput style={styles.input} placeholder="Budget (Ar)" value={budget} onChangeText={setBudget} keyboardType="numeric" />
      <TextInput style={styles.input} placeholder="Produit ID" value={produitId} onChangeText={setProduitId} />
      <TextInput style={styles.input} placeholder="Importance 1-5" value={importance} onChangeText={setImportance} keyboardType="numeric" />
      <TouchableOpacity style={styles.btn} onPress={optimiser}>
        <Text style={styles.btnText}>Optimiser le panier</Text>
      </TouchableOpacity>
      {result && (
        <View style={styles.card}>
          <Text style={styles.title}>Solution optimisee</Text>
          <Text>Cout : {result.solution_optimisee?.cout_total} Ar</Text>
          <Text>Reste : {result.solution_optimisee?.budget_restant} Ar</Text>
          <Text style={styles.sub}>Naif : {result.solution_naive?.cout_total} Ar</Text>
          <Text>Economie : {result.economie_realisee} Ar ({result.temps_calcul_ms} ms)</Text>
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.bg },
  info: { color: COLORS.textMuted, marginBottom: SPACING.md },
  link: { color: COLORS.primary, marginBottom: SPACING.md },
  input: { borderWidth: 1.5, borderColor: COLORS.border, borderRadius: RADIUS.md, padding: SPACING.md, backgroundColor: '#fff', marginBottom: SPACING.md },
  btn: { backgroundColor: COLORS.primary, padding: SPACING.md, borderRadius: RADIUS.md, alignItems: 'center' },
  btnText: { color: '#fff', fontWeight: '700' },
  card: { marginTop: SPACING.lg, backgroundColor: COLORS.card, padding: SPACING.md, borderRadius: RADIUS.md },
  title: { fontWeight: '800', marginBottom: SPACING.sm },
  sub: { marginTop: SPACING.sm, color: COLORS.textMuted }
});
