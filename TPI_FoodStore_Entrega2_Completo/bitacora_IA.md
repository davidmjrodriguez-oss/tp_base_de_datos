# Bitácora de Uso de IA · TPI Food Store · Segunda Entrega (Unidades 4 a 8)

> Registro del uso de IA en esta entrega. Cada entrada dice qué se pidió, qué se aceptó, qué se descartó y por qué.
> Todo lo aceptado se leyó y se probó antes de usarlo.
> **Antes de entregar:** revisá cada entrada, ajustala a lo que realmente hiciste y agregá lo que faltante.
> Lo que no puedas explicar en la defensa cuenta como no hecho.

---

## Unidad 4 · Normalización avanzada y redundancia

### Entrada 1 · Análisis FNBC de control_lote_almacen
- **Pedí:** analizar la tabla `control_lote_almacen(lote_id, deposito_id, responsable_control_id)` con PK `(lote_id, deposito_id)` y detectar violaciones de FNBC.
- **Acepté:** la dependencia `responsable_control_id → deposito_id` es violatoria; descomposición en `responsable_deposito(responsable_control_id PK, deposito_id)` + `control_lote(lote_id, responsable_control_id, PK(lote_id, responsable_control_id))`.
- **Descarté:** nada de lo propuesto; todo se verificó con EXCEPT en ambas direcciones (0 filas).
- **Cómo lo comprobé:** `tp_fnbc_control_lote.sql` ejecutado en PostgreSQL 16; salidas en `docs/evidencias/u4_salida_parte1.txt`.

### Entrada 2 · Triggers para preservar DF1
- **Pedí:** generar triggers que impidan que un lote tenga dos responsables del mismo depósito tras la descomposición FNBC.
- **Acepté:** `fn_chk_unico_responsable_por_lote_deposito()` y `fn_chk_cambio_deposito_responsable()` con triggers BEFORE INSERT/UPDATE.
- **Descarté:** nada.
- **Cómo lo comprobé:** prueba 7d en el script (insert de responsable 804 en depósito 30 para lote 501 ya controlado por 801 en depósito 30 → rechazado).

### Entrada 3 · Desnormalización por triggers
- **Pedí:** diseñar tabla resumen `ventas_categoria_dia` mantenida por triggers para consulta de top 5 categorías por día.
- **Acepté:** tabla resumen con triggers AFTER ROW sobre `detalle_pedido`, `pedido`, `producto`, `categoria` que aplican deltas atómicos (UPSERT).
- **Descarté:** vista materializada (no permite control granular de sincronización por fila ni auditoría sencilla).
- **Cómo lo comprobé:** EXPLAIN ANALYZE antes (113 ms) y después (0.011 ms); auditoría `v_auditoria_ventas_categoria_dia` da 0 filas tras cada escenario de cambio.

### Entrada 4 · Plan de reversión de migración
- **Pedí:** definir plan de reversión para la migración FNBC.
- **Acepté:** conservar la tabla original `control_lote_almacen` como evidencia; renombrar o eliminar tras validar en producción.
- **Descarté:** eliminar la tabla original inmediatamente (pierde evidencia de la migración).
- **Cómo lo comprobé:** revisión humana del script; la tabla original se conserva intencionalmente.

---

## Unidad 5 · Administración y seguridad

### Entrada 5 · Roles y permisos (mínimo privilegio)
- **Pedí:** auditar `roles.sql` y verificar que los permisos sean los mínimos necesarios.
- **Acepté:** segmentación en `rol_app_lectura` (SELECT), `rol_app_escritura` (INSERT/UPDATE/DELETE), `rol_reportes` (SELECT a nivel de columna), `rol_soporte`.
- **Descarté:** OpenCode sugirió `GRANT ALL PRIVILEGES ON ALL TABLES TO app_web` → **rechazado** (rompe mínimo privilegio).
- **Cómo lo comprobé:** revisión humana del archivo `u5_roles_permisos.sql`; especificación Kiro en `docs/kiro/roles_spec/u5_requirements_y_design.md`.

