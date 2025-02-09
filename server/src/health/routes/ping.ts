import { createRoute } from '@hono/zod-openapi';

import { HTTP_METHODS, STATUS_CODES } from '@/common/constants/http.js';
import { typedLowercased } from '@/common/utils/strings.js';
import { PingResponseSchema } from '../schemas.js';

const pingRoute = createRoute({
  method: typedLowercased(HTTP_METHODS.GET),
  path: 'ping',
  responses: {
    [STATUS_CODES.OK]: {
      content: {
        'application/json': {
          schema: PingResponseSchema,
        },
      },
      description: 'Ping server',
    },
  },
});

export default pingRoute;
