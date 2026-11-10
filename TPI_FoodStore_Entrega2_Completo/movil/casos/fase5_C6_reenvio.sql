-- Fase 5 · C6: reenviar la MISMA solicitud (mismo UUID que C5).
-- Esperado: ERROR UNIQUE constraint failed (clave primaria) y ninguna fila nueva.
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('e5000000-0000-4000-8000-0000000000c5', 'b5000000-0000-4000-8000-0000000000c5');
