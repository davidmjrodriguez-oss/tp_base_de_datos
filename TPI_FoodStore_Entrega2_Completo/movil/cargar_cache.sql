-- ============================================================
-- Carga (o recarga) producto_cache a partir de snapshot_servidor.
-- Es un UPSERT: NUNCA borra filas, porque item_borrador las referencia.
-- Un producto dado de baja llega con eliminado = 1 y deja de verse en el
-- catálogo, pero su fila queda (lápida).
-- ============================================================
PRAGMA foreign_keys = ON;

INSERT INTO producto_cache (id, nombre, precio_centavos, stock_visto, disponible, eliminado, fecha_copia)
SELECT id,
       nombre,
       precio_centavos,
       stock,
       CASE disponible WHEN 't' THEN 1 ELSE 0 END,
       CASE eliminado  WHEN 't' THEN 1 ELSE 0 END,
       fecha_copia
FROM snapshot_servidor
WHERE true
ON CONFLICT (id) DO UPDATE SET
    nombre          = excluded.nombre,
    precio_centavos = excluded.precio_centavos,
    stock_visto     = excluded.stock_visto,
    disponible      = excluded.disponible,
    eliminado       = excluded.eliminado,
    fecha_copia     = excluded.fecha_copia;
