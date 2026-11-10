-- Fase 4 · C2: el cliente ACEPTA el precio nuevo.
-- Se actualiza el precio del borrador con el de la instantánea y se crea una
-- solicitud NUEVA (UUID nuevo). La solicitud vieja queda en CONFLICTO como historial.
PRAGMA foreign_keys = ON;

BEGIN;
UPDATE item_borrador
SET precio_centavos_visto = (SELECT s.precio_centavos FROM snapshot_servidor s WHERE s.id = item_borrador.producto_id)
WHERE id_local = 'b2000000-0000-4000-8000-0000000000c2';

INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('e2000000-0000-4000-8000-0000000001c2', 'b2000000-0000-4000-8000-0000000000c2');
COMMIT;
