<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="_header.jsp" %>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Carte Interactive - Meilleur Prix</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css" />
  <link rel="stylesheet" href="https://unpkg.com/leaflet-routing-machine@3.2.12/dist/leaflet-routing-machine.css" />
  <style>
    .carte-layout { display: flex; gap: 1.25rem; height: calc(100vh - 140px); padding: 0 1.25rem 1.25rem; }
    .carte-layout #map { flex: 1; border-radius: var(--radius-lg); box-shadow: var(--shadow); z-index: 1; }
    .carte-sidebar { width: 360px; flex-shrink: 0; overflow-y: auto; }
    .search-market { margin-bottom: 0.85rem; }
    .search-market input { margin-bottom: 0; }
    .marche-count { font-size: 0.82rem; color: var(--text-muted); margin-bottom: 0.75rem; }
    .market-list-scroll { max-height: calc(100vh - 360px); overflow-y: auto; }
    .market-item { cursor: pointer; border: 1px solid var(--border); border-radius: var(--radius); padding: 0.75rem; margin-bottom: 0.5rem; transition: all 0.15s; }
    .market-item:hover { border-color: var(--primary-light); background: var(--bg); }
    .market-item.active { border-color: var(--primary); background: var(--primary-bg); }
    .market-item img { width: 100%; height: 100px; object-fit: cover; border-radius: 6px; margin-top: 0.4rem; }
    .legend-control { background: #fff; padding: 10px 14px; border-radius: 6px; box-shadow: 0 1px 6px rgba(0,0,0,0.15); font-size: 12px; line-height: 1.8; }
    .legend-control i { width: 12px; height: 12px; display: inline-block; border-radius: 50%; margin-right: 6px; vertical-align: middle; }
    .user-loc-btn { position: absolute; top: 80px; left: 10px; z-index: 1000; background: #fff; border: 2px solid rgba(0,0,0,0.2); border-radius: 4px; padding: 6px 10px; cursor: pointer; font-size: 14px; font-weight: 600; }
    .user-loc-btn:hover { background: #f4f4f4; }
    @media (max-width: 768px) { .carte-layout { flex-direction: column; height: auto; } .carte-sidebar { width: 100%; max-height: 300px; } .carte-layout #map { height: 400px; } }
  </style>
</head>
<body>
  <div class="page-header">
    <h1>Carte Interactive</h1>
    <p>Marches, geolocalisation et itineraire optimal</p>
  </div>
  <div class="carte-layout">
    <div style="position:relative;flex:1;display:flex;flex-direction:column;">
      <button class="user-loc-btn" id="btnUserLoc" title="Ma position">&#9679; Ma position</button>
      <div id="map" style="flex:1;border-radius:var(--radius-lg);"></div>
    </div>
    <div class="carte-sidebar map-sidebar">
      <div class="search-market">
        <input type="text" id="filterMarket" placeholder="Filtrer par nom ou ville...">
      </div>
      <h3>Marches</h3>
      <div class="marche-count" id="marcheCount"></div>
      <div class="market-list-scroll" id="marketsList">
        <div class="loading"><div class="spinner"></div> Chargement...</div>
      </div>
      <div id="userInfo" style="margin-top:1rem;font-size:0.82rem;color:var(--text-muted);display:none;"></div>
    </div>
  </div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>
  <script src="https://unpkg.com/leaflet-routing-machine@3.2.12/dist/leaflet-routing-machine.js"></script>
  <script>
  (function() {
    var API = window.API_URL + '/api/v1';
    var map = L.map('map').setView([-19.5, 46.5], 7);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution: '&copy; OpenStreetMap contributors', maxZoom: 19 }).addTo(map);
    var legend = L.control({position:'bottomright'});
    legend.onAdd = function() { var div=L.DomUtil.create('div','legend-control'); div.innerHTML='<strong>Legende</strong><br><i style="background:#0f766e;"></i> Marche actif<br><i style="background:#3b82f6;"></i> Vous<br><i style="background:#ea580c;"></i> Itineraire'; return div; };
    legend.addTo(map);
    var allMarches = [], markers = {}, userMarker = null, routingControl = null;
    var productPhotos = {};

    function getProductPhoto(m) {
      if (m.photo_url) return m.photo_url;
      var key = (m.nom||'').toLowerCase();
      if (productPhotos[key]) return productPhotos[key];
      var img = 'https://images.unsplash.com/photo-1707768285271-1ac875d59286?w=400&h=300&fit=crop&auto=format';
      productPhotos[key] = img;
      return img;
    }

    function fetchMarches() {
      fetch(API + '/marches').then(function(r){return r.json()}).then(function(j){
        if (j.success && j.data) { allMarches = j.data; renderList(allMarches); renderMap(allMarches); }
        else { document.getElementById('marketsList').innerHTML = '<div class="empty-state"><p>Erreur de chargement</p></div>'; }
      }).catch(function(err){ document.getElementById('marketsList').innerHTML = '<div class="message err">Erreur: ' + err.message + '</div>'; });
    }

    function renderMap(list) {
      Object.keys(markers).forEach(function(id){map.removeLayer(markers[id]);});
      markers = {};
      list.forEach(function(m) {
        var lat = parseFloat(m.latitude), lng = parseFloat(m.longitude);
        if (isNaN(lat)||isNaN(lng)) return;
        var color = m.est_actif ? '#0f766e' : '#94a3b8';
        var marker = L.circleMarker([lat,lng], {radius:8, fillColor:color, color:'#fff', weight:2, fillOpacity:0.8}).addTo(map);
        var imgHtml = '<img src="' + getProductPhoto(m) + '" alt="' + m.nom + '" style="width:100%;height:100px;object-fit:cover;border-radius:6px;margin-bottom:6px;">';
        marker.bindPopup(
          '<div style="min-width:200px;">' + imgHtml +
          '<h3 style="margin:0 0 4px;">' + m.nom + '</h3>' +
          '<p style="margin:2px 0;font-size:12px;"><strong>Ville:</strong> ' + m.ville + '</p>' +
          '<p style="margin:2px 0;font-size:12px;"><strong>Statut:</strong> ' + (m.est_actif ? 'Actif' : 'Inactif') + '</p>' +
          '<button onclick="showRouteTo(\''+m.id+'\')" style="background:#0f766e;color:#fff;border:none;padding:4px 12px;border-radius:4px;cursor:pointer;font-size:12px;margin-top:4px;">Itineraire</button>' +
          '</div>'
        );
        marker.on('click', function(){ highlightItem(m.id); });
        markers[m.id] = marker;
      });
      if (list.length > 0) { var bounds = L.featureGroup(Object.values(markers)).getBounds(); if (bounds.isValid()) map.fitBounds(bounds, {padding:[30,30]}); }
    }

    function renderList(list) {
      var container = document.getElementById('marketsList');
      var count = document.getElementById('marcheCount');
      count.textContent = list.length + ' marche(s) affichee(s)';
      if (list.length === 0) { container.innerHTML = '<div class="empty-state"><p>Aucun marche trouve</p></div>'; return; }
      var html = '';
      list.forEach(function(m) {
        var img = getProductPhoto(m);
        html += '<div class="market-item" data-id="' + m.id + '">' +
          '<div style="display:flex;align-items:center;gap:0.6rem;">' +
          '<img src="' + img + '" alt="' + m.nom + '" style="width:60px;height:45px;object-fit:cover;border-radius:6px;flex-shrink:0;">' +
          '<div style="flex:1;"><h4 style="margin:0;font-size:0.88rem;">' + m.nom + '</h4>' +
          '<p style="margin:0;font-size:0.76rem;color:var(--text-muted);">' + m.ville + ' &middot; <span class="badge ' + (m.est_actif?'badge-green':'badge-yellow') + '" style="font-size:0.65rem;">' + (m.est_actif?'Actif':'Inactif') + '</span></p></div>' +
          '</div></div>';
      });
      container.innerHTML = html;
      container.querySelectorAll('.market-item').forEach(function(el) {
        el.addEventListener('click', function() {
          var id = el.getAttribute('data-id');
          var m = allMarches.find(function(x){return x.id===id;});
          if (m && markers[id]) { highlightItem(id); map.setView([parseFloat(m.latitude), parseFloat(m.longitude)], 12); markers[id].openPopup(); }
        });
      });
    }

    function highlightItem(id) {
      document.querySelectorAll('.market-item.active').forEach(function(el){el.classList.remove('active');});
      var el = document.querySelector('.market-item[data-id="'+id+'"]');
      if (el) el.classList.add('active');
    }

    document.getElementById('filterMarket').addEventListener('input', function() {
      var q = this.value.toLowerCase().trim();
      if (!q) { renderList(allMarches); renderMap(allMarches); return; }
      var filtered = allMarches.filter(function(m){ return (m.nom&&m.nom.toLowerCase().indexOf(q)!==-1) || (m.ville&&m.ville.toLowerCase().indexOf(q)!==-1); });
      renderList(filtered); renderMap(filtered);
    });

    function showRouteTo(marcheId) {
      var m = allMarches.find(function(x){return x.id===marcheId;});
      if (!m) return;
      var mLat = parseFloat(m.latitude), mLng = parseFloat(m.longitude);
      if (isNaN(mLat)||isNaN(mLng)) return;
      if (!navigator.geolocation) { alert('Geolocalisation non disponible'); return; }
      navigator.geolocation.getCurrentPosition(function(pos) {
        var uLat = pos.coords.latitude, uLng = pos.coords.longitude;
        if (userMarker) map.removeLayer(userMarker);
        userMarker = L.circleMarker([uLat,uLng], {radius:8, fillColor:'#3b82f6', color:'#fff', weight:3, fillOpacity:0.9}).addTo(map).bindPopup('Vous etes ici');
        document.getElementById('userInfo').style.display = 'block';
        document.getElementById('userInfo').innerHTML = '<strong>Votre position:</strong> ' + uLat.toFixed(4) + ', ' + uLng.toFixed(4) + '<br><strong>Destination:</strong> ' + m.nom + ' (' + m.ville + ')';
        if (routingControl) map.removeControl(routingControl);
        routingControl = L.Routing.control({
          waypoints: [L.latLng(uLat,uLng), L.latLng(mLat,mLng)],
          routeWhileDragging: false, showAlternatives: true, fitSelectedRoutes: true,
          lineOptions: {styles:[{color:'#ea580c',weight:4,opacity:0.8}]},
          altLineOptions: {styles:[{color:'#94a3b8',weight:3,opacity:0.5,dashArray:'6,6'}]}
        }).addTo(map);
      }, function(err) { alert('Position indisponible: ' + err.message); }, {enableHighAccuracy:true});
    }

    window.showRouteTo = showRouteTo;

    document.getElementById('btnUserLoc').addEventListener('click', function() {
      if (!navigator.geolocation) { alert('Geolocalisation non disponible'); return; }
      navigator.geolocation.getCurrentPosition(function(pos) {
        var lat = pos.coords.latitude, lng = pos.coords.longitude;
        map.setView([lat,lng], 14);
        if (userMarker) map.removeLayer(userMarker);
        userMarker = L.circleMarker([lat,lng], {radius:8, fillColor:'#3b82f6', color:'#fff', weight:3, fillOpacity:0.9}).addTo(map).bindPopup('Vous etes ici<br>Lat: ' + lat.toFixed(4) + '<br>Lng: ' + lng.toFixed(4)).openPopup();
        document.getElementById('userInfo').style.display = 'block';
        document.getElementById('userInfo').innerHTML = '<strong>Votre position:</strong> ' + lat.toFixed(4) + ', ' + lng.toFixed(4);
      }, function(err) { alert('Erreur de geolocalisation: ' + err.message); }, {enableHighAccuracy:true});
    });

    fetchMarches();
  })();
  </script>
</body>
</html>