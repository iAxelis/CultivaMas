# Auditoría de interfaces — Rentabilidad Agrícola

Fuente funcional: `Analisis_y_Clasificacion_de_Interfaces_Faltantes_App_Agricola.pdf`.

Estados:

- **Preservada:** ya existía y no se rediseñó.
- **Ampliada:** existía parcialmente y se completó.
- **Creada:** no existía como pantalla funcional.

| Módulo | Interfaz | Preview Figma Make | Flutter | Roles | Estado |
|---|---|---|---|---|---|
| A | Bienvenida | Flujo inicial | `/welcome` | Público | Preservada / creada en Flutter |
| A | Login + Demo | Flujo inicial | `/login` | Público | Preservada |
| A | Alta empresa F-01 | Registro | `/company/new` | Público | Ampliada |
| A | Guía de Estilos | Flujo inicial | `/style-guide` | Público | Ampliada / creada en Flutter |
| B | Predios y parcelas | Más → Predios | `/properties` | Todos; edición ADMIN | Ampliada |
| B | Predio F-03 | Modal/formulario | `/catalog-form/property` | ADMIN | Creada |
| B | Parcela F-04 | Modal/formulario | `/catalog-form/parcel` | ADMIN | Creada |
| C | Detalle de venta | Ventas → detalle | `/sales/:id` | ADMIN, CONTADOR | Ampliada |
| C | Cuentas por cobrar | Más → Cuentas | `/receivables` | ADMIN, CONTADOR | Ampliada |
| C | Clientes | Más → Clientes | `/clients` | ADMIN, CONTADOR | Ampliada |
| D | Proveedores | Más → Proveedores | `/suppliers` | ADMIN, CONTADOR | Ampliada |
| D | Selección proveedor F-09 | Formulario gasto | `/form/expense` | Todos con gasto | Creada |
| D | Categorías de gasto | Más → Categorías | `/expense-categories` | ADMIN edita; otros leen | Ampliada |
| E | Usuarios y permisos | Más → Usuarios | `/users` | ADMIN | Ampliada |
| E | Usuario F-02 | Modal/formulario | `/catalog-form/user` | ADMIN | Creada |
| E | Empresa/Suscripción | Más → Mi empresa | `/company` | ADMIN | Ampliada |
| E | Auditoría | Más → Auditoría | `/audit` | ADMIN | Ampliada |
| F | Alertas | Más → Alertas | `/alerts` | ADMIN, CONTADOR | Ampliada |
| F | Comparativo | Más → Comparativo | `/comparison` | ADMIN, CONTADOR | Ampliada |
| F | Reportes | Más → Reportes | `/reports` | ADMIN, CONTADOR | Ampliada |
| G | Perfil + logout | Más → Perfil | `/profile` | Autenticados | Ampliada |
| G | Ayuda/Soporte | Más → Ayuda | `/help` | Autenticados | Ampliada |

## Permisos derivados

Se implementó un catálogo de 19 permisos:

`empresa:administrar`, `usuario:administrar`, `estructura:administrar`,
`catalogo:administrar`, `tercero:administrar`, `ciclo:crear`,
`ciclo:cerrar`, `actividad:crear`, `gasto:crear`, `cosecha:crear`,
`merma:crear`, `venta:ver`, `venta:crear`, `venta:cancelar`,
`cobro:ver`, `cobro:crear`, `reporte:ver`, `reporte:exportar`,
`auditoria:ver`.

## Reglas de rol verificables

- **ADMIN:** administración completa.
- **CAPTURISTA:** actividad, gasto, cosecha y merma; estructura y categorías en lectura; selección contextual de proveedor. Sin ventas, cobros, clientes, alertas, comparativos ni reportes.
- **CONTADOR:** finanzas, ventas, cobros, clientes, proveedores y reportes; estructura y categorías en lectura. Sin usuarios, empresa ni auditoría.

Las exportaciones, cambio de contraseña, contacto de soporte y descarga de manuales permanecen como simulaciones explícitas del wireframe.
