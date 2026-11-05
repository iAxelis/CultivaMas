import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  Length,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { RolCodigoEnum } from './create-usuario.dto';

export class UpdateUsuarioDto {
  @ApiPropertyOptional({ example: 'Luis Alberto' })
  @IsOptional()
  @IsString({ message: 'El nombre debe ser una cadena de texto' })
  @Length(2, 80, { message: 'El nombre debe tener entre 2 y 80 caracteres' })
  nombre?: string;

  @ApiPropertyOptional({ example: 'Pérez López' })
  @IsOptional()
  @IsString({ message: 'El apellido debe ser una cadena de texto' })
  @Length(2, 80, { message: 'El apellido debe tener entre 2 y 80 caracteres' })
  apellido?: string;

  @ApiPropertyOptional({ example: '9515550109' })
  @IsOptional()
  @IsString({ message: 'El teléfono debe ser una cadena de texto' })
  telefono?: string;

  @ApiPropertyOptional({
    enum: RolCodigoEnum,
    example: RolCodigoEnum.CONTADOR,
    description: 'Actualización del rol de acceso (RN-061)',
  })
  @IsOptional()
  @IsEnum(RolCodigoEnum, {
    message: 'El rol debe ser ADMIN, CAPTURISTA o CONTADOR',
  })
  rolCodigo?: RolCodigoEnum;

  @ApiPropertyOptional({
    example: true,
    description: 'Estado activo del usuario (reactivación o desactivación)',
  })
  @IsOptional()
  @IsBoolean({ message: 'El estado activo debe ser un valor booleano' })
  activo?: boolean;
}
