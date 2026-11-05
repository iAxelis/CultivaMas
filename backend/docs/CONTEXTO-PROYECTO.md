# Contexto Global del Proyecto — Backend Rentabilidad Agrícola

Documento de verdad técnica y arquitectura viva para el sistema backend de Rentabilidad Agrícola. Todos los datos, versiones, nombres de tablas, columnas, rutas y códigos de error aquí documentados provienen de la inspección directa del código fuente y de la base de datos física del repositorio en tiempo real.

---

## A. Stack y Versiones Exactas

### Runtime y Framework
- **Runtime**: Node.js v24.15.0 (64-bit Windows)
- **Framework Web**: NestJS v11.2.7
  - `@nestjs/common`: `11.2.7` (declarado: `^11.0.1`)
  - `@nestjs/core`: `11.2.7` (declarado: `^11.0.1`)
  - `@nestjs/platform-express`: `11.2.7` (declarado: `^11.0.1`)
  - `@nestjs/config`: `12.0.1` (declarado: `^12.0.1`)
  - `@nestjs/jwt`: `12.0.3` (declarado: `^12.0.3`)
  - `@nestjs/passport`: `12.0.0` (declarado: `^12.0.0`)
  - `@nestjs/swagger`: `11.4.7` (declarado: `^11.4.7`)
  - `@nestjs/throttler`: `6.7.1` (versión fija exacta)
  - `@nestjs/testing`: `11.2.7` (declarado: `^11.0.1`)
  - `@nestjs/cli`: `11.0.6` (declarado: `^11.0.0`)

### Servidor HTTP y Middleware
- `express`: `5.2.1`
- `body-parser`: `2.3.0`
- `multer`: `2.4.0`
- `helmet`: `8.3.0` (declarado: `^8.3.0`)
- `swagger-ui-express`: `5.0.1` (declarado: `^5.0.1`)

### Base de Datos y Persistencia
- **Motor de Base de Datos**: MySQL / MariaDB compatible server
- **Versión del Motor (`SELECT VERSION()`)**: `8.0.46`
- **ORM / Query Engine**: Prisma ORM `7.10.0` (declarado: `^7.10.0`)
- **Driver Adapter**: `@prisma/adapter-mariadb` `7.10.0`
- **Driver Nativo MariaDB**: `mariadb` `3.5.4` (directo) y `3.4.5` (subdependencia en adapter)
- **Driver MySQL2 (CLI desarrollo/introspección)**: `mysql2` `3.15.3` (subdependencia de `prisma@7.10.0`)

### Seguridad, Criptografía y Utilidades
- `argon2`: `0.45.1` (declarado: `^0.45.1`)
- `passport`: `0.7.0` (declarado: `^0.7.0`)
- `passport-jwt`: `4.0.1` (declarado: `^4.0.1`)
- `joi`: `18.2.9` (declarado: `^18.2.9`)
- `class-validator`: `0.15.1` (declarado: `^0.15.1`)
- `class-transformer`: `0.5.1` (declarado: `^0.5.1`)
- `nestjs-cls`: `7.0.1` (declarado: `^7.0.1`)
- `dayjs`: `1.11.23` (declarado: `^1.11.23`)
- `rxjs`: `7.8.1` (declarado: `^7.8.1`)
- `uuid`: `14.0.3` (directo) y `8.3.2` (subdependencia de `exceljs`)

### Motores de Exportación de Reportes
- `exceljs`: `4.4.0` (versión fija exacta)
- `pdfkit`: `0.17.2` (versión fija exacta)
- `@aws-sdk/client-s3`: `3.1152.0` (versión fija exacta — cliente S3 para Cloudflare R2, ADR-019)

### Calidad de Código y Pruebas
- `typescript`: `5.7.3` (declarado: `^5.7.3`)
- `eslint`: `9.18.0` (declarado: `^9.18.0`)
- `typescript-eslint`: `8.20.0` (declarado: `^8.20.0`)
- `jest`: `30.0.0` (declarado: `^30.0.0`)
- `ts-jest`: `29.2.5` (declarado: `^29.2.5`)
- `supertest`: `7.0.0` (declarado: `^7.0.0`)
- `prettier`: `3.4.2` (declarado: `^3.4.2`)

---

## B. Módulos y Arquitectura Funcional

