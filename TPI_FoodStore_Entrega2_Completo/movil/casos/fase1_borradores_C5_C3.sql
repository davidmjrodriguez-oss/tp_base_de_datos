-- Fase 1 (instantánea inicial). Dos borradores:
--   C5: sin cambios            -> esperado SIMULADO_APROBADO
--   C3: más unidades que stock -> esperado RECHAZADO (Combo feria: quedan 5, pide 6)
PRAGMA foreign_keys = ON;

BEGIN;
-- C5
INSERT INTO pedido_borrador (id_local, usuario, forma_pago)
VALUES ('b5000000-0000-4000-8000-0000000000c5', 'cliente_demo_05', 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
SELECT 'b5000000-0000-4000-8000-0000000000c5', id, 2, precio_centavos FROM producto_cache WHERE id = 1;
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('e5000000-0000-4000-8000-0000000000c5', 'b5000000-0000-4000-8000-0000000000c5');

-- C3
INSERT INTO pedido_borrador (id_local, usuario, forma_pago)
VALUES ('b3000000-0000-4000-8000-0000000000c3', 'cliente_demo_03', 'TARJETA');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
SELECT 'b3000000-0000-4000-8000-0000000000c3', id, 6, precio_centavos FROM producto_cache WHERE id = 8;
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('e3000000-0000-4000-8000-0000000000c3', 'b3000000-0000-4000-8000-0000000000c3');
COMMIT;
