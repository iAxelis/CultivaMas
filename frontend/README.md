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

## Inicio de sesión de prueba

La app abre con una animación breve y después muestra directamente el login.
Estas cuentas locales son únicamente para desarrollo; no protegen datos y no
deben usarse en producción:

| Perfil | Correo | Contraseña |
|---|---|---|
| Administrador | `ramon@lospinos.mx` | `Admin123!` |
| Capturista | `luis@lospinos.mx` | `Campo123!` |
| Contador | `marta@lospinos.mx` | `Finanzas123!` |

Las cuentas están definidas en `lib/data/mock_users.dart` y la validación
provisional en `lib/data/auth_service.dart`. La sesión se mantiene en memoria
hasta cerrar sesión o reiniciar la aplicación.

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

La aplicación es un wireframe funcional sin backend ni persistencia. Los datos
de demostración y la sesión se mantienen en memoria en `AppStore`; el perfil se
determina automáticamente con las credenciales de prueba.
# Cultiva-
