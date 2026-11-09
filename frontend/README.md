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
El registro empresarial usa el flujo OTP del backend; también están conectados
la recuperación/cambio de contraseña y el cierre de sesión.

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
general de registros aún no están conectadas desde la app. No se modificó el
backend. En Flutter Web el navegador puede requerir CORS habilitado en el
servidor o un proxy del mismo origen; CORS no aplica a las apps nativas.
El cliente no utiliza credenciales locales de demostración al iniciar sesión.
# Cultiva-
