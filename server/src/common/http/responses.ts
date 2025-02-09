import type { Context } from 'hono';

import { ERROR_STATUS_CODES } from '../constants/http.js';
import type { HonoEnvironment } from '../utils/contexts.js';
import { jsonResponse } from '../utils/responses.js';

export function internalServerErrorJSONResponse(c: Context<HonoEnvironment>) {
  return jsonResponse(
    c,
    ERROR_STATUS_CODES.INTERNAL_SERVER_ERROR,
    'Something went wrong'
  );
}