### Entrada 6 · Auditoría y simulacro de acceso indebido
- **Pedí:** analizar el log anonimizado del simulacro de fuerza bruta, lectura masiva y escalamiento de privilegios.
- **Acepté:** la IA identificó correctamente fuerza bruta, login exitoso y lectura masiva.
- **Descartado/Corregido:** la IA afirmó que el escalamiento de privilegios fue exitoso → **falso**. El log muestra `ERROR: must have admin option on role "Admin_Sintetico"`; el escalamiento falló por diseño de permisos.
- **Cómo lo comprobé:** revisión línea por línea de `docs/evidencias/u5_log_simulacro.txt`; el ERROR es explícito en la línea 7.

### Entrada 7 · Anonimización y equivalencia
- **Pedí:** generar consulta SQL para contar usuarios por rol en `usuario_anon` y verificar equivalencia con `usuario`.
- **Acepté:** `SELECT rol, COUNT(id) FROM usuario_anon GROUP BY rol;` (sintaxis correcta, conteos idénticos).
- **Descarté:** nada.
- **Cómo lo comprobé:** `docs/u5_verificacion_equivalencia.md` documenta ambas consultas y su equivalencia.

---

## Unidad 6 · Mantenimiento

### Entrada 8 · Scripts de backup y restauración
- **Pedí:** generar scripts de respaldo (`pg_dump`) y restauración (`pg_restore`) automatizados.
- **Acepté:** `pg_dump -F c -b -v` (formato custom, comprimido) y `pg_restore -v` con verificación post-restauración.
- **Descarté:** respaldo en formato SQL plano (menos eficiente, no permite restauración selectiva tan fácilmente).
- **Cómo lo comprobé:** `u6_backup_programado.sh` y `u6_restauracion.sh` revisados línea por línea; simulacro en `u6_simulacro_desastre.sql`.

### Entrada 9 · Tareas rutinarias de mantenimiento
- **Pedí:** definir tareas rutinarias: estadísticas, limpieza, verificación de integridad.
- **Acepté:** `ANALYZE VERBOSE`, `VACUUM (ANALYZE)` (no FULL), verificación de FK huérfanas, detección de bloat >20%.
- **Descarté:** `VACUUM FULL` como tarea rutinaria (bloquea la tabla; solo en ventanas de mantenimiento).
- **Cómo lo comprobé:** `u6_plan_mantenimiento.sql` ejecutado en PostgreSQL 16.

### Entrada 10 · Simulacro de desastre
- **Pedí:** diseñar simulacro de restauración contra reloj con informe post-incidente.
- **Acepté:** procedimiento completo (base sana → respaldo → destrucción → restauración → verificación) con medición de tiempo.
- **Descarté:** nada.
- **Cómo lo comprobé:** `u6_simulacro_desastre.sql` e `u6_informe_post_incidente.md`.

---

## Unidad 7 · NoSQL

### Entrada 11 · Modelo documental de pedidos
- **Pedí:** modelar pedidos en MongoDB con líneas y cliente embebidos.
- **Acepté:** documento `pedidos` con `_id`, `fecha`, `estado`, `total`, `cliente` embebido, `lineas` embebidas.
- **Descarté:** referenciar líneas en colección separada (requeriría lookup/join, pierde la ventaja documental).
- **Cómo lo comprobé:** `consultas_mongodb.js` con 8 consultas verificadas sobre la estructura propuesta.

### Entrada 12 · Comparación relacional vs documental
- **Pedí:** comparar PostgreSQL y MongoDB para el subconjunto de pedidos.
- **Acepté:** PostgreSQL como fuente de verdad; MongoDB como réplica de lectura solo si el volumen lo justifica.
- **Descarté:** MongoDB como fuente de verdad para pedidos (pierde integridad referencial y transacciones multi-tabla maduras).
- **Cómo lo comprobé:** `nosql/comparacion_relacional_vs_documental.md`.

