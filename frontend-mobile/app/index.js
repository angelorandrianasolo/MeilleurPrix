import { Redirect } from 'expo-router';
import { useAuth }  from '../src/context/AuthContext';
import { View, ActivityIndicator } from 'react-native';
import { COLORS } from '../src/utils/theme';
 
export default function Index() {
  const { token, loading } = useAuth();
 
  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: COLORS.bg }}>
        <ActivityIndicator size="large" color={COLORS.primary} />
      </View>
    );
  }
 
  // Redirection automatique selon l'état de connexion
  if (token) {
    return <Redirect href="/(tabs)/recherche" />;
  } else {
    return <Redirect href="/(auth)/login" />;
  }
}