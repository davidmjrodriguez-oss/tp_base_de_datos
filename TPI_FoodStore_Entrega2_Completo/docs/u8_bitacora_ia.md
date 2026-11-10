# Bitácora de uso de IA · TP8

> Registro del uso de IA en este TP. Cada entrada dice qué se pidió, qué se aceptó, qué se descartó y por qué.
> Todo lo aceptado se leyó y se probó antes de usarlo (ver `docs/evidencia_casos.txt`).
> **Antes de entregar:** revisá cada entrada, ajustala a lo que realmente hiciste vos y agregá lo que hayas
> hecho con Kiro y OpenCode (la cátedra pide usarlos). Lo que no puedas explicar en la defensa cuenta como no hecho.

## Entrada 1 · Esquema de la tablet
- **Pedí:** las cuatro tablas SQLite STRICT de la consigna 1.b con sus CHECK y claves foráneas.
- **Acepté:** precio en centavos enteros, CHECK de 0/1 y de estados, clave primaria compuesta `(id_local, producto_id)` en `item_borrador`, y `PRAGMA foreign_keys = ON`.
- **Descarté:** guardar el precio como REAL (error de redondeo en dinero) y una columna `total` en el borrador (se puede calcular; guardarla duplica el dato).
- **Cómo lo comprobé:** `pruebas_sqlite.sql` (C7 da CHECK y FOREIGN KEY) y `PRAGMA integrity_check` / `foreign_key_check`.

## Entrada 2 · El semáforo
- **Pedí:** una sola consulta que clasifique cada solicitud PENDIENTE contra `snapshot_servidor`.
- **Acepté:** `UPDATE … FROM` con una CTE que calcula la gravedad por ítem y toma el máximo por solicitud (rojo > amarillo > verde), y el motivo con `group_concat`.
- **Descarté:** la primera versión con `JOIN` simple a `item_borrador`: una solicitud con borrador sin ítems quedaba PENDIENTE para siempre. Se cambió a `LEFT JOIN` y ahora da RECHAZADO ("el borrador no tiene items"). Se comprobó con una copia de la base.
- **Cómo lo comprobé:** casos C2 a C6 y la repetición de la simulación (la cola queda idéntica).

## Entrada 3 · Booleanos del CSV
- **Pedí:** cómo cargar `producto_cache` desde un CSV de psql, donde los booleanos vienen como `t`/`f`.
- **Acepté:** guardar `t`/`f` con CHECK en `snapshot_servidor` y convertir a 0/1 con `CASE` al cargar el catálogo. Si el CSV trajera `true`, la importación falla en vez de convertir mal en silencio (se probó).
- **Descarté:** convertir en el `.import` con un script aparte; agregaba un paso más sin ganar seguridad.

## Entrada 4 · Recarga del catálogo
- **Pedí:** cómo reflejar una baja lógica sin romper los borradores.
- **Acepté:** UPSERT (`INSERT … ON CONFLICT DO UPDATE`) y no `DELETE`: la fila queda con `eliminado = 1` y desaparece del catálogo por el filtro.
- **Descarté:** `DELETE FROM producto_cache` + recarga completa: la clave foránea de `item_borrador` lo impediría (y con `ON DELETE CASCADE` se perderían borradores).
- **Cómo lo comprobé:** caso C4 (la fila sigue y el ítem del borrador queda intacto).

## Entrada 5 · Code review con OpenCode (completar)
- **Pedí:** _completá con lo que le pediste a OpenCode en el agente Plan_.
- **Acepté / descarté:** _completá_ (al menos un hallazgo descartado con fundamento; ver informe 3.c).
