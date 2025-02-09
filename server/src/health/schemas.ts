import { DefaultResponseSchema } from '@/common/schemas/responses.js';
import { extendZodWithOpenApi, z } from '@hono/zod-openapi';

extendZodWithOpenApi(z);

export type PingResponse = z.infer<typeof PingResponseSchema>;

export const PingResponseSchema = DefaultResponseSchema.merge(
  z.object({ details: z.literal('PONG') })
);
