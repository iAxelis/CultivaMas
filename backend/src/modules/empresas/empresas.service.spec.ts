import { Test, TestingModule } from '@nestjs/testing';
import { EstadoSuscripcion } from '@prisma/client';
import { EmpresasService } from './empresas.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../prisma/audit.service';
import { PasswordService } from '../../common/services/password.service';
import { AuthService } from '../auth/auth.service';
import { MailService } from '../mail/mail.service';
import { PlanCodigoEnum } from './dto/registro-empresa.dto';
import { DomainError } from '../../common/errors/domain.error';
import { CodigoError } from '../../common/errors/codigos-error.enum';

describe('EmpresasService (F-01, F0 con OTP, RN-037)', () => {
  let service: EmpresasService;

  const mockPrismaService = {
    empresa: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    usuario: {
      findUnique: jest.fn(),
      create: jest.fn(),
      count: jest.fn(),
    },
    parcela: {
      count: jest.fn(),
    },
    planSuscripcion: {
      findUnique: jest.fn(),
    },
    rol: {
      findUnique: jest.fn(),
    },
    $transaction: jest.fn(),
  };

  const mockAuditService = {
    registrar: jest.fn().mockResolvedValue(undefined),
  };

  const mockPasswordService = {
    hash: jest.fn().mockResolvedValue('argon2_hashed_password'),
  };

  const mockAuthService = {
    iniciarSesionPostRegistro: jest.fn().mockResolvedValue({
      accessToken: 'access_token_123',
      refreshToken: 'refresh_token_123',
      usuario: { id: 1, correo: 'admin@rancho.com' },
    }),
    login: jest.fn().mockResolvedValue({
      accessToken: 'access_token_123',
      refreshToken: 'refresh_token_123',
      usuario: { id: 1, correo: 'admin@rancho.com' },
    }),
  };

  const mockMailService = {
    enviarCodigoVerificacionRegistro: jest.fn().mockResolvedValue(undefined),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EmpresasService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: AuditService, useValue: mockAuditService },
        { provide: PasswordService, useValue: mockPasswordService },
        { provide: AuthService, useValue: mockAuthService },
        { provide: MailService, useValue: mockMailService },
      ],
    }).compile();

    service = module.get<EmpresasService>(EmpresasService);
    service.limpiarPreRegistros();
  });

  afterEach(() => {
    service.onModuleDestroy();
  });

  it('debe estar definido', () => {
    expect(service).toBeDefined();
  });

  describe('Flujo de Pre-registro en 2 pasos con OTP (Paso 1 + Paso 2)', () => {
    const dtoRegistro = {
      nombre: 'Rancho Los Pinos',
      rfc: 'OERA700101XX0',
      correo: 'contacto@rancho.com',
      planCodigo: PlanCodigoEnum.PRODUCTOR,
      usuarioNombre: 'Ramón',
      usuarioApellido: 'Ortega',
      usuarioCorreo: 'admin@rancho.com',
      usuarioContrasena: 'Clave123456',
    };

    const configurarMocksExitosos = () => {
      mockPrismaService.empresa.findUnique.mockResolvedValue(null);
      mockPrismaService.usuario.findUnique.mockResolvedValue(null);
      mockPrismaService.planSuscripcion.findUnique.mockResolvedValue({
        id: 2,
        codigo: 'PRODUCTOR',
        activo: true,
      });

      mockPrismaService.$transaction.mockImplementation(
        (callback: (tx: unknown) => unknown) => {
          const tx = {
            planSuscripcion: {
              findUnique: jest.fn().mockResolvedValue({
                id: 2,
                codigo: 'PRODUCTOR',
                activo: true,
              }),
            },
            rol: {
              findUnique: jest.fn().mockResolvedValue({
                id: 1,
                codigo: 'ADMIN',
              }),
            },
            empresa: {
              create: jest.fn().mockResolvedValue({
                id: 10,
                nombre: 'Rancho Los Pinos',
                rfc: 'OERA700101XX0',
                estadoSuscripcion: EstadoSuscripcion.PRUEBA,
              }),
            },
            usuario: {
              create: jest.fn().mockResolvedValue({
                id: 1,
                nombre: 'Ramón',
                correo: 'admin@rancho.com',
              }),
            },
          };
          return callback(tx);
        },
      );
    };

    it('debe completar Paso 1 y Paso 2 hasheando la contraseña UNA SOLA VEZ sin doble hash', async () => {
      configurarMocksExitosos();

      const resPaso1 = await service.solicitarCodigoRegistro(dtoRegistro);
      expect(resPaso1.mensaje).toContain('6 dígitos');
      expect(mockPasswordService.hash).toHaveBeenCalledTimes(1);
      expect(mockPasswordService.hash).toHaveBeenCalledWith('Clave123456');
      expect(
        mockMailService.enviarCodigoVerificacionRegistro,
      ).toHaveBeenCalledTimes(1);

      const codigoEnviado = (
        mockMailService.enviarCodigoVerificacionRegistro.mock
          .calls[0] as string[]
      )[2];
      expect(codigoEnviado).toMatch(/^\d{6}$/);

      // En Paso 1 NO se tocó la transacción de inserción en BD
      expect(mockPrismaService.$transaction).not.toHaveBeenCalled();

      // Paso 2: confirmar con el código recibido
      const resPaso2 = await service.confirmarRegistro(
        {
          correo: 'admin@rancho.com',
          codigo: codigoEnviado,
        },
        '192.168.1.1',
      );

      expect(resPaso2.accessToken).toBe('access_token_123');
      // Verificación crítica: NO se volvió a llamar a passwordService.hash en el Paso 2
      expect(mockPasswordService.hash).toHaveBeenCalledTimes(1);
      expect(mockAuthService.iniciarSesionPostRegistro).toHaveBeenCalledWith(
        1,
        '192.168.1.1',
      );
    });

    it('debe aplicar cooldown de 60s al mismo correo normalizado (429 DEMASIADAS_PETICIONES)', async () => {
      configurarMocksExitosos();

      await service.solicitarCodigoRegistro(dtoRegistro);

      await expect(
        service.solicitarCodigoRegistro({
          ...dtoRegistro,
          usuarioCorreo: '  ADMIN@rancho.com ',
        }),
      ).rejects.toMatchObject({
        code: CodigoError.DEMASIADAS_PETICIONES,
      });
    });

    it('debe invalidar el OTP al 5.º intento fallido consecutivo (400 PETICION_INVALIDA)', async () => {
      configurarMocksExitosos();

      await service.solicitarCodigoRegistro(dtoRegistro);
      const codigoReal = (
        mockMailService.enviarCodigoVerificacionRegistro.mock
          .calls[0] as string[]
      )[2];
      const codigoIncorrecto = codigoReal === '000000' ? '999999' : '000000';

      for (let i = 0; i < 5; i++) {
        await expect(
          service.confirmarRegistro({
            correo: 'admin@rancho.com',
            codigo: codigoIncorrecto,
          }),
        ).rejects.toMatchObject({
          code: CodigoError.PETICION_INVALIDA,
        });
      }

      // Al 6.º intento, incluso enviando el código real, ya fue autodestruido
      await expect(
        service.confirmarRegistro({
          correo: 'admin@rancho.com',
          codigo: codigoReal,
        }),
      ).rejects.toMatchObject({
        code: CodigoError.PETICION_INVALIDA,
      });
    });

    it('debe traducir colisión concurrente P2002 en Paso 2 a 409 CONFLICTO', async () => {
      configurarMocksExitosos();

      await service.solicitarCodigoRegistro(dtoRegistro);
      const codigoReal = (
        mockMailService.enviarCodigoVerificacionRegistro.mock
          .calls[0] as string[]
      )[2];

      mockPrismaService.$transaction.mockRejectedValueOnce({
        code: 'P2002',
        message: 'Unique constraint failed',
      });

      await expect(
        service.confirmarRegistro({
          correo: 'admin@rancho.com',
          codigo: codigoReal,
        }),
      ).rejects.toMatchObject({
        code: CodigoError.CONFLICTO,
      });
    });

    it('validarDominioMx debe rechazar dominios con ENOTFOUND (400) y permitir continuar ante ETIMEOUT (fail-open)', async () => {
      await expect(
        service.validarDominioMx('user@noexiste.invalid', () =>
          Promise.reject(
            Object.assign(new Error('not found'), { code: 'ENOTFOUND' }),
          ),
        ),
      ).rejects.toMatchObject({
        code: CodigoError.PETICION_INVALIDA,
      });

      // ETIMEOUT no debe lanzar excepción (fail-open)
      await expect(
        service.validarDominioMx('user@gmail.com', () =>
          Promise.reject(
            Object.assign(new Error('timeout'), { code: 'ETIMEOUT' }),
          ),
        ),
      ).resolves.toBeUndefined();
    });
  });

  describe('registrar directo interno (F0)', () => {
    const dtoRegistro = {
      nombre: 'Rancho Los Pinos',
      rfc: 'OERA700101XX0',
      correo: 'contacto@rancho.com',
      planCodigo: PlanCodigoEnum.PRODUCTOR,
      usuarioNombre: 'Ramón',
      usuarioApellido: 'Ortega',
      usuarioCorreo: 'admin@rancho.com',
      usuarioContrasena: 'Clave123456',
    };

    it('debe rechazar con 409 CONFLICTO si el RFC ya está registrado', async () => {
      mockPrismaService.empresa.findUnique.mockResolvedValue({
        id: 5,
        rfc: 'OERA700101XX0',
        deletedAt: null,
      });

      await expect(service.registrar(dtoRegistro)).rejects.toThrow(DomainError);
      try {
        await service.registrar(dtoRegistro);
      } catch (e: unknown) {
        const err = e as DomainError;
        expect(err.code).toBe(CodigoError.CONFLICTO);
        expect(err.getStatus()).toBe(409);
        expect(err.message).toContain('El RFC');
        expect(err.message).toContain('ya está registrado en otra empresa');
      }
    });

    it('debe rechazar con 409 CONFLICTO si el correo del admin ya está registrado (RN-002)', async () => {
      mockPrismaService.empresa.findUnique.mockResolvedValue(null);
      mockPrismaService.usuario.findUnique.mockResolvedValue({
        id: 3,
        correo: 'admin@rancho.com',
        deletedAt: null,
      });

      await expect(service.registrar(dtoRegistro)).rejects.toThrow(DomainError);
      try {
        await service.registrar(dtoRegistro);
      } catch (e: unknown) {
        const err = e as DomainError;
        expect(err.code).toBe(CodigoError.CONFLICTO);
        expect(err.getStatus()).toBe(409);
        expect(err.message).toContain(
          'Ya existe una cuenta registrada con el correo',
        );
      }
    });

    it('debe permitir el registro sin RFC (RFC opcional) y persistir null', async () => {
      mockPrismaService.empresa.findUnique.mockResolvedValue(null);
      mockPrismaService.usuario.findUnique.mockResolvedValue(null);

      const dtoSinRfc = {
        nombre: 'Pequeño Rancho Familiar',
        correo: 'contacto@pequenorancho.com',
        planCodigo: PlanCodigoEnum.BASICO,
        usuarioNombre: 'Pedro',
        usuarioApellido: 'Hernández',
        usuarioCorreo: 'pedro@pequenorancho.com',
        usuarioContrasena: 'Clave123456',
      };

      let datosEmpresaCreada: unknown = null;
      mockPrismaService.$transaction.mockImplementation(
        (callback: (tx: unknown) => unknown) => {
          const tx = {
            planSuscripcion: {
              findUnique: jest.fn().mockResolvedValue({
                id: 1,
                codigo: 'BASICO',
                activo: true,
              }),
            },
            rol: {
              findUnique: jest.fn().mockResolvedValue({
                id: 1,
                codigo: 'ADMIN',
              }),
            },
            empresa: {
              create: jest.fn().mockImplementation(({ data }) => {
                datosEmpresaCreada = data;
                return Promise.resolve({
                  id: 20,
                  ...data,
                  estadoSuscripcion: EstadoSuscripcion.PRUEBA,
                });
              }),
            },
            usuario: {
              create: jest.fn().mockResolvedValue({
                id: 2,
                nombre: 'Pedro',
                correo: 'pedro@pequenorancho.com',
              }),
            },
          };
          return callback(tx);
        },
      );

      const res = await service.registrar(dtoSinRfc);
      expect(res).toBeDefined();
      expect(mockPrismaService.empresa.findUnique).not.toHaveBeenCalled();
      expect((datosEmpresaCreada as any).rfc).toBeNull();
    });
  });

  describe('obtenerMiEmpresa', () => {
    it('debe calcular las cuotas de usuarios y parcelas del plan (RN-037)', async () => {
      mockPrismaService.empresa.findUnique.mockResolvedValue({
        id: 10,
        nombre: 'Rancho Los Pinos',
        rfc: 'OERA700101XX0',
        correo: 'contacto@rancho.com',
        moneda: 'MXN',
        estadoSuscripcion: 'ACTIVA',
        deletedAt: null,
        plan: {
          codigo: 'PRODUCTOR',
          nombre: 'Productor',
          precioMensual: '699.00',
          maxParcelas: 10,
          maxUsuarios: 3,
          incluyeReportes: false,
        },
      });

      mockPrismaService.usuario.count.mockResolvedValue(2);
      mockPrismaService.parcela.count.mockResolvedValue(4);

      const res = await service.obtenerMiEmpresa(10);

      expect(res.id).toBe(10);
      expect(res.cuotas.usuariosActivos).toBe(2);
      expect(res.cuotas.maxUsuarios).toBe(3);
      expect(res.cuotas.parcelasActivas).toBe(4);
      expect(res.cuotas.maxParcelas).toBe(10);
      expect(mockPrismaService.parcela.count).toHaveBeenCalledWith({
        where: {
          predio: { empresaId: 10, deletedAt: null },
          estado: { not: 'INACTIVA' },
          deletedAt: null,
        },
      });
    });
  });
});