| Módulo | Alcance y Funcionalidad | Componentes Clave | Estado y Cobertura |
|---|---|---|---|
| **Core y Persistencia** | Configuración base de NestJS 11, Prisma ORM y MariaDB | Modelo relacional de 29 tablas y 6 migraciones canónicas | 100% verificado (`npm run db:verify`, 74/74 Anexo D). |
| **Autenticación y Sesiones** | JWT, rotación atómica de Refresh Token, detección de reuso y hashing Argon2id | `AuthModule`, `JwtStrategy`, `ThrottlerGuard` dedicado | 100% passing (sesiones y familia de tokens probadas). |
| **Empresas y Usuarios (RBAC)** | Multi-tenant por empresa, gestión de usuarios, flujo F0 y pre-registro OTP | `EmpresasModule`, `UsuariosModule`, `RolesGuard` | Cobertura unitaria y E2E multiempresa. |
| **Catálogos y Estructura** | Predios, parcelas, terceros (clientes/proveedores) y unidades de medida | `EstructuraModule`, `TercerosModule`, `CatalogosModule` | Invariantes de catálogos y relación predio-parcela. |
| **Ciclos Productivos** | Núcleo productivo, máquina de estados formal (RN-009 ciclo activo único) | `CiclosModule`, máquina de estados, locks pesimistas | Validación de transiciones y concurrencia. |
| **Actividades Agrícolas** | Registro de labores de campo, insumos y maquinaria con gobernanza temporal (RN-044) | `ActividadesModule`, gobernanza temporal F-08 | Validaciones de fecha y rol de capturista. |
| **Gastos y Costos** | Costos operativos directos e indirectos, control de ventana de 48h (RN-062) | `GastosModule`, `GastoWindowValidator` | Control estricto de edición para capturista vs contador. |
| **Cosechas y Mermas** | Recolección, clasificación, mermas y balance físico de masa ($\Sigma\text{mermas}\le\Sigma\text{cosechas}$) | `CosechasModule`, `MermasModule`, balance de masa | Invariantes físicas estrictas de inventario. |
| **Ventas y Despacho** | Comercialización con revalidación cruzada bajo bloqueo pesimista contra sobreventa | `VentasModule`, control de inventario disponible | Prevención garantizada de sobreventa. |
| **Cobros y Créditos** | Cobros asociados a ventas, anulación lógica (RN-063) y cuentas por cobrar | `CobrosModule`, estado derivado de cobro | Inmutabilidad y cálculo de saldos. |
| **Indicadores y Tablero** | Vistas analíticas optimizadas (LEFT JOIN LATERAL, 5.6 ms), KPIs y alertas | `ReportesModule`, vistas SQL analíticas | 38 indicadores validados contra BD. |
| **Archivos Adjuntos** | Almacenamiento desacoplado (Local / Cloudflare R2) con descarga firmada temporal | `AdjuntosModule`, `R2StorageService`, token HMAC | Subida y descarga segura de comprobantes. |
| **Exportación de Reportes** | Generación síncrona de estados y reportes en Excel (.xlsx), PDF y CSV | `ReportesModule`, streaming y generación binaria | Reportes descargables y parametrizados. |
| **Seguridad y Contrato** | Congelación de contrato OpenAPI 3.0, AppVersionGuard, Throttlers y recuperación | `AppVersionGuard`, scripts OpenAPI, `MailModule` | 109 rutas HTTP y 38 códigos de error sincronizados. |

---

## C. Mapa del Sistema

### 1. Módulos de `src/modules` y Responsabilidad
1. `actividades`: Registro y control de labores agrícolas en ciclos de producción (F-08, RN-010, RN-015, RN-044).
2. `adjuntos`: Almacenamiento desacoplado (disco local/S3) de comprobantes y evidencias para gastos y cobros, con URL firmada temporal de descarga.
3. `auditoria`: Bitácora inmutable de eventos transaccionales para auditoría de cambios y accesos multi-tenant (RN-043, RN-060).
4. `auth`: Autenticación con JWT, emisión y rotación de Refresh Tokens, control de sesiones y extracción de contexto del usuario (RN-040, RN-072).
5. `catalogos`: Administración de catálogos maestros y categorías híbridas (árbol de gastos del sistema y por empresa, cultivos, variedades, tipos de suelo, unidades).
6. `ciclos`: Ciclo productivo agrícola y máquina de estados (PLANIFICADO, ACTIVO, SUSPENDIDO, FINALIZADO, CANCELADO) con control de ciclo activo por parcela (RN-009).
7. `cobros`: Registro, listado y anulación lógica de cobros contra ventas, derivando el estado financiero de cobro (PENDIENTE, PARCIAL, LIQUIDADO, ANULADO) (RN-063).
8. `cosechas`: Registro de cosechas por calidad y lote, validación de unidades de peso y base para balance de masa productiva (RN-024, RN-026, RN-069).
9. `empresas`: Administración de tenants, registro atómico de empresa con usuario administrador y control de suscripción/límites de plan (F-01, RN-003, RN-068).
10. `estructura`: Modelado físico del campo agrícola (predios y parcelas) con control de superficies y estados de uso (DISPONIBLE, EN_USO, DESCANSO, INACTIVA).
11. `exportacion`: Generación y descarga síncrona de reportes tabulares y ejecutivos en formatos Excel (.xlsx), PDF y CSV (.csv) con límites de seguridad *(Errata Hito 11A: la regla de plan para exportación corresponde a `plan_suscripcion.incluyeReportes` sin número de RN en el docx; la verdadera RN-073 del docx §2.9 regula comparaciones de "hoy" en `America/Mexico_City`)*.
12. `gastos`: Costos operativos directos e indirectos vinculados al ciclo o actividades, control de proveedores y ventanas de edición temporal (RN-062).
13. `health`: Verificación de salud y liveness del servicio HTTP para orquestadores y monitoreo.
14. `mermas`: Registro de pérdidas de cosecha (campo, poscosecha, transporte, almacén) con aplicación de balance de masa estricto (RN-031, RN-032, RN-049).
15. `reportes`: Indicadores analíticos consolidados de rentabilidad por ciclo, costos por categoría/actividad, comparativo entre ciclos y alertas preventivas.
16. `terceros`: Gestión de entidades externas comerciales: proveedores de insumos/servicios y clientes clasificados por canal de distribución.
17. `usuarios`: Gestión del personal de la empresa, asignación de roles RBAC, activación/desactivación lógica y control de cuotas por plan (RN-037).
18. `ventas`: Comercialización de cosechas con control de sobreventa, bloqueo pesimista contra balance de masa disponible y cálculo de totales (RN-027, RN-070).

---

