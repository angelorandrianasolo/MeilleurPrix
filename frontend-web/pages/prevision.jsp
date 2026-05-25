<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="_header.jsp" %>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Prevision des Prix - Meilleur Prix</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>
  <style>
    .prev-grid { display: grid; grid-template-columns: 1fr; gap: 1.25rem; }
    .prev-selector { display: flex; gap: 0.75rem; align-items: end; flex-wrap: wrap; }
    .prev-selector .form-group { flex: 1; min-width: 200px; }
    .prev-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 0.75rem; margin-top: 1rem; }
    .prev-stat { background: var(--bg); padding: 0.85rem; border-radius: var(--radius); text-align: center; }
    .prev-stat .val { font-size: 1.1rem; font-weight: 700; color: var(--primary); }
    .prev-stat .lbl { font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.03em; }
    .prev-chart-wrap { height: 320px; }
    .prev-selector .search-wrap { position: relative; flex: 1; min-width: 200px; }
    .prev-selector .search-wrap input { width: 100%; padding: 0.55rem 0.75rem; border: 1.5px solid var(--border); border-radius: var(--radius); font-size: 0.85rem; background: var(--surface); font-family: inherit; }
    .prev-selector .search-results { position: absolute; top: 100%; left: 0; right: 0; background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); max-height: 200px; overflow-y: auto; z-index: 10; display: none; box-shadow: var(--shadow); }
    .prev-selector .search-results .sr-item { padding: 0.5rem 0.75rem; cursor: pointer; font-size: 0.85rem; border-bottom: 1px solid var(--border); }
    .prev-selector .search-results .sr-item:hover { background: var(--bg); }
    .comparison-table { font-size: 0.85rem; }
    .comparison-table td { padding: 0.5rem 0.75rem; }
    @media (max-width: 768px) { .prev-stats { grid-template-columns: 1fr 1fr; } }
  </style>
