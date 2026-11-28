import { IsOptional, validate } from 'class-validator';
import { IsTelefono10Digitos } from './is-telefono-10-digitos.decorator';

class ContactoDto {
  @IsOptional()
  @IsTelefono10Digitos()
  telefono?: string;
}

describe('IsTelefono10Digitos', () => {
  it('acepta teléfonos vacíos u opcionales y números de 10 dígitos', async () => {
    for (const telefono of [undefined, '', '9515550101']) {
      const dto = Object.assign(new ContactoDto(), { telefono });
      const errors = await validate(dto);

      expect(errors).toHaveLength(0);
    }
  });

  it('rechaza teléfonos que no tengan exactamente 10 dígitos', async () => {
    for (const telefono of ['951555010', '95155501012', '95155A0101']) {
      const dto = Object.assign(new ContactoDto(), { telefono });
      const errors = await validate(dto);

      expect(errors[0]?.constraints).toEqual({
        matches: 'El teléfono debe tener exactamente 10 dígitos.',
      });
    }
  });
});