### 2. Las 29 Tablas Físicas de la Base de Datos
1. `_prisma_migrations`: Historial de control de versiones de migraciones de Prisma.
2. `plan_suscripcion`: Catálogo de planes comerciales (Básico, Productor, Profesional) con límites de parcelas y usuarios.
3. `empresa`: Tenants o empresas productoras con moneda, RFC y estado de suscripción.
4. `rol`: Roles del sistema RBAC (`ADMIN`, `CAPTURISTA`, `CONTADOR`).
5. `permiso`: Catálogo inmutable de los 19 permisos funcionales granulares.
6. `rol_permiso`: Tabla intermedia de asignación de permisos a roles.
7. `usuario`: Cuentas de acceso asociadas a una empresa y un rol, con hash de contraseña Argon2.
8. `refresh_token`: Tokens de refresco rotatorios con familia (`familiaId`), UUID (`jti`), hash y estado de revocación.
9. `predio`: Extensiones o ranchos pertenecientes a una empresa.
10. `tipo_suelo`: Catálogo maestro de tipos de suelo agrícola.
11. `parcela`: Divisiones productivas de un predio con superficie, coordenadas y estado.
12. `cultivo`: Catálogo maestro de especies agrícolas cultivables.
13. `variedad`: Variedades comerciales asociadas a un cultivo con días estimados de ciclo.
14. `unidad_medida`: Unidades de medida con tipo (`PESO`, `VOLUMEN`, `AREA`, `TIEMPO`, `CONTEO`) y `factorABase`.
15. `tipo_actividad`: Catálogo de labores culturales (riego, poda, cosecha, etc.).
16. `categoria_gasto`: Estructura jerárquica de categorías de costo (maestras y propias por empresa con columna generada `claveNombre`).
17. `motivo_merma`: Catálogo de causas de merma (plaga, sequía, granizo, etc.).
18. `proveedor`: Proveedores comerciales de insumos y servicios vinculados a la empresa.
19. `cliente`: Compradores y comercializadores clasificados por tipo.
20. `ciclo_produccion`: Registro central del ciclo de cultivo con columna generada `claveCicloActivo` (RN-009).
21. `actividad`: Labores realizadas en un ciclo con horas trabajadas y responsable.
22. `gasto`: Erogaciones operativas con comprobante, desglose de impuestos y total.
23. `cosecha`: Entradas físicas recolectadas de producto en peso con asignación de calidad.
24. `merma`: Registros de pérdida de producto por etapa con motivo y cantidad.
25. `venta`: Transacciones comerciales de venta con estado, fechas límite de pago e importes.
26. `detalle_venta`: Renglones de venta asociados a una cosecha, unidad, cantidad y precio unitario.
27. `cobro_venta`: Cobros parciales o totales aplicados a una venta con soporte de anulación lógica (`deletedAt`).
28. `bitacora_auditoria`: Registro inmutable transaccional de auditoría con valores anteriores y nuevos en JSON.
29. `adjunto`: Metadatos de archivos físicos almacenados (clave, MIME, tamaño) asociados polimórficamente a una entidad.

---

### 3. Las 5 Vistas Analíticas de Base de Datos y sus Columnas Reales
1. **`v_rentabilidad_ciclo`** (26 columnas):
   - `cicloId` (int), `empresaId` (int), `parcelaId` (int), `variedadId` (int), `estado` (enum: PLANIFICADO, ACTIVO, SUSPENDIDO, FINALIZADO, CANCELADO), `fechaInicio` (date), `superficieSembrada` (decimal).
   - `costoTotal` (decimal), `kgCosechados` (decimal), `kgMerma` (decimal), `kgMermaCampo` (decimal), `kgNetos` (decimal), `kgVendidos` (decimal), `kgDisponibles` (decimal).
   - `ingresos` (decimal), `totalFacturado` (decimal), `cobrado` (decimal), `ganancia` (decimal), `margenPct` (decimal), `roiPct` (decimal), `costoPorKg` (decimal), `precioPromedioKg` (decimal), `mermaPct` (decimal), `costoPorHectarea` (decimal), `rendimientoKgHa` (decimal), `porCobrar` (decimal).
2. **`v_costo_por_actividad`** (7 columnas):
   - `cicloId` (int), `empresaId` (int), `tipoActividadId` (int), `tipoActividad` (varchar), `numeroActividades` (bigint), `horasTotales` (decimal), `costoTotal` (decimal).
3. **`v_costo_por_categoria`** (6 columnas):
   - `cicloId` (int), `empresaId` (int), `categoriaRaizId` (bigint), `categoriaRaiz` (varchar), `monto` (decimal), `porcentaje` (decimal).
4. **`v_merma_desglose`** (5 columnas):
   - `cicloId` (int), `empresaId` (int), `motivo` (varchar), `etapa` (enum: CAMPO, POSCOSECHA, TRANSPORTE, ALMACEN), `kgMerma` (decimal).
5. **`v_comparativo_parcela`** (29 columnas):
   - Las 26 columnas de `v_rentabilidad_ciclo` más:
   - `margenPctCicloAnterior` (decimal): función de ventana `LAG(margenPct) OVER (PARTITION BY parcelaId ORDER BY fechaInicio, cicloId)`.
   - `costoPorKgCicloAnterior` (decimal): función de ventana `LAG(costoPorKg) OVER (PARTITION BY parcelaId ORDER BY fechaInicio, cicloId)`.
   - `gananciaCicloAnterior` (decimal): función de ventana `LAG(ganancia) OVER (PARTITION BY parcelaId ORDER BY fechaInicio, cicloId)`.

---

