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
const syncRoutes = require('./routes/syncRoutes');

const app = express();

app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// API V1 Endpoints
app.use('/api/v1/settings', settingsRoutes);
app.use('/api/v1/categories', categoryRoutes);
app.use('/api/v1/menu-items', menuItemRoutes);
app.use('/api/v1/orders', orderRoutes);
app.use('/api/v1/customers', customerRoutes);
app.use('/api/v1/expenses', expenseRoutes);
app.use('/api/v1/expense-categories', expenseCategoryRoutes);
app.use('/api/v1/reports', reportRoutes);
app.use('/api/v1/sync', syncRoutes);

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'FoodBillX POS Service is healthy' });
});

// Global Error Handler
app.use(errorHandler);

module.exports = app;