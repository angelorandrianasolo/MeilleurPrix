<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
<header id="mainHeader">
  <div class="container">
    <a href="<%= request.getContextPath() %>/pages/recherche.jsp" class="logo">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/><path d="M6 11h10"/><path d="M11 6v10"/>
      </svg>
      Meilleur Prix
    </a>
    <nav>
      <a href="recherche.jsp">Recherche</a>
      <a href="carte.jsp">Carte</a>
      <a href="saisie-prix.jsp">Saisie</a>
      <a href="comparaison.jsp">Comparaison</a>
      <a href="panier.jsp">Panier</a>
      <a href="prevision.jsp">Prevision</a>
      <a href="dashboard.jsp">Dashboard</a>
      <a href="#" id="logout" class="logout-link">Deconnexion</a>
    </nav>
  </div>
</header>
<%@ include file="_config.jsp" %>
<script src="<%= request.getContextPath() %>/js/api.js"></script>
<script>
  (function() {
    if (typeof requireAuth === 'function' && !requireAuth()) return;

    var header = document.getElementById('mainHeader');
    var ticking = false;
    window.addEventListener('scroll', function() {
      if (!ticking) {
        window.requestAnimationFrame(function() {
          if (window.scrollY > 10) header.classList.add('scrolled');
          else header.classList.remove('scrolled');
          ticking = false;
        });
        ticking = true;
      }
    });

    var links = document.querySelectorAll('nav a:not(#logout)');
    var current = location.pathname.split('/').pop() || 'recherche.jsp';
    links.forEach(function(a) {
      if (a.getAttribute('href') === current) a.classList.add('active');
    });

    var logoutBtn = document.getElementById('logout');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', function(e) {
        e.preventDefault();
        if (typeof setToken === 'function') setToken(null);
        if (typeof setUser === 'function') setUser(null);
        location.href = 'login.jsp';
      });
    }
  })();
</script>