### 4. Los 3 Roles Reales (`prisma/seed.ts`)
- **`ADMIN`** (Administrador): Dueño o productor con acceso total al sistema (los 19 permisos).
- **`CAPTURISTA`** (Capturista de campo): Encargado de capturar actividades, gastos, cosechas y mermas en campo (`actividad:crear`, `gasto:crear`, `cosecha:crear`, `merma:crear`).
- **`CONTADOR`** (Contador): Gestión de finanzas, ventas, cobros y reportes (`tercero:administrar`, `gasto:crear`, `gasto:editar_todos`, `venta:crear`, `venta:cancelar`, `cobro:crear`, `reporte:ver`, `reporte:exportar`).

---

### 5. Los 19 Permisos Reales (`prisma/seed.ts`)
1. `empresa:administrar`: Datos de la empresa, plan y bitácora.
2. `usuario:administrar`: Crear y desactivar usuarios, asignar rol.
3. `estructura:administrar`: Predios y parcelas.
4. `tercero:administrar`: Proveedores y clientes.
5. `catalogo:administrar`: Categorías de gasto propias.
6. `ciclo:crear`: Crear, editar, iniciar, suspender y reanudar ciclos.
7. `ciclo:cerrar`: Finalizar y cancelar ciclos.
8. `ciclo:reabrir`: Reabrir ciclos finalizados o cancelados.
9. `actividad:crear`: Registrar actividades.
10. `gasto:crear`: Registrar gastos.
11. `gasto:editar_todos`: Editar gastos de cualquier usuario.
12. `cosecha:crear`: Registrar cosechas.
13. `merma:crear`: Registrar mermas.
14. `venta:crear`: Crear y editar ventas.
15. `venta:cancelar`: Cancelar ventas.
16. `cobro:crear`: Registrar y anular cobros.
17. `registro:administrar`: Editar y eliminar cualquier actividad, gasto, cosecha o merma.
18. `reporte:ver`: Tablero, indicadores y alertas.
19. `reporte:exportar`: Exportar reportes a Excel, PDF y CSV.

---

### 6. Rutas de la API por Módulo

#### Autenticación (`/auth`)
- `POST /auth/login` (Público)
- `POST /auth/refresh` (Público)
- `POST /auth/logout` (Autenticado)
- `GET /auth/me` (Autenticado)

#### Empresas (`/empresas`)
- `POST /empresas/registro` (Público / Flujo F-01)
- `GET /empresas/mi-empresa` (Permiso: `empresa:administrar`)
- `PATCH /empresas/mi-empresa` (Permiso: `empresa:administrar`)

#### Usuarios (`/usuarios`)
- `POST /usuarios` (Permiso: `usuario:administrar`)
- `GET /usuarios` (Permiso: `usuario:administrar`)
- `GET /usuarios/:id` (Permiso: `usuario:administrar`)
- `PATCH /usuarios/:id` (Permiso: `usuario:administrar`)
- `DELETE /usuarios/:id` (Permiso: `usuario:administrar`)

#### Auditoría (`/auditoria`)
- `GET /auditoria` (Permiso: `empresa:administrar`)
- `GET /auditoria/:id` (Permiso: `empresa:administrar`)

#### Estructura Física: Predios y Parcelas (`/predios`, `/parcelas`)
- `POST /predios` (Permiso: `estructura:administrar`)
- `GET /predios` (Autenticado)
- `GET /predios/:id` (Autenticado)
- `PATCH /predios/:id` (Permiso: `estructura:administrar`)
- `DELETE /predios/:id` (Permiso: `estructura:administrar`)
- `POST /parcelas` (Permiso: `estructura:administrar`)
- `GET /parcelas` (Autenticado)
- `GET /parcelas/:id` (Autenticado)
- `PATCH /parcelas/:id` (Permiso: `estructura:administrar`)
- `DELETE /parcelas/:id` (Permiso: `estructura:administrar`)

#### Terceros: Clientes y Proveedores (`/clientes`, `/proveedores`)
- `POST /clientes` (Permiso: `tercero:administrar`)
- `GET /clientes` (Autenticado)
- `GET /clientes/:id` (Autenticado)
- `PATCH /clientes/:id` (Permiso: `tercero:administrar`)
- `DELETE /clientes/:id` (Permiso: `tercero:administrar`)
- `POST /proveedores` (Permiso: `tercero:administrar`)
- `GET /proveedores` (Autenticado)
- `GET /proveedores/:id` (Autenticado)
- `PATCH /proveedores/:id` (Permiso: `tercero:administrar`)
- `DELETE /proveedores/:id` (Permiso: `tercero:administrar`)

#### Catálogos (`/catalogos`)
- `GET /catalogos/cultivos` (Autenticado)
- `GET /catalogos/cultivos/:id/variedades` (Autenticado)
- `GET /catalogos/tipos-suelo` (Autenticado)
- `GET /catalogos/unidades-medida` (Autenticado)
- `GET /catalogos/tipos-actividad` (Autenticado)
- `GET /catalogos/motivos-merma` (Autenticado)
- `GET /catalogos/categorias-gasto` (Autenticado)
- `POST /catalogos/categorias-gasto` (Permiso: `catalogo:administrar`)

#### Ciclos de Producción (`/ciclos`)
- `POST /ciclos` (Permiso: `ciclo:crear`)
- `GET /ciclos` (Autenticado)
- `GET /ciclos/:id` (Autenticado)
- `PATCH /ciclos/:id` (Permiso: `ciclo:crear`)
- `PATCH /ciclos/:id/iniciar` (Permiso: `ciclo:crear`)
- `PATCH /ciclos/:id/suspender` (Permiso: `ciclo:crear`)
- `PATCH /ciclos/:id/reanudar` (Permiso: `ciclo:crear`)
- `PATCH /ciclos/:id/finalizar` (Permiso: `ciclo:cerrar`)
- `PATCH /ciclos/:id/cancelar` (Permiso: `ciclo:cerrar`)
- `PATCH /ciclos/:id/reabrir` (Permiso: `ciclo:reabrir`)
- `DELETE /ciclos/:id` (Permiso: `ciclo:cerrar`)

