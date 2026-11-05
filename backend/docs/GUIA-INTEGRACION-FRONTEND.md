# Guía Canónica de Integración Frontend — Cultiva+

Bienvenido a la guía oficial de integración del backend **Cultiva+**. Este documento fue diseñado para que el equipo de desarrollo frontend (móvil Flutter o aplicación Web) pueda conectar, autenticar y consumir la API REST de forma rápida, segura y sin fricciones.

---

## 1. Arquitectura del Sistema en 1 Minuto

**Cultiva+** es una plataforma SaaS multi-tenant para la gestión de costos, labores agrícolas y rentabilidad por ciclo productivo:

* **Multi-tenancy:** Cada usuario pertenece a una **Empresa** (`empresaId`). Todos los datos de fincas, ciclos, gastos y ventas están estrictamente aislados entre empresas.
* **Modelo Operativo:**
  $$\text{Empresa} \longrightarrow \text{Predios / Parcelas} \longrightarrow \text{Ciclos Productivos} \longrightarrow \begin{cases} \text{Labores / Actividades} \\ \text{Gastos Operativos (Insumos/Mano de obra)} \\ \text{Cosechas y Mermas (Balance de masa)} \end{cases} \longrightarrow \text{Ventas y Cobros} \longrightarrow \text{Rentabilidad}$$
* **Roles de Usuario (RBAC):**
  1. `ADMIN`: Dueño de la empresa o administrador general. Acceso y control total.
  2. `CAPTURISTA`: Operario en campo. Registra labores, gastos de sus actividades (ventana de 48h), cosechas y mermas. No accede a ventas, cobros ni reportes financieros.
  3. `CONTADOR`: Administración financiera. Registra y edita todos los gastos, gestiona clientes/proveedores, ventas, cobros y exporta reportes contables.

---

## 2. Puesta en Marcha Local (Windows Nativo + MySQL)

Para correr el backend en tu entorno local sin necesidad de Docker:

### Requisitos Previos
* **Node.js:** Versión 22 o superior (recomendado Node 24).
* **MySQL o MariaDB:** Corriendo localmente en el puerto `3306`.

### Paso a Paso
1. **Instalar Dependencias:**
   ```powershell
   npm ci
   ```
2. **Configurar Variables de Entorno:**
   Copia el archivo de ejemplo a tu archivo local `.env`:
   ```powershell
   copy .env.example .env
   ```
   Abre `.env` y ajusta la cadena de conexión con tus credenciales de MySQL:
   ```env
   DATABASE_URL="mysql://root:tu_password@localhost:3306/cultiva_backend"
   ```
3. **Crear Base de Datos y Aplicar Migraciones:**
   En tu cliente de MySQL ejecuta:
   ```sql
   CREATE DATABASE cultiva_backend CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```
   Luego aplica las 6 migraciones canónicas de Prisma:
   ```powershell
   npx prisma migrate deploy
   ```
4. **Cargar Semillas de Datos del Sistema (Seed):**
   ```powershell
   npx prisma db seed
   ```
   *Esto sembrará automáticamente los planes de suscripción, los 20 permisos, los 3 roles estándar, unidades de medida, motivos de merma, 11 categorías de gastos con sus subcategorías y el cultivo piloto de Tomate.*

5. **Iniciar Servidor de Desarrollo:**
   ```powershell
   npm run start:dev
   ```
   * El servidor levantará en `http://localhost:3000`.
   * **Swagger UI interactivo:** Abre `http://localhost:3000/api/docs` para explorar y probar los endpoints.
   * **Health Check:** `GET http://localhost:3000/api/v1/health` retornará `{ "status": "ok", "database": "ok" }`.

---

## 3. Flujo de Autenticación de Punta a Punta

### 3.1 Registro de Nueva Empresa y Administrador (OTP en 2 Pasos)

El registro en Cultiva+ es seguro y valida la identidad mediante un código OTP de 6 dígitos:

#### Paso 1: Solicitar Código OTP
* **Endpoint:** `POST /api/v1/empresas/registro/solicitar-codigo`
* **Body:**
  ```json
  {
    "correo": "productor@mifinca.com"
  }
  ```
* **En Desarrollo:** Gracias a la configuración `MAIL_TRANSPORT="log"`, **el código OTP se imprime directamente en la terminal donde corre el backend**:
  ```text
  [MailService] Código de verificación para productor@mifinca.com: 849201
  ```

#### Paso 2: Confirmar Registro y Crear Administrador
* **Endpoint:** `POST /api/v1/empresas/registro/confirmar`
* **Body:**
  ```json
  {
    "correo": "productor@mifinca.com",
    "codigo": "849201",
    "nombreEmpresa": "Agrícola Santa María",
    "nombreAdmin": "Carlos Mendoza",
    "password": "Password123!"
  }
  ```
* **Respuesta 201:** Retorna los datos de la empresa y del administrador creados, listos para iniciar sesión.

---

### 3.2 Inicio de Sesión (Login)

* **Endpoint:** `POST /api/v1/auth/login`
* **Body:**
  ```json
  {
    "correo": "productor@mifinca.com",
    "password": "Password123!"
  }
  ```
* **Respuesta 200 OK:**
  ```json
  {
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "d8f1e2c3-...",
    "usuario": {
      "id": "1",
      "correo": "productor@mifinca.com",
      "nombre": "Carlos Mendoza",
      "rol": "ADMIN",
      "empresaId": "1",
      "permisos": [
        "empresa:administrar",
        "usuario:administrar",
        "ciclo:crear",
        "gasto:crear",
        "reporte:ver"
      ]
    }
  }
  ```

### 3.3 Regla Crítica: Single-Flight Mutex para Refresco de Sesión

> [!CAUTION]
> **Detección de Reúso de Refresh Tokens (Familia Criptográfica):**
> Los Refresh Tokens son de un solo uso y rotan en cada llamada a `POST /api/v1/auth/refresh`. Si dos peticiones simultáneas intentan refrescar sesión con el mismo token, el backend detecta un ataque de reúso y **revoca inmediatamente toda la sesión del usuario**.
>
> **Requisito Obligatorio en el Frontend:** Utilizar un interceptor HTTP con cola o semáforo (*Single-Flight Mutex* / `QueuedInterceptor`). Cuando se reciba un `401 NO_AUTENTICADO`, solo una petición debe disparar el refresco, y las demás deben esperar ese resultado.

