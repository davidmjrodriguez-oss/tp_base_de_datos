-- ============================================================
-- Cambios que el PREPARADOR hace en la copia del servidor para armar
-- los casos C2 y C4 (la tablet NO hace nada de esto: solo consulta).
-- Se ejecutan después de que la tablet guardó sus borradores.
-- ============================================================

-- C2: el servidor sube el precio de las papas ($1800,00 -> $2000,00)
UPDATE producto SET precio_centavos = 200000 WHERE id = 3;

-- C4: baja lógica del choripán (la fila queda; solo cambia la marca)
UPDATE producto SET eliminado = TRUE, disponible = FALSE WHERE id = 6;
