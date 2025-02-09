import type { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import type { z } from 'zod';

import type { HonoEnvironment } from './utils/contexts.js';
import { ERROR_STATUS_CODES, type ErrorStatusCode } from './constants/http.js';

export class APIException extends HTTPException {
  readonly c: Context<HonoEnvironment>;

  constructor(
    c: Context<HonoEnvironment>,
    statusCode: ErrorStatusCode,
    options: { message: string }
  ) {
    super(statusCode, { message: options.message });
    this.c = c;
  }
}

export class InvalidPayload extends APIException {
  readonly validationError: z.ZodError;

  constructor(c: Context<HonoEnvironment>, validationError: z.ZodError) {
    super(c, ERROR_STATUS_CODES.BAD_REQUEST, { message: 'Invalid Payload' });

    this.validationError = validationError;
  }
}

export class NotFound extends APIException {
  constructor(c: Context<HonoEnvironment>) {
    super(c, ERROR_STATUS_CODES.NOT_FOUND, { message: 'Not Found' });
  }
}