#### Implementación para Flutter (Dio Interceptor):
Consulta la implementación completa en Dart lista para copiar en [docs/contrato-api-flutter.md](contrato-api-flutter.md#2-regla-crítica-single-flight-mutex-en-refresco-de-tokens).

---

## 4. Respuestas Estándar y Manejo de Errores

### Paginación de Listados
Todas las consultas de listado (`GET /actividades`, `GET /gastos`, `GET /cosechas`, etc.) devuelven el formato unificado:
```json
{
  "data": [ ... ],
  "meta": {
    "page": 1,
    "limit": 50,
    "total": 120,
    "totalPages": 3
  }
}
```
* Parámetros aceptados: `?page=1&limit=50` (Tope máximo: `limit=100`).

### Taxonomía de Errores (RFC 7807)
Cuando una petición falla, el backend siempre devuelve un objeto tipado con código de dominio:
```json
{
  "statusCode": 400,
  "codigo": "STOCK_INSUFICIENTE",
  "mensaje": "La cantidad a vender excede la existencia disponible del ciclo.",
  "detalles": null,
  "timestamp": "2026-11-05T05:30:00.000Z"
}
```

### Guía de Reacción en la UI:
| Código HTTP | `codigo` de Dominio | Causa Común | Acción Recomendada en UI |
|---|---|---|---|
| **401** | `NO_AUTENTICADO` | Access Token expirado (15 min) | Intentar refresco vía Mutex. Si falla, borrar tokens y navegar a Login. |
| **403** | `SUSCRIPCION_INACTIVA` | Suscripción de la empresa vencida | Desplegar banner de renovación y bloquear botones de creación/edición. |
| **403** | `PERMISO_DENEGADO` | El rol no tiene el permiso atómico | Mostrar Snackbar: *"Acción no permitida para tu perfil de usuario"*. |
| **400** | `VENTANA_EDICION_EXPIRADA` | Capturista intentó editar gasto > 48h | Alerta: *"El plazo de 48h para editar este registro ha vencido"*. |
| **400** | `CICLO_NO_ACTIVO` | Intento de registrar labor en ciclo cerrado | Bloquear formulario: *"El ciclo productivo no está activo"*. |

---

## 5. Ruta Sugerida de Implementación de Pantallas (Frontend Roadmap)

Para construir la interfaz de usuario de forma modular y progresiva, recomendamos seguir este orden de integración:

```mermaid
flowchart LR
    A["1. Autenticación<br/>(Login, Registro OTP)"] --> B["2. Estructura<br/>(Predios y Parcelas)"]
    B --> C["3. Catálogos<br/>(Cultivos y Terceros)"]
    C --> D["4. Ciclos<br/>(Apertura de Ciclo)"]
    D --> E["5. Operaciones Campo<br/>(Labores, Gastos, Cosechas)"]
    E --> F["6. Comercialización<br/>(Ventas y Cobros)"]
    F --> G["7. Tablero y Reportes<br/>(Márgenes, KPIs, PDF/Excel)"]
```

1. **Fase 1: Autenticación y Perfil:**
   * Registro con OTP (`/api/v1/empresas/registro/*`).
   * Login (`/api/v1/auth/login`) y Logout (`/api/v1/auth/logout`).
   * Recuperación de contraseña (`/api/v1/auth/contrasena/*`).
2. **Fase 2: Estructura Productiva:**
   * CRUD de Predios y Parcelas (`/api/v1/estructura/predios`, `/api/v1/estructura/parcelas`).
   * Administración de Usuarios y Roles (`/api/v1/usuarios`).
3. **Fase 3: Terceros y Catálogos:**
   * Clientes y Proveedores (`/api/v1/terceros`).
   * Categorías de gastos y unidades de medida (`/api/v1/catalogos/*`).
4. **Fase 4: Ciclos Productivos (Núcleo):**
   * Creación e inicio de ciclo (`POST /api/v1/ciclos`, `POST /api/v1/ciclos/:id/iniciar`).
   * Máquina de estados: Activo, Suspendido, Finalizado, Cancelado.
5. **Fase 5: Operaciones de Campo:**
   * Registro de Labores (`/api/v1/actividades`).
   * Registro de Gastos con comprobante adjunto (`/api/v1/gastos`, `/api/v1/adjuntos`).
   * Registro de Cosechas y Mermas (`/api/v1/cosechas`, `/api/v1/mermas`).
6. **Fase 6: Comercialización:**
   * Despacho y Ventas (`/api/v1/ventas`).
   * Registro de Cobros (`/api/v1/cobros`).
7. **Fase 7: Métricas, Tablero y Reportes:**
   * Indicadores de Rentabilidad (`/api/v1/reportes/indicadores`).
   * Alertas de rentabilidad y cuentas por cobrar (`/api/v1/reportes/alertas`).
   * Exportación a Excel y PDF (`/api/v1/reportes/exportaciones/*`).

---

## 6. Documentos de Referencia Técnica

* **Especificación OpenAPI 3.0 Congelada:** [docs/contrato/openapi.json](contrato/openapi.json)
* **Catálogo Completo de Errores:** [docs/contrato/errores.md](contrato/errores.md)
* **Matriz de Permisos por Endpoint:** [docs/contrato/matriz-permisos.md](contrato/matriz-permisos.md)
* **Manual Especializado para Flutter:** [docs/contrato-api-flutter.md](contrato-api-flutter.md)
* **Decisiones de Arquitectura (ADRs):** [docs/adr/INDEX.md](adr/INDEX.md)