<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Inscription - Meilleur Prix</title>
  <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
  <style>
    .auth-page {
      min-height: 100vh; display: flex;
      background: var(--bg); position: relative;
    }
    .auth-side {
      flex: 1; display: flex; align-items: center; justify-content: center;
      padding: 2rem;
    }
    .auth-side:first-child {
      flex: 1.1;
      background: linear-gradient(135deg, #0f766e 0%, #14b8a6 40%, #0ea5e9 70%, #7c3aed 100%);
      position: relative; overflow: hidden;
    }
    .auth-side:first-child::before {
      content: ''; position: absolute; inset: 0;
      background:
        radial-gradient(ellipse at 20% 50%, rgba(255,255,255,0.1) 0%, transparent 50%),
        radial-gradient(ellipse at 80% 20%, rgba(255,255,255,0.06) 0%, transparent 50%);
    }
    .auth-hero {
      position: relative; z-index: 1; max-width: 420px; color: #fff;
    }
    .auth-hero .brand {
      font-size: 2rem; font-weight: 900; letter-spacing: -0.04em;
      margin-bottom: 1rem; display: flex; align-items: center; gap: 0.75rem;
    }
    .auth-hero .brand svg { width: 40px; height: 40px; }
    .auth-hero h2 { font-size: 1.3rem; font-weight: 600; margin-bottom: 0.75rem; opacity: 0.92; line-height: 1.4; }
    .auth-hero p { font-size: 0.9rem; opacity: 0.75; line-height: 1.6; }
    .auth-hero .features { margin-top: 2rem; display: flex; flex-direction: column; gap: 0.85rem; }
    .auth-hero .feat { display: flex; align-items: center; gap: 0.7rem; font-size: 0.88rem; opacity: 0.8; }
    .auth-hero .feat svg { width: 18px; height: 18px; flex-shrink: 0; opacity: 0.7; }
    .auth-card { width: 100%; max-width: 420px; }
    .auth-card .logo-section { margin-bottom: 1.25rem; }
    .auth-card .logo-section h1 {
      font-size: 1.35rem; font-weight: 800; color: var(--text);
      letter-spacing: -0.03em; margin-bottom: 0.25rem;
    }
    .auth-card .logo-section p { color: var(--text-muted); font-size: 0.87rem; }
    .auth-card form .form-group { margin-bottom: 0.85rem; }
    .auth-card form label {
      font-size: 0.8rem; font-weight: 600; color: var(--text-secondary);
      margin-bottom: 0.3rem; display: block;
    }
    .auth-card form input, .auth-card form select {
      width: 100%; padding: 0.7rem 0.85rem; border: 1.5px solid var(--border);
      border-radius: var(--radius); font-size: 0.88rem; transition: all 0.2s;
      background: var(--surface); font-family: inherit;
    }
    .auth-card form input:focus, .auth-card form select:focus {
      border-color: var(--primary); box-shadow: 0 0 0 3px var(--primary-bg);
    }
    .auth-card .auth-footer {
      text-align: center; margin-top: 1.5rem; font-size: 0.87rem; color: var(--text-muted);
    }
    .auth-card .auth-footer a {
      color: var(--primary); text-decoration: none; font-weight: 600; transition: color 0.2s;
    }
    .auth-card .auth-footer a:hover { color: var(--primary-light); text-decoration: underline; }
    .auth-card .btn { margin-top: 0.25rem; }
    @media (max-width: 860px) {
      .auth-side:first-child { display: none; }
      .auth-side { padding: 1.5rem; }
    }
  </style>
</head>
<body>
  <div class="auth-page">
    <div class="auth-side">
      <div class="auth-hero">
        <div class="brand">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/><path d="M6 11h10"/><path d="M11 6v10"/>
          </svg>
          Meilleur Prix
        </div>
        <h2>Rejoignez la communaute</h2>
        <p>Inscrivez-vous pour contribuer a la collecte de prix et beneficier d'outils intelligents d'analyse et de comparaison.</p>
        <div class="features">
          <div class="feat"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg> Saisie collaborative des prix</div>
          <div class="feat"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg> Algorithmes de prevision et comparaison</div>
          <div class="feat"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg> Optimisation intelligente de votre panier</div>
        </div>
      </div>
    </div>
    <div class="auth-side">
      <div class="auth-card">
        <div class="logo-section">
          <h1>Creer un compte</h1>
          <p>Rejoignez Meilleur Prix des maintenant</p>
        </div>
        <div id="msg" class="message hidden"></div>
        <form id="formRegister">
          <div class="form-row">
            <div class="form-group">
              <label for="nom">Nom complet</label>
              <input type="text" id="nom" required placeholder="Votre nom">
            </div>
            <div class="form-group">
              <label for="email">Email</label>
              <input type="email" id="email" required placeholder="email@exemple.mg">
            </div>
          </div>
          <div class="form-group">
            <label for="mdp">Mot de passe (min. 6 caracteres)</label>
            <input type="password" id="mdp" required minlength="6" placeholder="Votre mot de passe">
          </div>
          <div class="form-row">
            <div class="form-group">
              <label for="role">Role</label>
              <select id="role">
                <option value="ACHETEUR">Acheteur</option>
                <option value="VENDEUR">Vendeur</option>
                <option value="COLLECTEUR">Collecteur</option>
              </select>
            </div>
            <div class="form-group">
              <label for="langue">Langue</label>
              <select id="langue">
                <option value="FR">Francais</option>
                <option value="MG">Malagasy</option>
              </select>
            </div>
          </div>
          <button type="submit" class="btn btn-primary btn-block">S'inscrire</button>
        </form>
        <div class="auth-footer">
          Deja inscrit ? <a href="login.jsp">Connectez-vous</a>
        </div>
      </div>
    </div>
  </div>
  <%@ include file="_config.jsp" %>
  <script src="<%= request.getContextPath() %>/js/api.js"></script>
  <script>
    document.getElementById('formRegister').addEventListener('submit', async function(e) {
      e.preventDefault();
      var msg = document.getElementById('msg');
      msg.className = 'message hidden';
      try {
        var res = await AuthAPI.register({
          nom: document.getElementById('nom').value.trim(),
          email: document.getElementById('email').value.trim(),
          mot_de_passe: document.getElementById('mdp').value,
          role: document.getElementById('role').value,
          langue: document.getElementById('langue').value
        });
        if (typeof setToken === 'function') setToken(res.data.token);
        if (typeof setUser === 'function') setUser(res.data.utilisateur);
        location.href = 'recherche.jsp';
      } catch (err) {
        msg.textContent = err.message || 'Erreur lors de l\'inscription';
        msg.className = 'message err';
      }
    });
  </script>
</body>
</html>
