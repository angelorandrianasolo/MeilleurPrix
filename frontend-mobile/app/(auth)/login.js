import { useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity,
  StyleSheet, ScrollView, ActivityIndicator, Alert
} from 'react-native';
import { router }   from 'expo-router';
import { AuthAPI }  from '../../src/services/api';
import { useAuth }  from '../../src/context/AuthContext';
import { COLORS, SPACING, FONT, RADIUS, SHADOW } from '../../src/utils/theme';
 
export default function LoginScreen() {
  const { login }  = useAuth();
  const [email,   setEmail]   = useState('');
  const [mdp,     setMdp]     = useState('');
  const [showMdp, setShowMdp] = useState(false);
  const [loading, setLoading] = useState(false);
 
  const handleLogin = async () => {
    if (!email.trim() || !mdp) {
      Alert.alert('Champs requis', 'Veuillez remplir tous les champs.');
      return;
    }
    setLoading(true);
    try {
      const data = await AuthAPI.login(email.trim(), mdp);
      await login(data.data.token, data.data.utilisateur);
      // Expo Router : redirection après connexion
      router.replace('/(tabs)/recherche');
    } catch (err) {
      Alert.alert('Erreur de connexion', err.message);
    } finally {
      setLoading(false);
    }
  };
 
  return (
    <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
 
      {/* Logo */}
      <View style={styles.logoBox}>
        <Text style={styles.logoEmoji}>🛒</Text>
        <Text style={styles.appName}>Meilleur Prix</Text>
        <Text style={styles.appSub}>Trouvez les meilleurs prix à Madagascar</Text>
      </View>
 
      {/* Formulaire */}
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Connexion</Text>
        <Text style={styles.cardSub}>Accédez à votre compte</Text>
 
        <Text style={styles.label}>Adresse email</Text>
        <TextInput
          style={styles.input}
          value={email}
          onChangeText={setEmail}
          placeholder="votre@email.mg"
          placeholderTextColor={COLORS.textMuted}
          keyboardType="email-address"
          autoCapitalize="none"
        />
 
        <Text style={styles.label}>Mot de passe</Text>
        <View style={styles.inputRow}>
          <TextInput
            style={[styles.input, { flex: 1, marginBottom: 0 }]}
            value={mdp}
            onChangeText={setMdp}
            placeholder="••••••••"
            placeholderTextColor={COLORS.textMuted}
            secureTextEntry={!showMdp}
          />
          <TouchableOpacity style={styles.eyeBtn} onPress={() => setShowMdp(v => !v)}>
            <Text style={{ fontSize: 20 }}>{showMdp ? '🙈' : '👁'}</Text>
          </TouchableOpacity>
        </View>
 
        <TouchableOpacity
          style={[styles.btnPrimary, loading && { opacity: 0.6 }]}
          onPress={handleLogin}
          disabled={loading}>
          {loading
            ? <ActivityIndicator color="#fff" />
            : <Text style={styles.btnText}>🔑 Se connecter</Text>}
        </TouchableOpacity>
      </View>
 
      {/* Séparateur */}
      <View style={styles.divider}>
        <View style={styles.dividerLine} />
        <Text style={styles.dividerText}>Pas encore de compte ?</Text>
        <View style={styles.dividerLine} />
      </View>
 
      {/* Bouton S'INSCRIRE bien visible */}
      <TouchableOpacity
        style={styles.btnRegister}
        onPress={() => router.push('/(auth)/register')}>
        <Text style={styles.btnRegisterText}>✍️ Créer un compte gratuitement</Text>
        <View style={styles.badgeNew}>
          <Text style={styles.badgeNewText}>Nouveau</Text>
        </View>
      </TouchableOpacity>
 
    </ScrollView>
  );
}
 
const styles = StyleSheet.create({
  container:       { flexGrow: 1, backgroundColor: COLORS.bg, padding: SPACING.lg, justifyContent: 'center' },
  logoBox:         { alignItems: 'center', marginBottom: SPACING.xl },
  logoEmoji:       { fontSize: 64 },
  appName:         { fontSize: FONT.xxl, fontWeight: '800', color: COLORS.primary, marginTop: SPACING.sm },
  appSub:          { fontSize: FONT.sm, color: COLORS.textMuted, textAlign: 'center' },
  card:            { backgroundColor: COLORS.card, borderRadius: RADIUS.lg, padding: SPACING.lg, ...SHADOW },
  cardTitle:       { fontSize: FONT.xl, fontWeight: '800', color: COLORS.text },
  cardSub:         { fontSize: FONT.sm, color: COLORS.textMuted, marginBottom: SPACING.md },
  label:           { fontSize: FONT.sm, fontWeight: '600', color: COLORS.text, marginBottom: SPACING.xs, marginTop: SPACING.sm },
  input:           { borderWidth: 1.5, borderColor: COLORS.border, borderRadius: RADIUS.md, padding: SPACING.md, fontSize: FONT.base, backgroundColor: '#fff', marginBottom: SPACING.sm, color: COLORS.text },
  inputRow:        { flexDirection: 'row', alignItems: 'center', marginBottom: SPACING.sm },
  eyeBtn:          { padding: SPACING.md, marginLeft: SPACING.sm },
  btnPrimary:      { backgroundColor: COLORS.primary, borderRadius: RADIUS.md, padding: SPACING.md, alignItems: 'center', marginTop: SPACING.sm },
  btnText:         { color: '#fff', fontWeight: '700', fontSize: FONT.md },
  divider:         { flexDirection: 'row', alignItems: 'center', marginVertical: SPACING.lg, gap: SPACING.sm },
  dividerLine:     { flex: 1, height: 1, backgroundColor: COLORS.border },
  dividerText:     { color: COLORS.textMuted, fontSize: FONT.sm },
  btnRegister:     { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: SPACING.sm, borderWidth: 2, borderColor: COLORS.primary, borderRadius: RADIUS.md, padding: SPACING.md, ...SHADOW },
  btnRegisterText: { color: COLORS.primary, fontWeight: '700', fontSize: FONT.md },
  badgeNew:        { backgroundColor: '#FEF3C7', borderRadius: RADIUS.full, paddingHorizontal: SPACING.sm, paddingVertical: 2 },
  badgeNewText:    { color: '#92400E', fontWeight: '700', fontSize: FONT.sm - 2 }
});