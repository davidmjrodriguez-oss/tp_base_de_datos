# Diseño · base de la tablet

## Motores y responsabilidades
| Motor | Rol | Quién manda |
|---|---|---|
| PostgreSQL | Fuente de verdad: precio, stock, pedidos, ventas | El servidor |
| SQLite (tablet) | Copia de lectura del catálogo + borradores + cola | Nadie: solo propone |

## Flujo
1. PostgreSQL publica `v_snapshot_movil` (solo columnas de producto, con lápidas) → CSV.
2. La tablet importa el CSV en `snapshot_servidor` y hace UPSERT en `producto_cache` (nunca borra filas).
3. Sin señal, el cliente arma un borrador: `pedido_borrador` + `item_borrador` + una fila `PENDIENTE` en `cola_sync`, todo en una transacción.
4. El semáforo compara cada solicitud PENDIENTE con `snapshot_servidor`: rojo (RECHAZADO) > amarillo (CONFLICTO) > verde (SIMULADO_APROBADO).

## Decisiones
- Precios en centavos enteros; tablas STRICT con CHECK; `PRAGMA foreign_keys = ON` en cada conexión.
- `solicitud_uuid` como clave primaria de `cola_sync`: la idempotencia la da la base.
- Bajas lógicas: la fila queda con `eliminado = 1` para no romper las claves foráneas de los borradores.
- Booleanos de psql (`t`/`f`) se guardan tal cual en `snapshot_servidor` con CHECK y se convierten a 0/1 al cargar `producto_cache`.
- La simulación nunca escribe en PostgreSQL.
