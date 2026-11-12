import { INestApplication } from '@nestjs/common';
import { CorsOptions } from '@nestjs/common/interfaces/external/cors-options.interface';
import { configurarCors } from './cors.config';

describe('configurarCors', () => {
  function createOriginPolicy(
    environment: string,
    configuredOrigins = '',
  ): (origin: string | undefined) => boolean {
    const enableCors = jest.fn();
    configurarCors(
      { enableCors } satisfies Pick<INestApplication, 'enableCors'>,
      environment,
      configuredOrigins,
    );

    const options = enableCors.mock.calls[0][0] as CorsOptions;
    if (typeof options.origin !== 'function') {
      throw new Error('La política CORS debe validar cada origen.');
    }

    return (origin) => {
      let allowed = false;
      options.origin(origin, (error, result) => {
        if (error) throw error;
        allowed = result === true;
      });
      return allowed;
    };
  }

  it('permite orígenes localhost durante desarrollo', () => {
    const isAllowed = createOriginPolicy('development');

    expect(isAllowed('http://localhost:5000')).toBe(true);
    expect(isAllowed('http://127.0.0.1:8080')).toBe(true);
    expect(isAllowed('https://malicious.example')).toBe(false);
  });

  it('solo permite orígenes configurados en producción', () => {
    const isAllowed = createOriginPolicy(
      'production',
      'https://app.example.com, https://admin.example.com/',
    );

    expect(isAllowed('https://app.example.com')).toBe(true);
    expect(isAllowed('https://admin.example.com')).toBe(true);
    expect(isAllowed('http://localhost:5000')).toBe(false);
    expect(isAllowed(undefined)).toBe(false);
  });
});
