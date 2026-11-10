-- ============================================================
-- Food Store · TP8 · Base de la tablet (SQLite 3.37+)
-- Se puede correr cuantas veces haga falta: recrea todo desde cero.
-- Uso:  sqlite3 foodstore_movil.db < schema_sqlite.sql
-- ============================================================
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS cola_sync;
DROP TABLE IF EXISTS item_borrador;
DROP TABLE IF EXISTS pedido_borrador;
DROP TABLE IF EXISTS producto_cache;
DROP TABLE IF EXISTS snapshot_servidor;

-- Copia local del catálogo. El precio es entero en centavos.
CREATE TABLE producto_cache (
    id               INTEGER PRIMARY KEY,
    nombre           TEXT    NOT NULL,
    precio_centavos  INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock_visto      INTEGER NOT NULL CHECK (stock_visto >= 0),
    disponible       INTEGER NOT NULL CHECK (disponible IN (0, 1)),
    eliminado        INTEGER NOT NULL CHECK (eliminado  IN (0, 1)),
    fecha_copia      TEXT    NOT NULL
) STRICT;

-- Borrador: lo que el cliente pidió en la feria. NO es una venta.
CREATE TABLE pedido_borrador (
    id_local    TEXT PRIMARY KEY,                       -- UUID generado en la tablet
    usuario     TEXT NOT NULL,                          -- nombre inventado, sin datos reales
    forma_pago  TEXT NOT NULL CHECK (forma_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA')),
    fecha       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
) STRICT;

CREATE TABLE item_borrador (
    id_local               TEXT    NOT NULL REFERENCES pedido_borrador (id_local),
    producto_id            INTEGER NOT NULL REFERENCES producto_cache (id),
    cantidad               INTEGER NOT NULL CHECK (cantidad > 0),
    precio_centavos_visto  INTEGER NOT NULL CHECK (precio_centavos_visto >= 0),
    PRIMARY KEY (id_local, producto_id)
) STRICT;

-- Cola de sincronización: una fila por solicitud (el UUID la hace idempotente).
CREATE TABLE cola_sync (
    solicitud_uuid  TEXT PRIMARY KEY,
    id_local        TEXT NOT NULL REFERENCES pedido_borrador (id_local),
    estado          TEXT NOT NULL DEFAULT 'PENDIENTE'
                    CHECK (estado IN ('PENDIENTE', 'CONFLICTO', 'RECHAZADO', 'SIMULADO_APROBADO')),
    motivo          TEXT
) STRICT;

-- Consigna 2.a: aquí se importa el CSV exportado desde PostgreSQL.
-- Los booleanos de psql llegan como 't' / 'f'.
CREATE TABLE snapshot_servidor (
    id               INTEGER PRIMARY KEY,
    nombre           TEXT    NOT NULL,
    precio_centavos  INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock            INTEGER NOT NULL CHECK (stock >= 0),
    disponible       TEXT    NOT NULL CHECK (disponible IN ('t', 'f')),
    eliminado        TEXT    NOT NULL CHECK (eliminado  IN ('t', 'f')),
    fecha_copia      TEXT    NOT NULL
) STRICT;
