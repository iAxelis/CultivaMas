# Cultiva+

Monorepositorio que reúne los proyectos de backend y frontend de Cultiva+.
Cada aplicación conserva sus dependencias, herramientas y ciclo de desarrollo
independientes; este repositorio no configura una conexión entre ellas.

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

Configura las variables locales a partir de la plantilla y actualiza las
credenciales de base de datos en `backend/.env`:

```powershell
cd backend
Copy-Item .env.example .env
npm run start:dev
```

La API se inicia en `http://localhost:3000/api/v1`. La configuración de base de
datos y otros comandos están documentados en [backend/README.md](backend/README.md).

### Frontend

```powershell
cd frontend
flutter run
```

Los comandos de análisis y pruebas están documentados en
[frontend/README.md](frontend/README.md). El frontend continúa funcionando de
forma independiente con sus datos de demostración.

## Pruebas y validación

Ejecuta los comandos de cada proyecto desde su propia carpeta. Backend y
frontend tienen configuraciones y dependencias separadas.
