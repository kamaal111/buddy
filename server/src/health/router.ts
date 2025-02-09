import { openAPIRouterFactory } from '@/common/utils/open-api.js';
import pingRoute from './routes/ping.js';
import type { PingResponse } from './schemas.js';

const healthAPI = openAPIRouterFactory();

healthAPI.openapi(pingRoute, c => {
  return c.json({ details: 'PONG' } as PingResponse, 200);
});

export default healthAPI;
