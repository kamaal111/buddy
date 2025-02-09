import { serve } from '@hono/node-server';
import { requestId } from 'hono/request-id';
import { compress } from 'hono/compress';
import { secureHeaders } from 'hono/secure-headers';
import { showRoutes } from 'hono/dev';

import env from './common/utils/env.js';
import {
  openAPIRouterFactory,
  withOpenAPIDocumentation,
} from './common/utils/open-api.js';
import loggerMiddleware from './common/middleware/logger.js';
import { injectRequestContext } from './common/utils/contexts.js';

let app = openAPIRouterFactory()
  .use(requestId())
  .use(compress({ encoding: 'gzip' }))
  .use(secureHeaders())
  .use(loggerMiddleware())
  .use(injectRequestContext())
  .get('/', c => {
    return c.text('Hello Hono!');
  });
app = withOpenAPIDocumentation(app);

const port = env.PORT;

console.log(`Server is running on :${port}\n`);

if (env.DEBUG) {
  showRoutes(app, { verbose: false });
}

serve({ fetch: app.fetch, port });
