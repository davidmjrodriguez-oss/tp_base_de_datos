-- Muestra la cola de sincronización (resultado del semáforo).
SELECT substr(solicitud_uuid, 1, 8) AS solicitud, substr(id_local, 1, 8) AS borrador, estado, motivo
FROM cola_sync
ORDER BY rowid;
