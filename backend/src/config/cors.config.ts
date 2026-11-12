import { INestApplication } from '@nestjs/common';
import { CustomOrigin } from '@nestjs/common/interfaces/external/cors-options.interface';

export function configurarCors(
  app: Pick<INestApplication, 'enableCors'>,
  environment = process.env.NODE_ENV,
  configuredOrigins = process.env.CORS_ORIGINS ?? '',
): void {
  const allowedOrigins = new Set(
    configuredOrigins
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean)
      .map((origin) => {
        const parsed = new URL(origin);
        if (
          parsed.origin === 'null' ||
          parsed.username ||
          parsed.password ||
          parsed.pathname !== '/' ||
          parsed.search ||
          parsed.hash
        ) {
          throw new Error(`Origen CORS inválido en CORS_ORIGINS: ${origin}`);
        }
        return parsed.origin;
      }),
  );

  const originPermitido: CustomOrigin = (origin, callback) => {
    callback(
      null,
      (origin !== undefined && allowedOrigins.has(origin)) ||
        (environment !== 'production' && esOrigenLocal(origin)),
    );
  };

  app.enableCors({ origin: originPermitido });
}

function esOrigenLocal(origin: string | undefined): boolean {
  if (origin === undefined) return false;
  try {
    const parsed = new URL(origin);
    return (
      (parsed.protocol === 'http:' || parsed.protocol === 'https:') &&
      ['localhost', '127.0.0.1', '[::1]'].includes(parsed.hostname)
    );
  } catch {
    return false;
  }
}
