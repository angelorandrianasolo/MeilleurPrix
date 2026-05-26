import { useEffect, useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ScrollView, Alert } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Picker } from '@react-native-picker/picker';
import { MarchesAPI } from '../../src/services/api';
import { COLORS, SPACING, FONT, RADIUS } from '../../src/utils/theme';
import { useLanguage } from '../../src/context';

export default function ComparerScreen() {
  const { t } = useLanguage();
  const [produitId, setProduitId] = useState('');
  const [departId, setDepartId] = useState('');
  const [marches, setMarches] = useState([]);
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    (async () => {
      const saved = await AsyncStorage.getItem('mp_produit');
      if (saved) setProduitId(JSON.parse(saved).id);
      const res = await MarchesAPI.list();
      setMarches(res.data || []);
      if (res.data?.[0]) setDepartId(res.data[0].id);
    })();
  }, []);

  const comparer = async () => {
    if (!produitId || !departId) {
      Alert.alert(t('error'), 'Veuillez sélectionner un produit et un marché de départ');
      return;
    }
    
    try {
      setLoading(true);
      const res = await MarchesAPI.comparer(produitId, departId);
      setResult(res.data);
    } catch (err) {
      Alert.alert(t('error'), err.message);
    } finally {
      setLoading(false);
    }
  };

  const getDepartureMarket = () => {
    return marches.find(m => m.id === departId);
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: SPACING.lg }}>
      <View style={styles.header}>
        <Text style={styles.title}>{t('compare_title')}</Text>
        <Text style={styles.subtitle}>{t('compare_dijkstra_info')}</Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Configuration</Text>
        
        <Text style={styles.label}>Produit ID</Text>
        <TextInput
          style={styles.input}
          placeholder="Entrez l'ID du produit"
          value={produitId}
          onChangeText={setProduitId}
          editable={!loading}
        />

        <Text style={styles.label}>Point de départ</Text>
        <View style={styles.pickerWrap}>
          <Picker
            selectedValue={departId}
            onValueChange={setDepartId}
            enabled={!loading}
          >
            {marches.map((m) => (
              <Picker.Item key={m.id} label={`${m.nom} (${m.ville})`} value={m.id} />
            ))}
          </Picker>
        </View>

        <TouchableOpacity
          style={[styles.btn, loading && styles.btnDisabled]}
          onPress={comparer}
          disabled={loading}
        >
          <Text style={styles.btnText}>
            {loading ? 'Calcul en cours...' : t('compare_find')}
          </Text>
        </TouchableOpacity>
      </View>

      {result && (
        <>
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Résultat optimal</Text>
            
            {result.marche_optimal ? (
              <View style={styles.optimalCard}>
                <View style={styles.marketInfo}>
                  <Text style={styles.marketName}>🏪 {result.marche_optimal.nom}</Text>
                  <Text style={styles.marketCity}>{result.marche_optimal.ville}</Text>
                </View>

                <View style={styles.costBreakdown}>
                  <View style={styles.costRow}>
                    <Text style={styles.costLabel}>Prix produit:</Text>
                    <Text style={styles.costValue}>{result.prix_produit} Ar</Text>
                  </View>
                  <View style={styles.costRow}>
                    <Text style={styles.costLabel}>Coût transport:</Text>
                    <Text style={styles.costValue}>{result.cout_transport} Ar</Text>
                  </View>
                  <View style={[styles.costRow, styles.totalRow]}>
                    <Text style={styles.totalLabel}>Coût total:</Text>
                    <Text style={styles.totalValue}>{result.cout_total} Ar</Text>
                  </View>
                </View>

                <View style={styles.perfInfo}>
                  <Text style={styles.perfText}>
                    ⏱️ Temps de calcul: {result.temps_calcul_ms}ms
                  </Text>
                  <Text style={styles.perfText}>
                    📍 Chemin: {result.chemin?.length || 0} étapes
                  </Text>
                </View>
              </View>
            ) : (
              <View style={styles.noResultCard}>
                <Text style={styles.noResultText}>Aucun marché avec ce produit trouvé</Text>
              </View>
            )}
          </View>

          {result.comparatif && result.comparatif.length > 0 && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>
                Comparatif des {Math.min(5, result.comparatif.length)} meilleurs marchés
              </Text>

              {result.comparatif.slice(0, 5).map((item, idx) => (
                <View
                  key={idx}
                  style={[
                    styles.compareItem,
                    idx === 0 && styles.compareItemBest
                  ]}
                >
                  <View style={styles.rankBadge}>
                    <Text style={styles.rankText}>#{idx + 1}</Text>
                  </View>

                  <View style={styles.marketData}>
                    <Text style={styles.marketNameSmall}>{item.marche.nom}</Text>
                    <Text style={styles.marketCitySmall}>{item.marche.ville}</Text>
                  </View>

                  <View style={styles.priceData}>
                    <View style={styles.priceRow}>
                      <Text style={styles.priceLabel}>Produit:</Text>
                      <Text style={styles.priceValueSmall}>{item.prix_produit}Ar</Text>
                    </View>
                    <View style={styles.priceRow}>
                      <Text style={styles.priceLabel}>Transport:</Text>
                      <Text style={styles.priceValueSmall}>{item.cout_transport}Ar</Text>
                    </View>
                    <View style={[styles.priceRow, styles.priceRowTotal]}>
                      <Text style={styles.priceTotalLabel}>Total:</Text>
                      <Text style={styles.priceTotalValue}>{item.cout_total}Ar</Text>
                    </View>
                  </View>
                </View>
              ))}
            </View>
          )}
        </>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.bg
  },
  header: {
    backgroundColor: COLORS.primary,
    padding: SPACING.lg,
    paddingTop: SPACING.md,
  },
  title: {
    color: '#fff',
    fontSize: FONT.lg,
    fontWeight: '800',
    marginBottom: SPACING.sm
  },
  subtitle: {
    color: '#e0e0e0',
    fontSize: FONT.sm,
    fontStyle: 'italic'
  },
  section: {
    backgroundColor: '#fff',
    marginHorizontal: SPACING.md,
    marginVertical: SPACING.md,
    padding: SPACING.lg,
    borderRadius: RADIUS.md,
    borderWidth: 1,
    borderColor: COLORS.border
  },
  sectionTitle: {
    fontSize: FONT.md,
    fontWeight: '700',
    color: COLORS.text,
    marginBottom: SPACING.md,
    borderBottomWidth: 2,
    borderBottomColor: COLORS.primary,
    paddingBottom: SPACING.sm
  },
  label: {
    fontSize: FONT.sm,
    fontWeight: '600',
    color: COLORS.text,
    marginBottom: SPACING.sm,
    marginTop: SPACING.md
  },
  input: {
    borderWidth: 1.5,
    borderColor: COLORS.border,
    borderRadius: RADIUS.md,
    padding: SPACING.md,
    backgroundColor: '#fafafa',
    fontSize: FONT.sm,
    marginBottom: SPACING.md
  },
  pickerWrap: {
    borderWidth: 1.5,
    borderColor: COLORS.border,
    borderRadius: RADIUS.md,
    marginBottom: SPACING.md,
    backgroundColor: '#fafafa',
    overflow: 'hidden'
  },
  btn: {
    backgroundColor: COLORS.primary,
    padding: SPACING.md,
    borderRadius: RADIUS.md,
    alignItems: 'center',
    marginTop: SPACING.md
  },
  btnDisabled: {
    opacity: 0.6
  },
  btnText: {
    color: '#fff',
    fontWeight: '700',
    fontSize: FONT.md
  },
  optimalCard: {
    backgroundColor: '#e8f5e9',
    borderWidth: 1,
    borderColor: '#4CAF50',
    borderRadius: RADIUS.md,
    padding: SPACING.lg,
    borderLeftWidth: 5,
    borderLeftColor: '#4CAF50'
  },
  marketInfo: {
    marginBottom: SPACING.md
  },
  marketName: {
    fontSize: FONT.lg,
    fontWeight: '700',
    color: COLORS.text
  },
  marketCity: {
    fontSize: FONT.sm,
    color: COLORS.textMuted,
    marginTop: SPACING.xs
  },
  costBreakdown: {
    marginBottom: SPACING.md
  },
  costRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: SPACING.sm,
    borderBottomWidth: 0.5,
    borderBottomColor: '#bbb'
  },
  totalRow: {
    borderBottomWidth: 0,
    marginTop: SPACING.sm,
    paddingTop: SPACING.sm
  },
  costLabel: {
    fontSize: FONT.sm,
    color: COLORS.text
  },
  costValue: {
    fontSize: FONT.sm,
    fontWeight: '700',
    color: COLORS.text
  },
  totalLabel: {
    fontSize: FONT.md,
    fontWeight: '700',
    color: COLORS.text
  },
  totalValue: {
    fontSize: FONT.md,
    fontWeight: '800',
    color: '#4CAF50'
  },
  perfInfo: {
    marginTop: SPACING.md,
    paddingTop: SPACING.md,
    borderTopWidth: 1,
    borderTopColor: '#bbb',
    gap: SPACING.xs
  },
  perfText: {
    fontSize: FONT.xs,
    color: COLORS.textMuted,
    fontStyle: 'italic'
  },
  noResultCard: {
    padding: SPACING.lg,
    backgroundColor: '#fff3cd',
    borderRadius: RADIUS.md,
    alignItems: 'center'
  },
  noResultText: {
    color: '#856404',
    fontSize: FONT.md,
    fontWeight: '600'
  },
  compareItem: {
    flexDirection: 'row',
    paddingVertical: SPACING.md,
    paddingHorizontal: SPACING.md,
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: RADIUS.md,
    marginBottom: SPACING.md,
    alignItems: 'center',
    backgroundColor: '#fafafa'
  },
  compareItemBest: {
    backgroundColor: '#e8f5e9',
    borderColor: '#4CAF50',
    borderLeftWidth: 3,
    borderLeftColor: '#4CAF50'
  },
  rankBadge: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: COLORS.primary,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: SPACING.md
  },
  rankText: {
    color: '#fff',
    fontWeight: '700',
    fontSize: FONT.md
  },
  marketData: {
    flex: 1,
    marginRight: SPACING.md
  },
  marketNameSmall: {
    fontSize: FONT.sm,
    fontWeight: '700',
    color: COLORS.text
  },
  marketCitySmall: {
    fontSize: FONT.xs,
    color: COLORS.textMuted,
    marginTop: 2
  },
  priceData: {
    justifyContent: 'flex-end'
  },
  priceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 2
  },
  priceRowTotal: {
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
    paddingVertical: 4
  },
  priceLabel: {
    fontSize: FONT.xs,
    color: COLORS.textMuted,
    marginRight: SPACING.sm
  },
  priceValueSmall: {
    fontSize: FONT.xs,
    fontWeight: '600',
    color: COLORS.text
  },
  priceTotalLabel: {
    fontSize: FONT.xs,
    fontWeight: '700',
    color: COLORS.text
  },
  priceTotalValue: {
    fontSize: FONT.xs,
    fontWeight: '800',
    color: '#4CAF50'
  }
});

