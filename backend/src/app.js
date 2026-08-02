const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const errorHandler = require('./middleware/errorHandler');

const settingsRoutes = require('./routes/settingsRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const menuItemRoutes = require('./routes/menuItemRoutes');
const orderRoutes = require('./routes/orderRoutes');
const customerRoutes = require('./routes/customerRoutes');
const expenseRoutes = require('./routes/expenseRoutes');
const expenseCategoryRoutes = require('./routes/expenseCategoryRoutes');
const reportRoutes = require('./routes/reportRoutes');
const authRoutes = require('./routes/authRoutes');

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

// API V1 Endpoints
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/settings', settingsRoutes);
app.use('/api/v1/categories', categoryRoutes);
app.use('/api/v1/menu-items', menuItemRoutes);
app.use('/api/v1/orders', orderRoutes);
app.use('/api/v1/customers', customerRoutes);
app.use('/api/v1/expenses', expenseRoutes);
app.use('/api/v1/expense-categories', expenseCategoryRoutes);
app.use('/api/v1/reports', reportRoutes);

// Global Error Handler
app.use(errorHandler);

module.exports = app;