#### Actividades Agrícolas (`/actividades`)
- `POST /actividades` (Permiso: `actividad:crear`)
- `GET /actividades` (Permiso: `actividad:crear`)
- `GET /actividades/:id` (Permiso: `actividad:crear`)
- `PATCH /actividades/:id` (Permiso: `actividad:crear`)
- `DELETE /actividades/:id` (Permiso: `registro:administrar`)

#### Gastos Operativos (`/gastos`)
- `POST /gastos` (Permiso: `gasto:crear`)
- `GET /gastos` (Permiso: `gasto:crear`)
- `GET /gastos/:id` (Permiso: `gasto:crear`)
- `PATCH /gastos/:id` (Permiso: `gasto:crear` o `gasto:editar_todos`)
- `DELETE /gastos/:id` (Permiso: `registro:administrar`)

#### Cosechas (`/cosechas`)
- `POST /cosechas` (Permiso: `cosecha:crear`)
- `GET /cosechas` (Permiso: `cosecha:crear`)
- `GET /cosechas/:id` (Permiso: `cosecha:crear`)
- `PATCH /cosechas/:id` (Permiso: `cosecha:crear`)
- `DELETE /cosechas/:id` (Permiso: `registro:administrar`)

#### Mermas (`/mermas`)
- `POST /mermas` (Permiso: `merma:crear`)
- `GET /mermas` (Permiso: `merma:crear`)
- `GET /mermas/:id` (Permiso: `merma:crear`)
- `PATCH /mermas/:id` (Permiso: `merma:crear`)
- `DELETE /mermas/:id` (Permiso: `registro:administrar`)

#### Ventas (`/ventas`)
- `POST /ventas` (Permiso: `venta:crear`)
- `GET /ventas` (Permiso: `venta:crear`)
- `GET /ventas/:id` (Permiso: `venta:crear`)
- `PATCH /ventas/:id` (Permiso: `venta:crear`)
- `PATCH /ventas/:id/cancelar` (Permiso: `venta:cancelar`)

#### Cobros (`/ventas/:ventaId/cobros`, `/cobros/:id`)
- `POST /ventas/:ventaId/cobros` (Permiso: `cobro:crear`)
- `GET /ventas/:ventaId/cobros` (Permiso: `cobro:crear`)
- `GET /cobros/:id` (Permiso: `cobro:crear`)
- `PATCH /cobros/:id/anular` (Permiso: `cobro:crear`)

#### Reportes y Alertas (`/reportes`)
- `GET /reportes/cuentas-por-cobrar` (Permiso: `reporte:ver`)
- `GET /reportes/alertas` (Permiso: `reporte:ver`)
- `GET /reportes/rentabilidad` (Permiso: `reporte:ver`)
- `GET /reportes/ciclos/:cicloId/rentabilidad` (Permiso: `reporte:ver`)
- `GET /reportes/ciclos/:cicloId/costos-por-categoria` (Permiso: `reporte:ver`)
- `GET /reportes/ciclos/:cicloId/costos-por-actividad` (Permiso: `reporte:ver`)
- `GET /reportes/ciclos/:cicloId/mermas` (Permiso: `reporte:ver`)
- `GET /reportes/parcelas/:parcelaId/comparativo` (Permiso: `reporte:ver`)

#### Exportación de Reportes (`/reportes/exportaciones`)
- `GET /reportes/exportaciones/rentabilidad` (Permiso: `reporte:exportar`)
- `GET /reportes/exportaciones/ciclos/:cicloId` (Permiso: `reporte:exportar`)
- `GET /reportes/exportaciones/parcelas/:parcelaId/comparativo` (Permiso: `reporte:exportar`)
- `GET /reportes/exportaciones/cuentas-por-cobrar` (Permiso: `reporte:exportar`)

#### Archivos Adjuntos (`/actividades/:id/adjuntos`, `/gastos/:id/adjuntos`, `/ventas/:id/adjuntos`, `/cobros/:id/adjuntos`, `/adjuntos/...`)
- `POST /actividades/:id/adjuntos` (Permiso: `actividad:crear`)
- `GET /actividades/:id/adjuntos` (Permiso: `actividad:crear`)
- `POST /gastos/:id/adjuntos` (Permiso: `gasto:crear`)
- `GET /gastos/:id/adjuntos` (Permiso: `gasto:crear`)
- `POST /ventas/:id/adjuntos` (Permiso: `venta:crear`)
- `GET /ventas/:id/adjuntos` (Permiso: `venta:crear`)
- `POST /cobros/:id/adjuntos` (Permiso: `cobro:crear`)
- `GET /cobros/:id/adjuntos` (Permiso: `cobro:crear`)
- `GET /adjuntos/:id/enlace-descarga` (Autenticado con acceso a la entidad)
- `GET /adjuntos/descarga` (`?token=`, Público con token criptográfico temporal firmado)
- `DELETE /adjuntos/:id` (Autenticado con propiedad o `registro:administrar`)

#### Health Check (`/health`)
- `GET /health` (Público)

---

## D. Códigos de Error

Tabla exhaustiva del enum `CodigoError` (`src/common/errors/codigos-error.enum.ts`) y su mapeo HTTP en `DomainExceptionFilter`:

