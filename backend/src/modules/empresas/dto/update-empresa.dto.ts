import { IsEmail, IsOptional, IsString, Length } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateEmpresaDto {
  @ApiPropertyOptional({ example: 'Rancho Los Pinos SPR de RL' })
  @IsOptional()
  @IsString({ message: 'El nombre debe ser una cadena de texto' })
  @Length(3, 150, {
    message: 'El nombre de la empresa debe tener entre 3 y 150 caracteres',
  })
  nombre?: string;

  @ApiPropertyOptional({ example: 'Ramón Ortega S.P.R. de R.L.' })
  @IsOptional()
  @IsString({ message: 'La razón social debe ser una cadena de texto' })
  @Length(3, 200, {
    message: 'La razón social debe tener entre 3 y 200 caracteres',
  })
  razonSocial?: string;

  @ApiPropertyOptional({ example: 'contacto@rancholospinos.com' })
  @IsOptional()
  @IsEmail({}, { message: 'El correo electrónico no tiene un formato válido' })
  correo?: string;

  @ApiPropertyOptional({ example: '9515550101' })
  @IsOptional()
  @IsString({ message: 'El teléfono debe ser una cadena de texto' })
  telefono?: string;

  @ApiPropertyOptional({ example: 'Camino a la Presa Km 2, Zimatlán, Oaxaca' })
  @IsOptional()
  @IsString({ message: 'La dirección debe ser una cadena de texto' })
  direccion?: string;
}
