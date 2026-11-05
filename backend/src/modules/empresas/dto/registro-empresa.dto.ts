import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  Length,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum PlanCodigoEnum {
  BASICO = 'BASICO',
  PRODUCTOR = 'PRODUCTOR',
  PROFESIONAL = 'PROFESIONAL',
}

export class RegistroEmpresaDto {
  // ================= EMPRESA =================
  @ApiProperty({
    example: 'Rancho Los Pinos',
    description: 'Nombre comercial de la empresa agrícola o predio (F-01)',
  })
  @IsString({
    message: 'El nombre de la empresa debe ser un texto válido',
  })
  @IsNotEmpty({
    message: 'Por favor, ingresa el nombre comercial de tu empresa o rancho',
  })
  @Length(3, 150, {
    message:
      'El nombre de la empresa debe tener entre 3 y 150 caracteres para ser legible',
  })
  nombre!: string;

  @ApiPropertyOptional({
    example: 'Ramón Ortega S.P.R. de R.L.',
    description: 'Razón social fiscal de la empresa (opcional)',
  })
  @IsOptional()
  @IsString({
    message: 'La razón social debe ser un texto válido',
  })
  @Length(3, 200, {
    message: 'La razón social debe tener entre 3 y 200 caracteres',
  })
  razonSocial?: string;

  @ApiPropertyOptional({
    example: 'OERA700101XX0',
    description:
      'RFC fiscal de la empresa (opcional para pequeños productores o quienes no tributan formalmente)',
  })
  @IsOptional()
  @IsString({
    message: 'El RFC debe ser una cadena de texto válida',
  })
  @Length(12, 13, {
    message:
      'Si ingresas un RFC, debe tener 12 caracteres (persona moral) o 13 caracteres (persona física)',
  })
  rfc?: string;

  @ApiProperty({
    example: 'contacto@rancholospinos.com',
    description: 'Correo de contacto general de la empresa',
  })
  @IsEmail(
    {},
    {
      message:
        'Por favor, ingresa una dirección de correo electrónico válida para la empresa (ejemplo: contacto@tuempresa.com)',
    },
  )
  @IsNotEmpty({
    message: 'El correo de contacto de la empresa es obligatorio',
  })
  correo!: string;

  @ApiPropertyOptional({
    example: '9515550101',
    description: 'Teléfono de contacto de la empresa',
  })
  @IsOptional()
  @IsString({
    message: 'El teléfono debe ser un texto con números válidos',
  })
  telefono?: string;

  @ApiPropertyOptional({
    example: 'Camino a la Presa Km 2, Zimatlán, Oaxaca',
    description: 'Dirección física o fiscal de la empresa',
  })
  @IsOptional()
  @IsString({
    message: 'La dirección debe ser un texto válido',
  })
  direccion?: string;

  @ApiProperty({
    enum: PlanCodigoEnum,
    example: PlanCodigoEnum.PRODUCTOR,
    description:
      'Código del plan comercial seleccionado (define límites de usuarios y parcelas)',
  })
  @IsEnum(PlanCodigoEnum, {
    message:
      'Debes seleccionar un plan comercial válido: BASICO, PRODUCTOR o PROFESIONAL',
  })
  @IsNotEmpty({
    message: 'Por favor, selecciona un plan comercial para tu suscripción',
  })
  planCodigo!: PlanCodigoEnum;

  // ================= PRIMER USUARIO (ADMIN) =================
  @ApiProperty({
    example: 'Ramón',
    description: 'Nombre del productor o administrador principal',
  })
  @IsString({
    message: 'El nombre del administrador debe ser un texto válido',
  })
  @IsNotEmpty({
    message:
      'Por favor, ingresa el nombre de la persona que administrará la cuenta',
  })
  @Length(2, 80, {
    message: 'El nombre del administrador debe tener al menos 2 caracteres',
  })
  usuarioNombre!: string;

  @ApiProperty({
    example: 'Ortega',
    description: 'Apellido del administrador',
  })
  @IsString({
    message: 'El apellido del administrador debe ser un texto válido',
  })
  @IsNotEmpty({
    message:
      'Por favor, ingresa el apellido de la persona que administrará la cuenta',
  })
  @Length(2, 80, {
    message: 'El apellido del administrador debe tener al menos 2 caracteres',
  })
  usuarioApellido!: string;

  @ApiProperty({
    example: 'ramon@correo.com',
    description:
      'Correo de acceso del administrador (único en todo el sistema, RN-002)',
  })
  @IsEmail(
    {},
    {
      message:
        'Por favor, ingresa un correo electrónico válido para tu usuario administrador (ejemplo: admin@correo.com)',
    },
  )
  @IsNotEmpty({
    message: 'El correo de acceso del usuario administrador es obligatorio',
  })
  usuarioCorreo!: string;

  @ApiProperty({
    example: 'ClaveSegura2026!',
    description: 'Contraseña de acceso del usuario administrador',
    minLength: 6,
  })
  @IsString({
    message: 'La contraseña debe ser un texto válido',
  })
  @IsNotEmpty({
    message: 'Por favor, define una contraseña segura para tu cuenta',
  })
  @MinLength(6, {
    message: 'Por seguridad, la contraseña debe tener al menos 6 caracteres',
  })
  usuarioContrasena!: string;

  @ApiPropertyOptional({
    example: '9515550102',
    description: 'Teléfono móvil del usuario administrador',
  })
  @IsOptional()
  @IsString({
    message: 'El teléfono móvil debe ser un texto válido',
  })
  usuarioTelefono?: string;
}
