# Cultiva+

Aplicación Flutter independiente para gestión de rentabilidad agrícola. Incluye
acceso y registro, paneles por rol, ciclos de cultivo, gastos, cosechas,
ventas, cobros, catálogos, reportes y auditoría.

## Requisitos

- Flutter 3.29 o superior
- Dart 3.7 o superior

Flutter Web se validó en este entorno con Flutter 3.47.2 y Dart 3.13.5.

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

El cliente centraliza la URL de la API mediante el `dart-define` `API_BASE_URL`.
El valor predeterminado de localhost es únicamente para desarrollo en la misma
máquina; especifica la URL apropiada para cada entorno:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1
flutter build web --release --dart-define=API_BASE_URL=https://api.ejemplo.com/api/v1
```

Para un emulador Android, usa la dirección del host accesible desde el emulador
(por ejemplo, `http://10.0.2.2:3000/api/v1`). En un dispositivo físico usa una
IP o dominio accesible desde el dispositivo. Para despliegues públicos utiliza
HTTPS. La app autentica contra
`POST /auth/login`, guarda los tokens en almacenamiento seguro, restaura la
sesión mediante `GET /auth/me` y renueva tokens rotatorios al recibir un 401.
El registro empresarial usa el flujo OTP del backend; también están conectados
la recuperación/cambio de contraseña y el cierre de sesión.
Para que el enlace del correo abra la app, configura en el backend
`PASSWORD_RESET_URL` con la URL del frontend terminada en
`/restablecer-contrasena`. En desarrollo usa
`http://localhost:8080/restablecer-contrasena` y ejecuta Flutter Web con
`flutter run -d web-server --web-port 8080`. También puedes pegar el enlace
completo del correo en el formulario de recuperación.

`API_BASE_URL` queda incorporada en el artefacto al compilar Web. Genera un
artefacto distinto por ambiente y permite el origen del frontend en
`CORS_ORIGINS` del backend. El almacenamiento seguro en navegador requiere un
contexto seguro (HTTPS o localhost).

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

Al iniciar sesión, la app carga ciclos, actividades, gastos, cosechas, mermas,
ventas y sus saldos, además de catálogos según el rol autenticado. También
consulta predios, clientes, proveedores, usuarios, empresa, alertas y auditoría
cuando el rol tiene permiso. Las capturas operativas, ciclos, catálogos y
usuarios se envían a la API; las ventas se cancelan en el servidor. La pantalla
de captura permite actualizar los datos con el gesto de refrescar.

Los reportes y comparativos visibles se calculan con datos sincronizados. La
descarga de archivos de exportación, carga de adjuntos y edición/eliminación
general de registros aún no están conectadas desde la app. Flutter Web requiere
que el origen esté permitido por CORS en el
backend; en desarrollo se permiten orígenes locales y en producción debe
configurarse `CORS_ORIGINS`. CORS no aplica a las apps nativas.
El cliente no utiliza credenciales locales de demostración al iniciar sesión.
# Cultiva-
