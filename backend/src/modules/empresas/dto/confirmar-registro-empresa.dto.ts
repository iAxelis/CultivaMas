import { IsEmail, IsNotEmpty, IsString, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ConfirmarRegistroEmpresaDto {
  @ApiProperty({
    example: 'ramon@correo.com',
    description:
      'Correo de acceso del administrador con el que se solicitó el código de verificación',
  })
  @IsEmail(
    {},
    {
      message:
        'El correo ingresado para confirmar no tiene un formato válido (ejemplo: admin@correo.com)',
    },
  )
  @IsNotEmpty({
    message:
      'Por favor, ingresa el correo electrónico con el que solicitaste tu registro',
  })
  correo!: string;

  @ApiProperty({
    example: '482910',
    description:
      'Código numérico de verificación de 6 dígitos enviado por correo electrónico',
  })
  @IsString({
    message: 'El código de verificación debe ser una cadena de texto',
  })
  @IsNotEmpty({
    message:
      'Por favor, ingresa el código de 6 dígitos que enviamos a tu correo electrónico',
  })
  @Matches(/^\d{6}$/, {
    message:
      'El código de verificación debe contener exactamente 6 dígitos numéricos (ejemplo: 482910)',
  })
  codigo!: string;
}
