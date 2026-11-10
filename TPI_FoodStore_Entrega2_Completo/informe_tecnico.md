# Informe Técnico · TPI Food Store · Segunda Entrega (Unidades 4 a 8)

**Integrantes:** Agustín Ponti, David Rodrigues  
**Materia:** Base de Datos II · Proyecto Integrador «Food Store»  
**Motores:** PostgreSQL 16+, MongoDB, SQLite  
**Fecha:** 2026-11-09

---

## 1. Unidad 4 · Normalización avanzada y redundancia

### Qué se implementó

1. **Refactorización a FNBC (Forma Normal de Boyce-Codd):**
   - Esquema original `control_lote_almacen(lote_id, deposito_id, responsable_control_id)` con PK `(lote_id, deposito_id)`.
   - Dependencia violatoria detectada: `responsable_control_id → deposito_id` (un responsable solo pertenece a un depósito).
   - Descomposición sin pérdida en dos tablas:
     - `responsable_deposito(responsable_control_id PK, deposito_id)`
     - `control_lote(lote_id, responsable_control_id, PK(lote_id, responsable_control_id))`
   - Vista de compatibilidad `v_control_lote_almacen` que reconstruye la relación original mediante NATURAL JOIN.
   - Verificación de equivalencia: `original EXCEPT vista` y `vista EXCEPT original` = 0 filas; conteo coincidente (3 filas).

2. **Migración de datos sin pérdida:**
   - Ejecutada dentro de transacciones reversibles (`BEGIN` / `ROLLBACK`).
   - Primero se pobla la tabla padre (`responsable_deposito`) con `SELECT DISTINCT` de la original.
   - Luego se pobla `control_lote` desde la original.
   - Plan de reversión: se conserva la tabla original `control_lote_almacen` como evidencia; en producción se renombra o elimina tras validar.

3. **Anomalías documentadas y corregidas:**
   - Inserción: no se puede registrar un responsable sin lote (NOT NULL en PK).
   - Borrado: al borrar el único lote de un responsable, se pierde el dato de a qué depósito pertenece.
   - Actualización: al cambiar el depósito de un responsable en una sola fila, queda en dos depósitos a la vez (DF2 violada).
   - Todas demostradas con `BEGIN` / `ROLLBACK`.

4. **Desnormalización controlada:**
   - Tabla resumen `ventas_categoria_dia(fecha, categoria_id, categoria_nombre, total_vendido)` mantenida por triggers.
   - Justificación: consulta de top 5 categorías por monto vendido en el día sobre 400,000 pedidos / 1M detalles.
   - EXPLAIN ANALYZE "antes": 113 ms (4 tablas, seq scans). "Después": 0.011 ms (index scan sobre tabla resumen).
   - Mejora: ~10,000× más rápido.
   - Salvaguardas: triggers AFTER ROW sobre `detalle_pedido`, `pedido`, `producto`, `categoria` que aplican deltas atómicos (UPSERT) en la misma transacción.
   - Vista de auditoría `v_auditoria_ventas_categoria_dia` que detecta discrepancias entre el resumen y la fuente de verdad (0 filas = todo sincronizado).
   - Pruebas de sincronización: alta, modificación de subtotal, cambio de producto, baja lógica, mover pedido, reclasificar producto, renombrar categoría, borrado físico — todas con 0 discrepancias.
   - Prueba negativa: alterar el resumen "a mano" es detectado por la auditoría.

### Cómo se probó

- Script `tp_fnbc_control_lote.sql` ejecutado en PostgreSQL 16 con `ON_ERROR_STOP on`.
- Salidas capturadas en `docs/evidencias/u4_salida_parte1.txt` y `u4_salida_parte2.txt`.
- Todas las transacciones usan `ROLLBACK` para no dejar residuos.

### Decisiones de diseño

- **FNBC vs 3NF:** Se eligió FNBC porque la dependencia `responsable_control_id → deposito_id` tiene un determinante que no es superclave.
- **Desnormalización por triggers (no vista materializada):** Se eligió tabla resumen + triggers porque permite consultas ultra-rápidas con índice y control granular de sincronización, a costa de complejidad de escritura.

---

## 2. Unidad 5 · Administración y seguridad

### Qué se implementó

