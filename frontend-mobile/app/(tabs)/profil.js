import { View, Text, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import { router } from 'expo-router';
import { useAuth } from '../../src/context/AuthContext';
import { COLORS, SPACING, FONT, RADIUS } from '../../src/utils/theme';

export default function ProfilScreen() {
  const { user, logout } = useAuth();

  const handleLogout = async () => {
    await logout();
    router.replace('/(auth)/login');
  };

  return (
    <View style={styles.container}>
      <View style={styles.card}>
        <Text style={styles.emoji}>👤</Text>
        <Text style={styles.nom}>{user?.nom || 'Utilisateur'}</Text>
        <Text style={styles.email}>{user?.email}</Text>
        <Text style={styles.role}>Role : {user?.role}</Text>
        <Text style={styles.lang}>Langue : {user?.langue}</Text>
      </View>
      <TouchableOpacity style={styles.btn} onPress={handleLogout}>
        <Text style={styles.btnText}>Deconnexion</Text>
      </TouchableOpacity>
      <Text style={styles.footer}>Meilleur Prix — SI20240029</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: SPACING.lg, backgroundColor: COLORS.bg },
  card: { backgroundColor: COLORS.card, padding: SPACING.xl, borderRadius: RADIUS.lg, alignItems: 'center', borderWidth: 1, borderColor: COLORS.border },
  emoji: { fontSize: 48 },
  nom: { fontSize: FONT.xl, fontWeight: '800', marginTop: SPACING.sm },
  email: { color: COLORS.textMuted },
  role: { marginTop: SPACING.md, fontWeight: '600' },
  lang: { color: COLORS.textMuted },
  btn: { marginTop: SPACING.xl, backgroundColor: COLORS.danger, padding: SPACING.md, borderRadius: RADIUS.md, alignItems: 'center' },
  btnText: { color: '#fff', fontWeight: '700' },
  footer: { textAlign: 'center', marginTop: SPACING.xl, color: COLORS.textMuted, fontSize: FONT.sm }
});
