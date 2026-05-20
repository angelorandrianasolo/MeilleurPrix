'use strict';
 
module.exports = {
  secret:     process.env.JWT_SECRET  || 'meilleur_prix_secret_dev_2024_change_in_prod',
  expiresIn:  process.env.JWT_EXPIRES || '24h',
  algorithm:  'HS256'
};