| Código del Enumerador | Código HTTP | Nombre HTTP | Significado en el Dominio |
|---|---|---|---|
| `CICLO_CERRADO` | 409 | Conflict | Se intentó registrar actividad, gasto, cosecha o merma en un ciclo finalizado o cancelado. |
| `CICLO_YA_ACTIVO` | 409 | Conflict | La parcela ya tiene un ciclo activo (violación de RN-009). |
| `VENTA_EXCEDE_DISPONIBLE` | 400 | Bad Request | La cantidad de venta excede los kg netos disponibles de la cosecha o ciclo (sobreventa). |
| `MERMA_EXCEDE_COSECHA` | 409 | Conflict | La sumatoria de mermas poscosecha excede el total de cosechas del ciclo (balance de masa). |
| `TOTAL_NO_COINCIDE` | 400 | Bad Request | El importe total de la venta no coincide con la suma de los detalles menos descuentos más impuestos. |
| `COBRO_EXCEDE_TOTAL` | 409 | Conflict | La sumatoria de cobros activos excede el importe total facturado de la venta. |
| `VENTANA_EDICION_VENCIDA` | 409 | Conflict | Se intentó modificar o eliminar un gasto fuera de la ventana permitida (RN-062). |
| `LIMITE_PLAN_EXCEDIDO` | 409 | Conflict | Se alcanzó el límite de usuarios o parcelas permitido por el plan de suscripción (RN-037). |
| `SUSCRIPCION_INACTIVA` | 403 | Forbidden | La empresa tiene su suscripción vencida o cancelada. |
| `PERMISO_DENEGADO` | 403 | Forbidden | El usuario autenticado carece del permiso RBAC requerido para ejecutar la operación. |
| `FECHA_ANTERIOR_AL_INICIO` | 400 | Bad Request | La fecha de una actividad, gasto o cosecha es anterior a la fecha de inicio del ciclo. |
| `UNIDAD_NO_PESO` | 400 | Bad Request | Se intentó registrar una cosecha o merma con una unidad que no es de tipo PESO (RN-024). |
| `ACTIVIDAD_DE_OTRO_CICLO` | 400 | Bad Request | La actividad vinculada a un gasto pertenece a un ciclo diferente. |
| `CICLO_NO_ACTIVO` | 409 | Conflict | La operación exige que el ciclo esté en estado ACTIVO y se encuentra en otro estado. |
| `COSECHA_DE_OTRO_CICLO` | 400 | Bad Request | La cosecha especificada no pertenece al ciclo de producción indicado. |
| `COSECHA_CON_MERMAS_VIGENTES` | 409 | Conflict | No se puede eliminar una cosecha que tiene registros de merma activos vinculados. |
| `VENTA_YA_CANCELADA` | 409 | Conflict | Se intentó cobrar, modificar o cancelar una venta que ya se encuentra cancelada. |
| `CLIENTE_NO_ACTIVO` | 400 | Bad Request | El cliente seleccionado está dado de baja o inactivo. |
| `COSECHA_CON_VENTAS_VINCULADAS` | 409 | Conflict | No se puede eliminar una cosecha que tiene detalles de venta activos asociados. |
| `KG_VENDIDOS_EXCEDEN_NETOS` | 400 | Bad Request | La reducción de cosecha o incremento de merma dejaría los kg vendidos por encima de los netos. |
| `RECURSO_NO_ENCONTRADO` | 404 | Not Found | El registro no existe o pertenece a otra empresa (aislamiento multi-tenant estricto). |
| `PETICION_INVALIDA` | 400 | Bad Request | Error de validación de sintaxis, formato o parámetros en el payload de entrada. |
| `NO_AUTENTICADO` | 401 | Unauthorized | Token JWT ausente, inválido, corrupto o con firma expirada. |
| `COBRO_YA_ANULADO` | 409 | Conflict | Se intentó anular un cobro que ya había sido anulado previamente. |
| `FECHA_COBRO_INVALIDA` | 400 | Bad Request | La fecha del cobro es anterior a la fecha de emisión de la venta. |
| `ARCHIVO_DEMASIADO_GRANDE` | 413 | Payload Too Large | El archivo adjunto supera el tamaño máximo permitido de 10 MB (10,485,760 bytes). |
| `TIPO_ARCHIVO_NO_PERMITIDO` | 415 | Unsupported Media Type | El formato o firma binaria (Magic Bytes) del archivo no corresponde a JPEG, PNG o PDF. |
| `ADJUNTO_ENTIDAD_NO_SOPORTADA` | 400 | Bad Request | Se intentó adjuntar un archivo a una entidad no soportada (acepta `gasto`, `actividad`, `venta` y `cobro`). |
| `ENLACE_DESCARGA_INVALIDO` | 403 | Forbidden | El token de descarga es inválido, expiró, pertenece a otro usuario o el emisor fue desactivado. |
| `LIMITE_ADJUNTOS_ALCANZADO` | 400 | Bad Request | Se alcanzó el límite máximo de 10 adjuntos por entidad. |
| `EXPORTACION_EXCEDE_LIMITE` | 400 | Bad Request | El conjunto de datos a exportar síncronamente supera el límite de seguridad de 5,000 filas. |
| `DEMASIADAS_PETICIONES` | 429 | Too Many Requests | Se excedió el límite de peticiones permitido por ventana de tiempo o bloqueo de fuerza bruta (incluye cabecera `Retry-After`). |
| `CONFLICTO` | 409 | Conflict | Conflicto de unicidad o clave foránea capturado por Prisma (códigos P2002 / P2003). |
| `ERROR_INTERNO` | 500 | Internal Server Error | Falla no controlada en el servidor o error no mapeado en base de datos. |

