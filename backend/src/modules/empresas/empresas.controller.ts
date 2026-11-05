import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Ip,
  HttpStatus,
  HttpCode,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { EmpresasService } from './empresas.service';
import { RegistroEmpresaDto } from './dto/registro-empresa.dto';
import { ConfirmarRegistroEmpresaDto } from './dto/confirmar-registro-empresa.dto';
import { UpdateEmpresaDto } from './dto/update-empresa.dto';
import { EmpresaResponseDto } from './dto/empresa-response.dto';
import { AuthResponseDto } from '../auth/dto/auth-response.dto';
import { MensajeResponseDto } from '../../common/dto/mensaje-response.dto';
import { Public } from '../auth/decorators/public.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { RequirePermisos } from '../../common/decorators/require-permisos.decorator';

@ApiTags('Empresas')
@Controller('empresas')
export class EmpresasController {
  constructor(private readonly empresasService: EmpresasService) {}

  @Public()
  @Post('registro/solicitar-codigo')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Paso 1 de registro: solicitar código OTP de 6 dígitos por correo (Formulario F-01 / Flujo F0)',
    description:
      'Valida unicidad de RFC y correo, verifica registros MX del dominio, almacena temporalmente el pre-registro por 10 minutos con contraseña hasheada y envía el código OTP de 6 dígitos al correo del administrador.',
  })
  @ApiResponse({ status: 200, type: MensajeResponseDto })
  @ApiResponse({ status: 409, description: 'RFC o correo ya registrado' })
  async solicitarCodigoRegistro(
    @Body() dto: RegistroEmpresaDto,
  ): Promise<MensajeResponseDto> {
    return this.empresasService.solicitarCodigoRegistro(dto);
  }

  @Public()
  @Post('registro/confirmar')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary:
      'Paso 2 de registro: confirmar código OTP de 6 dígitos y crear empresa y administrador (Flujo F0)',
    description:
      'Verifica el código OTP de 6 dígitos (máx. 5 intentos, TTL 10 min) y crea atómicamente la empresa en estado PRUEBA y su primer usuario con rol ADMIN. Emite tokens de acceso.',
  })
  @ApiResponse({ status: 201, type: AuthResponseDto })
  @ApiResponse({
    status: 400,
    description:
      'Código de verificación inválido, expirado o límite de intentos superado',
  })
  @ApiResponse({ status: 409, description: 'RFC o correo ya registrado' })
  async confirmarRegistro(
    @Body() dto: ConfirmarRegistroEmpresaDto,
    @Ip() ip: string,
  ): Promise<AuthResponseDto> {
    return this.empresasService.confirmarRegistro(dto, ip);
  }

  @ApiBearerAuth('JWT-auth')
  @RequirePermisos('empresa:administrar')
  @Get('mi-empresa')
  @ApiOperation({
    summary:
      'Consultar datos de la propia empresa, plan y cuotas de uso (RN-037)',
  })
  @ApiResponse({ status: 200, type: EmpresaResponseDto })
  @ApiResponse({
    status: 403,
    description: 'No tiene el permiso empresa:administrar',
  })
  async obtenerMiEmpresa(
    @CurrentUser('empresaId') empresaId: number,
  ): Promise<EmpresaResponseDto> {
    return this.empresasService.obtenerMiEmpresa(empresaId);
  }

  @ApiBearerAuth('JWT-auth')
  @RequirePermisos('empresa:administrar')
  @Patch('mi-empresa')
  @ApiOperation({
    summary: 'Actualizar datos comerciales de la propia empresa',
  })
  @ApiResponse({ status: 200, type: EmpresaResponseDto })
  async actualizarMiEmpresa(
    @CurrentUser('empresaId') empresaId: number,
    @Body() dto: UpdateEmpresaDto,
  ): Promise<EmpresaResponseDto> {
    return this.empresasService.actualizarMiEmpresa(empresaId, dto);
  }
}
