'use strict';

require('dotenv').config();

const { Pool } = require('pg');

const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT || '5432', 10),
  database: process.env.DB_NAME     || 'meilleur_prix_db',
  user:     process.env.DB_USER     || 'postgres',
  password: process.env.DB_PASSWORD || 'angelo',
  max:      20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000
});

pool.on('connect', (client) => {
  client.query('SET search_path TO meilleur_prix, public').catch(() => {});
});

pool.on('error', (err) => {
  console.error('Erreur PostgreSQL inattendue :', err.message);
});

module.exports = pool;
