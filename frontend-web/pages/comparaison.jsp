<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="_header.jsp" %>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Comparaison des Prix - Meilleur Prix</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css" />
  <style>
    .compare-layout { display: flex; gap: 1.25rem; }
    .compare-sidebar { width: 380px; flex-shrink: 0; }
    .compare-main { flex: 1; }
    .compare-main #map { width: 100%; height: 400px; border-radius: var(--radius-lg); }
    .route-info { margin-top: 0.75rem; }
    .route-info .result-item { display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--border); font-size: 0.88rem; }
    .route-info .result-item:last-child { border-bottom: none; }
    .search-prod-wrap, .search-marche-wrap { position: relative; }
    .search-prod-wrap input, .search-marche-wrap input { width: 100%; padding: 0.55rem 0.75rem; border: 1.5px solid var(--border); border-radius: var(--radius); font-size: 0.85rem; background: var(--surface); font-family: inherit; }
    .search-results { position: absolute; top: 100%; left: 0; right: 0; background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); max-height: 180px; overflow-y: auto; z-index: 10; display: none; box-shadow: var(--shadow); }
    .search-results .sr-item { padding: 0.5rem 0.75rem; cursor: pointer; font-size: 0.82rem; border-bottom: 1px solid var(--border); }
    .search-results .sr-item:hover { background: var(--bg); }
    .compare-marche-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem; }
    @media (max-width: 900px) { .compare-layout { flex-direction: column; } .compare-sidebar { width: 100%; } }
  </style>
