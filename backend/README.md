# Cultiva+ — Backend API REST

> **Plataforma SaaS multi-tenant para la gestión de costos operativos, labores agrícolas, balance de cosecha y rentabilidad financiera por ciclo productivo.**

Desarrollado con **NestJS 11**, **Prisma 7** y **MySQL 8.0+ / MariaDB 11+**, siguiendo principios de arquitectura limpia, control de concurrencia pesimista, inmutabilidad de auditoría transaccional y contrato OpenAPI determinista.

---

## 🚀 Inicio Rápido para Desarrolladores

Si vas a integrar el frontend o probar la API localmente en Windows:

### 1. Requisitos Previos
* **Node.js** >= 22 (recomendado Node 24).
* **MySQL** >= 8.0 o **MariaDB** >= 10.6 corriendo en el puerto `3306`.

### 2. Instalación y Configuración
```powershell
# 1. Instalar dependencias exactas
npm ci

# 2. Configurar variables de entorno
copy .env.example .env
```
> *Edita el archivo `.env` con tus credenciales de base de datos (`DATABASE_URL`).*

### 3. Base de Datos y Semillas
```powershell
# Aplicar las 6 migraciones canónicas
npx prisma migrate deploy

# Cargar catálogos del sistema (planes, roles, permisos, unidades, motivos merma)
npx prisma db seed
```

### 4. Ejecutar el Servidor
```powershell
# Modo desarrollo con recarga automática
npm run start:dev
```
* **API Base:** `http://localhost:3000/api/v1`
* **Swagger UI:** `http://localhost:3000/api/docs`
* **Health Check:** `http://localhost:3000/api/v1/health`

---

## 📱 Guía de Integración para el Frontend

Para el equipo de desarrollo de interfaces (Flutter móvil / Web):
👉 **Consulta la [Guía Canónica de Integración Frontend](docs/GUIA-INTEGRACION-FRONTEND.md)** para conocer:
* El flujo de registro de empresa con código OTP de 6 dígitos.
* El manejo de Refresh Tokens con Single-Flight Mutex.
* El catálogo de errores de dominio y cómo reaccionar en la UI.
* La ruta crítica sugerida para implementar las pantallas en orden.

---

## 🧪 Compuertas de Calidad y Pruebas

El proyecto cuenta con certificación mecánica al 100% en todas sus capas:

| Comando | Descripción | Cobertura |
|---|---|---|
| `npm run build` | Compilación estricta de TypeScript | Exit 0 limpio |
| `npm test` | Pruebas unitarias de servicios, DTOs y validadores | 95 suites, 710 tests pasados |
| `npm run test:e2e` | Pruebas de integración de punta a punta con MySQL | 17 suites activas, 280 tests pasados |
| `npm run db:verify` | Verificación de integridad relacional del Anexo D | 74/74 comprobaciones aprobadas |
| `npm run contrato:verificar` | Guardia anti-deriva contra el contrato OpenAPI | 109 rutas y 38 errores validados |

---

## 🏛️ Arquitectura y Documentación

* **[Guía de Integración Frontend](docs/GUIA-INTEGRACION-FRONTEND.md)**: Manual rápido de onboarding.
* **[Guía Especializada para Flutter](docs/contrato-api-flutter.md)**: Interceptores Dart, Mutex y tipos BigInt.
* **[Especificación OpenAPI 3.0](docs/contrato/openapi.json)**: Contrato congelado formal.
* **[Catálogo de Errores](docs/contrato/errores.md)**: Códigos de error tipados RFC 7807.
* **[Matriz de Permisos RBAC](docs/contrato/matriz-permisos.md)**: Permisos por endpoint y rol.
* **[Decisiones de Arquitectura (ADRs)](docs/adr/INDEX.md)**: 19 registros de decisiones técnicas (ADR-001 al ADR-019).
* **[Contexto Integral del Proyecto](docs/CONTEXTO-PROYECTO.md)**: Reglas de negocio y especificación de dominio.