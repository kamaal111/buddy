import { swaggerUI } from '@hono/swagger-ui';
import { OpenAPIHono } from '@hono/zod-openapi';
import type { Env, Hono, Schema } from 'hono';
import type { BlankSchema } from 'hono/types';

import type { HonoEnvironment } from './contexts.js';
import { InvalidPayload } from '../exceptions.js';

export type OpenAPIRouter = OpenAPIHono<HonoEnvironment>;

export function openAPIRouterFactory() {
  return new OpenAPIHono<HonoEnvironment>({
    defaultHook: (result, c) => {
      if (!result.success) {
        throw new InvalidPayload(c, result.error);
      }
    },
  });
}

export function withOpenAPIDocumentation<
  E extends Env = Env,
  S extends Schema = BlankSchema,
  BasePath extends string = '/',
>(app: Hono<E, S, BasePath>) {
  return (app as OpenAPIHono<E, S, BasePath>)
    .doc('/spec.json', {
      openapi: '3.0.0',
      info: { version: '1.0.0', title: 'Buddy API' },
    })
    .get('/doc', swaggerUI({ url: '/spec.json' }));
}