1. **Esquema de usuarios, roles y permisos (mínimo privilegio):**
   - Roles de grupo: `rol_app_lectura`, `rol_app_escritura`, `rol_soporte`, `rol_reportes`.
   - Roles de login: `app_web`, `admin_datos`.
   - `rol_app_lectura`: USAGE + SELECT sobre todas las tablas públicas.
   - `rol_app_escritura`: INSERT, UPDATE, DELETE sobre todas las tablas públicas.
   - `rol_reportes`: SELECT a nivel de columna (ej. `id, rol, fecha_alta` en `usuario`, omitiendo email).
   - `ALTER DEFAULT PRIVILEGES` para herencia en tablas futuras.

2. **Auditoría de accesos y operaciones:**
   - `postgresql.conf`: `log_connections = on`, `log_disconnections = on`, `log_statement = 'mod'`.
   - Simulacro de acceso indebido: fuerza bruta (3 intentos fallidos), login exitoso, lectura masiva de `usuario`, intento de escalamiento de privilegios (`GRANT admin_datos TO app_web` → ERROR por falta de admin option).
   - Log anonimizado en `docs/evidencias/u5_log_simulacro.txt`.

3. **Simulacro de acceso indebido y contención:**
   - Reconstrucción a partir del log de auditoría.
   - La IA interpretó incorrectamente el escalamiento como exitoso; la revisión humana detectó el `ERROR` nativo de PostgreSQL.
   - Medidas de contención: bloquear IP origen en firewall, resetear contraseña de `admin_datos`, informar a usuarios afectados.

4. **Anonimización de datos personales:**
   - Tabla `usuario_anon` creada con `SELECT id, 'Usuario_' || id AS nombre, 'user_' || id || '@anon-foodstore.com' AS email, rol, fecha_alta FROM usuario`.
   - Verificación de equivalencia: conteo de usuarios por rol idéntico en tabla real y anonimizada.

5. **Auditoría asistida por IA con decisión humana documentada:**
   - OpenCode sugirió `GRANT ALL PRIVILEGES ON ALL TABLES TO app_web` → **rechazado** (rompe mínimo privilegio).
   - IA interpretó el escalamiento de privilegios como exitoso → **corregido** (el ERROR demostró que falló).
   - Consulta de conteo por rol sobre `usuario_anon` → **aprobada**.

---

## 3. Unidad 6 · Mantenimiento

### Qué se implementó

1. **Plan de mantenimiento completo:**
   - Tareas rutinarias: `ANALYZE VERBOSE` sobre todas las tablas, `VACUUM (ANALYZE)` sin bloqueo, verificación de integridad referencial (FK huérfanas), detección de bloat excesivo (>20% tuplas muertas).
   - Respaldo programado: `pg_dump -F c -b -v` (formato custom, comprimido) con script de shell `u6_backup_programado.sh`, retención de 7 días.
   - Restauración: `pg_restore -v` con script `u6_restauracion.sh`, verificación post-restauración.

2. **Simulacro de desastre contra reloj:**
   - Base "sana" creada con datos de ejemplo (6 tablas, datos deterministas).
   - Respaldo generado con `pg_dump`.
   - Base destruida (`DROP DATABASE`) y recreada vacía.
   - Restauración desde el respaldo midiendo tiempo.
   - Verificación: conteo de filas, huella MD5, FK huérfanas (0), prueba de lectura/escritura.
   - Informe post-incidente en `relacional/u6_informe_post_incidente.md`.

3. **Automatización con OpenCode:**
   - Scripts de backup y restauración revisados por OpenCode (agente Plan).

### Cómo se probó

- Ejecución de `u6_plan_mantenimiento.sql` sobre PostgreSQL 16.
- Simulacro completo documentado en `u6_simulacro_desastre.sql`.
- Tiempo de restauración: < 1 segundo en entorno de prueba (base pequeña).
- Informe post-incidente con RTO/RPO y lecciones aprendidas.

---

## 4. Unidad 7 · NoSQL y nuevas formas de almacenamiento

### Qué se implementó

1. **Modelado documental (MongoDB):**
   - Colección `pedidos` con documento autocontenido:
     - `_id`, `fecha`, `estado`, `total`
     - `cliente` embebido (id, nombre, apellido, email)
     - `lineas` embebidas (detalle_id, producto_id, producto, cantidad, precio_unitario)
   - Reglas de integridad conservadas: `total = Σ(cantidad × precio_unitario)`, cada línea conserva precio_unitario histórico y producto_id, ningún pedido sin líneas.

