import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IMailTransport } from './interfaces/mail-transport.interface';
import { BrevoTransport } from './transports/brevo.transport';
import { LogTransport } from './transports/log.transport';
import { MemoryTransport } from './transports/memory.transport';

const DEFAULT_MAIL_LOGO_URL =
  'https://pub-fd463190d43e4b3a84df5cf12cd2aa6e.r2.dev/logo_redimensionado.png';

function escapeHtml(texto: string): string {
  return texto.replace(/[<>&"']/g, (c) => {
    switch (c) {
      case '<':
        return '&lt;';
      case '>':
        return '&gt;';
      case '&':
        return '&amp;';
      case '"':
        return '&quot;';
      case "'":
        return '&#39;';
      default:
        return c;
    }
  });
}

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private readonly transport: IMailTransport;
  private readonly enviosPendientes = new Set<Promise<unknown>>();

  registrarEnvio(promesa: Promise<unknown>): void {
    this.enviosPendientes.add(promesa);
    void promesa
      .catch((err: unknown) => {
        const errorClase =
          err instanceof Error ? err.constructor.name : typeof err;
        this.logger.error(
          `Error no manejado en envío registrado: ${errorClase}`,
        );
      })
      .finally(() => {
        this.enviosPendientes.delete(promesa);
      });
  }

  async esperarEnviosPendientes(): Promise<void> {
    await Promise.allSettled(Array.from(this.enviosPendientes));
  }

  constructor(private readonly configService: ConfigService) {
    // B4: Lectura solo vía ConfigService sin process.env ni defaults inseguros
    const modoTransport = this.configService.get<string>('MAIL_TRANSPORT');
    const apiKey = this.configService.get<string>('BREVO_API_KEY');
    const remitenteEmail = this.configService.get<string>(
      'MAIL_FROM_EMAIL',
      'no-reply@rentabilidad-agricola.com',
    );
    const remitenteNombre = this.configService.get<string>(
      'MAIL_FROM_NAME',
      'Cultiva+',
    );

    if (modoTransport === 'memory') {
      this.transport = new MemoryTransport();
    } else if (modoTransport === 'brevo' && apiKey) {
      this.transport = new BrevoTransport(
        apiKey,
        remitenteEmail,
        remitenteNombre,
      );
    } else {
      this.transport = new LogTransport(this.configService);
    }
  }

  getTransport(): IMailTransport {
    return this.transport;
  }

  private obtenerLogoUrl(): string {
    const raw = this.configService.get<string>('MAIL_LOGO_URL');
    if (raw && raw.trim().length > 0) {
      return raw.trim();
    }
    return DEFAULT_MAIL_LOGO_URL;
  }

  private construirEncabezadoMarcaHtml(): string {
    const logoUrlEscapada = escapeHtml(this.obtenerLogoUrl());
    return `
        <div style="text-align: center; margin-bottom: 20px;">
          <img src="${logoUrlEscapada}" alt="Cultiva+" width="72" height="72" style="width: 72px; height: 72px; border-radius: 50%; object-fit: cover; display: inline-block; border: 2px solid #2e7d32;" />
          <h2 style="color: #2e7d32; margin: 10px 0 4px 0; font-size: 24px;">Cultiva+</h2>
        </div>`;
  }

  async enviarRecuperacionContrasena(
    destinatario: string,
    nombre: string,
    enlace: string,
    tokenCrudo?: string,
  ): Promise<void> {
    const asunto = 'Restablecimiento de Contraseña - Cultiva+';
    // B5: Escapar nombre en el cuerpo HTML
    const nombreEscapado = escapeHtml(nombre);
    const encabezadoHtml = this.construirEncabezadoMarcaHtml();
    const contenidoHtml = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; border: 1px solid #e0e0e0; border-radius: 8px; background-color: #ffffff;">
        ${encabezadoHtml}
        <p>Hola, <strong>${nombreEscapado}</strong>:</p>
        <p>Recibimos una solicitud para restablecer la contraseña de tu cuenta en <strong>Cultiva+</strong>.</p>
        <p style="margin: 25px 0; text-align: center;">
          <a href="${enlace}" style="background-color: #2e7d32; color: #ffffff; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold; display: inline-block;">
            Restablecer Contraseña
          </a>
        </p>
        <p>Este enlace es válido por <strong>15 minutos</strong> y puede utilizarse una única vez.</p>
        <p style="color: #666666; font-size: 13px;">Si no solicitaste este cambio, puedes ignorar este correo; tu contraseña actual permanecerá segura.</p>
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;" />
        <p style="color: #999999; font-size: 11px; text-align: center;">Cultiva+ · Sistema de Gestión de Costos y Rentabilidad Agrícola</p>
      </div>
    `;

    const contenidoTexto = `Hola ${nombre},\n\nPara restablecer tu contraseña en Cultiva+, ingresa al siguiente enlace:\n${enlace}\n\nEste enlace expira en 15 minutos.\nSi no solicitaste este cambio, puedes ignorar este mensaje.`;

    // B4: en desarrollo imprimir en logger el destinatario, token en crudo y URL completa SOLO con log transport y NODE_ENV===development
    const nodeEnv = this.configService.get<string>('NODE_ENV');
    const mailTransport = this.configService.get<string>('MAIL_TRANSPORT');
    if (nodeEnv === 'development' && mailTransport === 'log') {
      this.logger.log(
        `[RECUPERACIÓN LOCAL] Destinatario: ${destinatario} | Token: ${tokenCrudo || 'N/A'} | Enlace: ${enlace}`,
      );
    }

    await this.transport.enviar({
      destinatario,
      nombreDestinatario: nombre,
      asunto,
      contenidoHtml,
      contenidoTexto,
    });
  }

  async enviarCodigoVerificacionRegistro(
    destinatario: string,
    nombre: string,
    codigoOtp: string,
  ): Promise<void> {
    const asunto = 'Código de Verificación de Registro - Cultiva+';
    const nombreEscapado = escapeHtml(nombre);
    const codigoEscapado = escapeHtml(codigoOtp);
    const encabezadoHtml = this.construirEncabezadoMarcaHtml();
    const contenidoHtml = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; border: 1px solid #e0e0e0; border-radius: 8px; background-color: #ffffff;">
        ${encabezadoHtml}
        <p>Hola, <strong>${nombreEscapado}</strong>:</p>
        <p>Para completar el registro de tu cuenta y empresa en <strong>Cultiva+</strong>, ingresa el siguiente código de verificación de 6 dígitos:</p>
        <div style="margin: 25px 0; text-align: center;">
          <span style="background-color: #f1f8e9; border: 2px solid #2e7d32; color: #1b5e20; padding: 14px 28px; border-radius: 6px; font-weight: bold; font-size: 28px; letter-spacing: 6px; display: inline-block;">
            ${codigoEscapado}
          </span>
        </div>
        <p>Este código es válido por <strong>10 minutos</strong> y puede utilizarse una única vez.</p>
        <p style="color: #666666; font-size: 13px;">Si no solicitaste crear una cuenta, puedes ignorar este correo de forma segura.</p>
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;" />
        <p style="color: #999999; font-size: 11px; text-align: center;">Cultiva+ · Sistema de Gestión de Costos y Rentabilidad Agrícola</p>
      </div>
    `;

    const contenidoTexto = `Hola ${nombre},\n\nTu código de verificación para completar el registro en Cultiva+ es:\n\n${codigoOtp}\n\nEste código expira en 10 minutos.\nSi no solicitaste este registro, puedes ignorar este mensaje.`;

    const nodeEnv = this.configService.get<string>('NODE_ENV');
    const mailTransport = this.configService.get<string>('MAIL_TRANSPORT');
    if (nodeEnv === 'development' && mailTransport === 'log') {
      this.logger.log(
        `[VERIFICACIÓN REGISTRO LOCAL] Destinatario: ${destinatario} | Código OTP: ${codigoOtp}`,
      );
    }

    await this.transport.enviar({
      destinatario,
      nombreDestinatario: nombre,
      asunto,
      contenidoHtml,
      contenidoTexto,
    });
  }
}
