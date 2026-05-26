import { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ScrollView, Alert } from 'react-native';
import { PrevisionAPI } from '../../src/services/api';
import { COLORS, SPACING, FONT, RADIUS } from '../../src/utils/theme';

export default function PrevisionScreen() {
  const [produitId, setProduitId] = useState('');
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  const calculer = async () => {
    if (!produitId) {
      Alert.alert('Erreur', 'ID produit requis');
      return;
    }
    setLoading(true);
    try {
      const res = await PrevisionAPI.get(produitId);
      setResult(res.data);
    } catch (err) {
      Alert.alert('Erreur', err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ padding: SPACING.md }}>
      <Text style={styles.info}>Moyenne mobile ponderee + DP — prevision 30 jours</Text>
      <TextInput
        style={styles.input}
        placeholder="ID du produit"
        value={produitId}
        onChangeText={setProduitId}
      />
      <TouchableOpacity style={[styles.btn, loading && styles.btnDisabled]} onPress={calculer} disabled={loading}>
        <Text style={styles.btnText}>{loading ? 'Calcul...' : 'Calculer prevision'}</Text>
      </TouchableOpacity>

      {result && (
        <View style={styles.card}>
          {result.message ? (
            <Text style={styles.warning}>{result.message}</Text>
          ) : (
            <>
              <Text style={styles.title}>Previsions 30 jours</Text>
              <View style={styles.row}>
                <Text style={styles.label}>Methode simple:</Text>
                <Text style={styles.value}>{result.prevision_simple?.[0] || 'N/A'} Ar</Text>
              </View>
              <View style={styles.row}>
                <Text style={styles.label}>Optimisee (DP):</Text>
                <Text style={styles.value}>{result.prevision_optimisee?.[0] || 'N/A'} Ar</Text>
              </View>
              {result.comparaison && (
                <>
                  <View style={styles.divider} />
                  <Text style={styles.subtitle}>Comparaison des erreurs</Text>
                  <View style={styles.row}>
                    <Text style={styles.label}>Erreur simple:</Text>
                    <Text style={styles.value}>{result.comparaison.erreur_simple || 'N/A'} Ar</Text>
                  </View>
                  <View style={styles.row}>
                    <Text style={styles.label}>Erreur optimisee:</Text>
                    <Text style={styles.value}>{result.comparaison.erreur_optimisee || 'N/A'} Ar</Text>
                  </View>
                  <Text style={styles.reco}>
                    Recommande: {result.comparaison.methode_recommandee}
                  </Text>
                </>
              )}
              {result.historique && (
                <Text style={styles.histNote}>
                  Base: {result.historique.length} jours d'historique
                </Text>
              )}
            </>
          )}
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.bg },
  info: { color: COLORS.textMuted, marginBottom: SPACING.md, fontStyle: 'italic' },
  input: { borderWidth: 1.5, borderColor: COLORS.border, borderRadius: RADIUS.md, padding: SPACING.md, backgroundColor: '#fff', marginBottom: SPACING.md },
  btn: { backgroundColor: COLORS.primary, padding: SPACING.md, borderRadius: RADIUS.md, alignItems: 'center', marginBottom: SPACING.md },
  btnDisabled: { opacity: 0.6 },
  btnText: { color: '#fff', fontWeight: '700' },
  card: { backgroundColor: COLORS.card, padding: SPACING.md, borderRadius: RADIUS.md, borderWidth: 1, borderColor: COLORS.border },
  title: { fontWeight: '800', fontSize: FONT.md, marginBottom: SPACING.md, color: COLORS.primary },
  subtitle: { fontWeight: '700', fontSize: FONT.sm, marginBottom: SPACING.sm, marginTop: SPACING.sm },
  row: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: SPACING.sm, borderBottomWidth: 0.5, borderBottomColor: COLORS.border },
  label: { color: COLORS.textMuted, fontSize: FONT.sm },
  value: { fontWeight: '700', color: COLORS.text, fontSize: FONT.sm },
  divider: { height: 1, backgroundColor: COLORS.border, marginVertical: SPACING.md },
  warning: { color: COLORS.danger, fontWeight: '600' },
  reco: { color: COLORS.success, fontWeight: '700', marginTop: SPACING.sm, textAlign: 'center' },
  histNote: { color: COLORS.textMuted, fontSize: FONT.sm, textAlign: 'center', marginTop: SPACING.md }
});
