// Système de traduction FR/MG pour l'application
const translations = {
  FR: {
    // Navigation
    nav_search: 'Recherche',
    nav_compare: 'Comparer',
    nav_map: 'Carte',
    nav_cart: 'Panier',
    nav_profile: 'Profil',
    nav_input: 'Saisie Prix',
    
    // Auth
    auth_login: 'Connexion',
    auth_register: 'Inscription',
    auth_email: 'Adresse email',
    auth_password: 'Mot de passe',
    auth_name: 'Nom complet',
    auth_role: 'Rôle',
    auth_signup: '✍️ Créer un compte gratuitement',
    auth_signin: '🔑 Se connecter',
    auth_already_member: 'Deja inscrit ?',
    auth_error: 'Erreur de connexion',
    auth_network_error: 'Erreur de connexion Network request failed',
    auth_required_fields: 'Champs requis',
    auth_fill_all: 'Veuillez remplir tous les champs.',
    auth_min_password: 'Mot de passe minimum 6 caractères',
    
    // Roles
    role_buyer: 'Acheteur',
    role_seller: 'Vendeur',
    role_collector: 'Collecteur',
    role_admin: 'Administrateur',
    
    // Search
    search_placeholder: 'Chercher un produit...',
    search_results: 'Résultats',
    search_no_results: 'Aucun produit trouvé',
    search_min_chars: 'Minimum 2 caractères',
    
    // Price input
    input_product: 'Produit',
    input_market: 'Marché',
    input_price: 'Prix',
    input_unit: 'Unité',
    input_date: 'Date',
    input_submit: 'Enregistrer prix',
    input_success: 'Prix enregistré avec succès',
    input_error: 'Erreur lors de l\'enregistrement',
    input_offline: 'Hors ligne - Prix enregistré localement',
    input_sync_queue: 'En attente de synchronisation',
    
    // Comparison
    compare_title: 'Comparer marchés',
    compare_optimal: 'Marché optimal',
    compare_product_price: 'Prix du produit',
    compare_transport: 'Coût de transport',
    compare_total: 'Coût total',
    compare_market: 'Marché',
    compare_find: 'Trouver le meilleur marché',
    compare_dijkstra_info: 'Dijkstra + min-heap — prix + transport',
    
    // Cart optimization
    cart_title: 'Panier',
    cart_budget: 'Budget disponible',
    cart_products: 'Produits à acheter',
    cart_optimize: 'Optimiser panier',
    cart_optimized: 'Panier optimisé',
    cart_naive: 'Panier naïf',
    cart_total_cost: 'Coût total',
    cart_value: 'Valeur',
    cart_remaining: 'Budget restant',
    
    // Forecasting
    forecast_title: 'Prévisions',
    forecast_simple: 'Moyenne simple',
    forecast_optimized: 'Moyenne mobile pondérée',
    forecast_30days: 'Prévision 30 jours',
    forecast_comparison: 'Comparaison',
    forecast_recommended: 'Méthode recommandée',
    forecast_error_rate: 'Taux d\'erreur',
    forecast_insufficient: 'Données insuffisantes',
    
    // Dashboard
    dashboard_title: 'Tableau de bord',
    dashboard_stats: 'Statistiques',
    dashboard_top_products: 'Top 5 produits',
    dashboard_top_markets: 'Top 5 marchés',
    dashboard_trend_30: 'Tendance 30j',
    dashboard_avg_price: 'Prix moyen',
    dashboard_entries: 'Saisies',
    
    // Offline
    offline_mode: 'Mode hors ligne',
    offline_title: 'Hors ligne',
    offline_queue: 'File d\'attente',
    offline_pending: 'En attente',
    offline_synced: 'Synchronisé',
    offline_failed: 'Échoué',
    offline_sync_now: 'Synchroniser maintenant',
    offline_retry: 'Réessayer',
    
    // Map
    map_title: 'Carte des marchés',
    map_markets: 'Afficher les marchés',
    map_market_active: 'Marché actif',
    map_coordinates: 'Coordonnées GPS',
    map_latitude: 'Latitude',
    map_longitude: 'Longitude',
    map_city: 'Ville',
    map_status: 'Statut',
    map_click_for_info: 'Cliquez sur un marqueur pour plus d\'infos',
    map_no_markets: 'Aucun marché trouvé',
    map_loading_markets: 'Chargement des marchés...',
    
    // General
    loading: 'Chargement...',
    error: 'Erreur',
    success: 'Succès',
    cancel: 'Annuler',
    close: 'Fermer',
    back: 'Retour',
    next: 'Suivant',
    save: 'Enregistrer',
    delete: 'Supprimer',
    logout: 'Déconnexion',
    settings: 'Paramètres',
    language: 'Langue',
    welcome: 'Bienvenue',
    goodbye: 'Au revoir'
  },
  
  MG: {
    // Navigation
    nav_search: 'Fitadiavana',
    nav_compare: 'Mampitaha',
    nav_map: 'Sakalaham-pirenena',
    nav_cart: 'Fiara',
    nav_profile: 'Profily',
    nav_input: 'Fanisana Vidiny',
    
    // Auth
    auth_login: 'Hiditra',
    auth_register: 'Misoratra',
    auth_email: 'Adiresy mailaka',
    auth_password: 'Teny miafina',
    auth_name: 'Anarana feno',
    auth_role: 'Anjara',
    auth_signup: '✍️ Hamorona kaonty fahala',
    auth_signin: '🔑 Hiditra',
    auth_already_member: 'Efa misoratra ve?',
    auth_error: 'Hadisoana indrindra',
    auth_network_error: 'Tsy afaka mifandray ny network',
    auth_required_fields: 'Sahan-kazo ilaina',
    auth_fill_all: 'Amidinio ny sahan-kazo rehetra.',
    auth_min_password: 'Teny miafina farafaharatsiny 6 taratasy',
    
    // Roles
    role_buyer: 'Mpividy',
    role_seller: 'Mpandeha',
    role_collector: 'Mpanangonana',
    role_admin: 'Mpitantana',
    
    // Search
    search_placeholder: 'Mitadiava vokatra...',
    search_results: 'Vokatra',
    search_no_results: 'Tsy misy vokatra',
    search_min_chars: 'Minimum 2 taratasy',
    
    // Price input
    input_product: 'Vokatra',
    input_market: 'Tsenam-bary',
    input_price: 'Vidiny',
    input_unit: 'Singa',
    input_date: 'Andro',
    input_submit: 'Hitahiry vidiny',
    input_success: 'Vidiny hitahiry tsara',
    input_error: 'Hadisoana teo amin ny fitahiry',
    input_offline: 'Tsy mifandray - Vidiny na hitahiry teo amin ny finday',
    input_sync_queue: 'Namiandry ny faninjenjenja',
    
    // Comparison
    compare_title: 'Mampitaha tsenam-bary',
    compare_optimal: 'Tsenam-bary mahomby',
    compare_product_price: 'Vidiny vokatra',
    compare_transport: 'Vidin\'alahady',
    compare_total: 'Vidin\'iray',
    compare_market: 'Tsenam-bary',
    compare_find: 'Tadiavina tsenam-bary mahomby',
    compare_dijkstra_info: 'Dijkstra + min-heap — vidiny + alahady',
    
    // Cart optimization
    cart_title: 'Fiara',
    cart_budget: 'Vola voaankohonana',
    cart_products: 'Vokatra hovidiana',
    cart_optimize: 'Hokasika fiara',
    cart_optimized: 'Fiara hokasika',
    cart_naive: 'Fiara fototra',
    cart_total_cost: 'Vidin\'iray',
    cart_value: 'Sandany',
    cart_remaining: 'Vola sisa',
    
    // Forecasting
    forecast_title: 'Vinavina',
    forecast_simple: 'Salan-karany tsotra',
    forecast_optimized: 'Salan-karany antsasany misy lanja',
    forecast_30days: 'Vinavina 30 andro',
    forecast_comparison: 'Mampitaha',
    forecast_recommended: 'Fomba notadiavina',
    forecast_error_rate: 'Taham-pahadisoana',
    forecast_insufficient: 'Tahiry tsy ampy',
    
    // Dashboard
    dashboard_title: 'Korajia fitarihan\'asa',
    dashboard_stats: 'Statistika',
    dashboard_top_products: 'Top 5 vokatra',
    dashboard_top_markets: 'Top 5 tsenam-bary',
    dashboard_trend_30: 'Fironana 30 andro',
    dashboard_avg_price: 'Salan-karany vidiny',
    dashboard_entries: 'Fanisana',
    
    // Offline
    offline_mode: 'Fanjakana tsy mifandray',
    offline_title: 'Tsy mifandray',
    offline_queue: 'Filaharana faninjenjenja',
    offline_pending: 'Namiandry',
    offline_synced: 'Synkro',
    offline_failed: 'Tsy nahomby',
    offline_sync_now: 'Synkro ankehitriny',
    offline_retry: 'Avereno indray',
    
    // Map
    map_title: 'Sakalaham-pirenena ny tsenam-bary',
    map_markets: 'Asehoy ny tsenam-bary',
    map_market_active: 'Tsenam-bary mavitrika',
    map_coordinates: 'Fanondro GPS',
    map_latitude: 'Latitude',
    map_longitude: 'Longitude',
    map_city: 'Kaominina',
    map_status: 'Fiainam-piditra',
    map_click_for_info: 'Sokafin\'ny mariker raha maniry ny tilifitra',
    map_no_markets: 'Tsy misy tsenam-bary',
    map_loading_markets: 'Misambotra ny tsenam-bary...',
    
    // General
    loading: 'Misambotra...',
    error: 'Hadisoana',
    success: 'Mahomby',
    cancel: 'Avela',
    close: 'Hidio',
    back: 'Imeraina',
    next: 'Manaraka',
    save: 'Hitahiry',
    delete: 'Hofafina',
    logout: 'Hiala',
    settings: 'Fanatsarana',
    language: 'Fiteny',
    welcome: 'Tongasoa',
    goodbye: 'Veloma'
  }
};

export function getTranslation(lang, key) {
  const lang_obj = translations[lang] || translations.FR;
  return lang_obj[key] || key;
}

export function t(key, lang = 'FR') {
  return getTranslation(lang, key);
}

export default translations;
