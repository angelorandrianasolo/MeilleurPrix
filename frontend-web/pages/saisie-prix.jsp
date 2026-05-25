<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="_header.jsp" %>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Saisie des Prix - Meilleur Prix</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css" />
  <style>
    .saisie-layout { display: grid; grid-template-columns: 1fr 1fr; gap: 1.25rem; }
    .saisie-layout #map { width: 100%; height: 100%; min-height: 350px; border-radius: var(--radius-lg); }
    .search-select { position: relative; }
    .search-select .dropdown { position: absolute; top: 100%; left: 0; right: 0; background: #fff; border: 1px solid var(--border); border-radius: var(--radius); max-height: 200px; overflow-y: auto; z-index: 10; display: none; box-shadow: var(--shadow-lg); }
    .search-select .dropdown div { padding: 0.5rem 0.75rem; cursor: pointer; font-size: 0.88rem; border-bottom: 1px solid var(--border); }
    .search-select .dropdown div:last-child { border-bottom: none; }
    .search-select .dropdown div:hover { background: var(--bg); }
    .info-badge { font-size: 0.82rem; background: var(--bg); padding: 0.5rem 0.75rem; border-radius: var(--radius); margin-bottom: 0.75rem; }
    .queue-badge { display: inline-block; background: #e67e22; color: #fff; font-size: 0.75rem; padding: 0.15rem 0.5rem; border-radius: 10px; margin-left: 0.5rem; vertical-align: middle; font-weight: 600; }
    @media (max-width: 768px) { .saisie-layout { grid-template-columns: 1fr; } }
  </style>
</head>
<body>
  <div class="page-header">
    <h1>Saisie des Prix<span id="queueBadge" class="queue-badge" style="display:none;"></span></h1>
    <p>Enregistrez le prix d'un produit dans un marche - validation automatique</p>
  </div>
  <div class="container">
    <div class="saisie-layout">
      <div>
        <div class="card">
          <div class="card-header"><span class="card-title">Nouvelle saisie</span></div>
          <div id="msg" class="message hidden"></div>

          <div class="form-group search-select" id="produitGroup">
            <label for="produitSearch">Produit</label>
            <input type="text" id="produitSearch" placeholder="Tapez le nom du produit...">
            <input type="hidden" id="produit_id">
            <div class="dropdown" id="produitDropdown"></div>
          </div>

          <div class="form-group search-select" id="marcheGroup">
            <label for="marcheSearch">Marche</label>
            <input type="text" id="marcheSearch" placeholder="Tapez le nom du marche...">
            <input type="hidden" id="marche_id">
            <div class="dropdown" id="marcheDropdown"></div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label for="prix">Prix (Ariary)</label>
              <input type="number" id="prix" step="0.01" min="0.01" required>
            </div>
            <div class="form-group">
              <label for="unite">Unite</label>
              <select id="unite">
                <option value="kg">kg</option>
                <option value="L">Litre</option>
                <option value="piece">Piece</option>
                <option value="botte">Botte</option>
                <option value="sac">Sac</option>
              </select>
            </div>
          </div>

          <button id="btnSaisie" class="btn btn-primary btn-block">Enregistrer le prix</button>
          <div id="loadingSaisie" class="loading hidden"><div class="spinner"></div> Enregistrement...</div>

          <div id="validationInfo" class="info-badge" style="margin-top:0.75rem;display:none;"></div>
        </div>
      </div>

      <div>
        <div class="map-container" id="mapContainer" style="display:none;">
          <div id="map"></div>
        </div>
        <div class="card" id="emptyMapSaisie">
          <div class="empty-state">
            <p>Selectionnez un marche pour voir sa position sur la carte</p>
          </div>
        </div>

        <div class="card" id="lastSaisies" style="display:none;">
          <div class="card-header"><span class="card-title">Dernieres saisies</span></div>
          <div class="table-wrapper">
            <table><thead><tr><th>Produit</th><th>Marche</th><th>Prix</th><th>Date</th></tr></thead>
              <tbody id="lastSaisiesBody"></tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>
  <script>
  (function() {
    var API = window.API_URL + '/api/v1';
    var map = null;
    var mapInit = false;
    var marcheMarker = null;
    var allProduits = [];
    var allMarches = [];

    function getToken() {
      try { return sessionStorage.getItem('mp_token') || localStorage.getItem('mp_token'); } catch(e) { return null; }
    }

    function getApiHeaders() {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + (getToken() || '')
      };
    }

    // ---- Offline Queue ----
    function getQueue() {
      try { return JSON.parse(localStorage.getItem('offline_saisies') || '[]'); } catch(e) { return []; }
    }

    function saveQueue(queue) {
      localStorage.setItem('offline_saisies', JSON.stringify(queue));
    }

    function updateQueueBadge() {
      var queue = getQueue();
      var badge = document.getElementById('queueBadge');
      if (queue.length > 0) {
        badge.textContent = queue.length + ' hors ligne';
        badge.style.display = 'inline-block';
      } else {
        badge.style.display = 'none';
      }
    }

    function addToQueue(pid, mid, prix) {
      var queue = getQueue();
      queue.push({pid: pid, mid: mid, prix: prix, ts: new Date().toISOString()});
      saveQueue(queue);
      updateQueueBadge();
    }

    function showMessage(text, type) {
      var msg = document.getElementById('msg');
      msg.textContent = text;
      msg.className = 'message ' + type;
    }

    async function syncQueue() {
      var queue = getQueue();
      if (queue.length === 0) return;

      var synced = 0;
      var remaining = [];

      for (var i = 0; i < queue.length; i++) {
        var entry = queue[i];
        try {
          var res = await fetch(API + '/prix', {
            method: 'POST',
            headers: getApiHeaders(),
            body: JSON.stringify({
              produit_id: entry.pid,
              marche_id: entry.mid,
              valeur: entry.prix,
              unite: 'kg',
              source_saisie: 'WEB_OFFLINE'
            })
          });
          var json = await res.json();
          if (json.success) {
            synced++;
          } else {
            remaining.push(entry);
          }
        } catch(e) {
          remaining.push(entry);
        }
      }

      saveQueue(remaining);
      updateQueueBadge();

      if (synced > 0) {
        showMessage(synced + ' saisie(s) synchronisées depuis le mode hors-ligne', 'ok');
        loadLastSaisies();
      }
    }
    // ---- End Offline Queue ----

    function initMap() {
      if (mapInit) return;
      document.getElementById('mapContainer').style.display = 'block';
      document.getElementById('emptyMapSaisie').style.display = 'none';
      map = L.map('map').setView([-19.5, 46.5], 7);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors', maxZoom: 19
      }).addTo(map);
      mapInit = true;
    }

    function showMarcheOnMap(marche) {
      initMap();
      if (marcheMarker) map.removeLayer(marcheMarker);
      var lat = parseFloat(marche.latitude);
      var lng = parseFloat(marche.longitude);
      if (isNaN(lat) || isNaN(lng)) return;
      marcheMarker = L.circleMarker([lat, lng], {
        radius: 10, fillColor: '#e8a838', color: '#fff', weight: 3, fillOpacity: 0.9
      }).addTo(map);
      marcheMarker.bindPopup('<h3>' + marche.nom + '</h3><p>' + marche.ville + '</p>').openPopup();
      map.setView([lat, lng], 13);
    }

    // ---- Pre-load reference data ----
    function loadProduits() {
      fetch(API + '/produits')
        .then(function(r) { return r.json(); })
        .then(function(json) {
          if (json.success && json.data) allProduits = json.data;
        }).catch(function() {});
    }

    function loadMarches() {
      fetch(API + '/marches')
        .then(function(r) { return r.json(); })
        .then(function(json) {
          if (json.success && json.data) allMarches = json.data;
        }).catch(function() {});
    }

    // ---- Search UI ----
    var prodTimer;
    document.getElementById('produitSearch').addEventListener('input', function() {
      clearTimeout(prodTimer);
      var q = this.value.trim();
      var dd = document.getElementById('produitDropdown');
      if (q.length < 2) { dd.style.display = 'none'; return; }
      prodTimer = setTimeout(function() {
        var filtered = allProduits.filter(function(p) {
          return (p.nom_fr && p.nom_fr.toLowerCase().indexOf(q.toLowerCase()) !== -1) ||
                 (p.nom_mg && p.nom_mg.toLowerCase().indexOf(q.toLowerCase()) !== -1) ||
                 (p.categorie && p.categorie.toLowerCase().indexOf(q.toLowerCase()) !== -1);
        });
        if (filtered.length) {
          dd.innerHTML = filtered.map(function(p) {
            return '<div data-id="' + p.id + '" data-nom="' + (p.nom_fr || '') + '">' +
              (p.nom_fr || '') + ' / ' + (p.nom_mg || '') + ' <span style="color:var(--text-muted);font-size:0.78rem;">' + (p.categorie || '') + '</span></div>';
          }).join('');
          dd.style.display = 'block';
          dd.querySelectorAll('div').forEach(function(div) {
            div.addEventListener('click', function() {
              document.getElementById('produitSearch').value = div.getAttribute('data-nom');
              document.getElementById('produit_id').value = div.getAttribute('data-id');
              dd.style.display = 'none';
            });
          });
        } else { dd.style.display = 'none'; }
      }, 200);
    });
    document.addEventListener('click', function(e) {
      if (!document.getElementById('produitGroup').contains(e.target)) {
        document.getElementById('produitDropdown').style.display = 'none';
      }
      if (!document.getElementById('marcheGroup').contains(e.target)) {
        document.getElementById('marcheDropdown').style.display = 'none';
      }
    });

    var marcheTimer;
    document.getElementById('marcheSearch').addEventListener('input', function() {
      clearTimeout(marcheTimer);
      var q = this.value.trim().toLowerCase();
      var dd = document.getElementById('marcheDropdown');
      if (q.length < 1) { dd.style.display = 'none'; return; }
      marcheTimer = setTimeout(function() {
        var filtered = allMarches.filter(function(m) {
          return (m.nom && m.nom.toLowerCase().indexOf(q) !== -1) ||
                 (m.ville && m.ville.toLowerCase().indexOf(q) !== -1);
        });
        if (filtered.length) {
          dd.innerHTML = filtered.map(function(m) {
            return '<div data-id="' + m.id + '" data-nom="' + m.nom + '" data-lat="' + m.latitude + '" data-lng="' + m.longitude + '" data-ville="' + (m.ville || '') + '">' +
              '<strong>' + m.nom + '</strong> <span style="color:var(--text-muted);font-size:0.78rem;">' + (m.ville || '') + '</span></div>';
          }).join('');
          dd.style.display = 'block';
          dd.querySelectorAll('div').forEach(function(div) {
            div.addEventListener('click', function() {
              document.getElementById('marcheSearch').value = div.getAttribute('data-nom');
              document.getElementById('marche_id').value = div.getAttribute('data-id');
              dd.style.display = 'none';
              showMarcheOnMap({
                id: div.getAttribute('data-id'),
                nom: div.getAttribute('data-nom'),
                ville: div.getAttribute('data-ville'),
                latitude: div.getAttribute('data-lat'),
                longitude: div.getAttribute('data-lng')
              });
            });
          });
        } else { dd.style.display = 'none'; }
      }, 200);
    });

    // ---- Submit ----
    document.getElementById('btnSaisie').addEventListener('click', async function() {
      var produitId = document.getElementById('produit_id').value;
      var marcheId = document.getElementById('marche_id').value;
      var prix = document.getElementById('prix').value;
      var unite = document.getElementById('unite').value;
      var msg = document.getElementById('msg');

      msg.className = 'message hidden';
      if (!produitId || !marcheId || !prix || prix <= 0) {
        msg.textContent = 'Veuillez remplir tous les champs correctement';
        msg.className = 'message err';
        return;
      }

      if (typeof navigator !== 'undefined' && navigator.onLine === false) {
        addToQueue(produitId, marcheId, prix);
        var queue = getQueue();
        showMessage('Sauvegardé localement (' + queue.length + ' en attente)', 'info');
        document.getElementById('prix').value = '';
        return;
      }

      var loading = document.getElementById('loadingSaisie');
      loading.classList.remove('hidden');

      try {
        var res = await fetch(API + '/prix', {
          method: 'POST',
          headers: getApiHeaders(),
          body: JSON.stringify({
            produit_id: produitId,
            marche_id: marcheId,
            valeur: prix,
            unite: unite,
            source_saisie: 'WEB'
          })
        });
        var json = await res.json();
        loading.classList.add('hidden');

        if (json.success) {
          msg.textContent = 'Prix enregistre avec succes !';
          msg.className = 'message ok';
          document.getElementById('prix').value = '';
          loadLastSaisies();
        } else {
          var errMsg = json.message || 'Erreur lors de l\'enregistrement';
          if (json.warning) errMsg += ' (Avertissement: ' + json.warning + ')';
          msg.textContent = errMsg;
          msg.className = 'message err';
          document.getElementById('validationInfo').style.display = 'block';
          document.getElementById('validationInfo').textContent = json.warning ? 'Attention: ' + json.warning : '';
        }
      } catch (err) {
        loading.classList.add('hidden');
        addToQueue(produitId, marcheId, prix);
        var queue = getQueue();
        showMessage('Sauvegardé localement (' + queue.length + ' en attente)', 'info');
        document.getElementById('prix').value = '';
      }
    });

    // ---- Recent entries ----
    function loadLastSaisies() {
      fetch(API + '/prix?limit=5')
        .then(function(r) { return r.json(); })
        .then(function(json) {
          if (json.success && json.data && json.data.length) {
            document.getElementById('lastSaisies').style.display = 'block';
            var tbody = document.getElementById('lastSaisiesBody');
            tbody.innerHTML = json.data.map(function(p) {
              var d = p.date_saisie ? new Date(p.date_saisie) : new Date();
              return '<tr><td>' + (p.nom_produit || p.produit_nom || '-') + '</td>' +
                '<td>' + (p.nom_marche || p.marche_nom || '-') + '</td>' +
                '<td><strong>' + (p.valeur || p.prix || 0) + ' Ar</strong></td>' +
                '<td>' + d.toLocaleDateString('fr-FR') + '</td></tr>';
            }).join('');
          }
        }).catch(function() {});
    }

    // ---- Init ----
    var params = new URLSearchParams(window.location.search);
    if (params.get('produit')) document.getElementById('produit_id').value = params.get('produit');
    if (params.get('marche')) document.getElementById('marche_id').value = params.get('marche');

    var saved = (function() { try { return JSON.parse(sessionStorage.getItem('mp_produit')); } catch(e) { return null; } })();
    if (saved && !params.get('produit')) {
      document.getElementById('produitSearch').value = saved.nom_fr || saved.nom_mg || '';
      document.getElementById('produit_id').value = saved.id;
    }

    loadProduits();
    loadMarches();
    loadLastSaisies();
    updateQueueBadge();

    if (typeof navigator !== 'undefined' && navigator.onLine !== false) {
      syncQueue();
    }

    window.addEventListener('online', function() {
      syncQueue();
    });
  })();
  </script>
</body>
</html>
