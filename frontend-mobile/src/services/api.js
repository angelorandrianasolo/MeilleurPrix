import AsyncStorage from '@react-native-async-storage/async-storage';

const API_BASE =
  process.env.EXPO_PUBLIC_API_URL || 'http://localhost:3000/api/v1';

async function getToken() {
  return AsyncStorage.getItem('mp_token');
}

async function apiFetch(path, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {})
  };
  const token = await getToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}${path}`, { ...options, headers });
  const data = await res.json().catch(() => ({}));

  if (!res.ok) {
    throw new Error(data.message || 'Erreur serveur');
  }
  return data;
}

export const AuthAPI = {
  login: (email, mot_de_passe) =>
    apiFetch('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, mot_de_passe })
    }),
  register: (body) =>
    apiFetch('/auth/register', { method: 'POST', body: JSON.stringify(body) })
};

export const ProduitsAPI = {
  search: (q) => apiFetch(`/produits/search?q=${encodeURIComponent(q)}`),
  list: () => apiFetch('/produits'),
  categories: () => apiFetch('/produits/categories/list')
};

export const MarchesAPI = {
  list: () => apiFetch('/marches'),
  comparer: (produitId, departId) =>
    apiFetch(`/marches/comparer?produitId=${produitId}&departId=${departId}`)
};

export const PrixAPI = {
  create: (body) => apiFetch('/prix', { method: 'POST', body: JSON.stringify(body) })
};

export const SyncAPI = {
  push: (saisies) =>
    apiFetch('/sync', { method: 'POST', body: JSON.stringify({ saisies }) })
};

export const PanierAPI = {
  optimiser: (budget, produits) =>
    apiFetch('/panier/optimiser', {
      method: 'POST',
      body: JSON.stringify({ budget, produits })
    })
};

export const PrevisionAPI = {
  get: (produitId, marcheId) => {
    let url = `/previsions/${produitId}`;
    if (marcheId) url += `?marcheId=${marcheId}`;
    return apiFetch(url);
  }
};

export { API_BASE, getToken };
