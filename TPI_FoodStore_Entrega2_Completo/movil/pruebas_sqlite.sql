-- ============================================================
-- Consigna 1.c · Pruebas de la base de la tablet
-- Requiere: schema_sqlite.sql + snapshot importado + cargar_cache.sql
-- Al final borra sus datos de prueba para dejar la base lista para los casos C2-C6.
-- ============================================================
PRAGMA foreign_keys = ON;

.print '=== 1) COMMIT: borrador completo (borrador + items + solicitud) ==='
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario, forma_pago)
VALUES ('bf000000-0000-4000-8000-000000000001', 'cliente_demo_01', 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
SELECT 'bf000000-0000-4000-8000-000000000001', id, 2, precio_centavos FROM producto_cache WHERE id = 1;
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
SELECT 'bf000000-0000-4000-8000-000000000001', id, 1, precio_centavos FROM producto_cache WHERE id = 4;
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('ef000000-0000-4000-8000-000000000001', 'bf000000-0000-4000-8000-000000000001');
COMMIT;

SELECT (SELECT count(*) FROM pedido_borrador) AS borradores,
       (SELECT count(*) FROM item_borrador)   AS items,
       (SELECT count(*) FROM cola_sync)       AS solicitudes;   -- esperado: 1, 2, 1

.print '=== 1) ROLLBACK: otra operacion que se deshace ==='
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario, forma_pago)
VALUES ('bf000000-0000-4000-8000-000000000002', 'cliente_demo_02', 'TARJETA');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
SELECT 'bf000000-0000-4000-8000-000000000002', id, 3, precio_centavos FROM producto_cache WHERE id = 2;
SELECT count(*) AS borradores_dentro_de_la_transaccion FROM pedido_borrador;   -- esperado: 2
ROLLBACK;
SELECT count(*) AS borradores_despues_del_rollback FROM pedido_borrador;       -- esperado: 1

.print '=== C1) Catalogo disponible, sin conectarse al servidor ==='
-- Todo sale del archivo foodstore_movil.db: no hay red ni PostgreSQL en juego.
SELECT id, nombre, precio_centavos / 100.0 AS precio_pesos, stock_visto
FROM producto_cache
WHERE disponible = 1 AND eliminado = 0
ORDER BY nombre;

.print '=== C7) Cantidad en 0: da error y no deja filas ==='
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario, forma_pago)
VALUES ('bf000000-0000-4000-8000-000000000007', 'cliente_demo_07', 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('bf000000-0000-4000-8000-000000000007', 1, 0, 350000);   -- ERROR esperado: CHECK constraint failed
ROLLBACK;
SELECT (SELECT count(*) FROM pedido_borrador WHERE id_local LIKE 'bf000000-0000-4000-8000-000000000007') AS borrador_c7,
       (SELECT count(*) FROM item_borrador   WHERE id_local LIKE 'bf000000-0000-4000-8000-000000000007') AS items_c7;  -- esperado: 0, 0

.print '=== C7) Producto inexistente: da error y no deja filas ==='
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario, forma_pago)
VALUES ('bf000000-0000-4000-8000-000000000008', 'cliente_demo_08', 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('bf000000-0000-4000-8000-000000000008', 9999, 1, 100000);   -- ERROR esperado: FOREIGN KEY constraint failed
ROLLBACK;
SELECT (SELECT count(*) FROM pedido_borrador WHERE id_local LIKE 'bf000000-0000-4000-8000-000000000008') AS borrador_c7b,
       (SELECT count(*) FROM item_borrador   WHERE id_local LIKE 'bf000000-0000-4000-8000-000000000008') AS items_c7b;  -- esperado: 0, 0

.print '=== Totales finales (deben ser iguales a los del paso 1: 1 borrador, 2 items, 1 solicitud) ==='
SELECT (SELECT count(*) FROM pedido_borrador) AS borradores,
       (SELECT count(*) FROM item_borrador)   AS items,
       (SELECT count(*) FROM cola_sync)       AS solicitudes;

.print '=== Limpieza de los datos de prueba ==='
DELETE FROM cola_sync;
DELETE FROM item_borrador;
DELETE FROM pedido_borrador;
