'use strict';

require('dotenv').config();

const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const morgan  = require('morgan');

const db = require('./config/db');

const authRoutes      = require('./routes/authRoutes');
const produitRoutes   = require('./routes/produitRoutes');
const marcheRoutes    = require('./routes/marcheRoutes');
const prixRoutes      = require('./routes/prixRoutes');
const previsionRoutes = require('./routes/previsionRoutes');
const panierRoutes    = require('./routes/panierRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const syncRoutes      = require('./routes/syncRoutes');
const alerteRoutes    = require('./routes/alerteRoutes');
const utilisateurRoutes = require('./routes/utilisateurRoutes');

const errorHandler = require('./middlewares/errorHandler');
const notFound     = require('./middlewares/notFound');

const app = express();

app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(morgan('dev'));
app.use(express.json({ limit: '50kb' }));
app.use(express.urlencoded({ extended: true }));

const API_PREFIX = '/api/v1';

app.use(`${API_PREFIX}/auth`,       authRoutes);
app.use(`${API_PREFIX}/produits`,   produitRoutes);
app.use(`${API_PREFIX}/marches`,    marcheRoutes);
app.use(`${API_PREFIX}/prix`,       prixRoutes);
app.use(`${API_PREFIX}/previsions`, previsionRoutes);
app.use(`${API_PREFIX}/panier`,     panierRoutes);
app.use(`${API_PREFIX}/dashboard`,  dashboardRoutes);
app.use(`${API_PREFIX}/sync`,          syncRoutes);
app.use(`${API_PREFIX}/alertes`,       alerteRoutes);
app.use(`${API_PREFIX}/utilisateurs`,  utilisateurRoutes);

app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    projet: 'MEILLEUR PRIX',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.use(notFound);
app.use(errorHandler);

const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    await db.query('SELECT 1');
    console.log('Connexion PostgreSQL etablie');

    app.listen(PORT, () => {
      console.log(`Backend MEILLEUR PRIX sur http://localhost:${PORT}`);
      console.log(`API : http://localhost:${PORT}/api/v1`);
    });
  } catch (err) {
    console.error('Impossible de se connecter a PostgreSQL :', err.message);
    process.exit(1);
  }
}

startServer();

module.exports = app;
