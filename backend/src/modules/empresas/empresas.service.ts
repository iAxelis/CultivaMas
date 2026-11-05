import * as crypto from 'crypto';
import * as dns from 'dns';
import {
  Injectable,
  HttpStatus,
  Logger,
  OnModuleDestroy,
} from '@nestjs/common';
import { EstadoSuscripcion, AccionAuditoria, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../prisma/audit.service';
import { PasswordService } from '../../common/services/password.service';
import { AuthService } from '../auth/auth.service';
import { MailService } from '../mail/mail.service';
import { PlanCodigoEnum, RegistroEmpresaDto } from './dto/registro-empresa.dto';
import { ConfirmarRegistroEmpresaDto } from './dto/confirmar-registro-empresa.dto';
import { UpdateEmpresaDto } from './dto/update-empresa.dto';
import { EmpresaResponseDto } from './dto/empresa-response.dto';
import { AuthResponseDto } from '../auth/dto/auth-response.dto';
import { CodigoError } from '../../common/errors/codigos-error.enum';
import { DomainError } from '../../common/errors/domain.error';

export interface DatosPreRegistroHash {
  nombre: string;
  razonSocial: string | null;
  rfc: string | null;
  correo: string;
  telefono: string | null;
  direccion: string | null;
  planCodigo: PlanCodigoEnum;
  usuarioNombre: string;
  usuarioApellido: string;
  usuarioCorreo: string;
  contrasenaHash: string;
  usuarioTelefono: string | null;
}

export interface PreRegistroPendiente {
  datos: DatosPreRegistroHash;
  codigoHash: string;
  creadoEn: number;
  expiraEn: number;
  intentosFallidos: number;
}

export const OTP_TTL_MS = 10 * 60 * 1000; // 10 minutos
export const MAX_INTENTOS_OTP = 5;
export const COOLDOWN_REENVIO_MS = 60 * 1000; // 60 segundos entre reenvíos al mismo correo
export const VENTANA_SOLICITUDES_CORREO_MS = 15 * 60 * 1000; // 15 minutos
export const MAX_SOLICITUDES_POR_CORREO = 3; // Máximo 3 códigos cada 15 min por correo
export const MAX_ENTRADAS_MEMORIA_OTP = 10_000; // Límite estricto de memoria (instancia única, ver DT-10)
const INTERVALO_LIMPIEZA_OTP_MS = 5 * 60 * 1000; // 5 minutos
const DNS_MX_TIMEOUT_MS = 2000; // 2 segundos máximo para resolución MX

@Injectable()
export class EmpresasService implements OnModuleDestroy {
  private readonly logger = new Logger(EmpresasService.name);

  /**
   * Almacén en memoria para pre-registros con código OTP de 6 dígitos (instancia única).
   * Indexado por correo de usuario normalizado (lowercase + trim).
   * Garantiza un único registro pendiente activo por correo.
   */
  private readonly preRegistros = new Map<string, PreRegistroPendiente>();

  /**
   * Ventana rodante de timestamps de solicitud por correo normalizado (máx 3 / 15 min).
   */
  private readonly historialSolicitudesCorreo = new Map<string, number[]>();

  private readonly intervaloLimpieza: NodeJS.Timeout;

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
    private readonly passwordService: PasswordService,
    private readonly authService: AuthService,
    private readonly mailService?: MailService,
  ) {
    this.intervaloLimpieza = setInterval(() => {
      this.purgarExpirados();
    }, INTERVALO_LIMPIEZA_OTP_MS);
    if (typeof this.intervaloLimpieza.unref === 'function') {
      this.intervaloLimpieza.unref();
    }
  }

  onModuleDestroy(): void {
    clearInterval(this.intervaloLimpieza);
  }

  /**
   * Elimina entradas de pre-registro expiradas y ventanas de rate limit obsoletas.
   */
  public purgarExpirados(ahora = Date.now()): void {
    for (const [correo, entrada] of this.preRegistros.entries()) {
      if (entrada.expiraEn <= ahora) {
        this.preRegistros.delete(correo);
      }
    }

    for (const [
      correo,
      timestamps,
    ] of this.historialSolicitudesCorreo.entries()) {
      const vigentes = timestamps.filter(
        (ts) => ahora - ts < VENTANA_SOLICITUDES_CORREO_MS,
      );
      if (vigentes.length === 0) {
        this.historialSolicitudesCorreo.delete(correo);
      } else if (vigentes.length !== timestamps.length) {
        this.historialSolicitudesCorreo.set(correo, vigentes);
      }
    }
  }

  /**
   * Verifica los registros MX del dominio del correo electrónico.
   * Si el dominio no existe o carece de MX (ENOTFOUND, ENODATA, lista vacía), rechaza con 400.
   * Si ocurre un fallo transitorio de red o timeout del servidor DNS, registra warning y deja pasar (fail-open).
   */
  public async validarDominioMx(
    correo: string,
    resolverMx: (hostname: string) => Promise<dns.MxRecord[]> = dns.promises
      .resolveMx,
  ): Promise<void> {
    const partes = correo.split('@');
    const dominio = partes.length === 2 ? partes[1].toLowerCase().trim() : '';
    if (!dominio) {
      throw new DomainError(
        CodigoError.PETICION_INVALIDA,
        'El correo electrónico no contiene un dominio válido',
        HttpStatus.BAD_REQUEST,
      );
    }

    let timeoutHandle: NodeJS.Timeout | undefined;
    const timeoutPromise = new Promise<'DNS_TIMEOUT'>((resolve) => {
      timeoutHandle = setTimeout(
        () => resolve('DNS_TIMEOUT'),
        DNS_MX_TIMEOUT_MS,
      );
      if (typeof timeoutHandle.unref === 'function') {
        timeoutHandle.unref();
      }
    });

    try {
      const resultado = await Promise.race([
        resolverMx(dominio),
        timeoutPromise,
      ]);

      if (resultado === 'DNS_TIMEOUT') {
        this.logger.warn(
          `Timeout de ${DNS_MX_TIMEOUT_MS}ms al consultar registros MX para el dominio ${dominio}. Permitiendo continuar (fail-open).`,
        );
        return;
      }

      if (!Array.isArray(resultado) || resultado.length === 0) {
        throw new DomainError(
          CodigoError.PETICION_INVALIDA,
          `El dominio del correo '${dominio}' no puede recibir correos electrónicos (sin registros MX)`,
          HttpStatus.BAD_REQUEST,
        );
      }
    } catch (err: unknown) {
      if (err instanceof DomainError) {
        throw err;
      }

      const code =
        typeof err === 'object' && err !== null
          ? (err as { code?: string }).code
          : undefined;

      if (code === 'ENOTFOUND' || code === 'ENODATA' || code === 'EBADNAME') {
        throw new DomainError(
          CodigoError.PETICION_INVALIDA,
          `El dominio del correo '${dominio}' no existe o no puede recibir correos electrónicos`,
          HttpStatus.BAD_REQUEST,
        );
      }

      this.logger.warn(
        `Error transitorio DNS (${code ?? 'UNKNOWN'}) al verificar MX de ${dominio}. Permitiendo continuar (fail-open).`,
      );
    } finally {
      if (timeoutHandle) {
        clearTimeout(timeoutHandle);
      }
    }
  }

  /**
   * Paso 1 del Registro con Verificación OTP:
   * Valida reglas de negocio, unicidad de RFC y correo, plan comercial, límites por correo
   * (cooldown 60s y máx 3 cada 15m), hashea la contraseña una sola vez con Argon2id,
   * almacena temporalmente en memoria por 10 minutos y envía el código de 6 dígitos por correo.
   */
  async solicitarCodigoRegistro(
    dto: RegistroEmpresaDto,
  ): Promise<{ mensaje: string }> {
    if (!dto.usuarioContrasena || dto.usuarioContrasena.length < 6) {
      throw new DomainError(
        CodigoError.PETICION_INVALIDA,
        'La contraseña debe tener al menos 6 caracteres',
        HttpStatus.BAD_REQUEST,
      );
    }

    const rfcNormalizado =
      dto.rfc && dto.rfc.trim().length > 0
        ? dto.rfc.toUpperCase().trim()
        : null;
    const correoUsuarioNormalizado = dto.usuarioCorreo.toLowerCase().trim();
    const correoEmpresaNormalizado = dto.correo.toLowerCase().trim();
    const ahora = Date.now();

    this.purgarExpirados(ahora);

    // 1. Verificar cooldown de reenvío (60 s) y límite de 3 solicitudes / 15 min por correo
    const entradaPrevia = this.preRegistros.get(correoUsuarioNormalizado);
    if (
      entradaPrevia &&
      entradaPrevia.expiraEn > ahora &&
      ahora - entradaPrevia.creadoEn < COOLDOWN_REENVIO_MS
    ) {
      const segundosRestantes = Math.max(
        1,
        Math.ceil(
          (COOLDOWN_REENVIO_MS - (ahora - entradaPrevia.creadoEn)) / 1000,
        ),
      );
      throw new DomainError(
        CodigoError.DEMASIADAS_PETICIONES,
        `Debe esperar ${segundosRestantes} segundos antes de solicitar un nuevo código de verificación.`,
        HttpStatus.TOO_MANY_REQUESTS,
        { retryAfter: segundosRestantes },
      );
    }

    const historial =
      this.historialSolicitudesCorreo.get(correoUsuarioNormalizado) ?? [];
    const historialVigente = historial.filter(
      (ts) => ahora - ts < VENTANA_SOLICITUDES_CORREO_MS,
    );
    if (historialVigente.length >= MAX_SOLICITUDES_POR_CORREO) {
      throw new DomainError(
        CodigoError.DEMASIADAS_PETICIONES,
        'Ha alcanzado el límite de 3 códigos de verificación en 15 minutos para este correo. Intente más tarde.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // 2. Verificar límite de capacidad del Map en memoria (protección contra agotamiento de RAM)
    if (
      !this.preRegistros.has(correoUsuarioNormalizado) &&
      this.preRegistros.size >= MAX_ENTRADAS_MEMORIA_OTP
    ) {
      throw new DomainError(
        CodigoError.DEMASIADAS_PETICIONES,
        'El servicio de registro experimenta alta demanda temporal. Intente nuevamente en unos minutos.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // 3. Validaciones de unicidad en base de datos y existencia de plan
    await this.validarDisponibilidadRfcYCorreo(
      rfcNormalizado,
      correoUsuarioNormalizado,
    );

    const plan = await this.prisma.planSuscripcion.findUnique({
      where: { codigo: dto.planCodigo },
    });
    if (!plan || !plan.activo) {
      throw new DomainError(
        CodigoError.RECURSO_NO_ENCONTRADO,
        `El plan comercial '${dto.planCodigo}' no está disponible`,
        HttpStatus.NOT_FOUND,
      );
    }

    // 4. Validación MX del dominio (omitida en entorno test para determinismo offline)
    if (process.env.NODE_ENV !== 'test') {
      await this.validarDominioMx(correoUsuarioNormalizado);
    }

    // 5. Hashear la contraseña UNA SOLA VEZ con Argon2id antes de guardar en memoria
    const contrasenaHash = await this.passwordService.hash(
      dto.usuarioContrasena,
    );

    // 6. Generar código OTP criptográfico de 6 dígitos y su digest SHA-256
    const codigoOtp = crypto.randomInt(100000, 1000000).toString();
    const codigoHash = crypto
      .createHash('sha256')
      .update(codigoOtp)
      .digest('hex');

    const nuevoPreRegistro: PreRegistroPendiente = {
      datos: {
        nombre: dto.nombre.trim(),
        razonSocial: dto.razonSocial?.trim() || null,
        rfc: rfcNormalizado,
        correo: correoEmpresaNormalizado,
        telefono: dto.telefono?.trim() || null,
        direccion: dto.direccion?.trim() || null,
        planCodigo: dto.planCodigo,
        usuarioNombre: dto.usuarioNombre.trim(),
        usuarioApellido: dto.usuarioApellido.trim(),
        usuarioCorreo: correoUsuarioNormalizado,
        contrasenaHash,
        usuarioTelefono: dto.usuarioTelefono?.trim() || null,
      },
      codigoHash,
      creadoEn: ahora,
      expiraEn: ahora + OTP_TTL_MS,
      intentosFallidos: 0,
    };

    // Un único registro activo por correo normalizado (sobrescribe e invalida el anterior)
    this.preRegistros.set(correoUsuarioNormalizado, nuevoPreRegistro);
    this.historialSolicitudesCorreo.set(correoUsuarioNormalizado, [
      ...historialVigente,
      ahora,
    ]);

    // 7. Enviar código por correo electrónico
    if (this.mailService) {
      try {
        await this.mailService.enviarCodigoVerificacionRegistro(
          correoUsuarioNormalizado,
          dto.usuarioNombre.trim(),
          codigoOtp,
        );
      } catch {
        this.preRegistros.delete(correoUsuarioNormalizado);
        this.historialSolicitudesCorreo.set(
          correoUsuarioNormalizado,
          historialVigente,
        );
        throw new DomainError(
          CodigoError.ERROR_INTERNO,
          'No fue posible enviar el código de verificación al correo proporcionado',
          HttpStatus.INTERNAL_SERVER_ERROR,
        );
      }
    }

    return {
      mensaje:
        'Se ha enviado un código de verificación de 6 dígitos a su correo electrónico. El código expira en 10 minutos.',
    };
  }

  /**
   * Paso 2 del Registro con Verificación OTP:
   * Verifica el código de 6 dígitos en tiempo constante (máx 5 intentos, TTL 10m),
   * consume el pre-registro y crea atómicamente la empresa y el usuario en MySQL
   * utilizando el hash Argon2id ya calculado en el Paso 1 (sin doble hash).
   */
  async confirmarRegistro(
    dto: ConfirmarRegistroEmpresaDto,
    ip?: string,
  ): Promise<AuthResponseDto> {
    const MENSAJE_CODIGO_INVALIDO =
      'El código de verificación es inválido o ha expirado. Por favor, solicita un nuevo código para continuar con tu registro.';
    const correoNormalizado = dto.correo.toLowerCase().trim();
    const codigoLimpio = dto.codigo.trim();
    const ahora = Date.now();

    this.purgarExpirados(ahora);

    const pendiente = this.preRegistros.get(correoNormalizado);
    if (!pendiente || pendiente.expiraEn <= ahora) {
      this.preRegistros.delete(correoNormalizado);
      throw new DomainError(
        CodigoError.PETICION_INVALIDA,
        MENSAJE_CODIGO_INVALIDO,
        HttpStatus.BAD_REQUEST,
      );
    }

    const hashRecibido = crypto
      .createHash('sha256')
      .update(codigoLimpio)
      .digest('hex');

    const bufferRecibido = Buffer.from(hashRecibido, 'hex');
    const bufferEsperado = Buffer.from(pendiente.codigoHash, 'hex');
    const esValido =
      bufferRecibido.length === bufferEsperado.length &&
      crypto.timingSafeEqual(bufferRecibido, bufferEsperado);

    if (!esValido) {
      pendiente.intentosFallidos += 1;
      const intentosRestantes = Math.max(
        0,
        MAX_INTENTOS_OTP - pendiente.intentosFallidos,
      );
      if (pendiente.intentosFallidos >= MAX_INTENTOS_OTP) {
        this.preRegistros.delete(correoNormalizado);
        throw new DomainError(
          CodigoError.PETICION_INVALIDA,
          'Has superado el límite de intentos permitidos para verificar este código. Por tu seguridad, solicita un nuevo código de verificación.',
          HttpStatus.BAD_REQUEST,
        );
      }
      throw new DomainError(
        CodigoError.PETICION_INVALIDA,
        `El código de verificación ingresado no es correcto. Te quedan ${intentosRestantes} ${intentosRestantes === 1 ? 'intento' : 'intentos'} antes de que el código sea cancelado por seguridad.`,
        HttpStatus.BAD_REQUEST,
      );
    }

    // Consumir atómicamente en memoria antes de persistir para evitar replay concurrente
    this.preRegistros.delete(correoNormalizado);
    this.historialSolicitudesCorreo.delete(correoNormalizado);

    return this.persistirRegistroConHash(pendiente.datos, ip);
  }

  /**
   * Registro directo interno (restringido exclusivamente a pruebas unitarias/semilla;
   * deshabilitado en producción para impedir salto de verificación OTP).
   */
  async registrar(
    dto: RegistroEmpresaDto,
    ip?: string,
  ): Promise<AuthResponseDto> {
    if (process.env.NODE_ENV === 'production') {
      throw new DomainError(
        CodigoError.PERMISO_DENEGADO,
        'El registro directo sin verificación de correo está deshabilitado en producción',
        HttpStatus.FORBIDDEN,
      );
    }

    const rfcNormalizado =
      dto.rfc && dto.rfc.trim().length > 0
        ? dto.rfc.toUpperCase().trim()
        : null;
    const correoUsuarioNormalizado = dto.usuarioCorreo.toLowerCase().trim();
    const correoEmpresaNormalizado = dto.correo.toLowerCase().trim();

    await this.validarDisponibilidadRfcYCorreo(
      rfcNormalizado,
      correoUsuarioNormalizado,
    );

    const contrasenaHash = await this.passwordService.hash(
      dto.usuarioContrasena,
    );

    return this.persistirRegistroConHash(
      {
        nombre: dto.nombre.trim(),
        razonSocial: dto.razonSocial?.trim() || null,
        rfc: rfcNormalizado,
        correo: correoEmpresaNormalizado,
        telefono: dto.telefono?.trim() || null,
        direccion: dto.direccion?.trim() || null,
        planCodigo: dto.planCodigo,
        usuarioNombre: dto.usuarioNombre.trim(),
        usuarioApellido: dto.usuarioApellido.trim(),
        usuarioCorreo: correoUsuarioNormalizado,
        contrasenaHash,
        usuarioTelefono: dto.usuarioTelefono?.trim() || null,
      },
      ip,
      dto.usuarioContrasena,
    );
  }

  private async validarDisponibilidadRfcYCorreo(
    rfcNormalizado: string | null,
    correoUsuarioNormalizado: string,
  ): Promise<void> {
    if (rfcNormalizado) {
      const empresaExistente = await this.prisma.empresa.findUnique({
        where: { rfc: rfcNormalizado },
      });
      if (empresaExistente && empresaExistente.deletedAt === null) {
        throw new DomainError(
          CodigoError.CONFLICTO,
          `El RFC '${rfcNormalizado}' ya está registrado en otra empresa. Si formas parte de esta organización, solicita a tu administrador que te agregue como colaborador o revisa si lo escribiste correctamente.`,
          HttpStatus.CONFLICT,
        );
      }
    }

    const usuarioExistente = await this.prisma.usuario.findUnique({
      where: { correo: correoUsuarioNormalizado },
    });
    if (usuarioExistente && usuarioExistente.deletedAt === null) {
      throw new DomainError(
        CodigoError.CONFLICTO,
        `Ya existe una cuenta registrada con el correo '${correoUsuarioNormalizado}'. Si ya eres usuario de Cultiva+, inicia sesión en la aplicación o solicita restablecer tu contraseña si la olvidaste.`,
        HttpStatus.CONFLICT,
      );
    }
  }

  /**
   * Ejecuta la transacción atómica de creación de Empresa y Usuario ADMIN
   * recibiendo el hash Argon2id ya calculado (nunca vuelve a hashear).
   * Maneja condiciones de carrera entre Paso 1 y Paso 2 capturando P2002 -> 409 CONFLICTO.
   */
  private async persistirRegistroConHash(
    datos: DatosPreRegistroHash,
    ip?: string,
    contrasenaCrudaFallbackTest?: string,
  ): Promise<AuthResponseDto> {
    await this.validarDisponibilidadRfcYCorreo(datos.rfc, datos.usuarioCorreo);

    let resultadoTx: {
      empresa: { id: number };
      usuario: { id: number; correo: string };
    };

    try {
      resultadoTx = await this.prisma.$transaction(async (tx) => {
        const plan = await tx.planSuscripcion.findUnique({
          where: { codigo: datos.planCodigo },
        });
        if (!plan || !plan.activo) {
          throw new DomainError(
            CodigoError.RECURSO_NO_ENCONTRADO,
            `El plan comercial '${datos.planCodigo}' no está disponible`,
            HttpStatus.NOT_FOUND,
          );
        }

        const rolAdmin = await tx.rol.findUnique({
          where: { codigo: 'ADMIN' },
        });
        if (!rolAdmin) {
          throw new DomainError(
            CodigoError.ERROR_INTERNO,
            'El rol ADMIN del sistema no fue encontrado',
            HttpStatus.INTERNAL_SERVER_ERROR,
          );
        }

        const nuevaEmpresa = await tx.empresa.create({
          data: {
            planId: plan.id,
            nombre: datos.nombre,
            razonSocial: datos.razonSocial,
            rfc: datos.rfc,
            correo: datos.correo,
            telefono: datos.telefono,
            direccion: datos.direccion,
            moneda: 'MXN',
            estadoSuscripcion: EstadoSuscripcion.PRUEBA,
            fechaInicioPlan: new Date(),
            activo: true,
          },
        });

        const nuevoUsuario = await tx.usuario.create({
          data: {
            empresaId: nuevaEmpresa.id,
            rolId: rolAdmin.id,
            nombre: datos.usuarioNombre,
            apellido: datos.usuarioApellido,
            correo: datos.usuarioCorreo,
            contrasenaHash: datos.contrasenaHash,
            telefono: datos.usuarioTelefono,
            activo: true,
          },
        });

        await this.auditService.registrar(
          {
            empresaId: nuevaEmpresa.id,
            usuarioId: null,
            entidad: 'empresa',
            entidadId: nuevaEmpresa.id,
            accion: AccionAuditoria.CREAR,
            valoresNuevos: {
              id: nuevaEmpresa.id,
              nombre: nuevaEmpresa.nombre,
              rfc: nuevaEmpresa.rfc,
              planId: nuevaEmpresa.planId,
            },
            ip,
          },
          tx,
        );

        await this.auditService.registrar(
          {
            empresaId: nuevaEmpresa.id,
            usuarioId: nuevoUsuario.id,
            entidad: 'usuario',
            entidadId: nuevoUsuario.id,
            accion: AccionAuditoria.CREAR,
            valoresNuevos: {
              id: nuevoUsuario.id,
              nombre: nuevoUsuario.nombre,
              apellido: nuevoUsuario.apellido,
              correo: nuevoUsuario.correo,
              rol: 'ADMIN',
            },
            ip,
          },
          tx,
        );

        return { empresa: nuevaEmpresa, usuario: nuevoUsuario };
      });
    } catch (err: unknown) {
      if (err instanceof DomainError) {
        throw err;
      }
      const prismaCode =
        err instanceof Prisma.PrismaClientKnownRequestError
          ? err.code
          : typeof err === 'object' && err !== null
            ? (err as { code?: string }).code
            : undefined;

      if (prismaCode === 'P2002') {
        throw new DomainError(
          CodigoError.CONFLICTO,
          'No fue posible completar el registro porque el correo electrónico o el RFC ya se encuentran registrados en el sistema.',
          HttpStatus.CONFLICT,
        );
      }
      throw err;
    }

    if (typeof this.authService.iniciarSesionPostRegistro === 'function') {
      return this.authService.iniciarSesionPostRegistro(
        resultadoTx.usuario.id,
        ip,
      );
    }

    return this.authService.login(
      {
        correo: datos.usuarioCorreo,
        contrasena: contrasenaCrudaFallbackTest ?? '',
      },
      ip,
    );
  }

  /**
   * Limpia el almacén en memoria (uso exclusivo para aislamiento en pruebas).
   */
  public limpiarPreRegistros(): void {
    this.preRegistros.clear();
    this.historialSolicitudesCorreo.clear();
  }

  /**
   * Consulta los datos de la empresa actual, su plan y las cuotas de uso (RN-037).
   */
  async obtenerMiEmpresa(empresaId: number): Promise<EmpresaResponseDto> {
    const empresa = await this.prisma.empresa.findUnique({
      where: { id: empresaId },
      include: {
        plan: true,
      },
    });

    if (!empresa || empresa.deletedAt !== null) {
      throw new DomainError(
        CodigoError.RECURSO_NO_ENCONTRADO,
        'Empresa no encontrada',
        HttpStatus.NOT_FOUND,
      );
    }

    // Cuotas de uso actuales
    const usuariosActivos = await this.prisma.usuario.count({
      where: {
        empresaId,
        activo: true,
        deletedAt: null,
      },
    });

    const parcelasActivas = await this.prisma.parcela.count({
      where: {
        predio: { empresaId, deletedAt: null },
        estado: { not: 'INACTIVA' },
        deletedAt: null,
      },
    });

    return {
      id: empresa.id,
      nombre: empresa.nombre,
      razonSocial: empresa.razonSocial,
      rfc: empresa.rfc,
      correo: empresa.correo,
      telefono: empresa.telefono,
      direccion: empresa.direccion,
      moneda: empresa.moneda,
      estadoSuscripcion: empresa.estadoSuscripcion,
      plan: {
        codigo: empresa.plan.codigo,
        nombre: empresa.plan.nombre,
        precioMensual: empresa.plan.precioMensual.toString(),
        maxParcelas: empresa.plan.maxParcelas,
        maxUsuarios: empresa.plan.maxUsuarios,
        incluyeReportes: empresa.plan.incluyeReportes,
      },
      cuotas: {
        usuariosActivos,
        maxUsuarios: empresa.plan.maxUsuarios,
        parcelasActivas,
        maxParcelas: empresa.plan.maxParcelas,
      },
    };
  }

  /**
   * Actualiza los datos comerciales de la empresa actual (RN-003).
   */
  async actualizarMiEmpresa(
    empresaId: number,
    dto: UpdateEmpresaDto,
  ): Promise<EmpresaResponseDto> {
    const empresaActual = await this.prisma.empresa.findUnique({
      where: { id: empresaId },
    });

    if (!empresaActual || empresaActual.deletedAt !== null) {
      throw new DomainError(
        CodigoError.RECURSO_NO_ENCONTRADO,
        'Empresa no encontrada',
        HttpStatus.NOT_FOUND,
      );
    }

    await this.prisma.$transaction(async (tx) => {
      const actualizada = await tx.empresa.update({
        where: { id: empresaId },
        data: {
          ...(dto.nombre && { nombre: dto.nombre.trim() }),
          ...(dto.razonSocial !== undefined && {
            razonSocial: dto.razonSocial?.trim() || null,
          }),
          ...(dto.correo && { correo: dto.correo.toLowerCase().trim() }),
          ...(dto.telefono !== undefined && {
            telefono: dto.telefono?.trim() || null,
          }),
          ...(dto.direccion !== undefined && {
            direccion: dto.direccion?.trim() || null,
          }),
        },
      });

      // Auditar cambio en la misma transacción convirtiendo Date/Decimal a string (ADR-001 / C5)
      await this.auditService.registrar(
        {
          empresaId,
          entidad: 'empresa',
          entidadId: empresaId,
          accion: AccionAuditoria.ACTUALIZAR,
          valoresAnteriores: {
            nombre: empresaActual.nombre,
            razonSocial: empresaActual.razonSocial,
            correo: empresaActual.correo,
            telefono: empresaActual.telefono,
            direccion: empresaActual.direccion,
            fechaInicioPlan: empresaActual.fechaInicioPlan
              ? empresaActual.fechaInicioPlan.toISOString()
              : null,
            createdAt: empresaActual.createdAt.toISOString(),
            updatedAt: empresaActual.updatedAt.toISOString(),
          },
          valoresNuevos: {
            nombre: actualizada.nombre,
            razonSocial: actualizada.razonSocial,
            correo: actualizada.correo,
            telefono: actualizada.telefono,
            direccion: actualizada.direccion,
            updatedAt: actualizada.updatedAt.toISOString(),
          },
        },
        tx,
      );
    });

    return this.obtenerMiEmpresa(empresaId);
  }
}