</head>
<body>
  <div class="page-header">
    <h1>Prevision des Prix</h1>
    <p>Courbe d'evolution et prevision 30 jours par moyenne mobile ponderee + DP</p>
  </div>
  <div class="container">
    <div class="card">
      <div class="card-header"><span class="card-title">Selection du produit</span></div>
      <div class="prev-selector">
        <div class="search-wrap">
          <input type="text" id="prevSearch" placeholder="Rechercher un produit par nom..." autocomplete="off">
          <div class="search-results" id="prevSearchResults"></div>
        </div>
        <button class="btn btn-primary" id="btnPrevLoad">Afficher la prevision</button>
      </div>
    </div>
    <div class="prev-grid">
      <div class="card" id="prevChartCard" style="display:none;">
        <div class="card-header"><span class="card-title" id="prevProductTitle">Prevision</span></div>
        <div class="chart-wrapper"><div class="prev-chart-wrap"><canvas id="chartPrev"></canvas></div></div>
        <div class="prev-stats" id="prevMetrics">
          <div class="prev-stat"><div class="val" id="prixActuel">-</div><div class="lbl">Prix actuel</div></div>
          <div class="prev-stat"><div class="val" id="prixPrevu">-</div><div class="lbl">Prevision J+30</div></div>
          <div class="prev-stat"><div class="val" id="tendance">-</div><div class="lbl">Tendance</div></div>
          <div class="prev-stat"><div class="val" id="donneesCount">-</div><div class="lbl">Jours d'historique</div></div>
        </div>
      </div>
      <div class="card" id="prevCompareCard" style="display:none;">
        <div class="card-header"><span class="card-title">Comparaison des methodes</span></div>
        <div class="table-wrapper">
          <table>
            <thead><tr><th>Methode</th><th>Description</th><th>Erreur (MAE)</th><th>J+30 prevu</th></tr></thead>
            <tbody id="compareBody"></tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
  <script>
  (function() {
    var API = window.API_URL + '/api/v1';
    var chartInstance = null;
    var selectedProduit = null;
    var searchTimer = null;

    function getToken() { try{return sessionStorage.getItem('mp_token')||localStorage.getItem('mp_token')}catch(e){return null} }
    function getHeaders() { var h={'Content-Type':'application/json'}; var t=getToken(); if(t)h['Authorization']='Bearer '+t; return h; }

    function formatDate(ts) { var d = new Date(ts); return d.toLocaleDateString('fr-FR', { day: '2-digit', month: 'short' }); }

    function loadGlobalPrevision() {
      var token = getToken();
      if (!token) { document.getElementById('prevProductTitle').textContent = 'Connexion requise'; return; }
      document.getElementById('prevChartCard').style.display = 'block';
      document.getElementById('prevProductTitle').textContent = 'Prevision globale - Tous marches';
      fetch(API + '/dashboard', {headers:{'Authorization':'Bearer '+token}})
        .then(function(r){return r.json()})
        .then(function(j){
          if (!j.success) throw new Error(j.message);
          var d = j.data, stats = d.statistiques||{}, trend = d.tendance_30j||d.evolution_prix||d.tendance||[];
          var latestPrix = trend.length ? parseFloat(trend[trend.length-1].prix_moyen_global||0) : 0;
          var firstPrix = trend.length ? parseFloat(trend[0].prix_moyen_global||0) : 0;
          var tendanceLabel = trend.length ? (latestPrix > firstPrix ? 'Hausse' : (latestPrix < firstPrix ? 'Baisse' : 'Stable')) : 'Stable';
          document.getElementById('prixActuel').textContent = latestPrix+' Ar';
          document.getElementById('prixPrevu').textContent = (stats.nb_saisies_total||0)+' saisies';
          document.getElementById('tendance').textContent = tendanceLabel;
          document.getElementById('donneesCount').textContent = (stats.nb_produits||0)+' produits';
          if (trend.length) {
            var labels = trend.map(function(p){ var dd=new Date(p.date_jour); return dd.toLocaleDateString('fr-FR',{day:'2-digit',month:'short'}); });
            var data = trend.map(function(p){ return parseFloat(p.prix_moyen_global||0); });
            if (chartInstance) { try{chartInstance.destroy()}catch(e){} chartInstance=null; }
            var ctx = document.getElementById('chartPrev').getContext('2d');
            chartInstance = new Chart(ctx, {
              type: 'line',
              data: { labels: labels, datasets: [{label:'Prix moyen global',data:data,borderColor:'#0f766e',backgroundColor:'rgba(15,118,110,0.06)',fill:true,tension:0.4,pointRadius:3,pointBackgroundColor:'#0f766e'}]},
              options: { responsive:true, maintainAspectRatio:true, plugins:{ legend:{position:'top',labels:{font:{size:12}}}, tooltip:{callbacks:{label:function(ctx){return ctx.parsed.y+' Ar'}}} }, scales:{ x:{ticks:{maxTicksLimit:15,font:{size:11}}}, y:{beginAtZero:false,ticks:{callback:function(v){return v+' Ar'},font:{size:11}}} } }
            });
          }
        })
        .catch(function(err){ document.getElementById('prixActuel').textContent = 'Erreur'; document.getElementById('prixPrevu').textContent = err.message; });
    }

    function loadPrevision(p) {
      selectedProduit = p;
      document.getElementById('prevProductTitle').textContent = 'Prevision: '+(p.nom_fr||p.nom_mg||'');
      document.getElementById('prevChartCard').style.display = 'block';
      document.getElementById('prixActuel').textContent = '...';
      fetch(API + '/previsions/' + encodeURIComponent(p.id), {headers:getHeaders()})
        .then(function(r){return r.json()})
        .then(function(j){
          if (!j.success) throw new Error(j.message || 'Erreur');
          var d = j.data;
          document.getElementById('prixActuel').textContent = (d.prix_actuel || 0) + ' Ar';
          var prevuOptimise = d.prix_prevu_optimise || (d.prevision_optimisee && d.prevision_optimisee.length ? d.prevision_optimisee[d.prevision_optimisee.length-1] : 0);
          var prevuSimple = d.prix_prevu_simple || (d.prevision_simple && d.prevision_simple.length ? d.prevision_simple[d.prevision_simple.length-1] : 0);
          document.getElementById('prixPrevu').textContent = prevuOptimise + ' Ar';
          var tendance = d.tendance || (d.prix_prevu_optimise > d.prix_actuel ? 'Hausse' : 'Baisse');
          document.getElementById('tendance').textContent = tendance;
          var compareBody = document.getElementById('compareBody');
          compareBody.innerHTML = '<tr><td><strong>Moyenne simple</strong></td><td>Moyenne arithmetique</td><td>'+(d.comparaison&&d.comparaison.erreur_simple!=null?d.comparaison.erreur_simple+' Ar':'N/A')+'</td><td>'+prevuSimple+' Ar</td></tr><tr style="background:var(--success-bg)"><td><strong>Fenetre glissante + DP</strong></td><td>Moyenne ponderee avec selection optimale</td><td><strong>'+(d.comparaison&&d.comparaison.erreur_optimisee!=null?d.comparaison.erreur_optimisee+' Ar':'N/A')+'</strong></td><td><strong>'+prevuOptimise+' Ar</strong></td></tr>';
          document.getElementById('prevCompareCard').style.display = 'block';
          var labels = [], histData = [], prevData = [];
          if (d.historique) d.historique.forEach(function(h){ var dd=new Date(h.date); labels.push(dd.toLocaleDateString('fr-FR',{day:'2-digit',month:'short'})); histData.push(parseFloat(h.valeur||h.prix)); });
          if (d.prevision_optimisee) d.prevision_optimisee.forEach(function(v,i){ labels.push('J+'+(i+1)); prevData.push(v); });
          else if (d.previsions) d.previsions.forEach(function(h,i){ labels.push('J+'+(i+1)); prevData.push(h.optimise||null); });
          if (chartInstance) { try{chartInstance.destroy()}catch(e){} chartInstance=null; }
          var ctx = document.getElementById('chartPrev').getContext('2d');
          chartInstance = new Chart(ctx, {
            type: 'line',
            data: { labels: labels, datasets: [
              { label: 'Historique', data: histData, borderColor: '#0f766e', backgroundColor: 'rgba(15,118,110,0.06)', fill: true, tension: 0.4, pointRadius: 3, pointBackgroundColor: '#0f766e' },
              { label: 'Prevision (courbe)', data: prevData, borderColor: '#ea580c', backgroundColor: 'rgba(234,88,12,0.06)', fill: true, borderDash: [5,5], pointRadius: 3, tension: 0.4 }
            ]},
            options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { position: 'top', labels: { font: { size: 12 } } }, tooltip: { callbacks: { label: function(ctx) { return ctx.dataset.label + ': ' + ctx.parsed.y + ' Ar'; } } } }, scales: { x: { ticks: { maxTicksLimit: 15, font: { size: 11 } } }, y: { beginAtZero: false, ticks: { callback: function(v) { return v + ' Ar'; }, font: { size: 11 } } } } }
          });
        })
        .catch(function(err){
          document.getElementById('prixActuel').textContent = 'Erreur';
          document.getElementById('prixPrevu').textContent = err.message;
        });
    }

    document.getElementById('prevSearch').addEventListener('input', function() {
      clearTimeout(searchTimer);
      var q = this.value.trim();
      if (q.length < 2) { document.getElementById('prevSearchResults').style.display = 'none'; return; }
      searchTimer = setTimeout(function() {
        fetch(API + '/produits/search?q=' + encodeURIComponent(q))
          .then(function(r){return r.json()})
          .then(function(j){
            if (!j.success || !j.data) return;
            var res = document.getElementById('prevSearchResults');
            res.innerHTML = '';
            j.data.forEach(function(p) {
              var div = document.createElement('div');
              div.className = 'sr-item';
              div.textContent = (p.nom_fr||'')+' / '+(p.nom_mg||'');
              div.addEventListener('click', function() {
                document.getElementById('prevSearch').value = p.nom_fr||p.nom_mg||'';
                res.style.display = 'none';
                loadPrevision(p);
              });
              res.appendChild(div);
            });
            res.style.display = j.data.length ? 'block' : 'none';
          }).catch(function(){});
      }, 200);
    });

    document.addEventListener('click', function(e) {
      if (!e.target.closest('.search-wrap')) document.getElementById('prevSearchResults').style.display = 'none';
    });

    document.getElementById('btnPrevLoad').addEventListener('click', function() {
      var q = document.getElementById('prevSearch').value.trim();
      if (!q) return;
      fetch(API + '/produits/search?q=' + encodeURIComponent(q))
        .then(function(r){return r.json()})
        .then(function(j){ if (j.success && j.data && j.data.length) loadPrevision(j.data[0]); })
        .catch(function(){});
    });

    var savedProduit = (function(){try{return JSON.parse(sessionStorage.getItem('mp_produit'))}catch(e){return null}})();
    if (savedProduit && (savedProduit.nom_fr||savedProduit.nom_mg)) {
      document.getElementById('prevSearch').value = savedProduit.nom_fr||savedProduit.nom_mg||'';
      loadPrevision(savedProduit);
    } else {
      loadGlobalPrevision();
    }
  })();
  </script>
</body>
</html>