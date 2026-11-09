# Cultiva+

Aplicación Flutter independiente para gestión de rentabilidad agrícola. Incluye
acceso y registro, paneles por rol, ciclos de cultivo, gastos, cosechas,
ventas, cobros, catálogos, reportes y auditoría.

## Requisitos

- Flutter 3.29 o superior
- Dart 3.7 o superior

## Ejecutar

```bash
flutter pub get
flutter run
```

Para ejecutar en un destino concreto, por ejemplo Chrome:

```bash
flutter run -d chrome
```

## Conexión con el backend

El frontend consume la API versionada en `http://localhost:3000/api/v1` por
defecto. La URL se puede cambiar al ejecutar Flutter:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Para un emulador Android, configura la dirección del host accesible desde el
emulador (por ejemplo, `http://10.0.2.2:3000/api/v1`). La app autentica contra
`POST /auth/login`, guarda los tokens en almacenamiento seguro, restaura la
sesión mediante `GET /auth/me` y renueva tokens rotatorios al recibir un 401.
El registro empresarial todavía requiere completar el flujo de verificación
OTP del backend.

## Organización del código

- `lib/app`: configuración y rutas de la aplicación.
- `lib/core`: tema y componentes visuales compartidos.
- `lib/data`: modelos y estado en memoria.
- `lib/features`: pantallas de acceso, catálogos, captura y módulos.
- `lib/main.dart`: punto de entrada de Flutter.

Se fija `path_provider_foundation` en 2.4.2 para evitar el hook nativo
transitivo de `objective_c`, que falla en Windows cuando el SDK de Flutter está
instalado en una ruta con espacios y no es necesario para ejecutar en Chrome.

## Verificar

```bash
flutter analyze
flutter test
```

Al iniciar sesión, la app carga ciclos, actividades, gastos, cosechas, ventas y
catálogos según el rol autenticado; también consulta predios, clientes,
proveedores, usuarios y auditoría cuando el rol tiene permiso. La pantalla de
captura permite actualizar los datos desde la API con el gesto de refrescar.
Las operaciones de escritura y los módulos restantes siguen en integración.
El cliente no utiliza credenciales locales de demostración.
# Cultiva-