</head>
<body>
  <div class="page-header">
    <h1>Comparaison Inter-Marche</h1>
    <p>Recherchez un produit et un marche pour comparer les prix</p>
  </div>
  <div class="container">
    <div class="compare-layout">
      <div class="compare-sidebar">
        <div class="card">
          <div class="card-header"><span class="card-title">Parametres</span></div>
          <div class="form-group">
            <label>Produit</label>
            <div class="search-prod-wrap">
              <input type="text" id="searchProduit" placeholder="Tapez le nom du produit...">
              <div class="search-results" id="prodResults"></div>
            </div>
          </div>
          <div class="form-group">
            <label>Marche de depart</label>
            <div class="search-marche-wrap">
              <input type="text" id="searchMarche" placeholder="Tapez le nom du marche...">
              <div class="search-results" id="marcheResults"></div>
            </div>
          </div>
          <button id="btnCompare" class="btn btn-primary btn-block">Comparer les prix</button>
          <div id="loadingCompare" class="loading hidden"><div class="spinner"></div> Calcul en cours...</div>
        </div>
        <div class="card" id="resultatCard" style="display:none;">
          <div class="card-header"><span class="card-title">Meilleur choix</span></div>
          <div id="resultat"></div>
        </div>
      </div>
      <div class="compare-main">
        <div id="map"></div>
        <div class="card" id="tableauComparatif" style="display:none;">
          <div class="card-header"><span class="card-title">Comparatif detaille</span></div>
          <div class="table-wrapper">
            <table>
              <thead><tr><th>Marche</th><th>Ville</th><th>Prix</th><th>Transport</th><th>Cout total</th></tr></thead>
              <tbody id="comparatifBody"></tbody>
            </table>
          </div>
          <div id="tempsCalcul" style="margin-top:0.75rem;font-size:0.82rem;color:var(--text-muted);"></div>
        </div>
      </div>
    </div>
  </div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>
  <script>
  (function() {
    var API = window.API_URL + '/api/v1';
    var map = L.map('map').setView([-19.5, 46.5], 7);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution: '&copy; OpenStreetMap contributors', maxZoom: 19 }).addTo(map);
    var allMarches = [], marcheMarkers = {}, routeLines = [];
    var selectedProduit = null, selectedMarche = null;
    var searchTimer = null;

    function loadMarches() {
      fetch(API + '/marches').then(function(r){return r.json()}).then(function(j){
        if (j.success && j.data) {
          allMarches = j.data;
          allMarches.forEach(function(m) {
            var lat=parseFloat(m.latitude), lng=parseFloat(m.longitude);
            if (isNaN(lat)||isNaN(lng)) return;
            var mk = L.circleMarker([lat,lng], {radius:7, fillColor:'#0d6e6e', color:'#fff', weight:2, fillOpacity:0.7}).addTo(map);
            mk.bindPopup('<h3>'+m.nom+'</h3><p>'+m.ville+'</p>');
            marcheMarkers[m.id] = mk;
          });
        }
      }).catch(function(){});
    }

    function clearRoutes() {
      routeLines.forEach(function(l){map.removeLayer(l);});
      routeLines = [];
      Object.keys(marcheMarkers).forEach(function(id){marcheMarkers[id].setStyle({fillColor:'#0d6e6e',radius:7});});
    }

    function setupSearch(inputId, resultId, endpoint, onSelect) {
      document.getElementById(inputId).addEventListener('input', function() {
        clearTimeout(searchTimer);
        var q = this.value.trim();
        if (q.length < 2) { document.getElementById(resultId).style.display = 'none'; return; }
        searchTimer = setTimeout(function() {
          fetch(API + endpoint + encodeURIComponent(q))
            .then(function(r){return r.json()})
            .then(function(j){
              if (!j.success || !j.data) return;
              var res = document.getElementById(resultId);
              res.innerHTML = '';
              j.data.forEach(function(item) {
                var div = document.createElement('div');
                div.className = 'sr-item';
                div.textContent = item.nom_fr ? (item.nom_fr+'/'+(item.nom_mg||'')) : (item.nom||'');
                if (item.ville) div.textContent += ' - ' + item.ville;
                div.addEventListener('click', function() {
                  document.getElementById(inputId).value = item.nom_fr || item.nom || item.nom_mg || '';
                  res.style.display = 'none';
                  onSelect(item);
                });
                res.appendChild(div);
              });
              res.style.display = j.data.length ? 'block' : 'none';
            }).catch(function(){});
        }, 200);
      });
      document.addEventListener('click', function(e) {
        if (!e.target.closest('.'+inputId.replace('search','').toLowerCase()+'-wrap')) document.getElementById(resultId).style.display = 'none';
      });
    }

    setupSearch('searchProduit', 'prodResults', '/produits/search?q=', function(p) { selectedProduit = p; });

    function setupMarcheSearch() {
      var input = document.getElementById('searchMarche');
      var res = document.getElementById('marcheResults');
      input.addEventListener('input', function() {
        clearTimeout(searchTimer);
        var q = this.value.trim();
        if (q.length < 1) { res.style.display = 'none'; return; }
        searchTimer = setTimeout(function() {
          var filtered = allMarches.filter(function(m) { return (m.nom&&m.nom.toLowerCase().indexOf(q.toLowerCase())!==-1)||(m.ville&&m.ville.toLowerCase().indexOf(q.toLowerCase())!==-1); });
          res.innerHTML = '';
          filtered.forEach(function(m) {
            var div = document.createElement('div');
            div.className = 'sr-item';
            div.textContent = m.nom + ' - ' + m.ville;
            div.addEventListener('click', function() { input.value = m.nom; res.style.display = 'none'; selectedMarche = m; });
            res.appendChild(div);
          });
          res.style.display = filtered.length ? 'block' : 'none';
        }, 150);
      });
      document.addEventListener('click', function(e) { if (!e.target.closest('.search-marche-wrap')) res.style.display = 'none'; });
    }
    setupMarcheSearch();

    document.getElementById('btnCompare').addEventListener('click', async function() {
      if (!selectedProduit || !selectedMarche) {
        document.getElementById('resultatCard').style.display = 'block';
        document.getElementById('resultat').innerHTML = '<div class="message err">Veuillez selectionner un produit ET un marche de depart</div>';
        return;
      }
      var loading = document.getElementById('loadingCompare');
      var resultatCard = document.getElementById('resultatCard');
      var tableauCard = document.getElementById('tableauComparatif');
      loading.classList.remove('hidden');
      resultatCard.style.display = 'none';
      tableauCard.style.display = 'none';
      clearRoutes();
      try {
        var token = (function(){try{return sessionStorage.getItem('mp_token')}catch(e){return null}})();
        var headers = {'Content-Type':'application/json'};
        if (token) headers['Authorization'] = 'Bearer '+token;
        var res = await fetch(API + '/marches/comparer?produitId=' + encodeURIComponent(selectedProduit.id) + '&departId=' + encodeURIComponent(selectedMarche.id), {headers:headers});
        var json = await res.json();
        loading.classList.add('hidden');
        if (!json.success) throw new Error(json.message || 'Erreur serveur');
        var d = json.data;
        resultatCard.style.display = 'block';
        tableauCard.style.display = 'block';
        var optimal = d.marche_optimal;
        document.getElementById('resultat').innerHTML =
          '<div style="background:var(--bg);border-radius:8px;padding:1rem;">' +
          '<div style="font-size:0.82rem;color:var(--text-muted);">Marche optimal</div>' +
          '<div style="font-size:1.2rem;font-weight:700;color:var(--primary);margin-top:0.15rem;">' + (optimal ? optimal.nom : 'N/A') + '</div>' +
          '<div style="font-size:0.9rem;margin-top:0.3rem;">Cout total: <strong>' + d.cout_total + ' Ar</strong></div>' +
          '<div style="font-size:0.8rem;color:var(--text-muted);margin-top:0.2rem;">Temps: ' + d.temps_calcul_ms + ' ms</div>' +
          '</div>';
          document.getElementById('tempsCalcul').textContent = 'Temps de calcul: ' + d.temps_calcul_ms + ' ms | Algorithme: Dijkstra';
        var tbody = document.getElementById('comparatifBody');
        tbody.innerHTML = '';
        if (d.comparatif && d.comparatif.length) {
          d.comparatif.forEach(function(c) {
            var tr = document.createElement('tr');
            var photo = c.marche.photo_url || ''; var imgHtml = photo ? '<img src="'+photo+'" style="width:36px;height:36px;border-radius:6px;object-fit:cover;margin-right:8px;vertical-align:middle;" alt="" loading="lazy">' : ''; tr.innerHTML = '<td>'+imgHtml+'<strong>' + (c.marche.nom||'') + '</strong></td><td style="font-size:0.82rem;color:var(--text-muted);">' + (c.marche.ville||'') + '</td><td>' + (c.prix_produit||0) + ' Ar</td><td>' + (c.cout_transport ? c.cout_transport + ' Ar' : '-') + '</td><td><strong>' + c.cout_total + ' Ar</strong></td>';
            if (c.cout_total === d.cout_total) tr.style.background = '#e6f7ee';
            tbody.appendChild(tr);
            var m = allMarches.find(function(x){return x.id === c.marche.id;});
            if (m && marcheMarkers[m.id]) marcheMarkers[m.id].setStyle({fillColor: c.cout_total===d.cout_total?'#1a8a5c':'#0d6e6e', radius: c.cout_total===d.cout_total?10:7});
          });
        }
        if (d.chemin && d.chemin.length > 1) {
          var points = [];
          d.chemin.forEach(function(marchId) {
            var m = allMarches.find(function(x){return x.id === marchId;});
            if (m) points.push([parseFloat(m.latitude), parseFloat(m.longitude)]);
          });
          if (points.length >= 2) {
            var line = L.polyline(points, {color:'#e8a838', weight:3, dashArray:'8,8', opacity:0.8}).addTo(map);
            routeLines.push(line);
            map.fitBounds(line.getBounds(), {padding:[40,40]});
          }
        }
      } catch (err) {
        loading.classList.add('hidden');
        resultatCard.style.display = 'block';
        document.getElementById('resultat').innerHTML = '<div class="message err">' + err.message + '</div>';
      }
    });
    loadMarches();
  })();
  </script>
</body>
</html>