<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="_header.jsp" %>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Recherche de Produits - Meilleur Prix</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css" />
  <link rel="stylesheet" href="https://unpkg.com/leaflet-routing-machine@3.2.12/dist/leaflet-routing-machine.css" />
  <style>
    .sr-section { padding: 1.5rem 0; }
    .sr-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin-top: 0; }
    .sr-list { display: flex; flex-direction: column; gap: 0.5rem; }
    .sr-list .section-label { font-size: 0.72rem; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.06em; padding: 0.25rem 0 0.5rem; border-bottom: 1px solid var(--border); margin-bottom: 0.5rem; }
    .sr-item { background: var(--surface); border: 1px solid var(--surface-border); border-radius: var(--radius-lg); padding: 0.85rem 1rem; cursor: pointer; transition: all 0.2s; box-shadow: var(--shadow-sm); display: flex; align-items: center; gap: 0.85rem; }
    .sr-item:hover { box-shadow: var(--shadow-md); transform: translateY(-1px); border-color: var(--primary-light); }
    .sr-item .av { width: 40px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.85rem; color: #fff; flex-shrink: 0; }
    .sr-item .info { flex: 1; min-width: 0; }
    .sr-item .info .nm { font-weight: 600; font-size: 0.88rem; color: var(--text); }
    .sr-item .info .sb { font-size: 0.76rem; color: var(--text-muted); display: flex; align-items: center; gap: 0.35rem; margin-top: 0.1rem; }
    .sr-item .info .sb .ct { display: inline-block; padding: 0.1rem 0.5rem; border-radius: 999px; font-size: 0.68rem; font-weight: 500; }
    .sr-item .qa { display: flex; gap: 0.35rem; flex-shrink: 0; }
    .sr-item .qa button { padding: 0.3rem 0.6rem; font-size: 0.7rem; border-radius: 6px; border: none; font-weight: 600; cursor: pointer; transition: all 0.15s; font-family: inherit; }
    .sr-item .qa .ap { background: var(--primary-bg); color: var(--primary); }
    .sr-item .qa .ap:hover { background: var(--primary); color: #fff; }
    .sr-item .qa .ap.active { background: var(--primary); color: #fff; }
    .sr-item .qa .as { background: var(--bg-alt); color: var(--text-secondary); }
    .sr-item .qa .as:hover { background: #e2e8f0; }
    .sr-item .qa .as.active { background: #0f766e; color: #fff; }
    .sr-detail { display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem; }
    .sr-detail .f { background: var(--bg-alt); padding: 0.6rem 0.85rem; border-radius: 8px; }
    .sr-detail .f .l { font-size: 0.68rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.04em; font-weight: 600; }
    .sr-detail .f .v { font-size: 0.9rem; font-weight: 600; color: var(--text); margin-top: 0.1rem; }
    .sr-detail .f.full { grid-column: 1 / -1; }
    .sr-empty { text-align: center; padding: 3rem 1.5rem; }
    .sr-empty svg { width: 40px; height: 40px; color: var(--text-muted); opacity: 0.35; margin-bottom: 0.75rem; }
    .sr-empty p { color: var(--text-muted); font-size: 0.9rem; }
    .sr-empty .h { color: var(--text-muted); font-size: 0.78rem; margin-top: 0.35rem; }
    .panel-card { margin-top: 1rem; border: 1px solid var(--primary-light); border-radius: var(--radius-lg); padding: 1.25rem; background: var(--surface); display: none; box-shadow: var(--shadow); }
    .panel-card.visible { display: block; animation: fadeIn 0.2s ease; }
    @keyframes fadeIn { from { opacity: 0; transform: translateY(-6px); } to { opacity: 1; transform: translateY(0); } }
    .panel-card .panel-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 1rem; }
    .panel-card .panel-header h3 { font-size: 0.95rem; font-weight: 700; color: var(--text); margin: 0; }
    .panel-card .panel-header .close-panel { background: none; border: none; font-size: 1.2rem; cursor: pointer; color: var(--text-muted); padding: 0.2rem; line-height: 1; }
    .panel-card .panel-header .close-panel:hover { color: var(--text); }
    .prix-form { display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem; }
    .prix-form .full-w { grid-column: 1 / -1; }
    .prix-form label { font-size: 0.78rem; font-weight: 600; color: var(--text-secondary); display: block; margin-bottom: 0.25rem; }
    .prix-form input, .prix-form select { width: 100%; padding: 0.55rem 0.75rem; border: 1.5px solid var(--border); border-radius: var(--radius); font-size: 0.85rem; background: var(--surface); font-family: inherit; }
    .prev-inline-chart { height: 220px; margin: 0.5rem 0; }
    .compare-inline-table { font-size: 0.82rem; }
    .compare-inline-table th { font-size: 0.72rem; text-transform: uppercase; letter-spacing: 0.04em; color: var(--text-muted); }
    .compare-inline-table td { padding: 0.4rem 0.6rem; }
    @media (max-width: 768px) { .sr-grid { grid-template-columns: 1fr; } }
  </style>
</head>
<body>
  <div class="page-header" style="padding-bottom:3rem;">
    <h1>Recherche de Produits</h1>
    <p>Resultats instantanes grace a l'algorithme Trie (francais / malagasy)</p>
    <div style="max-width:580px;margin:1.5rem auto 0;position:relative;">
      <svg style="position:absolute;left:1rem;top:50%;transform:translateY(-50%);width:20px;height:20px;color:rgba(255,255,255,0.5);z-index:2;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
      <input type="text" id="q" placeholder="Rechercher un produit (Riz, Vary, Tomate, Voatabia...)" autofocus style="width:100%;padding:0.85rem 1rem 0.85rem 3rem;border:none;border-radius:12px;font-size:1rem;background:rgba(255,255,255,0.96);box-shadow:0 8px 30px rgba(0,0,0,0.12);transition:all 0.25s;">
    </div>
    <div style="display:flex;align-items:center;justify-content:center;gap:0.75rem;margin-top:0.75rem;position:relative;">
      <span style="background:rgba(255,255,255,0.18);color:#fff;padding:0.25rem 0.8rem;border-radius:999px;font-size:0.78rem;font-weight:500;" id="resultCount">Tapez au moins 2 caracteres</span>
      <span style="color:rgba(255,255,255,0.65);font-size:0.78rem;" id="searchTimer"></span>
    </div>
  </div>
  <div class="container sr-section">
    <div class="sr-grid">
      <div id="leftCol">
        <div id="resultsContainer">
          <div class="sr-empty">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/><path d="M8 11h6"/><path d="M11 8v6"/></svg>
            <p>Commencez a taper pour voir les resultats</p>
            <p class="h">La recherche fonctionne en francais et en malagasy</p>
          </div>
        </div>
        <div id="detailCard" style="display:none;">
          <div class="card fade-in">
            <div class="card-header">
              <span class="card-title" id="detailTitle">Detail du produit</span>
              <span id="detailBadge" class="badge badge-primary"></span>
            </div>
            <div id="detailContent"></div>
          </div>
        </div>
        <div class="panel-card" id="panelPrix">
          <div class="panel-header"><h3 id="prixPanelTitle">Prix du produit</h3><button class="close-panel" onclick="closeAllPanels()">&times;</button></div>
          <div style="max-height:260px;overflow-y:auto;"><table class="compare-inline-table"><thead><tr><th>Marche</th><th>Ville</th><th>Prix moyen</th><th>Saisies</th></tr></thead><tbody id="prixPanelBody"></tbody></table></div>
        </div>
        <div class="panel-card" id="panelSaisiePrix">
          <div class="panel-header"><h3 id="saisiePrixTitre">Saisir un prix</h3><button class="close-panel" onclick="closeAllPanels()">&times;</button></div>
          <div style="display:flex;flex-direction:column;gap:0.75rem;">
            <div><label>Marche</label><select id="saisieMarcheSelect"><option value="">Chargement...</option></select></div>
            <div><label>Prix (Ar)</label><input type="number" id="saisiePrixMontant" min="0" step="10"></div>
            <button class="btn btn-primary btn-sm" id="btnSaisiePrixSubmit">Enregistrer</button>
            <div id="saisiePrixMsg"></div>
          </div>
        </div>
        <div class="panel-card" id="panelPrev">
          <div class="panel-header"><h3>Prevision des prix</h3><button class="close-panel" onclick="closeAllPanels()">&times;</button></div>
          <div><canvas id="prevInlineChart" class="prev-inline-chart"></canvas></div>
          <div style="display:grid;grid-template-columns:1fr 1fr 1fr 1fr;gap:0.5rem;margin-top:0.5rem;">
            <div style="background:var(--bg-alt);padding:0.5rem;border-radius:6px;text-align:center;"><div style="font-size:0.65rem;color:var(--text-muted);">Actuel</div><div style="font-weight:700;font-size:0.9rem;" id="prevActuel">-</div></div>
            <div style="background:var(--bg-alt);padding:0.5rem;border-radius:6px;text-align:center;"><div style="font-size:0.65rem;color:var(--text-muted);">Prev J+30</div><div style="font-weight:700;font-size:0.9rem;" id="prevFutur">-</div></div>
            <div style="background:var(--bg-alt);padding:0.5rem;border-radius:6px;text-align:center;"><div style="font-size:0.65rem;color:var(--text-muted);">Tendance</div><div style="font-weight:700;font-size:0.9rem;" id="prevTendance">-</div></div>
            <div style="background:var(--bg-alt);padding:0.5rem;border-radius:6px;text-align:center;"><div style="font-size:0.65rem;color:var(--text-muted);">Jours</div><div style="font-weight:700;font-size:0.9rem;" id="prevJours">-</div></div>
          </div>
        </div>
        <div class="panel-card" id="panelComparer">
          <div class="panel-header"><h3>Comparaison par marche</h3><button class="close-panel" onclick="closeAllPanels()">&times;</button></div>
          <div style="max-height:260px;overflow-y:auto;"><table class="compare-inline-table"><thead><tr><th>Marche</th><th>Ville</th><th>Prix</th><th>Dist.</th></tr></thead><tbody id="compareInlineBody"></tbody></table></div>
          <div id="compareInlineMsg" style="font-size:0.82rem;color:var(--text-muted);margin-top:0.5rem;"></div>
        </div>
      </div>
      <div>
        <div class="map-container" id="mapContainer" style="display:none;"><div id="map"></div></div>
        <div class="card" id="emptyMap" style="text-align:center;padding:2.5rem;">
          <div style="font-size:0.85rem;color:var(--text-muted);">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom:0.5rem;opacity:0.35;"><circle cx="12" cy="12" r="10"/><path d="M2 12h20"/><path d="M12 2a15.3 15.3 0 014 10 15.3 15.3 0 01-4 10 15.3 15.3 0 01-4-10 15.3 15.3 0 014-10z"/></svg>
            <p>Selectionnez un produit pour voir les marches</p>
            <p class="h">Les marches apparaissent sur la carte interactive</p>
          </div>
        </div>
      </div>
    </div>
  </div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>
  <script src="https://unpkg.com/leaflet-routing-machine@3.2.12/dist/leaflet-routing-machine.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>
  <script>
  (function() {
    var API = window.API_URL + '/api/v1';
    var PALETTE = ['#0f766e','#14b8a6','#d97706','#dc2626','#7c3aed','#0284c7','#059669','#9333ea','#b45309','#0369a1'];
    var map = null, mapInit = false, markers = null, allProduits = [], allMarches = [];
    var selectedProduit = null;
    var routingControl = null;
    var savedProduit = (function(){try{return JSON.parse(sessionStorage.getItem('mp_produit'))}catch(e){return null}})();
    var prevChartInstance = null;

    function hashColor(s) { var h=0; for(var i=0;i<(s||'X').length;i++) h=(h*31+s.charCodeAt(i))>>>0; return PALETTE[h%PALETTE.length]; }

    function initMap() {
      if(mapInit) return;
      map = L.map('map').setView([-19.5,46.5],7);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{attribution:'&copy; OpenStreetMap',maxZoom:19}).addTo(map);
      markers = L.layerGroup().addTo(map);
      mapInit = true;
      fetch(API+'/marches').then(function(r){return r.json()}).then(function(j){if(j.success&&j.data)allMarches=j.data}).catch(function(){});
    }

    function getToken() { try{return sessionStorage.getItem('mp_token')||localStorage.getItem('mp_token')}catch(e){return null} }
    function getApiHeaders() { var h={'Content-Type':'application/json'}; var t=getToken(); if(t)h.Authorization='Bearer '+t; return h; }

    function showMap(pid) {
      var mc=document.getElementById('mapContainer'),em=document.getElementById('emptyMap');
      mc.style.display='block'; em.style.display='none';
      if(!mapInit) initMap();
      markers.clearLayers();
      if(routingControl) { map.removeControl(routingControl); routingControl=null; }
      if(!pid) return;
      var b=[];
      allMarches.forEach(function(m){
        var la=parseFloat(m.latitude),lo=parseFloat(m.longitude);
        if(isNaN(la)||isNaN(lo)) return;
        var mk=L.circleMarker([la,lo],{radius:7,fillColor:'#0f766e',color:'#fff',weight:2,fillOpacity:0.7}).addTo(markers);
        mk.bindPopup('<div style="min-width:160px;"><h3 style="font-size:14px;margin:0 0 4px;">'+m.nom+'</h3><p style="margin:2px 0;font-size:12px;color:#475569;">'+m.ville+'</p><p style="margin:2px 0;font-size:11px;color:#0f766e;">Cliquez pour itineraire</p></div>');
        mk.on('click',function(){ getRoute(m.id); });
        b.push([la,lo]);
      });
      if(b.length>1) map.fitBounds(L.latLngBounds(b),{padding:[30,30]});
    }

    function getRoute(marcheId) {
      if(!navigator.geolocation) { alert('Geolocalisation non disponible'); return; }
      navigator.geolocation.getCurrentPosition(function(pos){
        var userLat=pos.coords.latitude, userLng=pos.coords.longitude;
        var m=allMarches.find(function(x){return x.id===marcheId});
        if(!m) return;
        var mLat=parseFloat(m.latitude), mLng=parseFloat(m.longitude);
        if(isNaN(mLat)||isNaN(mLng)) return;
        if(routingControl) map.removeControl(routingControl);
        routingControl = L.Routing.control({
          waypoints: [L.latLng(userLat,userLng), L.latLng(mLat,mLng)],
          routeWhileDragging: false,
          showAlternatives: false,
          fitSelectedRoutes: true,
          lineOptions: { styles: [{color:'#0f766e',weight:4,opacity:0.8}] }
        }).addTo(map);
        L.circleMarker([userLat,userLng],{radius:6,fillColor:'#3b82f6',color:'#fff',weight:2,fillOpacity:0.9}).addTo(markers).bindPopup('Vous etes ici');
      }, function(){ alert('Impossible d\'obtenir votre position'); }, {enableHighAccuracy:true});
    }

    function closeAllPanels() {
      document.querySelectorAll('.panel-card').forEach(function(p){p.classList.remove('visible');});
    }

    function openPanel(id) {
      closeAllPanels();
      var el=document.getElementById(id);
      if(el) el.classList.add('visible');
    }

    function showSaisiePrix(p) {
      selectedProduit = p;
      document.getElementById('saisiePrixTitre').textContent='Saisir prix: '+(p.nom_fr||p.nom_mg||'Produit');
      var sel=document.getElementById('saisieMarcheSelect');
      sel.innerHTML='<option value="">Chargement...</option>';
      if(allMarches.length){
        sel.innerHTML='<option value="">Selectionnez un marche</option>';
        allMarches.forEach(function(m){sel.innerHTML+='<option value="'+m.id+'">'+m.nom+' - '+m.ville+'</option>';});
      }else{
        fetch(API+'/marches').then(function(r){return r.json()}).then(function(j){if(j.success&&j.data){allMarches=j.data;sel.innerHTML='<option value="">Selectionnez un marche</option>';allMarches.forEach(function(m){sel.innerHTML+='<option value="'+m.id+'">'+m.nom+' - '+m.ville+'</option>';});}}).catch(function(){});
      }
      document.getElementById('saisiePrixMontant').value='';
      document.getElementById('saisiePrixMsg').textContent='';
      openPanel('panelSaisiePrix');
    }
    function showPrixPanel(p) {
      selectedProduit = p;
      document.getElementById('prixPanelTitle').textContent='Prix de '+(p.nom_fr||p.nom_mg||'Produit');
      openPanel('panelPrix');
      var tbody=document.getElementById('prixPanelBody');
      tbody.innerHTML='<tr><td colspan="4" style="text-align:center;color:var(--text-muted);">Chargement...</td></tr>';
      if(allMarches.length===0){
        fetch(API+'/marches').then(function(r){return r.json()}).then(function(j){if(j.success&&j.data){allMarches=j.data;loadPrix(p.id);}}).catch(function(){});
      }else{loadPrix(p.id);}
    }
    function loadPrix(produitId) {
      fetch(API+'/prix/produit/'+encodeURIComponent(produitId),{headers:getApiHeaders()})
        .then(function(r){return r.json()})
        .then(function(j){
          if(!j.success) throw new Error(j.message||'Erreur');
          var prixList=j.data||[];
          if(!prixList.length){document.getElementById('prixPanelBody').innerHTML='<tr><td colspan="4" style="text-align:center;color:var(--text-muted);">Aucun prix saisi pour ce produit</td></tr>';return;}
          var grouped={};
          prixList.forEach(function(pr){var mid=pr.marche_id||pr.id_marche;if(!grouped[mid])grouped[mid]={marcheId:mid,prix:[],count:0};grouped[mid].prix.push(parseFloat(pr.prix_moyen||pr.prix||pr.montant||0));grouped[mid].count++;});
          var html='', sortedKeys=Object.keys(grouped).sort(function(a,b){var ga=grouped[a],gb=grouped[b];return (ga.prix.reduce(function(x,y){return x+y;},0)/ga.prix.length)-(gb.prix.reduce(function(x,y){return x+y;},0)/gb.prix.length);});
          sortedKeys.forEach(function(mid){
            var g=grouped[mid], avg=g.prix.reduce(function(a,b){return a+b;},0)/g.prix.length, m=allMarches.find(function(x){return x.id==mid;});
            if(!m) return;
            var ph=m.photo_url?'<img src="'+m.photo_url+'" style="width:28px;height:28px;border-radius:5px;object-fit:cover;margin-right:6px;vertical-align:middle;" alt="" loading="lazy">':'';
            html+='<tr><td>'+ph+'<strong>'+m.nom+'</strong></td><td style="font-size:0.78rem;color:var(--text-muted);">'+m.ville+'</td><td><strong>'+avg.toFixed(0)+' Ar</strong></td><td style="font-size:0.78rem;">'+g.count+' saisie(s)</td></tr>';
          });
          if(!html) html='<tr><td colspan="4" style="text-align:center;color:var(--text-muted);">Aucune donnee disponible</td></tr>';
          document.getElementById('prixPanelBody').innerHTML=html;
        })
        .catch(function(err){document.getElementById('prixPanelBody').innerHTML='<tr><td colspan="4" style="text-align:center;color:var(--danger);">'+err.message+'</td></tr>';});
    }

    function showPrevPanel(p) {
      selectedProduit = p;
      document.getElementById('prevActuel').textContent='...';
      document.getElementById('prevFutur').textContent='...';
      document.getElementById('prevTendance').textContent='...';
      document.getElementById('prevJours').textContent='...';
      openPanel('panelPrev');
      fetch(API+'/previsions/'+encodeURIComponent(p.id), {headers: getApiHeaders()})
        .then(function(r){return r.json()})
        .then(function(j){
          if(!j.success) throw new Error(j.message);
          var d=j.data;
          document.getElementById('prevActuel').textContent=(d.prix_actuel||0)+' Ar';
          document.getElementById('prevFutur').textContent=(d.prix_prevu_optimise||d.prix_prevu_simple||0)+' Ar';
          var t=d.tendance||(d.prix_prevu_optimise>d.prix_actuel?'Hausse':'Baisse');
          document.getElementById('prevTendance').textContent=t;
          document.getElementById('prevJours').textContent=(d.historique&&d.historique.length)||0;
          var labels=[],histData=[],prevData=[];
          if(d.historique){d.historique.forEach(function(h){var dd=new Date(h.date);labels.push(dd.toLocaleDateString('fr-FR',{day:'2-digit',month:'short'}));histData.push(parseFloat(h.valeur||h.prix));});}
          if(d.previsions){d.previsions.forEach(function(h,i){labels.push('J+'+(i+1));prevData.push(h.optimise||null);});}
          try { if(prevChartInstance) prevChartInstance.destroy(); } catch(e) {}
          prevChartInstance = null;
          var ctx=document.getElementById('prevInlineChart').getContext('2d');
          prevChartInstance=new Chart(ctx,{
            type:'line',
            data:{labels:labels,datasets:[{label:'Historique',data:histData,borderColor:'#0f766e',backgroundColor:'rgba(15,118,110,0.06)',fill:true,tension:0.4,pointRadius:2},{label:'Prevision',data:prevData,borderColor:'#ea580c',borderDash:[5,5],pointRadius:2,tension:0.4,fill:false}]},
            options:{responsive:true,maintainAspectRatio:true,plugins:{legend:{position:'top',labels:{font:{size:10}}}},scales:{y:{beginAtZero:false,ticks:{font:{size:10}}}}}
          });
        })
        .catch(function(err){document.getElementById('prevActuel').textContent='Erreur';document.getElementById('prevFutur').textContent=err.message;});
    }

    function showComparerPanel(p) {
      selectedProduit = p;
      openPanel('panelComparer');
      document.getElementById('compareInlineBody').innerHTML='<tr><td colspan="4" style="text-align:center;color:var(--text-muted);">Chargement...</td></tr>';
      document.getElementById('compareInlineMsg').textContent='';
      if(allMarches.length===0){
        fetch(API+'/marches').then(function(r){return r.json()}).then(function(j){if(j.success&&j.data)allMarches=j.data;}).catch(function(){});
      }
      fetch(API+'/prix/produit/'+encodeURIComponent(p.id),{headers:getApiHeaders()})
        .then(function(r){return r.json()})
        .then(function(j){
          if(!j.success) throw new Error(j.message||'Erreur');
          var prixList=j.data||[];
          if(!prixList.length){document.getElementById('compareInlineBody').innerHTML='<tr><td colspan="4" style="text-align:center;color:var(--text-muted);">Aucun prix saisi pour ce produit</td></tr>';return;}
          var grouped={};
          prixList.forEach(function(pr){
            var mid=pr.marche_id||pr.id_marche;
            if(!grouped[mid]) grouped[mid]={marcheId:mid,prix:[],count:0};
            grouped[mid].prix.push(parseFloat(pr.prix_moyen||pr.prix||pr.montant||0));
            grouped[mid].count++;
          });
          var html='';
          var sortedKeys=Object.keys(grouped).sort(function(a,b){
            var ga=grouped[a],gb=grouped[b];
            var aa=ga.prix.reduce(function(x,y){return x+y;},0)/ga.prix.length;
            var ab=gb.prix.reduce(function(x,y){return x+y;},0)/gb.prix.length;
            return aa-ab;
          });
          sortedKeys.forEach(function(mid){
            var g=grouped[mid];
            var avg=g.prix.reduce(function(a,b){return a+b;},0)/g.prix.length;
            var m=allMarches.find(function(x){return x.id==mid;});
            if(!m) return;
            var ph=m.photo_url?'<img src="'+m.photo_url+'" style="width:28px;height:28px;border-radius:5px;object-fit:cover;margin-right:6px;vertical-align:middle;" alt="" loading="lazy">':'';
            html+='<tr><td>'+ph+'<strong>'+m.nom+'</strong></td><td style="font-size:0.78rem;color:var(--text-muted);">'+m.ville+'</td><td><strong>'+avg.toFixed(0)+' Ar</strong></td><td style="font-size:0.78rem;">'+(m.distance_km||'-')+' km</td></tr>';
          });
          if(!html) html='<tr><td colspan="4" style="text-align:center;color:var(--text-muted);">Aucune donnee disponible</td></tr>';
          document.getElementById('compareInlineBody').innerHTML=html;
          document.getElementById('compareInlineMsg').textContent=prixList.length+' saisie(s) de prix';
        })
        .catch(function(err){
          document.getElementById('compareInlineBody').innerHTML='<tr><td colspan="4" style="text-align:center;color:var(--danger);">'+err.message+'</td></tr>';
        });
    }

    function renderResults(list, ms) {
      var c=document.getElementById('resultsContainer');
      document.getElementById('resultCount').textContent=list.length+' resultat(s)';
      document.getElementById('searchTimer').textContent=ms+' ms (Trie)';
      if(!list.length){
        c.innerHTML='<div class="sr-empty"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/><line x1="8" y1="8" x2="14" y2="14"/><line x1="14" y1="8" x2="8" y2="14"/></svg><p>Aucun produit trouve</p><p class="h">Essayez un autre terme de recherche</p></div>';
        document.getElementById('mapContainer').style.display='none';
        document.getElementById('emptyMap').style.display='block';
        return;
      }
      allProduits = list;
      var h='<div class="card" style="padding:0.85rem 1rem;"><div class="section-label">Produits</div>';
      list.forEach(function(p){
        var co=hashColor(p.nom_fr||p.nom_mg), ca=p.categorie||'General';
        h+='<div class="sr-item" data-id="'+p.id+'">'+
          '<div class="av" style="background:'+co+';">'+(p.nom_fr||'P')[0]+'</div>'+
          '<div class="info"><div class="nm">'+(p.nom_fr||'')+' / '+(p.nom_mg||'')+'</div>'+
          '<div class="sb"><span class="ct" style="background:'+co+'15;color:'+co+';">'+ca+'</span>'+(p.unite||'')+'</div></div>'+
          '<div class="qa">'+
          '<button class="ap" data-action="prix" data-pid="'+p.id+'">Prix</button>'+
          '<button class="as" data-action="prev" data-pid="'+p.id+'">Prev</button>'+
          '<button class="as" data-action="comparer" data-pid="'+p.id+'">Comparer</button>'+
          '</div></div>';
      });
      h+='</div>';
      c.innerHTML = h;
      c.querySelectorAll('.sr-item').forEach(function(el){
        el.addEventListener('click',function(e){
          if(e.target.closest('.qa')) return;
          var id=el.getAttribute('data-id'), p=allProduits.find(function(x){return x.id===id});
          if(p){sessionStorage.setItem('mp_produit',JSON.stringify(p));showDetail(p);showMap(p.id);}
        });
      });
      c.querySelectorAll('[data-action]').forEach(function(btn){
        btn.addEventListener('click',function(e){
          e.stopPropagation();
          var pid=btn.getAttribute('data-pid'),action=btn.getAttribute('data-action');
          var p=allProduits.find(function(x){return x.id===pid});
          if(!p) return;
          if(action==='prix') showPrixPanel(p);
          else if(action==='prev') showPrevPanel(p);
          else if(action==='comparer') showComparerPanel(p);
        });
      });
      if(list.length && list[0].id) showMap(list[0].id);
    }

    function showDetail(p) {
      var dc=document.getElementById('detailCard'); dc.style.display='block';
      document.getElementById('detailTitle').textContent=(p.nom_fr||p.nom_mg||'Produit');
      document.getElementById('detailBadge').textContent=p.categorie||'General';
      document.getElementById('detailContent').innerHTML=
        '<div class="sr-detail">'+
        '<div class="f"><div class="l">Nom francais</div><div class="v">'+(p.nom_fr||'-')+'</div></div>'+
        '<div class="f"><div class="l">Nom malagasy</div><div class="v">'+(p.nom_mg||'-')+'</div></div>'+
        '<div class="f"><div class="l">Categorie</div><div class="v">'+(p.categorie||'-')+'</div></div>'+
        '<div class="f"><div class="l">Unite</div><div class="v">'+(p.unite||'-')+'</div></div>'+
        '</div>'+
        '<div style="display:flex;gap:0.5rem;margin-top:1rem;flex-wrap:wrap;">'+
        '<button class="btn btn-primary btn-sm" onclick="showPrixPanel('+JSON.stringify(p).replace(/"/g,'&quot;')+')">Voir les prix</button>'+
        '<button class="btn btn-secondary btn-sm" onclick="showSaisiePrix('+JSON.stringify(p).replace(/"/g,'&quot;')+')">Saisir un prix</button>'+
        '<button class="btn btn-secondary btn-sm" onclick="showPrevPanel('+JSON.stringify(p).replace(/"/g,'&quot;')+')">Voir prevision</button>'+
        '<button class="btn btn-secondary btn-sm" onclick="showComparerPanel('+JSON.stringify(p).replace(/"/g,'&quot;')+')">Comparer les prix</button>'+
        '</div>';
    }

    function ClientTrie() {
      this._root = {};
      this._products = {};
    }

    ClientTrie.prototype._norm = function(s) {
      return (s||'').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'');
    };

    ClientTrie.prototype.add = function(product) {
      this._products[product.id] = product;
      var text = this._norm((product.nom_fr||'') + ' ' + (product.nom_mg||''));
      for (var start = 0; start < text.length; start++) {
        var node = this._root;
        for (var i = start; i < text.length; i++) {
          var ch = text[i];
          if (!node[ch]) node[ch] = {};
          node = node[ch];
          if (!node._ids) node._ids = {};
          node._ids[product.id] = 1;
        }
      }
    };

    ClientTrie.prototype.search = function(prefix) {
      if (!prefix || prefix.length < 2) return [];
      prefix = this._norm(prefix);
      var node = this._root;
      for (var i = 0; i < prefix.length; i++) {
        if (!node[prefix[i]]) return [];
        node = node[prefix[i]];
      }
      var seen = {}, results = [], prods = this._products;
      (function collect(n) {
        if (n._ids) Object.keys(n._ids).forEach(function(id) { if (!seen[id]) { seen[id] = 1; if (prods[id]) results.push(prods[id]); } });
        Object.keys(n).forEach(function(k) { if (k !== '_ids') collect(n[k]); });
      })(node);
      return results;
    };

    var trie = new ClientTrie();
    var trieReady = false;

    fetch(API+'/produits')
      .then(function(r){return r.json()})
      .then(function(j){
        if (j.success && j.data) {
          j.data.forEach(function(p){trie.add(p);});
        }
        trieReady = true;
      })
      .catch(function(){});

    document.getElementById('q').addEventListener('input',function(){
      var q=this.value.trim();
      if(q.length<2){
        document.getElementById('resultsContainer').innerHTML='<div class="sr-empty"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/><path d="M8 11h6"/><path d="M11 8v6"/></svg><p>Commencez a taper pour voir les resultats</p><p class="h">Minimum 2 caracteres</p></div>';
        document.getElementById('resultCount').textContent='Tapez au moins 2 caracteres';
        document.getElementById('searchTimer').textContent='';
        document.getElementById('mapContainer').style.display='none';
        document.getElementById('emptyMap').style.display='block';
        return;
      }
      if (!trieReady) { document.getElementById('resultsContainer').innerHTML='<div class="sr-empty"><div class="spinner"></div><p>Chargement des produits...</p></div>'; return; }
      var t0=performance.now();
      var results=trie.search(q);
      var elapsed=(performance.now()-t0).toFixed(1);
      renderResults(results, elapsed);
    });



    document.getElementById('btnSaisiePrixSubmit').addEventListener('click',function(){
      var marcheId=document.getElementById('saisieMarcheSelect').value;
      var montant=parseFloat(document.getElementById('saisiePrixMontant').value);
      if(!marcheId){document.getElementById('saisiePrixMsg').innerHTML='<span style="color:var(--danger);">Veuillez selectionner un marche</span>';return;}
      if(!montant||montant<=0){document.getElementById('saisiePrixMsg').innerHTML='<span style="color:var(--danger);">Veuillez entrer un prix valide</span>';return;}
      var msg=document.getElementById('saisiePrixMsg');
      msg.innerHTML='<span>Enregistrement...</span>';
      fetch(API+'/prix',{method:'POST',headers:getApiHeaders(),body:JSON.stringify({produit_id:selectedProduit.id,marche_id:marcheId,prix:montant})})
        .then(function(r){return r.json()})
        .then(function(j){
          if(j.success) msg.innerHTML='<span style="color:var(--success);">Prix enregistre avec succes!</span>';
          else msg.innerHTML='<span style="color:var(--danger);">'+j.message+'</span>';
        })
        .catch(function(err){msg.innerHTML='<span style="color:var(--danger);">'+err.message+'</span>';});
    });

    if (savedProduit && (savedProduit.nom_fr||savedProduit.nom_mg)) {
      document.getElementById('q').value = savedProduit.nom_fr||savedProduit.nom_mg||'';
      showDetail(savedProduit);
      renderResults([savedProduit], '0');
    }

    window.showPrixPanel = showPrixPanel;
    window.showSaisiePrix = showSaisiePrix;
    window.showPrevPanel = showPrevPanel;
    window.showComparerPanel = showComparerPanel;
    window.closeAllPanels = closeAllPanels;
  })();
  </script>
</body>
</html>
