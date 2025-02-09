import { extendZodWithOpenApi, z } from '@hono/zod-openapi';

extendZodWithOpenApi(z);

export type DefaultResponse = z.infer<typeof DefaultResponseSchema>;

export const DefaultResponseSchema = z.object({ details: z.string() });
