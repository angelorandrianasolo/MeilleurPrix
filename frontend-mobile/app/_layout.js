import { useEffect } from 'react';
import { Stack }     from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import * as SplashScreen from 'expo-splash-screen';
import { AuthProvider } from '../src/context/AuthContext';
import { LanguageProvider, OfflineProvider } from '../src/context';
 
// Garder le splash screen visible pendant le chargement
SplashScreen.preventAutoHideAsync();
 
export default function RootLayout() {
  useEffect(() => {
    SplashScreen.hideAsync();
  }, []);
 
  return (
    <AuthProvider>
      <LanguageProvider>
        <OfflineProvider>
          <StatusBar style="auto" />
          <Stack screenOptions={{ headerShown: false }}>
            {/*
              Expo Router détecte automatiquement :
              - app/(auth)/_layout.js  → groupe Auth (login, register)
              - app/(tabs)/_layout.js  → groupe Tabs (écrans principaux)
            */}
          </Stack>
        </OfflineProvider>
      </LanguageProvider>
    </AuthProvider>
  );
}