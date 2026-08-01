const AppError = require('../utils/appError');
const { sendError } = require('../utils/apiResponse');

const errorHandler = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  if (process.env.NODE_ENV === 'development') {
    console.error('ERROR 💥:', err);
  }

  // Handle Mongoose CastError (Invalid ID)
  if (err.name === 'CastError') {
    const message = `Invalid ${err.path}: ${err.value}`;
    return sendError(res, 400, message);
  }

  // Handle Mongoose Duplicate Key Error
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    const message = `Duplicate value for field '${field}'. Please use another value.`;
    return sendError(res, 409, message);
  }

  // Handle Mongoose ValidationError
  if (err.name === 'ValidationError') {
    const errors = Object.values(err.errors).map(el => el.message);
    return sendError(res, 400, 'Validation failed', errors);
  }

  // Handle JWT Errors
  if (err.name === 'JsonWebTokenError') {
    return sendError(res, 401, 'Invalid token. Please log in again.');
  }

  if (err.name === 'TokenExpiredError') {
    return sendError(res, 401, 'Your session has expired. Please log in again.');
  }

  // Operational error: send message to client
  if (err.isOperational) {
    return sendError(res, err.statusCode, err.message);
  }

  // Generic Programming / Internal error
  return sendError(res, 500, 'Something went wrong on the server.');
};

module.exports = errorHandler;
