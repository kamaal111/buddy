import type { Context } from 'hono';

import type { ContentfulStatusCode } from '../constants/http.js';

export function jsonResponse<
  SC extends ContentfulStatusCode,
  ExtraData extends Record<string, unknown>,
>(
  c: Context,
  statusCode: SC,
  details: string,
  extraData: ExtraData = {} as ExtraData
) {
  return c.json({ ...extraData, details }, statusCode);
}
