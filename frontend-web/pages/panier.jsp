<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="_header.jsp" %>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Optimisation Panier - Meilleur Prix</title>
  <style>
    .pn-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; padding: 1.5rem 0; }
    .pn-row { display: flex; gap: 0.5rem; align-items: center; padding: 0.65rem 0.75rem; background: var(--bg-alt); border-radius: var(--radius); margin-bottom: 0.45rem; }
    .pn-row input[type="text"] { flex: 1; margin-bottom: 0; }
    .pn-row .qty { width: 70px; }
    .pn-row .imp-wrap { text-align: center; }
    .pn-row .imp-wrap input { width: 80px; margin-bottom: 0; }
    .pn-row .imp-wrap .il { font-size: 0.65rem; color: var(--text-muted); }
    .pn-row .prod-photo { width: 35px; height: 35px; border-radius: 8px; object-fit: cover; flex-shrink: 0; }
    .pn-res-opt { background: var(--success-bg); border: 1px solid rgba(5,150,105,0.2); border-radius: var(--radius-lg); padding: 1.15rem; }
    .pn-res-naive { background: var(--bg-alt); border: 1px solid var(--border); border-radius: var(--radius-lg); padding: 1.15rem; margin-top: 1rem; }
    .pn-economy { background: #fef3c7; border: 1px solid rgba(217,119,6,0.15); border-radius: var(--radius); padding: 0.75rem 1rem; display: flex; align-items: center; gap: 0.5rem; margin-top: 0.75rem; font-size: 0.88rem; font-weight: 600; color: #92400e; }
    .pn-progress { height: 8px; background: var(--border); border-radius: 999px; overflow: hidden; margin-top: 0.5rem; }
    .pn-progress .pn-progress-bar { height: 100%; background: linear-gradient(90deg, #0f766e, #14b8a6); border-radius: 999px; transition: width 0.4s ease; }
    .search-prod-panier { position: relative; }
    .search-prod-panier input { width: 100%; margin-bottom: 0; }
    .search-prod-panier .search-results { position: absolute; top: 100%; left: 0; right: 0; background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); max-height: 160px; overflow-y: auto; z-index: 10; display: none; box-shadow: var(--shadow); }
    .search-prod-panier .search-results .sr-item { padding: 0.4rem 0.65rem; cursor: pointer; font-size: 0.8rem; border-bottom: 1px solid var(--border); }
    .search-prod-panier .search-results .sr-item:hover { background: var(--bg); }
    @media (max-width: 768px) { .pn-grid { grid-template-columns: 1fr; } }
  </style>
</head>
<body>
  <div class="page-header">
    <h1>Optimisation du Panier</h1>
  </div>
  <div class="container">
    <div class="pn-grid">
      <div>
        <div class="card">
          <div class="card-header"><span class="card-title">Budget et produits</span><span class="badge badge-primary">DP Knapsack</span></div>
          <div class="form-group">
            <label for="budget">Budget total (Ariary)</label>
            <input type="number" id="budget" value="50000" min="1000" step="1000">
          </div>
          <div id="productList">
            <div class="pn-row">
              <div class="search-prod-panier" style="flex:1;">
                <input type="text" class="pid" placeholder="Nom du produit..." autocomplete="off">
                <div class="search-results"></div>
              </div>
              <input type="number" class="pq" value="1" min="1" style="width:70px;">
              <div class="imp-wrap">
                <input type="range" class="pi" min="1" max="5" value="3">
                <div class="il">Importance</div>
              </div>
              <button class="btn btn-sm btn-secondary pr" style="width:34px;padding:0.3rem;">X</button>
            </div>
          </div>
          <div style="display:flex;gap:0.5rem;margin-top:0.75rem;">
            <button id="addProduct" class="btn btn-sm btn-secondary">+ Ajouter</button>
            <button id="btnOptimiser" class="btn btn-primary" style="flex:1;">Optimiser</button>
          </div>
          <div id="loadingOpti" class="loading hidden"><div class="spinner"></div> Optimisation DP en cours...</div>
        </div>
      </div>
      <div>
        <div class="card" id="resultatCard" style="display:none;">
          <div class="card-header"><span class="card-title">Resultat</span><span id="optiStats" class="badge badge-green"></span></div>
          <div id="resultatContent"><div class="empty-state"><p>Lancez l'optimisation pour voir les resultats</p></div></div>
        </div>
      </div>
    </div>
  </div>
  <script>
  (function() {
    var API = window.API_URL + '/api/v1';
    var allProduits = [];
    function getToken(){try{return sessionStorage.getItem('mp_token')||localStorage.getItem('mp_token')}catch(e){return null}}
    var searchTimer = null;

    function fetchAllProduits() {
      fetch(API+'/produits').then(function(r){return r.json()}).then(function(j){if(j.success&&j.data)allProduits=j.data;}).catch(function(){});
    }
    fetchAllProduits();

    function setupSearch(input) {
      var parent = input.closest('.search-prod-panier');
      var results = parent.querySelector('.search-results');
      input.addEventListener('input', function() {
        clearTimeout(searchTimer);
        var q = this.value.trim();
        if (q.length < 2) { results.style.display = 'none'; return; }
        searchTimer = setTimeout(function() {
          var filtered = allProduits.filter(function(p){ return (p.nom_fr&&p.nom_fr.toLowerCase().indexOf(q)!==-1)||(p.nom_mg&&p.nom_mg.toLowerCase().indexOf(q)!==-1); }).slice(0,8);
          results.innerHTML = '';
          filtered.forEach(function(p) {
            var div = document.createElement('div');
            div.className = 'sr-item';
            div.textContent = (p.nom_fr||'')+'/'+(p.nom_mg||'');
            div.addEventListener('click', function() {
              input.value = p.nom_fr||p.nom_mg||'';
              input.setAttribute('data-prodid', p.id);
              results.style.display = 'none';
            });
            results.appendChild(div);
          });
          results.style.display = filtered.length ? 'block' : 'none';
        }, 200);
      });
      document.addEventListener('click', function(e) {
        if (!e.target.closest('.search-prod-panier')) results.style.display = 'none';
      });
    }

    function addRow() {
      var list=document.getElementById('productList'), row=document.createElement('div');
      row.className='pn-row';
      row.innerHTML='<div class="search-prod-panier" style="flex:1;"><input type="text" class="pid" placeholder="Nom du produit..." autocomplete="off"><div class="search-results"></div></div><input type="number" class="pq" value="1" min="1" style="width:70px;"><div class="imp-wrap"><input type="range" class="pi" min="1" max="5" value="3"><div class="il">Importance</div></div><button class="btn btn-sm btn-secondary pr" style="width:34px;padding:0.3rem;">X</button>';
      list.appendChild(row);
      var input = row.querySelector('.pid');
      setupSearch(input);
      row.querySelector('.pr').addEventListener('click', function(){row.remove()});
    }

    document.getElementById('addProduct').addEventListener('click', addRow);
    document.querySelectorAll('.search-prod-panier').forEach(function(w){setupSearch(w.querySelector('.pid'));});
    document.querySelectorAll('.pr').forEach(function(b){b.addEventListener('click',function(){b.closest('.pn-row').remove()})});

    document.getElementById('btnOptimiser').addEventListener('click', async function(){
      var b=parseFloat(document.getElementById('budget').value);
      if(!b||b<=0){alert('Budget invalide');return}
      var rows=document.querySelectorAll('.pn-row'), prods=[];
      rows.forEach(function(r){
        var input = r.querySelector('.pid');
        var id = input.getAttribute('data-prodid');
        var nom = input.value.trim();
        if (!id && nom) {
          var found = allProduits.find(function(p){return (p.nom_fr&&p.nom_fr.toLowerCase()===nom.toLowerCase())||(p.nom_mg&&p.nom_mg.toLowerCase()===nom.toLowerCase());});
          if (found) id = found.id;
        }
        var q=parseInt(r.querySelector('.pq').value)||1, i=parseInt(r.querySelector('.pi').value)||3;
        if (id) prods.push({id_produit:id, importance:i, quantite:q});
      });
      if(!prods.length){alert('Ajoutez au moins un produit avec un nom valide');return}
      var ld=document.getElementById('loadingOpti'), rc=document.getElementById('resultatCard');
      ld.classList.remove('hidden'); rc.style.display='none';
      try{
        var res=await fetch(API+'/panier/optimiser',{method:'POST',headers:{'Content-Type':'application/json','Authorization':'Bearer '+(getToken()||'')},body:JSON.stringify({budget:b,produits:prods})});
        var j=await res.json(); ld.classList.add('hidden');
        if(!j.success) throw new Error(j.message||'Erreur');
        var d=j.data, opt=d.panier_optimise||d.optimise||d.optimal||{}, naive=d.panier_naif||d.naif||{};
        var items=opt.produits||opt.items||[], total=opt.total||opt.cout_total||0, val=opt.valeur||opt.valeur_totale||0, budgetUtilise=opt.budget_utilise||total;
        rc.style.display='block';
        document.getElementById('optiStats').textContent=items.length+' article(s)';
        var pct = b>0 ? Math.min(100, Math.round(budgetUtilise/b*100)) : 0;
        var h='<div class="pn-res-opt"><strong>Panier optimise (DP)</strong>'+
          '<div class="pn-progress"><div class="pn-progress-bar" style="width:'+pct+'%;"></div></div>'+
          '<div style="display:flex;gap:1.5rem;margin-top:0.6rem;flex-wrap:wrap;">'+
          '<div><span style="font-size:0.72rem;color:var(--text-muted);text-transform:uppercase;">Budget utilise</span><div style="font-size:1.1rem;font-weight:700;">'+budgetUtilise+' Ar / '+b+' Ar ('+pct+'%)</div></div>'+
          '<div><span style="font-size:0.72rem;color:var(--text-muted);text-transform:uppercase;">Valeur totale</span><div style="font-size:1.1rem;font-weight:700;">'+val+'</div></div></div>';
        if(items.length){
          h+='<div class="table-wrapper" style="margin-top:0.75rem;"><table><thead><tr><th>Produit</th><th>Marche</th><th>Prix</th><th>Qte</th></tr></thead><tbody>';
          items.forEach(function(it){
            var p = allProduits.find(function(x){return x.id==(it.id_produit||it.produit_id);});
            var nom = it.nom_produit||it.nom||p ? (p.nom_fr||p.nom_mg||'') : (it.id_produit||'N/A');
            h+='<tr><td>'+nom+'</td><td>'+(it.nom_marche||it.marche||'-')+'</td><td>'+(it.prix||it.prix_unitaire||0)+' Ar</td><td>'+(it.quantite||1)+'</td></tr>';
          });
          h+='</tbody></table></div>';
        }
        h+='</div>';
        if(naive.total||naive.cout_total){
          var ni=naive.produits||naive.items||[], nt=naive.total||naive.cout_total||0;
          h+='<div class="pn-res-naive"><strong>Achat naif (premier prix)</strong><div style="margin-top:0.3rem;">Total: <strong>'+nt+' Ar</strong> | Economie DP: <strong>'+(nt-budgetUtilise)+' Ar</strong></div>';
          if(ni.length){h+='<div class="table-wrapper" style="margin-top:0.5rem;"><table><thead><tr><th>Produit</th><th>Prix</th></tr></thead><tbody>';ni.forEach(function(it){h+='<tr><td>'+(it.nom_produit||it.nom||it.id_produit||'N/A')+'</td><td>'+(it.prix||0)+' Ar</td></tr>'});h+='</tbody></table></div>';}
          h+='</div>';
        }
        if(d.economie||d.gain)h+='<div class="pn-economy"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>Economie realisee: <strong>'+(d.economie||d.gain)+' Ar</strong></div>';
        document.getElementById('resultatContent').innerHTML=h;
      }catch(err){ld.classList.add('hidden'); rc.style.display='block'; document.getElementById('resultatContent').innerHTML='<div class="message err">'+err.message+'</div>';}
    });
  })();
  </script>
</body>
</html>