---

## Unidad 8 · Bases de datos móviles e integración

### Entrada 13 · Esquema SQLite de la tablet
- **Pedí:** las cuatro tablas STRICT de la consigna con CHECK y claves foráneas.
- **Acepté:** precio en centavos enteros, CHECK de 0/1 y de estados, PK compuesta `(id_local, producto_id)` en `item_borrador`, `PRAGMA foreign_keys = ON`.
- **Descarté:** precio como REAL (error de redondeo en dinero); columna `total` en borrador (duplica dato calculable).
- **Cómo lo comprobé:** `pruebas_sqlite.sql` (C7 da CHECK y FOREIGN KEY) y `PRAGMA integrity_check` / `foreign_key_check`.

### Entrada 14 · Semáforo de sincronización
- **Pedí:** consulta que clasifique solicitudes PENDIENTE contra `snapshot_servidor`.
- **Acepté:** `UPDATE … FROM` con CTE que calcula gravedad por ítem (rojo > amarillo > verde) y `group_concat` para motivos.
- **Descarté:** primera versión con JOIN simple (borrador sin ítems quedaba PENDIENTE para siempre; se cambió a LEFT JOIN → RECHAZADO).
- **Cómo lo comprobé:** casos C2 a C6; repetición de la simulación da cola idéntica.

### Entrada 15 · Booleanos del CSV (t/f → 0/1)
- **Pedí:** cargar `producto_cache` desde CSV de psql con booleanos `t`/`f`.
- **Acepté:** guardar `t`/`f` en `snapshot_servidor` con CHECK y convertir a 0/1 con `CASE` al cargar `producto_cache`.
- **Descarté:** convertir en `.import` con script aparte (agrega paso sin ganar seguridad).
- **Cómo lo comprobé:** `cargar_cache.sql` con UPSERT y conversión CASE.

### Entrada 16 · Recarga del catálogo (bajas lógicas)
- **Pedí:** reflejar baja lógica sin romper borradores.
- **Acepté:** UPSERT (`INSERT … ON CONFLICT DO UPDATE`) con `eliminado = 1` (lápida); la fila queda y los ítems del borrador siguen apuntando a ella.
- **Descarté:** `DELETE FROM producto_cache` + recarga completa (rompería FK de `item_borrador`; con CASCADE se perderían borradores).
- **Cómo lo comprobé:** caso C4 (fila sigue con `eliminado = 1`; item del borrador intacto).

### Entrada 17 · Code review final con OpenCode (pendiente)
- **Pedí:** revisar todos los scripts de la cursada con el agente Plan de OpenCode.
- **Acepté / descarté:** _completar con los hallazgos reales de OpenCode y las decisiones humanas sobre cada uno_.
- **Cómo lo comprobé:** ver informe 3.c del TP8 (pendiente de completar).

---

## Consolidado de herramientas

| Unidad | IA usada | Qué se aceptó | Qué se descartó/corrigió |
|--------|----------|---------------|--------------------------|
| 4 | Claude / OpenCode | Descomposición FNBC, triggers DF1, tabla resumen + triggers | VACUUM FULL rutinario |
| 5 | OpenCode | Segmentación de roles, consulta conteo por rol | `GRANT ALL PRIVILEGES` a `app_web`; interpretación errónea de escalamiento |
| 6 | OpenCode | Scripts pg_dump/pg_restore, tareas rutinarias, simulacro | — |
| 7 | Claude | Modelo documental embebido, consultas MongoDB | MongoDB como fuente de verdad |
| 8 | Claude | Esquema SQLite STRICT, semáforo con CTE, UPSERT con lápida | Precio REAL, DELETE+recarga completa, JOIN simple en semáforo |

**Firma / fecha:** Agustín Ponti, David Rodrigues  2026-11-09