const { validationResult } = require('express-validator');
const { sendError } = require('../utils/apiResponse');

const validateRequest = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map(err => ({
      field: err.path,
      message: err.msg,
    }));
    return sendError(res, 400, 'Validation Error', formattedErrors);
  }
  next();
};

module.exports = validateRequest;