---

## E. Invariantes de Arquitectura

- empresaId siempre del JWT; recurso ajeno = 404.
- Orden de bloqueo: ciclo primero, venta después. Dentro de toda $transaction, la PRIMERA sentencia es bloquearCicloParaCaptura; las lecturas previas van FUERA de la transacción y el registro se RELEE bajo el lock (regla REPEATABLE READ, ADR-007).
- Escribir, recalcular y revertir con error de dominio, en lugar de validar antes con aritmética de deltas.
- Auditoría en la misma transacción; la bitácora nunca guarda secretos ni claves de almacenamiento.
- Errores solo de dominio, centralizados en codigos-error.enum.ts; nunca throw new Error en producción.
- @RequirePermisos tiene semántica AND: un permiso por endpoint; el bypass de registro:administrar va en el servicio.
- Dinero y kg solo con Prisma.Decimal; en la API como string (importes y porcentajes 2 decimales, kg 3, HALF_UP vía reporte-formato.util).
- Fórmulas de indicadores solo en las vistas; no se recalculan en TypeScript.
- SQL crudo solo con Prisma.sql parametrizado, columnas explícitas y empresaId en el WHERE.
- Cambios de contrato JSON solo aditivos. Estados de ciclo según tabla 2.6.
- Los nombres reales de BD son camelCase; el documento maestro es referencia de reglas, no de nombres.

---

## F. Métricas de Calidad y Línea Base de Ingeniería

- **Compilación:** `npm run build` exit 0 estricto en TypeScript.
- **Pruebas Unitarias:** 95 suites, 710 tests pasados al 100% (`npm test`).
- **Pruebas E2E:** 17 suites activas, 280 tests certificados en ejecución continua (`npm run test:e2e`).
- **Base de Datos:** 74/74 comprobaciones de integridad del Anexo D aprobadas (`npm run db:verify`).
- **Contrato OpenAPI:** 109 rutas HTTP y 38 códigos de error sincronizados sin deriva (`npm run contrato:verificar`).
- **Migraciones:** 6 migraciones canónicas aplicadas en orden sobre MariaDB/MySQL.
- **Seguridad Criptográfica:** Hash Argon2id con rehash transparente, tokens de sesión rotatorios y limitadores de tasa (throttling).

---

## G. Deuda Técnica Consolidada (de todos los ADR) con su Origen