2. **Consultas documentales verificadas:**
   - `consultas_mongodb.js` con 8 consultas: estado ENTREGADO, producto específico, valor alto (>4000), agregación por estado, verificación de integridad de totales, pedidos sin líneas, top clientes, ingresos por mes.

3. **Comparación relacional vs documental:**
   - PostgreSQL como fuente de verdad (integridad referencial, transacciones, dominio relacional).
   - MongoDB como réplica de lectura para pedidos (un solo documento, sin JOINs).
   - Justificación documentada en `comparacion_relacional_vs_documental.md`.

---

## 5. Unidad 8 · Bases de datos móviles e integración

### Qué se implementó

1. **Base SQLite de la tablet (Food Store móvil):**
   - `producto_cache`: catálogo local con precios en centavos enteros, tablas STRICT, CHECK constraints, `PRAGMA foreign_keys = ON`.
   - `pedido_borrador` + `item_borrador`: borradores de venta sin señal (clave primaria compuesta `(id_local, producto_id)`).
   - `cola_sync`: cola de sincronización con `solicitud_uuid` como PK (idempotencia).
   - `snapshot_servidor`: instantánea importada desde PostgreSQL (booleanos `t`/`f`).

2. **Sincronización especificada en Kiro y generada con OpenCode:**
   - `semaforo.sql`: clasifica solicitudes PENDIENTE como ROJO (RECHAZADO), AMARILLO (CONFLICTO) o VERDE (SIMULADO_APROBADO).
   - Requisitos EARS en `docs/kiro/u8_requirements.md` (REQ-01 a REQ-06).
   - Diseño en `docs/kiro/u8_design.md`.

3. **Casos de conflicto probados y resueltos:**
   - C1: Catálogo disponible sin servidor.
   - C2: Precio cambió en servidor → CONFLICTO; cliente acepta → nueva solicitud SIMULADO_APROBADO.
   - C3: Más unidades que stock → RECHAZADO.
   - C4: Producto dado de baja → RECHAZADO; UPSERT sin borrar filas (lápida).
   - C5: Todo coincide → SIMULADO_APROBADO.
   - C6: Mismo UUID → ERROR de clave primaria (idempotencia).
   - C7: Cantidad 0 y producto inexistente → errores de CHECK y FK.

4. **Verificación de no escritura en PostgreSQL:**
   - Pedidos y stock sin cambios antes y después de la simulación (misma huella MD5).

5. **Code review final asistido por IA:**
   - Entrada 5 de la bitácora (pendiente de completar con hallazgos específicos de OpenCode).
   - Decisiones humanas documentadas sobre cada hallazgo.

---

## 6. Herramientas de IA utilizadas (bitácora y DUIA)

- **Claude (Anthropic):** generación de scripts SQL, documentos, informe.
- **Kiro:** requisitos EARS, diseño, tareas (TP8).
- **OpenCode (agente Plan):** revisión de código de roles, backup, restauración.

Toda declaración detallada en `DUIA.md` y `bitacora_IA.md` (incluidas en esta entrega).

---

## 7. Evidencias incluidas

| Archivo | Contenido |
|---------|-----------|
| `docs/evidencias/u4_salida_parte1.txt` | Ejecución FNBC: anomalías, descomposición, verificación |
| `docs/evidencias/u4_salida_parte2.txt` | Ejecución desnormalización: EXPLAIN ANALYZE antes/después, auditoría |
| `docs/evidencias/u5_log_simulacro.txt` | Log anonimizado del simulacro de acceso indebido |
| `docs/evidencias/u5_log_auditoria.txt` | Log de prueba de auditoría |
| `docs/evidencias/u8_evidencia_casos.txt` | Ejecución completa de la simulación móvil C1-C7 |

---

## 8. Conclusión

La capa de datos del proyecto Food Store está completa y verificada:

- **Relacional (PostgreSQL 16+):** esquema refactorizado a FNBC, roles y permisos con mínimo privilegio, auditoría activada, plan de mantenimiento con respaldo/restauración probado, desnormalización controlada con triggers y auditoría de sincronización.
- **Documental (MongoDB):** modelo de pedidos embebido, consultas verificadas, comparación documentada vs relacional.
- **Móvil (SQLite):** base de tablet con borradores, cola de sincronización, semáforo de conflictos, casos C1-C7 probados.

Todos los scripts fueron leídos, comprendidos y probados sobre copias o dentro de transacciones reversibles, cumpliendo el protocolo obligatorio de uso de IA sobre datos.