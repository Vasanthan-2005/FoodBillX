const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const errorHandler = require('./middleware/errorHandler');

const settingsRoutes = require('./routes/settingsRoutes');
const reportRoutes = require('./routes/reportRoutes');
const authRoutes = require('./routes/authRoutes');
const syncRoutes = require('./routes/syncRoutes');
const { router: appRoutes, getAppVersionHandler } = require('./routes/appRoutes');

const app = express();

app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

/**
 * Health Check Endpoint
 * 
 * Intended for:
 * - Render keep-alive monitoring
 * - Health checks
 * - Deployment verification
 * - Uptime monitoring
 * 
 * Unauthenticated, no database access, lightweight & instant response.
 */
const healthHandler = (req, res) => {
  res.status(200).json({
    success: true,
    status: 'healthy',
    service: 'FoodBillX Backend',
    timestamp: new Date().toISOString(),
    uptime: Math.floor(process.uptime()),
    environment: process.env.NODE_ENV || 'development'
  });
};

app.get('/health', healthHandler);
app.get('/api/v1/health', healthHandler);

// Top-level App Version Endpoint (matching user requirement GET /api/app-version)
app.get('/api/app-version', getAppVersionHandler);
app.get('/api/v1/app-version', getAppVersionHandler);

// Active API V1 Endpoints
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/settings', settingsRoutes);
app.use('/api/v1/reports', reportRoutes);
app.use('/api/v1/sync', syncRoutes);
app.use('/api/v1/app', appRoutes);

// Global Error Handler
app.use(errorHandler);

module.exports = app;