import { Matches } from 'class-validator';

export function IsTelefono10Digitos(): PropertyDecorator {
  return Matches(/^(?:\d{10})?$/, {
    message: 'El teléfono debe tener exactamente 10 dígitos.',
  });
}
