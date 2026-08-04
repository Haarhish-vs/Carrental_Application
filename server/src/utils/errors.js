class ApplicationError extends Error {
  constructor(message, statusCode = 500, errors = []) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.errors = errors;
    Error.captureStackTrace(this, this.constructor);
  }
}

class BadRequestError extends ApplicationError {
  constructor(message = 'Bad Request', errors = []) {
    super(message, 400, errors);
  }
}

class NotFoundError extends ApplicationError {
  constructor(message = 'Resource Not Found') {
    super(message, 404);
  }
}

class ValidationError extends ApplicationError {
  constructor(errors = [], message = 'Validation failed') {
    super(message, 400, errors);
  }
}

class ConflictError extends ApplicationError {
  constructor(message = 'Resource Conflict') {
    super(message, 409);
  }
}

module.exports = {
  ApplicationError,
  BadRequestError,
  NotFoundError,
  ValidationError,
  ConflictError
};
