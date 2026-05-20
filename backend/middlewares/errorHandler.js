'use strict';
 
const errorHandler = (err, req, res, next) => {
  const status  = err.statusCode || err.status || 500;
  const message = err.message    || 'Erreur interne du serveur';
 
  // Log en développement
  if (process.env.NODE_ENV !== 'production') {
    console.error(`[ERROR] ${req.method} ${req.path} → ${status} : ${message}`);
    if (err.stack) console.error(err.stack);
  }
 
  res.status(status).json({
    success: false,
    message,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
  });
};
 
module.exports = errorHandler;