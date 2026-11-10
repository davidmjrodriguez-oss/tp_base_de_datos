-- ============================================================
-- Consigna 2.b · El semáforo
-- Compara cada solicitud PENDIENTE con snapshot_servidor y guarda estado y motivo
-- en cola_sync. Solo toca la base de la tablet: PostgreSQL no se modifica.
--   Rojo     RECHAZADO         producto inexistente / no disponible / dado de baja / sin stock
--   Amarillo CONFLICTO         sin rojo, pero cambió algún precio
--   Verde    SIMULADO_APROBADO todo coincide (NO es una venta)
-- Solo evalúa PENDIENTE: repetir la simulación no cambia nada.
-- ============================================================
PRAGMA foreign_keys = ON;

WITH problema_item AS (
    SELECT c.solicitud_uuid,
           CASE
               WHEN i.id_local IS NULL
                    THEN 2
               WHEN s.id IS NULL
                    THEN 2
               WHEN s.eliminado = 't' OR s.disponible = 'f' OR i.cantidad > s.stock
                    THEN 2
               WHEN i.precio_centavos_visto <> s.precio_centavos
                    THEN 1
               ELSE 0
           END AS gravedad,
           CASE
               WHEN i.id_local IS NULL
                    THEN 'el borrador no tiene items'
               WHEN s.id IS NULL
                    THEN 'producto ' || i.producto_id || ' no existe en el servidor'
               WHEN s.eliminado = 't'
                    THEN s.nombre || ' fue dado de baja'
               WHEN s.disponible = 'f'
                    THEN s.nombre || ' no esta disponible'
               WHEN i.cantidad > s.stock
                    THEN s.nombre || ': pide ' || i.cantidad || ' y quedan ' || s.stock
               WHEN i.precio_centavos_visto <> s.precio_centavos
                    THEN s.nombre || ': precio visto ' || i.precio_centavos_visto
                         || ' y actual ' || s.precio_centavos || ' centavos'
           END AS detalle
    FROM cola_sync c
    LEFT JOIN item_borrador i       ON i.id_local = c.id_local
    LEFT JOIN snapshot_servidor s   ON s.id = i.producto_id
    WHERE c.estado = 'PENDIENTE'
),
resultado AS (
    SELECT solicitud_uuid,
           CASE MAX(gravedad)
               WHEN 2 THEN 'RECHAZADO'
               WHEN 1 THEN 'CONFLICTO'
               ELSE        'SIMULADO_APROBADO'
           END AS estado,
           COALESCE(group_concat(detalle, '; '),
                    'todo coincide con la instantanea (simulado, no es una venta)') AS motivo
    FROM problema_item
    GROUP BY solicitud_uuid
)
UPDATE cola_sync
SET estado = resultado.estado,
    motivo = resultado.motivo
FROM resultado
WHERE cola_sync.solicitud_uuid = resultado.solicitud_uuid
  AND cola_sync.estado = 'PENDIENTE';
