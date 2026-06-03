<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Gestion des utilisateurs - Meilleur Prix</title>
  <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
  <style>
    .user-table { width: 100%; border-collapse: collapse; font-size: 0.87rem; }
    .user-table th { text-align: left; padding: 0.6rem 0.75rem; border-bottom: 2px solid var(--border); font-weight: 600; color: var(--text-secondary); white-space: nowrap; }
    .user-table td { padding: 0.6rem 0.75rem; border-bottom: 1px solid var(--border); vertical-align: middle; }
    .user-table tr:hover td { background: var(--bg-alt); }
    .user-table .actions { white-space: nowrap; text-align: right; }
    .role-badge { display: inline-block; padding: 0.15rem 0.5rem; border-radius: 999px; font-size: 0.75rem; font-weight: 600; }
    .role-ACHETEUR { background: #dbeafe; color: #1d4ed8; }
    .role-VENDEUR { background: #d1fae5; color: #059669; }
    .role-COLLECTEUR { background: #fef3c7; color: #d97706; }
    .role-ADMINISTRATEUR { background: #fee2e2; color: #dc2626; }
    .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.4); z-index: 200; display: none; align-items: center; justify-content: center; }
    .modal-overlay.active { display: flex; }
    .modal { background: #fff; border-radius: var(--radius); padding: 1.5rem; width: 90%; max-width: 480px; box-shadow: 0 20px 60px rgba(0,0,0,0.15); }
    .modal h3 { margin-top: 0; }
    .empty-state { text-align: center; padding: 2rem; color: var(--text-muted); }
    .stat-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 1rem; margin-bottom: 1.5rem; }
    .stat-card { background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 1rem; text-align: center; }
    .stat-card .nb { font-size: 1.5rem; font-weight: 800; color: var(--primary); }
    .stat-card .label { font-size: 0.8rem; color: var(--text-muted); margin-top: 0.25rem; }
  </style>
</head>
<body>
  <%@ include file="_header.jsp" %>
  <div class="page-header">
    <div class="container">
      <h1>Gestion des utilisateurs</h1>
      <p>Gerer les comptes, roles et activites des utilisateurs</p>
    </div>
  </div>
  <div class="container" style="padding-top:1.5rem">
    <div id="msg" class="message hidden"></div>
    <div id="statsContainer" class="stat-cards"></div>
    <div class="card">
      <div class="card-header">
        <h2>Liste des utilisateurs</h2>
      </div>
      <div class="card-body" style="overflow-x:auto">
        <table class="user-table" id="userTable">
          <thead>
            <tr>
              <th>Nom</th>
              <th>Email</th>
              <th>Role</th>
              <th>Langue</th>
              <th>Statut</th>
              <th>Date creation</th>
              <th class="actions">Actions</th>
            </tr>
          </thead>
          <tbody id="userBody">
            <tr><td colspan="7" class="empty-state">Chargement...</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
  <div class="modal-overlay" id="modalEdit">
    <div class="modal">
      <h3>Modifier l'utilisateur</h3>
      <form id="formEdit">
        <div class="form-group">
          <label>Nom</label>
          <input type="text" id="edit_nom" class="form-control" required>
        </div>
        <div class="form-group">
          <label>Email</label>
          <input type="email" id="edit_email" class="form-control" disabled style="background:#f9fafb;color:#6b7280">
        </div>
        <div class="form-group">
          <label>Role</label>
          <select id="edit_role" class="form-control">
            <option value="ACHETEUR">Acheteur</option>
            <option value="VENDEUR">Vendeur</option>
            <option value="COLLECTEUR">Collecteur</option>
            <option value="ADMINISTRATEUR">Administrateur</option>
          </select>
        </div>
        <div class="form-group">
          <label>Langue</label>
          <select id="edit_langue" class="form-control">
            <option value="FR">Francais</option>
            <option value="MG">Malagasy</option>
          </select>
        </div>
        <div class="form-group">
          <label>Compte actif</label>
          <select id="edit_est_actif" class="form-control">
            <option value="true">Actif</option>
            <option value="false">Desactive</option>
          </select>
        </div>
        <div style="display:flex;gap:0.75rem;margin-top:1rem">
          <button type="submit" class="btn btn-primary">Enregistrer</button>
          <button type="button" class="btn" onclick="fermerModal()">Annuler</button>
        </div>
      </form>
    </div>
  </div>
  <%@ include file="_config.jsp" %>
  <script src="<%= request.getContextPath() %>/js/api.js"></script>
  <script>
  (function() {
    if (typeof requireAuth === 'function' && !requireAuth()) return;

    var API = window.API_URL;
    var userIdEdition = null;

    function msg(text, type) {
      var el = document.getElementById('msg');
      el.textContent = text;
      el.className = 'message ' + (type || 'success');
      if (text) setTimeout(function() { el.className = 'message hidden'; }, 4000);
    }

    function chargerStats() {
      apiFetch(API + '/api/v1/utilisateurs').then(function(res) {
        if (!res.success || !res.data) return;
        var users = res.data;
        var stats = {
          total: users.length,
          actifs: users.filter(function(u) { return u.est_actif; }).length,
          acheteurs: users.filter(function(u) { return u.role === 'ACHETEUR'; }).length,
          vendeurs: users.filter(function(u) { return u.role === 'VENDEUR'; }).length,
          collecteurs: users.filter(function(u) { return u.role === 'COLLECTEUR'; }).length,
          admins: users.filter(function(u) { return u.role === 'ADMINISTRATEUR'; }).length
        };
        document.getElementById('statsContainer').innerHTML =
          '<div class="stat-card"><div class="nb">' + stats.total + '</div><div class="label">Total</div></div>' +
          '<div class="stat-card"><div class="nb">' + stats.actifs + '</div><div class="label">Actifs</div></div>' +
          '<div class="stat-card"><div class="nb">' + stats.acheteurs + '</div><div class="label">Acheteurs</div></div>' +
          '<div class="stat-card"><div class="nb">' + stats.vendeurs + '</div><div class="label">Vendeurs</div></div>' +
          '<div class="stat-card"><div class="nb">' + stats.collecteurs + '</div><div class="label">Collecteurs</div></div>' +
          '<div class="stat-card"><div class="nb">' + stats.admins + '</div><div class="label">Administrateurs</div></div>';
      }).catch(function() {});
    }

    function chargerUtilisateurs() {
      apiFetch(API + '/api/v1/utilisateurs').then(function(res) {
        if (!res.success) throw new Error('Erreur chargement');
        var tbody = document.getElementById('userBody');
        if (!res.data || res.data.length === 0) {
          tbody.innerHTML = '<tr><td colspan="7" class="empty-state">Aucun utilisateur.</td></tr>';
          return;
        }
        tbody.innerHTML = res.data.map(function(u) {
          var d = u.created_at ? new Date(u.created_at).toLocaleDateString('fr-FR') : '-';
          return '<tr>' +
            '<td><strong>' + (u.nom || '-') + '</strong></td>' +
            '<td>' + (u.email || '-') + '</td>' +
            '<td><span class="role-badge role-' + u.role + '">' + u.role + '</span></td>' +
            '<td>' + u.langue + '</td>' +
            '<td>' + (u.est_actif ? '<span style="color:#059669;font-weight:600">Actif</span>' : '<span style="color:#dc2626;font-weight:600">Desactive</span>') + '</td>' +
            '<td>' + d + '</td>' +
            '<td class="actions">' +
              '<button class="btn btn-sm" onclick="editerUtilisateur(\'' + u.id + '\')">Modifier</button> ' +
              '<button class="btn btn-sm btn-danger" onclick="supprimerUtilisateur(\'' + u.id + '\',\'' + u.nom.replace(/'/g,"\\'") + '\')">Supprimer</button>' +
            '</td></tr>';
        }).join('');
      }).catch(function(e) { msg('Erreur: ' + e.message, 'err'); });
    }

    window.editerUtilisateur = function(id) {
      apiFetch(API + '/api/v1/utilisateurs/' + id).then(function(res) {
        if (!res.success) throw new Error('Erreur');
        var u = res.data;
        userIdEdition = id;
        document.getElementById('edit_nom').value = u.nom || '';
        document.getElementById('edit_email').value = u.email || '';
        document.getElementById('edit_role').value = u.role || 'ACHETEUR';
        document.getElementById('edit_langue').value = u.langue || 'FR';
        document.getElementById('edit_est_actif').value = u.est_actif ? 'true' : 'false';
        document.getElementById('modalEdit').classList.add('active');
      }).catch(function(e) { msg('Erreur: ' + e.message, 'err'); });
    };

    window.fermerModal = function() {
      userIdEdition = null;
      document.getElementById('modalEdit').classList.remove('active');
    };

    window.supprimerUtilisateur = function(id, nom) {
      if (id === getUserId()) {
        msg('Vous ne pouvez pas supprimer votre propre compte.', 'err');
        return;
      }
      if (!confirm('Supprimer definitivement l\'utilisateur "' + nom + '" ? Cette action est irreversible.')) return;
      apiFetch(API + '/api/v1/utilisateurs/' + id, { method: 'DELETE' }).then(function(res) {
        if (!res.success) throw new Error(res.message || 'Erreur');
        msg('Utilisateur supprime.');
        chargerUtilisateurs();
        chargerStats();
      }).catch(function(e) { msg('Erreur: ' + e.message, 'err'); });
    };

    document.getElementById('formEdit').addEventListener('submit', function(e) {
      e.preventDefault();
      if (!userIdEdition) return;
      var data = {
        nom: document.getElementById('edit_nom').value.trim(),
        role: document.getElementById('edit_role').value,
        langue: document.getElementById('edit_langue').value,
        est_actif: document.getElementById('edit_est_actif').value === 'true'
      };
      if (!data.nom) { msg('Le nom est obligatoire.', 'err'); return; }
      apiFetch(API + '/api/v1/utilisateurs/' + userIdEdition, { method: 'PUT', body: JSON.stringify(data) }).then(function(res) {
        if (!res.success) throw new Error(res.message || 'Erreur');
        msg('Utilisateur mis a jour.');
        fermerModal();
        chargerUtilisateurs();
        chargerStats();
      }).catch(function(e) { msg('Erreur: ' + e.message, 'err'); });
    });

    function getUserId() {
      try { return JSON.parse(sessionStorage.getItem('mp_user') || '{}').id || null; } catch(e) { return null; }
    }

    document.getElementById('modalEdit').addEventListener('click', function(e) {
      if (e.target === this) fermerModal();
    });

    chargerStats();
    chargerUtilisateurs();
  })();
  </script>
</body>
</html>