| ID | Deuda Técnica Consolidada | Origen Arquitectónico | Impacto / Mitigación Actual |
|---|---|---|---|
| **DT-01** | Propagación explícita del parámetro transaccional `tx` en servicios | ADR-001 (Auditoría transaccional) | Si se omite `tx`, la auditoría o la mutación se ejecutan fuera de la transacción atómica. Mitigado con tests unitarios que simulan fallas y comprueban el rollback en cascada. |
| **DT-02** | Serialización pesimista estricta en transiciones de ciclo | ADR-007 (Concurrencia) | Alta contención si múltiples capturistas escriben mientras se cierra un ciclo. Recomendación: desacoplar réplica de solo lectura para reportes históricos. |
| **DT-03** | Filtrado avanzado en memoria vs SQL para `estadoCobro` en ventas | ADR-009 (Cobros y Cuentas por Cobrar) | `estadoCobro` es un estado derivado en runtime. Al paginar grandes volúmenes de ventas, requerirá subconsultas indexadas o columna materializada en BD. |
| **DT-04** | Alertas push en tiempo real ante cuentas por cobrar vencidas | ADR-009 (Cobros) | Actualmente solo se evalúa pull vía API (`GET /reportes/cuentas-por-cobrar`). Pendiente worker de notificaciones push para la app móvil. |
| **DT-05** | Configuración personalizada de umbrales de alerta por empresa | ADR-010 (Indicadores y Tablero) | Los umbrales de margen y merma están fijos en código/vistas. Se difirió la tabla `configuracion_alerta` por tenant. |
| **DT-06** | Job periódico de reconciliación de huérfanos en almacenamiento (local y R2) | ADR-012 / ADR-019 (Archivos Adjuntos) | Abierta: si el servidor se apaga abruptamente tras escribir en almacenamiento (disco local o Cloudflare R2) y antes del commit de BD, o falla la compensación post-rollback, queda un objeto huérfano. Requiere un cron nocturno de reconciliación (aplica también a R2). |
| **DT-07** | Driver de almacenamiento para nube (Cloudflare R2 / S3) | ADR-012 / ADR-019 (Hito R2) | **Resuelta con driver R2 (verificación manual pendiente — ver DT-23)**: Implementado `R2StorageService` (`@aws-sdk/client-s3@3.1152.0`) seleccionable vía `STORAGE_DRIVER=r2`, bucket privado, clave `<empresaId>/<uuid>.<ext>` y descarga en streaming con token HMAC de 300 s. |
| **DT-08** | Cola asíncrona (BullMQ / Redis) para exportaciones masivas (>5,000 filas) | ADR-013 (Exportación de Reportes) | Exportaciones síncronas están acotadas a 5,000 registros para proteger la memoria del proceso Node.js. Volúmenes mayores requieren procesamiento background con streaming. |
| **DT-09** | Gating por `incluyeReportes` del plan de suscripción (sin número de RN, pendiente decisión de producto) | ADR-013 (Exportación de Reportes — Errata 11A) | Pendiente definición de producto sobre si `plan_suscripcion.incluyeReportes` restringe solo `/reportes/exportaciones/*` o todo `/reportes/*` para planes BASICO y PRODUCTOR. |
| **DT-10** | Almacenamiento distribuido (Redis) para `@nestjs/throttler` en despliegues multi-instancia | ADR-014 (Seguridad y Throttling) | El limitador de tasa opera en memoria local del proceso Node.js. Al escalar horizontalmente a múltiples instancias se debe inyectar storage Redis compartido. |
| **DT-11** | Validación formal de OpenAPI en pipeline CI/CD con generador Dart | Hito 11D / 11C.1 | Validador OpenAPI vía red (`npx @stoplight/spectral-cli`) restringido en sandbox sin red externa. Se delega la validación formal al pipeline de generación del cliente Dart en Flutter (`openapi-generator-cli`). |
| **DT-12** | Job periódico de purga de tokens de recuperación expirados | ADR-017 (Gestión de Contraseñas) | La tabla `password_reset_token` acumula registros consumidos, revocados o expirados. Requiere un cron job nocturno (`@nestjs/schedule`) para eliminar físicamente tokens con más de 30 días. |
| **DT-13** | Cola asíncrona (BullMQ / Redis) para despacho de correos masivos | ADR-017 (Gestión de Contraseñas) | `BrevoTransport` despacha vía HTTP nativo con timeout de 5s. Al escalar la concurrencia se recomienda migrar a un worker en cola persistente con reintentos exponenciales. |
| **DT-14** | Verificación manual pendiente de exportación y casos negativos de adjuntos | Hito 10A / 10B (Cierre con verificación parcial) | Pendiente abrir físicamente archivos generados (.xlsx, .pdf, .csv) en aplicaciones de escritorio; validar casos negativos de adjuntos (archivos corruptos, formatos no soportados como webp real y borrado restringido por rol). |
| **DT-15** | Actualización y remediación de dependencias vulnerables | ADR-018 / Hito 11F | Resuelto y mitigado en Hito 11F mediante fijación exacta y overrides controlados (qs, mariadb, mysql2, deepmerge-ts, js-yaml, uuid, fast-uri). Retención controlada de body-parser y multer por regla de 14 días con mitigación activa en runtime. |
| **DT-16** | Inestabilidad del entorno de pruebas E2E en Windows (crash 0xC0000409) | Hito 11F / ADR-018 | Mitigado por reducción del costo de Argon2 en entorno de pruebas; causa raíz no probada (hipótesis de contención de pool de libuv / vm-modules no demostrada). |
| **DT-17** | Reintento acotado ante deadlock transaccional en recuperación concurrente de contraseñas | Hito 11E.5 / 11F / ADR-018 | Solicitudes concurrentes masivas sobre el mismo correo compiten por revocación de tokens previos en InnoDB; mitigado con reintento defensivo (máx. 2 intentos con `setImmediate`) y fallback seguro que responde 200 genérico sin propagar error 500 al cliente. |
| **DT-18** | Actualización de dependencias en cuarentena de 14 días (`body-parser@2.4.0` y `multer@2.5.0`) | Hito 11F.1 / ADR-018 | Ambas versiones corregidas fueron publicadas el 2026-10-22. Su ventana de cuarentena de seguridad finaliza el 2026-11-05, momento en que deberán actualizarse en `package.json`. Mitigado actualmente en runtime con `inflate: false`, `limit: 1mb` (HTTP 415 con `PETICION_INVALIDA`) y `limits: { fileSize: 10MB, files: 1 }` sin `fileFilter`. |
| **DT-19** | Saneamiento residual de 323 errores de lint en el repositorio | Hito 11B / Hito 11F.2 | Deuda técnica opcional de limpieza estética de código heredado sin valor funcional inmediato. La compuerta mecánica de cierre (`scripts/cierre-hito.ps1`) garantiza 0/0 en archivos de la rama y tope estricto de 323/84 para evitar cualquier aumento o regresión (reducido a 161 errores y 76 avisos tras Fase D). |
| **DT-20** | Código HTTP en `GET /api/v1/health` ante desconexión de BD (200 vs 503 — C4, decisión pendiente) | ADR-015 (`ADR-015-congelacion-contrato-openapi-y-control-version-cliente.md`) / ADR-003 (`ADR-003-taxonomia-errores-prisma-domain-exception-filter.md`) | `HealthResponseDto` congelado en `docs/contrato/openapi.json` documenta `database: ["ok", "disconnected"]` bajo HTTP 200 y el catálogo de errores no define código de dominio 503; pasar a 503 rompería clientes y sondas actuales, por lo que queda pendiente de decisión de contrato. |
| **DT-21** | Semántica de `meta.totalPages` con `total = 0` (0 vs 1 — D4, decisión pendiente) | ADR-015 (`ADR-015-congelacion-contrato-openapi-y-control-version-cliente.md`) | `cosechas`, `gastos`, `mermas` y `ventas` calculan `Math.ceil(total / limit)` (devuelve `0` con `total = 0`), mientras `PaginationUtil.crearMeta` y `actividades` aplican `\|\| 1`. Unificar con `crearMeta` cambiaría el valor observable de `0` a `1` en listados vacíos; se mantiene sin cambio hasta decisión de contrato con Flutter. |
| **DT-22** | Parámetro `tx?: Prisma.TransactionClient` opcional en `AuditService.registrar` | ADR-001 (`ADR-001-auditoria-transaccional.md`) | Aunque C1 envolvió todas las escrituras productivas en `prisma.$transaction` propagando `tx`, la firma `AuditService.registrar(options, tx?)` conserva `tx` como opcional en TypeScript; volverlo obligatorio en la firma prevendría en tiempo de compilación futuras llamadas fuera de transacción. |
