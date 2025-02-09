import { serve } from '@hono/node-server';
import { requestId } from 'hono/request-id';
import { compress } from 'hono/compress';
import { secureHeaders } from 'hono/secure-headers';
import { showRoutes } from 'hono/dev';
import { HTTPException } from 'hono/http-exception';

import env from './common/utils/env.js';
import {
  openAPIRouterFactory,
  withOpenAPIDocumentation,
} from './common/utils/open-api.js';
import loggerMiddleware, {
  makeUncaughtErrorLog,
} from './common/middleware/logger.js';
import { injectRequestContext } from './common/utils/contexts.js';
import healthAPI from './health/router.js';
import { InvalidPayload, NotFound } from './common/exceptions.js';
import { jsonResponse } from './common/utils/responses.js';
import type { ContentfulStatusCode } from './common/constants/http.js';
import { internalServerErrorJSONResponse } from './common/http/responses.js';

const app = withOpenAPIDocumentation(
  openAPIRouterFactory()
    .use(requestId())
    .use(compress({ encoding: 'gzip' }))
    .use(secureHeaders())
    .use(loggerMiddleware())
    .use(injectRequestContext())
    .route('/health', healthAPI)
)
  .all('/*', c => {
    throw new NotFound(c);
  })
  .onError((err, c) => {
    if (err instanceof InvalidPayload) {
      return jsonResponse(c, err.status as ContentfulStatusCode, err.message, {
        validations: err.validationError.errors,
      });
    }

    if (err instanceof HTTPException) {
      return jsonResponse(c, err.status as ContentfulStatusCode, err.message);
    }

    makeUncaughtErrorLog(c, err);

    return internalServerErrorJSONResponse(c);
  });

const port = env.PORT;

console.log(`Server is running on :${port}\n`);

if (env.DEBUG) {
  showRoutes(app, { verbose: false });
}

serve({ fetch: app.fetch, port });
