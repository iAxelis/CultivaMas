import { Test, TestingModule } from '@nestjs/testing';
import { EmpresasController } from './empresas.controller';
import { EmpresasService } from './empresas.service';
import { PlanCodigoEnum } from './dto/registro-empresa.dto';

describe('EmpresasController', () => {
  let controller: EmpresasController;

  const mockEmpresasService = {
    solicitarCodigoRegistro: jest.fn(),
    confirmarRegistro: jest.fn(),
    obtenerMiEmpresa: jest.fn(),
    actualizarMiEmpresa: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [EmpresasController],
      providers: [{ provide: EmpresasService, useValue: mockEmpresasService }],
    }).compile();

    controller = module.get<EmpresasController>(EmpresasController);
  });

  it('debe estar definido', () => {
    expect(controller).toBeDefined();
  });

  it('debe delegar solicitarCodigoRegistro (Paso 1 F0) al servicio', async () => {
    const dto = {
      nombre: 'Rancho Santa Fe',
      rfc: 'OERA700101XX0',
      correo: 'contacto@rancho.com',
      planCodigo: PlanCodigoEnum.PRODUCTOR,
      usuarioNombre: 'Ramón',
      usuarioApellido: 'Ortega',
      usuarioCorreo: 'admin@rancho.com',
      usuarioContrasena: 'ClaveSegura123',
    };
    mockEmpresasService.solicitarCodigoRegistro.mockResolvedValue({
      mensaje:
        'Se ha enviado un código de verificación de 6 dígitos a su correo electrónico. El código expira en 10 minutos.',
    });

    const res = await controller.solicitarCodigoRegistro(dto);
    expect(mockEmpresasService.solicitarCodigoRegistro).toHaveBeenCalledWith(
      dto,
    );
    expect(res.mensaje).toContain('6 dígitos');
  });

  it('debe delegar confirmarRegistro (Paso 2 F0) al servicio', async () => {
    const dto = {
      correo: 'admin@rancho.com',
      codigo: '482910',
    };
    mockEmpresasService.confirmarRegistro.mockResolvedValue({
      accessToken: 'token_f0',
      refreshToken: 'ref_f0',
      usuario: { id: 1 },
    });

    const res = await controller.confirmarRegistro(dto, '127.0.0.1');
    expect(mockEmpresasService.confirmarRegistro).toHaveBeenCalledWith(
      dto,
      '127.0.0.1',
    );
    expect(res.accessToken).toBe('token_f0');
  });

  it('debe delegar obtenerMiEmpresa con el tenant del usuario autenticado', async () => {
    mockEmpresasService.obtenerMiEmpresa.mockResolvedValue({
      id: 5,
      nombre: 'Rancho Santa Fe',
    });

    const res = await controller.obtenerMiEmpresa(5);
    expect(mockEmpresasService.obtenerMiEmpresa).toHaveBeenCalledWith(5);
    expect(res.id).toBe(5);
  });

  it('debe delegar actualizarMiEmpresa con el tenant del usuario autenticado', async () => {
    const dto = { telefono: '9511112233' };
    mockEmpresasService.actualizarMiEmpresa.mockResolvedValue({
      id: 5,
      telefono: '9511112233',
    });

    const res = await controller.actualizarMiEmpresa(5, dto);
    expect(mockEmpresasService.actualizarMiEmpresa).toHaveBeenCalledWith(
      5,
      dto,
    );
    expect(res.telefono).toBe('9511112233');
  });
});
