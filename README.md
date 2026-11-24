# Cultiva+

Monorepositorio que reúne el backend y frontend de Cultiva+. El backend es una
API NestJS con Prisma y MySQL/MariaDB; el frontend es una aplicación Flutter
que consume la API mediante una URL configurable.

## Estructura

```text
Cultiva-Plus/
├── backend/   # API REST en NestJS, Prisma y MySQL/MariaDB
└── frontend/  # Aplicación Flutter
```

## Requisitos

- Git
- Node.js 22 o superior y npm
- Flutter 3.29 o superior (incluye Dart 3.7 o superior)
- MySQL 8 o MariaDB 10.6 o superior para ejecutar el backend
- Docker Desktop con Docker Compose para el flujo en contenedores

Flutter Web fue validado en este entorno con Flutter 3.47.2 y Dart 3.13.5.

## Instalar dependencias

Instala cada conjunto de dependencias desde su carpeta:

```powershell
cd backend
npm ci
cd ..\frontend
flutter pub get
```

## Ejecutar por separado

### Backend

Si aún no existe `backend/.env`, créalo desde la plantilla y completa las
variables requeridas. No reemplaces un archivo existente:

```powershell
Copy-Item backend\.env.example backend\.env
```

Define `DATABASE_URL`, `JWT_SECRET` y `JWT_REFRESH_SECRET`. Los dos secretos JWT
deben ser diferentes y tener al menos 64 caracteres; puedes generar cada uno
con:

```powershell
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
```

Inicia la API desde `backend`:

```powershell
cd backend
npm run start:dev
```

La API se inicia en `http://localhost:3000/api/v1`. La configuración de base de
datos y otros comandos están documentados en [backend/README.md](backend/README.md).

### Frontend

Para abrir la aplicación en Chrome usando el backend local:

```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Para compilar Flutter Web:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://api.ejemplo.com/api/v1
```

`API_BASE_URL` queda fijada al compilar. Genera un artefacto por entorno y usa
la URL que el dispositivo pueda alcanzar. En Android Emulator suele usarse
`http://10.0.2.2:3000/api/v1`; en un teléfono físico configura la IP o dominio
accesible del backend. Para entornos públicos usa HTTPS.

Consulta los detalles en [frontend/README.md](frontend/README.md).

## Android e iOS

Para generar un APK o Android App Bundle, instala Android Command-line Tools y
acepta las licencias del SDK:

```powershell
cd frontend
flutter doctor
flutter build apk --release --dart-define=API_BASE_URL=https://api.ejemplo.com/api/v1
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.ejemplo.com/api/v1
```

La firma de producción debe configurarse fuera del repositorio y no se deben
versionar claves privadas. iOS requiere macOS y Xcode; desde macOS se puede
validar y compilar con `flutter build ios --release` después de configurar la
firma y el identificador de la aplicación.

## Backend y base de datos con Docker Compose

1. Si no existe `.env` en la raíz, cópialo desde `.env.example`.
2. Define `DB_PASSWORD` y `DB_ROOT_PASSWORD` en ese archivo. Usa contraseñas
   URL-safe (por ejemplo, solo letras y números), porque Compose las inserta en
   la URL de conexión.
3. Si no existe `backend/.env`, cópialo desde `backend/.env.example` y completa
   `JWT_SECRET` y `JWT_REFRESH_SECRET`. En producción, configura además todas
   las variables requeridas para correo, almacenamiento y enlaces HTTPS.
4. Inicia la base, aplica las migraciones explícitamente y luego levanta la API:

```powershell
docker compose up -d db
docker compose --profile tools run --rm migrate
docker compose up --build -d backend
```

La base de datos no se publica al host. El backend se conecta por el nombre del
servicio `db`; su puerto HTTP se publica solo en `127.0.0.1:3000`. Las
migraciones no se ejecutan al iniciar el contenedor. Los datos de la base y los
archivos adjuntos locales persisten en volúmenes de Docker. Para detener los
servicios sin borrar esos datos:

```powershell
docker compose down
```

No uses `docker compose down -v` salvo que quieras eliminar deliberadamente
esos volúmenes y sus datos. Para producción, entrega secretos mediante el
gestor de secretos de la plataforma, configura CORS con los orígenes HTTPS
autorizados y publica el backend detrás de un proxy HTTPS.

## Pruebas e2e con base aislada

Las pruebas e2e recrean y eliminan la base `rentabilidad_agricola_test`. Nunca
las conectes a una base de desarrollo o producción. Compose ofrece una
instancia separada, accesible solo desde la máquina local:

```powershell
docker compose --profile e2e up -d --wait e2e-db
```

Crea `backend/.env.test` (archivo ignorado por Git) con una URL de este tipo,
usando el mismo `DB_ROOT_PASSWORD` del `.env` raíz:

```text
DATABASE_URL=mysql://root:CONTRASENA_URL_SAFE@localhost:3308/rentabilidad_agricola_test
```

Después ejecuta desde `backend`:

```powershell
npm run test:e2e
```

Al terminar, detén y elimina el contenedor temporal:

```powershell
docker compose --profile e2e down
```

## Validaciones

Desde `backend`: `npm run lint:check`, `npm run build`, `npm test`,
`npm run db:verify` y `npm run contrato:verificar`. Desde `frontend`:
`flutter analyze`, `flutter test` y `flutter build web --release`. Android
requiere las herramientas de línea de comandos y licencias del SDK; iOS requiere
macOS y Xcode.
