-- ============================================================================
-- TP Unidad 6 · Mantenimiento de la Base de Datos · Food Store
-- Motor: PostgreSQL 16+
-- Plan de mantenimiento completo: respaldo programado, tareas rutinarias
-- (estadísticas, limpieza, verificación de integridad) y restauración.
--
-- Secciones:
--   1. Tareas rutinarias: ANALYZE, VACUUM, verificación de integridad
--   2. Respaldo programado (pg_dump) - esquema de comandos
--   3. Restauración (pg_restore / psql) - esquema de comandos
--   4. Simulacro de desastre contra reloj
-- ============================================================================

\set ON_ERROR_STOP on
\pset pager off

-- ============================================================================
-- 1. TAREAS RUTINARIAS
-- ============================================================================

\echo '=== 1.1 Verificación de integridad de las tablas del esquema Food Store ==='
-- pg_check_integrity equivalente: verificar que no hay páginas corruptas
-- (requiere superusuario o pg_read_all_stats)
SELECT
    schemaname,
    tablename,
    n_tup_ins AS filas_insertadas,
    n_tup_upd AS filas_actualizadas,
    n_tup_del AS filas_eliminadas,
    n_live_tup AS filas_vivas,
    n_dead_tup AS filas_muertas,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY tablename;

\echo
\echo '=== 1.2 Estadísticas: ANALYZE sobre todas las tablas del esquema ==='
-- Actualiza las estadísticas del optimizador para que las consultas sean rápidas.
-- Se recomienda ejecutar periódicamente (p. ej. semanalmente o tras cargas masivas).
ANALYZE VERBOSE categoria;
ANALYZE VERBOSE producto;
ANALYZE VERBOSE etiqueta;
ANALYZE VERBOSE producto_etiqueta;
ANALYZE VERBOSE pedido;
ANALYZE VERBOSE detalle_pedido;

\echo
\echo '=== 1.3 Limpieza: VACUUM (no FULL, para no bloquear lecturas) ==='
-- VACUUM recupera espacio de tuplas muertas sin bloquear la tabla.
-- VACUUM FULL bloquearía la tabla: solo se usa en ventanas de mantenimiento.
VACUUM (ANALYZE) categoria;
VACUUM (ANALYZE) producto;
VACUUM (ANALYZE) etiqueta;
VACUUM (ANALYZE) producto_etiqueta;
VACUUM (ANALYZE) pedido;
VACUUM (ANALYZE) detalle_pedido;

\echo
\echo '=== 1.4 Verificación de integridad referencial: claves foráneas huérfanas ==='
-- Verifica que no haya filas huérfanas en las FK del esquema.
-- Si alguna consulta devuelve filas, hay inconsistencia.
SELECT 'detalle_pedido sin pedido' AS problema, COUNT(*) AS cantidad
FROM detalle_pedido dp
LEFT JOIN pedido p ON p.id = dp.pedido_id
WHERE p.id IS NULL
UNION ALL
SELECT 'detalle_pedido sin producto', COUNT(*)
FROM detalle_pedido dp
LEFT JOIN producto pr ON pr.id = dp.producto_id
WHERE pr.id IS NULL
UNION ALL
SELECT 'producto_etiqueta sin producto', COUNT(*)
FROM producto_etiqueta pe
LEFT JOIN producto pr ON pr.id = pe.producto_id
WHERE pr.id IS NULL
UNION ALL
SELECT 'producto_etiqueta sin etiqueta', COUNT(*)
FROM producto_etiqueta pe
LEFT JOIN etiqueta e ON e.id = pe.etiqueta_id
WHERE e.id IS NULL
UNION ALL
SELECT 'producto con categoria inexistente o inactiva', COUNT(*)
FROM producto pr
LEFT JOIN categoria c ON c.id = pr.categoria_id
WHERE c.id IS NULL OR c.activo = FALSE;

\echo
\echo '=== 1.5 Tablas con bloat excesivo (más de 20% de espacio muerto) ==='
-- Ayuda a decidir cuándo programar un VACUUM FULL.
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS tamano_total,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS tamano_tabla,
    n_dead_tup AS tuplas_muertas,
    round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS pct_muertas
FROM pg_stat_user_tables
WHERE schemaname = 'public'
  AND (n_live_tup + n_dead_tup) > 0
  AND round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) > 20
ORDER BY pct_muertas DESC;

-- ============================================================================
-- 2. RESPALDO PROGRAMADO (pg_dump)
-- ============================================================================
-- Ejecutar desde el sistema operativo (no desde psql), p. ej. vía cron o Task Scheduler:
--
--   # Respaldo completo de la base food_store (formato custom, comprimido)
--   pg_dump -h localhost -U postgres -d food_store -F c -b -v -f "C:\respaldos\food_store_20261109.backup"
--
--   # Respaldo solo del esquema (DDL)
--   pg_dump -h localhost -U postgres -d food_store -s -v -f "C:\respaldos\food_store_schema_20261109.sql"
--
--   # Respaldo solo de datos (INSERTs)
--   pg_dump -h localhost -U postgres -d food_store -a -v -f "C:\respaldos\food_store_data_20261109.sql"
--
-- Programación sugerida (cron Linux / Task Scheduler Windows):
--   - Respaldo completo diario a las 02:00 AM
--   - Respaldo incremental de WAL cada 30 min (archivado de WAL habilitado)
--   - Retención: 7 diarios, 4 semanales, 12 mensuales

-- ============================================================================
-- 3. RESTAURACIÓN (pg_restore / psql)
-- ============================================================================
-- Ejecutar desde el sistema operativo:
--
--   # Restaurar respaldo completo (formato custom)
--   pg_restore -h localhost -U postgres -d food_store_restaurada -v "C:\respaldos\food_store_20261109.backup"
--
--   # Restaurar solo esquema
--   psql -h localhost -U postgres -d food_store_restaurada -f "C:\respaldos\food_store_schema_20261109.sql"
--
--   # Restaurar solo datos
--   psql -h localhost -U postgres -d food_store_restaurada -f "C:\respaldos\food_store_data_20261109.sql"
--
-- Previos a la restauración:
--   1. Crear la base de destino: createdb food_store_restaurada
--   2. Detener aplicaciones que usen la base (modo mantenimiento)
--   3. Verificar integridad del archivo de respaldo (pg_restore -l)

-- ============================================================================
-- 4. SIMULACRO DE DESASTRE CONTRA RELOJ
-- ============================================================================
-- Véase u6_simulacro_desastre.sql para el procedimiento paso a paso con
-- medición de tiempo de restauración e informe post-incidente.