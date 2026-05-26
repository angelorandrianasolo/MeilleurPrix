import { Tabs } from 'expo-router';
import { COLORS } from '../../src/utils/theme';

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerStyle: { backgroundColor: COLORS.primary },
        headerTintColor: '#fff',
        tabBarActiveTintColor: COLORS.primary
      }}>
      <Tabs.Screen name="recherche" options={{ title: 'Recherche', tabBarLabel: 'Recherche' }} />
      <Tabs.Screen name="saisie" options={{ title: 'Saisie', tabBarLabel: 'Saisie' }} />
      <Tabs.Screen name="carte" options={{ title: 'Carte', tabBarLabel: 'Carte' }} />
      <Tabs.Screen name="comparer" options={{ title: 'Comparer', tabBarLabel: 'Marchés' }} />
      <Tabs.Screen name="prevision" options={{ title: 'Prévisions', tabBarLabel: 'Prévisions' }} />
      <Tabs.Screen name="panier" options={{ title: 'Panier', tabBarLabel: 'Panier' }} />
      <Tabs.Screen name="profil" options={{ title: 'Profil', tabBarLabel: 'Profil' }} />
    </Tabs>
  );
}
