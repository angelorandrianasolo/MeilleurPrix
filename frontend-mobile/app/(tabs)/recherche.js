import { useState } from 'react';
import { View, Text, TextInput, FlatList, StyleSheet, TouchableOpacity } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { ProduitsAPI } from '../../src/services/api';
import { COLORS, SPACING, FONT, RADIUS } from '../../src/utils/theme';

export default function RechercheScreen() {
  const [q, setQ] = useState('');
  const [items, setItems] = useState([]);
  const [temps, setTemps] = useState(null);

  const search = async (text) => {
    setQ(text);
    if (text.length < 2) {
      setItems([]);
      return;
    }
    try {
      const res = await ProduitsAPI.search(text);
      setItems(res.data || []);
      setTemps(res.temps_ms);
    } catch {
      setItems([]);
    }
  };

  const selectProduit = async (p) => {
    await AsyncStorage.setItem('mp_produit', JSON.stringify(p));
  };

  return (
    <View style={styles.container}>
      <Text style={styles.hint}>Trie local — min. 2 caracteres (FR/MG)</Text>
      <TextInput
        style={styles.input}
        placeholder="Riz, Vary, Tomate..."
        value={q}
        onChangeText={search}
      />
      {temps !== null && <Text style={styles.temps}>{temps} ms</Text>}
      <FlatList
        data={items}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <TouchableOpacity style={styles.row} onPress={() => selectProduit(item)}>
            <Text style={styles.nom}>{item.nom_fr}</Text>
            <Text style={styles.sub}>{item.nom_mg} — {item.unite}</Text>
          </TouchableOpacity>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: SPACING.md, backgroundColor: COLORS.bg },
  hint: { color: COLORS.textMuted, marginBottom: SPACING.sm },
  input: { borderWidth: 1.5, borderColor: COLORS.border, borderRadius: RADIUS.md, padding: SPACING.md, backgroundColor: '#fff', marginBottom: SPACING.sm },
  temps: { color: COLORS.primary, fontSize: FONT.sm, marginBottom: SPACING.sm },
  row: { backgroundColor: COLORS.card, padding: SPACING.md, borderRadius: RADIUS.md, marginBottom: SPACING.sm, borderWidth: 1, borderColor: COLORS.border },
  nom: { fontWeight: '700', color: COLORS.text },
  sub: { color: COLORS.textMuted, fontSize: FONT.sm }
});
