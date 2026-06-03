<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Alertes de prix - Meilleur Prix</title>
  <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
  <style>
    .alertes-layout { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }
    .badge { display: inline-block; padding: 0.2rem 0.6rem; border-radius: 999px; font-size: 0.75rem; font-weight: 600; }
    .badge-INFERIEUR { background: #dbeafe; color: #1d4ed8; }
    .badge-SUPERIEUR { background: #fee2e2; color: #dc2626; }
    .badge-actif { background: #d1fae5; color: #059669; }
    .badge-inactif { background: #f3f4f6; color: #6b7280; }
    .badge-declenche { background: #fef3c7; color: #d97706; }
    .alert-item { display: flex; justify-content: space-between; align-items: center; padding: 0.75rem 0; border-bottom: 1px solid var(--border); }
    .alert-item:last-child { border-bottom: none; }
    .alert-info { flex: 1; }
    .alert-actions { display: flex; gap: 0.5rem; align-items: center; }
    .historique-item { padding: 0.6rem 0; border-bottom: 1px solid #f3f4f6; font-size: 0.87rem; }
    .historique-item:last-child { border-bottom: none; }
    .notif-badge { background: #ef4444; color: #fff; border-radius: 999px; padding: 0.15rem 0.45rem; font-size: 0.7rem; font-weight: 700; margin-left: 0.3rem; }
    .empty-state { text-align: center; padding: 2rem; color: var(--text-muted); }
    .inline-flex { display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; }
    @media (max-width: 768px) { .alertes-layout { grid-template-columns: 1fr; } }
  </style>
</head>
<body>
  <%@ include file="_header.jsp" %>
  <div class="page-header">
    <div class="container">
      <h1>Alertes de prix</h1>
      <p>Recevez une notification quand un prix atteint le seuil que vous avez defini</p>
    </div>
  </div>
  <div class="container" style="padding-top:1.5rem">
    <div id="msg" class="message hidden"></div>
    <div class="alertes-layout">
      <div class="card">
        <div class="card-header">
          <h2>Nouvelle alerte</h2>
        </div>
        <div class="card-body">
          <form id="formAlerte">
            <div class="form-group">
              <label for="produit_id">Produit</label>
              <select id="produit_id" class="form-control" required>
                <option value="">Chargement...</option>
              </select>
            </div>
            <div class="form-group">
              <label for="marche_id">Marche (optionnel, tous si vide)</label>
              <select id="marche_id" class="form-control">
                <option value="">Tous les marches</option>
              </select>
            </div>
            <div class="form-group">
              <label for="prix_seuil">Prix seuil (Ar)</label>
              <input type="number" id="prix_seuil" class="form-control" step="100" min="1" required placeholder="Ex: 2000">
            </div>
            <div class="form-group">
              <label for="type_seuil">Condition</label>
              <select id="type_seuil" class="form-control" required>
                <option value="INFERIEUR">Prix inferieur au seuil</option>
                <option value="SUPERIEUR">Prix superieur au seuil</option>
              </select>
            </div>
            <button type="submit" class="btn btn-primary btn-block">Creer l'alerte</button>
          </form>
        </div>
      </div>
      <div>
        <div class="card" style="margin-bottom:1.5rem">
          <div class="card-header">
            <div class="inline-flex">
              <h2>Mes alertes</h2>
              <span id="notifBadge" class="notif-badge" style="display:none">0</span>
            </div>
          </div>
          <div class="card-body" id="listeAlertes">
            <div class="empty-state">Chargement...</div>
          </div>
        </div>
        <div class="card">
          <div class="card-header">
            <div class="inline-flex">
              <h2>Historique des declenchements</h2>
              <button id="btnMarquerLues" class="btn btn-sm" style="display:none">Tout marquer lu</button>
            </div>
          </div>
          <div class="card-body" id="listeHistorique">
            <div class="empty-state">Chargement...</div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <script src="<%= request.getContextPath() %>/js/api.js"></script>
  <script>
  (function() {
    if (typeof requireAuth === 'function' && !requireAuth()) return;

    var API = window.API_URL;

    function msg(text, type) {
      var el = document.getElementById('msg');
      el.textContent = text;
      el.className = 'message ' + (type || 'success');
      if (text) setTimeout(function() { el.className = 'message hidden'; }, 4000);
    }

    function chargerProduits() {
      apiFetch(API + '/api/v1/produits').then(function(res) {
        if (!res.success) throw new Error('Erreur chargement produits');
        var sel = document.getElementById('produit_id');
        sel.innerHTML = '<option value="">Selectionner un produit</option>';
        res.data.forEach(function(p) {
          sel.innerHTML += '<option value="' + p.id + '">' + (p.nom_fr || p.nom_mg || '') + '</option>';
        });
      }).catch(function(e) { msg('Erreur: ' + e.message, 'err'); });
    }

    function chargerMarches() {
      apiFetch(API + '/api/v1/marches').then(function(res) {
        if (!res.success) throw new Error('Erreur chargement marches');
        var sel = document.getElementById('marche_id');
        var curr = sel.value;
        sel.innerHTML = '<option value="">Tous les marches</option>';
        res.data.forEach(function(m) {
          sel.innerHTML += '<option value="' + m.id + '">' + (m.nom || m.ville || '') + ' - ' + (m.ville || '') + '</option>';
        });
        if (curr) sel.value = curr;
      }).catch(function(e) { msg('Erreur: ' + e.message, 'err'); });
    }

    function chargerAlertes() {
      apiFetch(API + '/api/v1/alertes').then(function(res) {
        if (!res.success) throw new Error('Erreur chargement alertes');
        var el = document.getElementById('listeAlertes');
        if (!res.data || res.data.length === 0) {
          el.innerHTML = '<div class="empty-state">Aucune alerte pour le moment.</div>';
          return;
        }
        el.innerHTML = res.data.map(function(a) {
          var badgeType = 'badge-' + a.type_seuil;
          var badgeEtat = a.est_actif ? 'badge-actif' : 'badge-inactif';
          return '<div class="alert-item">' +
            '<div class="alert-info">' +
              '<strong>' + (a.produit_nom || 'Produit') + '</strong>' +
              (a.marche_nom ? ' @ ' + a.marche_nom + ' (' + a.marche_ville + ')' : ' (tous marches)') +
              '<br><span class="badge ' + badgeType + '">' + (a.type_seuil === 'INFERIEUR' ? '<' : '>') + ' ' + parseFloat(a.prix_seuil).toLocaleString('fr-FR') + ' Ar</span> ' +
              '<span class="badge ' + badgeEtat + '">' + (a.est_actif ? 'Actif' : 'Inactif') + '</span>' +
              (a.date_dernier_declenchement ? ' <span class="badge badge-declenche">Declenchee</span>' : '') +
            '</div>' +
            '<div class="alert-actions">' +
              '<button class="btn btn-sm" onclick="basculerAlerte(\'' + a.id + '\')">' + (a.est_actif ? 'Desactiver' : 'Activer') + '</button>' +
              '<button class="btn btn-sm btn-danger" onclick="supprimerAlerte(\'' + a.id + '\')">Supprimer</button>' +
            '</div></div>';
        }).join('');
      }).catch(function(e) { msg('Erreur: ' + e.message, 'err'); });
    }

    function chargerHistorique() {
      apiFetch(API + '/api/v1/alertes/historique').then(function(res) {
        if (!res.success) throw new Error('Erreur chargement historique');
        var el = document.getElementById('listeHistorique');
        if (!res.data || res.data.length === 0) {
          el.innerHTML = '<div class="empty-state">Aucun declenchement.</div>';
          return;
        }
        el.innerHTML = res.data.map(function(h) {
          var date = new Date(h.date_declenchement);
          return '<div class="historique-item' + (h.est_lue ? '' : ' unread') + '">' +
            '<strong>' + (h.produit_nom || 'Produit') + '</strong>' +
            (h.marche_nom ? ' @ ' + h.marche_nom : '') +
            ' : <strong>' + parseFloat(h.prix_actuel).toLocaleString('fr-FR') + ' Ar</strong> ' +
            (h.type_seuil === 'INFERIEUR' ? 'devenu <' : 'devenu >') +
            ' ' + parseFloat(h.prix_seuil).toLocaleString('fr-FR') + ' Ar' +
            '<br><small>' + date.toLocaleString('fr-FR') + '</small></div>';
        }).join('');
        document.getElementById('btnMarquerLues').style.display = 'inline-block';
      }).catch(function(e) { msg('Erreur: ' + e.message, 'err'); });
    }

    function chargerNonLues() {
      apiFetch(API + '/api/v1/alertes/non-lues').then(function(res) {
        if (!res.success) return;
        var badge = document.getElementById('notifBadge');
        if (res.data && res.data.nb > 0) {
          badge.textContent = res.data.nb;
          badge.style.display = 'inline';
        } else {
          badge.style.display = 'none';
        }
      }).catch(function() {});
    }

    window.basculerAlerte = function(id) {
      apiFetch(API + '/api/v1/alertes/' + id + '/toggle', { method: 'PATCH' }).then(function(res) {
        if (!res.success) throw new Error('Erreur');
        chargerAlertes();
      }).catch(function(e) { msg('Erreur: ' + e.message, 'err'); });
    };

    window.supprimerAlerte = function(id) {
      if (!confirm('Supprimer cette alerte ?')) return;
      apiFetch(API + '/api/v1/alertes/' + id, { method: 'DELETE' }).then(function(res) {
        if (!res.success) throw new Error('Erreur');
        chargerAlertes();
      }).catch(function(e) { msg('Erreur: ' + e.message, 'err'); });
    };

    document.getElementById('formAlerte').addEventListener('submit', function(e) {
      e.preventDefault();
      var data = {
        produit_id: document.getElementById('produit_id').value,
        marche_id: document.getElementById('marche_id').value || null,
        prix_seuil: parseFloat(document.getElementById('prix_seuil').value),
        type_seuil: document.getElementById('type_seuil').value
      };
      if (!data.produit_id) { msg('Selectionnez un produit.', 'err'); return; }
      if (!data.prix_seuil || data.prix_seuil <= 0) { msg('Prix seuil invalide.', 'err'); return; }
      apiFetch(API + '/api/v1/alertes', { method: 'POST', body: JSON.stringify(data) }).then(function(res) {
        if (!res.success) throw new Error(res.message || 'Erreur creation');
        msg('Alerte creee avec succes !');
        document.getElementById('formAlerte').reset();
        chargerAlertes();
      }).catch(function(e) { msg('Erreur: ' + e.message, 'err'); });
    });

    document.getElementById('btnMarquerLues').addEventListener('click', function() {
      apiFetch(API + '/api/v1/alertes/lues', { method: 'PUT' }).then(function(res) {
        if (!res.success) throw new Error('Erreur');
        chargerHistorique();
        chargerNonLues();
        document.getElementById('btnMarquerLues').style.display = 'none';
      }).catch(function(e) { msg('Erreur: ' + e.message, 'err'); });
    });

    chargerProduits();
    chargerMarches();
    chargerAlertes();
    chargerHistorique();
    chargerNonLues();
  })();
  </script>
</body>
</html>
