import { z } from 'zod';

const EnvSchema = z.object({
  PORT: z.number({ coerce: true }).gte(1000).default(8080),
  DEBUG: z.boolean({ coerce: true }).default(false),
});

const env = EnvSchema.parse(process.env);

export default env;
