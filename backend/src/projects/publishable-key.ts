import { randomBytes } from 'node:crypto';

export const PUBLISHABLE_KEY_PREFIX = 'pk_';

export function generatePublishableKey(): string {
  return PUBLISHABLE_KEY_PREFIX + randomBytes(32).toString('base64url');
}
