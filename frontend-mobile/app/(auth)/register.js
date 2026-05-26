import { useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet,
  ScrollView, ActivityIndicator, Alert
} from 'react-native';
import { router } from 'expo-router';
import { Picker } from '@react-native-picker/picker';
import { AuthAPI } from '../../src/services/api';
import { useAuth } from '../../src/context/AuthContext';
import { COLORS, SPACING, FONT, RADIUS } from '../../src/utils/theme';

export default function RegisterScreen() {
  const { login } = useAuth();
  const [nom, setNom] = useState('');
  const [email, setEmail] = useState('');
  const [mdp, setMdp] = useState('');
  const [role, setRole] = useState('ACHETEUR');
  const [langue, setLangue] = useState('FR');
  const [loading, setLoading] = useState(false);

  const handleRegister = async () => {
    if (!nom.trim() || !email.trim() || mdp.length < 6) {
      Alert.alert('Erreur', 'Remplissez tous les champs (mdp min. 6 caracteres).');
      return;
    }
    setLoading(true);
    try {
      const data = await AuthAPI.register({
        nom: nom.trim(),
        email: email.trim(),
        mot_de_passe: mdp,
        role,
        langue
      });
      await login(data.data.token, data.data.utilisateur);
      router.replace('/(tabs)/recherche');
    } catch (err) {
      Alert.alert('Inscription', err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Creer un compte</Text>
      <TextInput style={styles.input} placeholder="Nom" value={nom} onChangeText={setNom} />
      <TextInput style={styles.input} placeholder="Email" value={email} onChangeText={setEmail}
        keyboardType="email-address" autoCapitalize="none" />
      <TextInput style={styles.input} placeholder="Mot de passe" value={mdp} onChangeText={setMdp}
        secureTextEntry />
      <Text style={styles.label}>Role</Text>
      <View style={styles.pickerWrap}>
        <Picker selectedValue={role} onValueChange={setRole}>
          <Picker.Item label="Acheteur" value="ACHETEUR" />
          <Picker.Item label="Vendeur" value="VENDEUR" />
          <Picker.Item label="Collecteur" value="COLLECTEUR" />
        </Picker>
      </View>
      <TouchableOpacity style={styles.btn} onPress={handleRegister} disabled={loading}>
        {loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.btnText}>S'inscrire</Text>}
      </TouchableOpacity>
      <TouchableOpacity onPress={() => router.back()}>
        <Text style={styles.link}>Deja inscrit ? Connexion</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flexGrow: 1, padding: SPACING.lg, backgroundColor: COLORS.bg },
  title: { fontSize: FONT.xl, fontWeight: '800', color: COLORS.primary, marginBottom: SPACING.lg },
  input: { borderWidth: 1.5, borderColor: COLORS.border, borderRadius: RADIUS.md, padding: SPACING.md, marginBottom: SPACING.sm, backgroundColor: '#fff' },
  label: { fontWeight: '600', marginBottom: SPACING.xs },
  pickerWrap: { borderWidth: 1.5, borderColor: COLORS.border, borderRadius: RADIUS.md, marginBottom: SPACING.md, backgroundColor: '#fff' },
  btn: { backgroundColor: COLORS.primary, padding: SPACING.md, borderRadius: RADIUS.md, alignItems: 'center' },
  btnText: { color: '#fff', fontWeight: '700' },
  link: { color: COLORS.primary, textAlign: 'center', marginTop: SPACING.lg }
});
