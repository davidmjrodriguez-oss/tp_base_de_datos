-- Fase 2 (todavía con la instantánea inicial en el catálogo). Dos borradores:
--   C2: papas fritas al precio visto ($1800); después el servidor lo sube -> esperado CONFLICTO
--   C4: choripán; después el servidor lo da de baja                      -> esperado RECHAZADO
PRAGMA foreign_keys = ON;

BEGIN;
-- C2
INSERT INTO pedido_borrador (id_local, usuario, forma_pago)
VALUES ('b2000000-0000-4000-8000-0000000000c2', 'cliente_demo_02', 'TRANSFERENCIA');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
SELECT 'b2000000-0000-4000-8000-0000000000c2', id, 2, precio_centavos FROM producto_cache WHERE id = 3;
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('e2000000-0000-4000-8000-0000000000c2', 'b2000000-0000-4000-8000-0000000000c2');

-- C4
INSERT INTO pedido_borrador (id_local, usuario, forma_pago)
VALUES ('b4000000-0000-4000-8000-0000000000c4', 'cliente_demo_04', 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
SELECT 'b4000000-0000-4000-8000-0000000000c4', id, 1, precio_centavos FROM producto_cache WHERE id = 6;
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('e4000000-0000-4000-8000-0000000000c4', 'b4000000-0000-4000-8000-0000000000c4');
COMMIT;
