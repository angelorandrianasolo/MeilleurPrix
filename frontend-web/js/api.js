const API_BASE = (window.API_URL || 'http://localhost:3000') + '/api/v1';

function getToken() {
  return sessionStorage.getItem('mp_token');
}

function setToken(token) {
  if (token) sessionStorage.setItem('mp_token', token);
  else sessionStorage.removeItem('mp_token');
}

function getUser() {
  const u = sessionStorage.getItem('mp_user');
  return u ? JSON.parse(u) : null;
}

function setUser(user) {
  if (user) sessionStorage.setItem('mp_user', JSON.stringify(user));
  else sessionStorage.removeItem('mp_user');
}

async function apiFetch(path, options = {}) {
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
  const token = getToken();
  if (token) headers.Authorization = 'Bearer ' + token;

  const res = await fetch(API_BASE + path, { ...options, headers });
  const data = await res.json().catch(() => ({}));

  if (!res.ok) {
    const msg = data.message || 'Erreur serveur';
    throw new Error(msg);
  }
  return data;
}

const AuthAPI = {
  login: (email, mot_de_passe) =>
    apiFetch('/auth/login', { method: 'POST', body: JSON.stringify({ email, mot_de_passe }) }),
  register: (body) =>
    apiFetch('/auth/register', { method: 'POST', body: JSON.stringify(body) }),
  me: () => apiFetch('/auth/me')
};

const ProduitsAPI = {
  search: (q) => apiFetch('/produits/search?q=' + encodeURIComponent(q)),
  list: () => apiFetch('/produits'),
  categories: () => apiFetch('/produits/categories/list')
};

const MarchesAPI = {
  list: () => apiFetch('/marches'),
  comparer: (produitId, departId) =>
    apiFetch('/marches/comparer?produitId=' + produitId + '&departId=' + departId)
};

const PrixAPI = {
  create: (body) => apiFetch('/prix', { method: 'POST', body: JSON.stringify(body) }),
  historique: (produitId, marcheId) => {
    let url = '/prix/produit/' + produitId;
    if (marcheId) url += '?marcheId=' + marcheId;
    return apiFetch(url);
  }
};

const PrevisionAPI = {
  get: (produitId, marcheId) => {
    let url = '/previsions/' + produitId;
    if (marcheId) url += '?marcheId=' + marcheId;
    return apiFetch(url);
  }
};

const PanierAPI = {
  optimiser: (budget, produits) =>
    apiFetch('/panier/optimiser', {
      method: 'POST',
      body: JSON.stringify({ budget, produits })
    })
};

const DashboardAPI = {
  get: () => apiFetch('/dashboard')
};

function requireAuth() {
  if (!getToken()) {
    window.location.href = 'login.jsp';
    return false;
  }
  return true;
}
