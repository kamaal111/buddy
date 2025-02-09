import type { GetRecordValues } from '../utils/typing.js';

export type HTTPMethod = GetRecordValues<typeof HTTP_METHODS>;

export const HTTP_METHODS = {
  GET: 'GET',
  POST: 'POST',
  OPTIONS: 'OPTIONS',
} as const;

export type ErrorStatusCode = GetRecordValues<typeof ERROR_STATUS_CODES>;

export const ERROR_STATUS_CODES = {
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  INTERNAL_SERVER_ERROR: 500,
} as const;

export type ContentfulStatusCode = GetRecordValues<
  typeof CONTENTFUL_STATUS_CODES
>;

export const CONTENTFUL_STATUS_CODES = {
  ...ERROR_STATUS_CODES,
  OK: 200,
  CREATED: 201,
} as const;

export type StatusCode = GetRecordValues<typeof STATUS_CODES>;

export const STATUS_CODES = {
  ...CONTENTFUL_STATUS_CODES,
  NO_CONTENT: 204,
  NOT_MODIFIED: 304,
} as const;
