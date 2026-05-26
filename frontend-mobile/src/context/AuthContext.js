import { createContext, useContext, useEffect, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [token, setToken] = useState(null);
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const t = await AsyncStorage.getItem('mp_token');
        const u = await AsyncStorage.getItem('mp_user');
        if (t) setToken(t);
        if (u) setUser(JSON.parse(u));
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const login = async (newToken, utilisateur) => {
    await AsyncStorage.setItem('mp_token', newToken);
    await AsyncStorage.setItem('mp_user', JSON.stringify(utilisateur));
    setToken(newToken);
    setUser(utilisateur);
  };

  const logout = async () => {
    await AsyncStorage.multiRemove(['mp_token', 'mp_user']);
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ token, user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth doit etre dans AuthProvider');
  return ctx;
}
