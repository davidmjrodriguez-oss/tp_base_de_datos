-- Fase 3 · C4: recargar el catálogo con la instantánea nueva (UPSERT, sin borrar).
-- Se corre DESPUÉS de .read cargar_cache.sql.
.print 'Catalogo disponible (el choripan ya no aparece):'
SELECT id, nombre FROM producto_cache WHERE disponible = 1 AND eliminado = 0 ORDER BY id;

.print 'Pero la fila sigue en producto_cache (lapida):'
SELECT id, nombre, disponible, eliminado FROM producto_cache WHERE id = 6;

.print 'Y el item del borrador C4 sigue apuntando a una fila que existe:'
SELECT i.id_local IS NOT NULL AS item_intacto, p.nombre
FROM item_borrador i JOIN producto_cache p ON p.id = i.producto_id
WHERE i.id_local = 'b4000000-0000-4000-8000-0000000000c4';
