<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="_header.jsp" %>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Tableau de Bord - Meilleur Prix</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css" />
  <style>
    .stats-grid { gap: 1rem; }
    .stat-card { padding: 1.25rem 1.35rem; }
    .stat-card .stat-icon { width: 40px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; margin-bottom: 0.65rem; }
    .stat-card .stat-value { font-size: 1.6rem; }
    .stat-card .stat-label { font-size: 0.78rem; }
    .dash-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1.25rem; }
    .dash-grid-wide { grid-column: 1 / -1; }
    .top-list { list-style: none; }
    .top-list li { display: flex; align-items: center; padding: 0.65rem 0; border-bottom: 1px solid var(--border); font-size: 0.87rem; }
    .top-list li:last-child { border-bottom: none; }
    .top-list .rank { width: 26px; height: 26px; display: flex; align-items: center; justify-content: center; border-radius: 8px; font-size: 0.72rem; font-weight: 700; margin-right: 0.75rem; flex-shrink: 0; }
    .top-list .rank-1 { background: #fef3c7; color: #b45309; }
    .top-list .rank-2 { background: #f1f5f9; color: #64748b; }
    .top-list .rank-3 { background: #fde8e8; color: #b91c1c; }
    .top-list .rank-other { background: var(--bg-alt); color: var(--text-muted); }
    .top-list .item-info { flex: 1; min-width: 0; }
    .top-list .item-info .name { font-weight: 600; color: var(--text); }
    .top-list .item-info .meta { font-size: 0.76rem; color: var(--text-muted); }
    .top-list .item-value { font-weight: 700; color: var(--primary); }
    .chart-wrapper { padding: 1rem; }
    .chart-wrapper .chart-height { height: 240px; }
    #dashMap { height: 300px; border-radius: var(--radius-lg); margin-top: 0.5rem; }
    .market-prices { display: flex; flex-wrap: wrap; gap: 0.5rem; margin-top: 0.5rem; }
    .market-price-chip { background: var(--bg-alt); border-radius: 999px; padding: 0.25rem 0.7rem; font-size: 0.75rem; white-space: nowrap; }
    .market-price-chip strong { color: var(--primary); }
    .activity-empty { text-align: center; padding: 2rem; color: var(--text-muted); font-size: 0.85rem; }
    .kpi-trend { font-size: 0.72rem; display: flex; align-items: center; gap: 0.25rem; margin-top: 0.15rem; }
    .kpi-trend.up { color: var(--success); }
    .kpi-trend.down { color: var(--danger); }
    @media (max-width: 768px) { .dash-grid { grid-template-columns: 1fr; } }
  </style>
</head>
<body>
  <div class="page-header">
    <h1>Tableau de Bord</h1>
    <p>Indicateurs cles, carte interactive et statistiques</p>
  </div>
  <div class="container">
    <div class="stats-grid" id="statsGrid">
      <div class="stat-card"><div class="stat-icon" style="background:#e0f2fe;color:#0284c7;"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg></div><div class="stat-value" id="statProduits">-</div><div class="stat-label">Produits references</div></div>
      <div class="stat-card"><div class="stat-icon" style="background:#fef3c7;color:#b45309;"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg></div><div class="stat-value" id="statMarches">-</div><div class="stat-label">Marches suivis</div></div>
      <div class="stat-card"><div class="stat-icon" style="background:#d1fae5;color:#059669;"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="12" y1="18" x2="12" y2="12"/><line x1="9" y1="15" x2="15" y2="15"/></svg></div><div class="stat-value" id="statSaisies">-</div><div class="stat-label">Saisies totales</div></div>
      <div class="stat-card"><div class="stat-icon" style="background:#f3e8ff;color:#7c3aed;"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="20" x2="12" y2="10"/><line x1="18" y1="20" x2="18" y2="4"/><line x1="6" y1="20" x2="6" y2="16"/></svg></div><div class="stat-value" id="statEnv">-</div><div class="stat-label">Prix moyen general</div></div>
    </div>
    <div class="card dash-grid-wide">
      <div class="card-header"><span class="card-title">Carte des Marches et Prix</span></div>
      <div id="dashMap"></div>
      <div class="market-prices" id="marketPrices"></div>
    </div>
    <div class="dash-grid">
      <div class="card"><div class="card-header"><span class="card-title">Top produits</span><span class="badge badge-primary">Par saisies</span></div><ul class="top-list" id="topProduits"><li class="activity-empty">Chargement...</li></ul></div>
      <div class="card"><div class="card-header"><span class="card-title">Top marches</span><span class="badge badge-primary">Plus actifs</span></div><ul class="top-list" id="topMarches"><li class="activity-empty">Chargement...</li></ul></div>
      <div class="card"><div class="card-header"><span class="card-title">Repartition par categorie</span></div><div class="chart-wrapper"><div class="chart-height"><canvas id="chartCategories"></canvas></div></div></div>
      <div class="card"><div class="card-header"><span class="card-title">Evolution des prix (30 jours)</span></div><div class="chart-wrapper"><div class="chart-height"><canvas id="chartTrend"></canvas></div></div></div>
    </div>
  </div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>
  <script>
  (function() {
    var API = window.API_URL + '/api/v1';
    var PALETTE = ['#0f766e','#14b8a6','#d97706','#dc2626','#7c3aed','#0284c7','#059669','#9333ea'];
    var dashMap = null, dashMarkers = null;
    function getToken() { try{return sessionStorage.getItem('mp_token')||localStorage.getItem('mp_token')}catch(e){return null} }

    function initMap() {
      dashMap = L.map('dashMap').setView([-19.5,46.5],6);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{attribution:'&copy; OpenStreetMap',maxZoom:19}).addTo(dashMap);
      dashMarkers = L.layerGroup().addTo(dashMap);
    }

    function loadDashboard() {
      var token=getToken();
      if(!token){document.querySelector('.container').innerHTML='<div class="card"><div class="message err">Acces non autorise. <a href="login.jsp">Connectez-vous</a></div></div>';return;}
      initMap();
      fetch(API+'/dashboard',{headers:{'Authorization':'Bearer '+token}})
      .then(function(r){return r.json()})
      .then(function(json){
        if(!json.success)throw new Error(json.message||'Erreur');
        var d=json.data, s=d.statistiques||{};
        document.getElementById('statProduits').textContent=s.nb_produits||0;
        document.getElementById('statMarches').textContent=s.nb_marches||0;
        document.getElementById('statSaisies').textContent=(s.nb_saisies_total||s.nb_saisies||0);
        document.getElementById('statEnv').textContent=(s.prix_moyen||s.prix_moyen_general||0)+' Ar';
        var topP=d.top_produits||[], ulP=document.getElementById('topProduits');
        if(topP.length){ulP.innerHTML=topP.map(function(p,i){var rc=i===0?'rank-1':i===1?'rank-2':i===2?'rank-3':'rank-other';return '<li><span class="rank '+rc+'">'+(i+1)+'</span><div class="item-info"><div class="name">'+(p.nom_fr||p.nom||'Produit')+'</div><div class="meta">'+p.nb_saisies+' saisies</div></div><span class="item-value">'+(p.nb_saisies||0)+'</span></li>';}).join('');}else{ulP.innerHTML='<li class="activity-empty">Aucune donnee</li>';}
        var topM=d.top_marches||[], ulM=document.getElementById('topMarches');
        if(topM.length){ulM.innerHTML=topM.map(function(m,i){var rc=i===0?'rank-1':i===1?'rank-2':i===2?'rank-3':'rank-other';var img=m.photo_url?'<img src="'+m.photo_url+'" style="width:32px;height:32px;border-radius:6px;object-fit:cover;margin-right:8px;vertical-align:middle;" alt="" loading="lazy">':'';return '<li>'+img+'<span class="rank '+rc+'">'+(i+1)+'</span><div class="item-info"><div class="name">'+(m.nom||'Marche')+'</div><div class="meta">'+(m.ville||'')+'</div></div><span class="item-value">'+(m.nb_saisies||0)+'</span></li>';}).join('');}else{ulM.innerHTML='<li class="activity-empty">Aucune donnee</li>';}
        var cats=d.repartition_categories||d.statistiques.par_categorie||[];
        if(cats.length){new Chart(document.getElementById('chartCategories').getContext('2d'),{type:'doughnut',data:{labels:cats.map(function(c){return c.categorie||c.nom||c.libelle;}),datasets:[{data:cats.map(function(c){return c.nb_saisies||c.count||c.total||0;}),backgroundColor:PALETTE}]},options:{responsive:true,maintainAspectRatio:true,plugins:{legend:{position:'right',labels:{font:{size:11}}}}}});}
        var trend=d.tendance_30j||d.evolution_prix||d.tendance||[];
        if(trend.length){new Chart(document.getElementById('chartTrend').getContext('2d'),{type:'line',data:{labels:trend.map(function(p){var d=new Date(p.date_jour||p.date||p.jour);return d.toLocaleDateString('fr-FR',{day:'2-digit',month:'short'});}),datasets:[{label:'Prix moyen global',data:trend.map(function(p){return parseFloat(p.prix_moyen_global||p.prix_moyen||p.prix||0);}),borderColor:'#0f766e',backgroundColor:'rgba(15,118,110,0.06)',fill:true,tension:0.4,pointRadius:3,pointBackgroundColor:'#0f766e',borderWidth:2}]},options:{responsive:true,maintainAspectRatio:true,plugins:{legend:{display:false}},scales:{y:{beginAtZero:false,grid:{color:'rgba(0,0,0,0.04)'},ticks:{callback:function(v){return v+' Ar'}}}}}});}
      }).catch(function(err){document.querySelector('.container').innerHTML='<div class="card"><div class="message err">'+err.message+'</div></div>';});
      fetch(API+'/marches').then(function(r){return r.json()}).then(function(j){
        if(!j.success||!j.data) return;
        var marches=j.data, html='';
        marches.forEach(function(m){
          var lat=parseFloat(m.latitude),lng=parseFloat(m.longitude);
          if(isNaN(lat)||isNaN(lng)) return;
          var col=m.est_actif?'#0f766e':'#94a3b8';
          var mk=L.circleMarker([lat,lng],{radius:7,fillColor:col,color:'#fff',weight:2,fillOpacity:0.8}).addTo(dashMarkers);
          mk.bindPopup('<div style="min-width:150px;"><h3 style="margin:0 0 4px;font-size:14px;">'+m.nom+'</h3><p style="margin:2px 0;font-size:12px;color:#475569;">'+m.ville+'</p><span class="badge '+(m.est_actif?'badge-green':'badge-yellow')+'">'+(m.est_actif?'Actif':'Inactif')+'</span></div>');
          html+='<span class="market-price-chip" style="border-left:3px solid '+col+';">'+m.nom+' <strong>'+m.ville+'</strong></span>';
        });
        document.getElementById('marketPrices').innerHTML=html||'<span style="color:var(--text-muted);font-size:0.82rem;">Aucun marche disponible</span>';
        var bounds=dashMarkers.getBounds();
        if(bounds.isValid()) dashMap.fitBounds(bounds,{padding:[20,20]});
      }).catch(function(){});
    }
    loadDashboard();
  })();
  </script>
</body>
</html>