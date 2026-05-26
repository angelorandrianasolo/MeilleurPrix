import { useEffect, useState, useRef } from 'react';
import { Platform, View, Text, StyleSheet, Alert, TouchableOpacity, ScrollView } from 'react-native';
import { MarchesAPI } from '../../src/services/api';

const WebView = Platform.OS === 'web' ? null : require('react-native-webview').WebView;
import { COLORS, SPACING, FONT, RADIUS } from '../../src/utils/theme';
import { useLanguage } from '../../src/context';

export default function CarteScreen() {
  const { t } = useLanguage();
  const [marches, setMarches] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedMarche, setSelectedMarche] = useState(null);
  const webViewRef = useRef(null);
  const isWeb = Platform.OS === 'web';

  useEffect(() => {
    loadMarches();
  }, []);

  useEffect(() => {
    if (!isWeb) return;

    const handleWindowMessage = (event) => {
      if (!event?.data) return;
      handleWebViewMessage({ data: event.data });
    };

    window.addEventListener('message', handleWindowMessage);
    return () => window.removeEventListener('message', handleWindowMessage);
  }, [isWeb]);

  const loadMarches = async () => {
    try {
      setLoading(true);
      const res = await MarchesAPI.list();
      if (res.data) {
        setMarches(res.data);
      }
    } catch (err) {
      Alert.alert(t('error'), err.message);
    } finally {
      setLoading(false);
    }
  };

  // Générer le HTML pour la carte Leaflet
  const getMapHtml = () => {
    const marchesGeoJson = marches.map((m, idx) => ({
      id: m.id,
      nom: m.nom,
      ville: m.ville,
      lat: parseFloat(m.latitude),
      lng: parseFloat(m.longitude),
      idx
    }));

    // Centre de Madagascar approximativement
    const centerLat = -19.5;
    const centerLng = 46.5;

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css" />
        <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f5f5; }
          #map { height: 100vh; width: 100%; }
          .popup-content { 
            font-size: 13px; 
            min-width: 150px;
          }
          .popup-content h3 { 
            margin: 5px 0; 
            color: #2c3e50; 
            font-weight: 700;
          }
          .popup-content p { 
            margin: 3px 0; 
            color: #555;
          }
          .legend {
            background: white;
            padding: 12px;
            border-radius: 5px;
            box-shadow: 0 0 15px rgba(0,0,0,0.2);
            font-size: 13px;
            line-height: 18px;
          }
          .legend i {
            width: 18px;
            height: 18px;
            float: left;
            margin-right: 8px;
            opacity: 0.7;
          }
        </style>
      </head>
      <body>
        <div id="map"></div>
        <script>
          const marches = ${JSON.stringify(marchesGeoJson)};
          
          // Initialiser la carte
          const map = L.map('map').setView([${centerLat}, ${centerLng}], 7);
          
          L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap',
            maxZoom: 19
          }).addTo(map);
          
          // Ajouter les marqueurs
          marches.forEach((marche, idx) => {
            const marker = L.circleMarker([marche.lat, marche.lng], {
              radius: 8,
              fillColor: '#4CAF50',
              color: '#fff',
              weight: 2,
              opacity: 0.8,
              fillOpacity: 0.8
            }).addTo(map);
            
            marker.bindPopup(\`
              <div class="popup-content">
                <h3>\${marche.nom}</h3>
                <p><strong>Ville:</strong> \${marche.ville}</p>
                <p><strong>Lat:</strong> \${marche.lat.toFixed(4)}</p>
                <p><strong>Lng:</strong> \${marche.lng.toFixed(4)}</p>
              </div>
            \`);
            
            marker.on('click', function() {
              const message = JSON.stringify({
                type: 'MARCHE_SELECTED',
                marche: marche
              });

              if (window.ReactNativeWebView && window.ReactNativeWebView.postMessage) {
                window.ReactNativeWebView.postMessage(message);
              } else {
                window.parent.postMessage(message, '*');
              }
            });
          });
          
          // Ajouter une légende
          const legend = L.control({ position: 'bottomright' });
          legend.onAdd = function(map) {
            const div = L.DomUtil.create('div', 'legend');
            div.innerHTML = '<strong>Marchés</strong><br/><i style="background:#4CAF50;border-radius:50%;"></i>Marché actif';
            return div;
          };
          legend.addTo(map);
        </script>
      </body>
      </html>
    `;
  };

  const handleWebViewMessage = (event) => {
    try {
      const rawData = isWeb ? event.data : event.nativeEvent?.data;
      if (!rawData) return;
      const message = JSON.parse(rawData);
      if (message.type === 'MARCHE_SELECTED') {
        setSelectedMarche(message.marche);
      }
    } catch (err) {
      console.log('Erreur parsing message:', err);
    }
  };

  return (
    <View style={styles.container}>
      {loading ? (
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>{t('loading')}</Text>
        </View>
      ) : (
        <>
          <View style={styles.mapContainer}>
            {isWeb ? (
              <iframe
                title="Carte"
                srcDoc={getMapHtml()}
                style={{ width: '100%', height: '100%', border: 'none' }}
                sandbox="allow-scripts allow-same-origin"
              />
            ) : (
              <WebView
                ref={webViewRef}
                source={{ html: getMapHtml() }}
                style={styles.webView}
                onMessage={handleWebViewMessage}
                javaScriptEnabled={true}
                domStorageEnabled={true}
                startInLoadingState={true}
              />
            )}
          </View>
          
          {selectedMarche && (
            <View style={styles.selectedPanel}>
              <ScrollView style={styles.panelContent}>
                <View style={styles.panelHeader}>
                  <Text style={styles.panelTitle}>{selectedMarche.nom}</Text>
                  <TouchableOpacity onPress={() => setSelectedMarche(null)}>
                    <Text style={styles.closeBtn}>✕</Text>
                  </TouchableOpacity>
                </View>
                <View style={styles.panelInfo}>
                  <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>Ville:</Text>
                    <Text style={styles.infoValue}>{selectedMarche.ville}</Text>
                  </View>
                  <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>Latitude:</Text>
                    <Text style={styles.infoValue}>{parseFloat(selectedMarche.lat).toFixed(6)}</Text>
                  </View>
                  <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>Longitude:</Text>
                    <Text style={styles.infoValue}>{parseFloat(selectedMarche.lng).toFixed(6)}</Text>
                  </View>
                  <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>Statut:</Text>
                    <Text style={[styles.infoValue, styles.activeStatus]}>
                      {selectedMarche.est_actif ? '✓ Actif' : '✗ Inactif'}
                    </Text>
                  </View>
                </View>
              </ScrollView>
            </View>
          )}
        </>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.bg
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center'
  },
  loadingText: {
    fontSize: FONT.md,
    color: COLORS.textMuted
  },
  mapContainer: {
    flex: 1
  },
  webView: {
    flex: 1
  },
  selectedPanel: {
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
    maxHeight: 250,
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.sm
  },
  panelContent: {
    flex: 1
  },
  panelHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: SPACING.md
  },
  panelTitle: {
    fontSize: FONT.lg,
    fontWeight: '700',
    color: COLORS.text
  },
  closeBtn: {
    fontSize: FONT.xl,
    color: COLORS.textMuted
  },
  panelInfo: {
    gap: SPACING.sm
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: SPACING.sm,
    borderBottomWidth: 0.5,
    borderBottomColor: COLORS.border
  },
  infoLabel: {
    fontWeight: '600',
    color: COLORS.textMuted,
    fontSize: FONT.sm
  },
  infoValue: {
    color: COLORS.text,
    fontSize: FONT.sm,
    fontWeight: '500'
  },
  activeStatus: {
    color: '#4CAF50',
    fontWeight: '700'
  }
});
