-- ============================================================
-- Food Store · TP8 · PostgreSQL de PRUEBAS (copia con datos inventados)
-- Crea el mínimo del servidor que necesita la simulación y la vista
-- v_snapshot_movil (parada 5 del apunte).
-- Uso:  createdb foodstore_prueba
--       psql -d foodstore_prueba -f postgres/01_esquema_prueba.sql
-- NUNCA correr esto contra la base real del proyecto.
-- ============================================================

DROP VIEW  IF EXISTS v_snapshot_movil;
DROP TABLE IF EXISTS detalle_pedido;
DROP TABLE IF EXISTS pedido;
DROP TABLE IF EXISTS producto;

CREATE TABLE producto (
    id               INTEGER PRIMARY KEY,
    nombre           TEXT        NOT NULL,
    precio_centavos  INTEGER     NOT NULL CHECK (precio_centavos >= 0),
    stock            INTEGER     NOT NULL CHECK (stock >= 0),
    disponible       BOOLEAN     NOT NULL DEFAULT TRUE,
    eliminado        BOOLEAN     NOT NULL DEFAULT FALSE,   -- baja lógica (lápida)
    -- columnas que NO viajan a la tablet:
    costo_centavos   INTEGER     NOT NULL DEFAULT 0,
    proveedor_interno TEXT
);

CREATE TABLE pedido (
    id          SERIAL PRIMARY KEY,
    usuario     TEXT        NOT NULL,
    forma_pago  TEXT        NOT NULL CHECK (forma_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA')),
    fecha       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE detalle_pedido (
    pedido_id    INTEGER NOT NULL REFERENCES pedido(id),
    producto_id  INTEGER NOT NULL REFERENCES producto(id),
    cantidad     INTEGER NOT NULL CHECK (cantidad > 0),
    precio_centavos INTEGER NOT NULL,
    PRIMARY KEY (pedido_id, producto_id)
);

-- Datos inventados -------------------------------------------------
INSERT INTO producto (id, nombre, precio_centavos, stock, disponible, eliminado, costo_centavos, proveedor_interno) VALUES
 (1, 'Hamburguesa clasica', 350000, 20, TRUE,  FALSE, 180000, 'prov_demo_a'),
 (2, 'Hamburguesa doble',   480000, 15, TRUE,  FALSE, 260000, 'prov_demo_a'),
 (3, 'Papas fritas',        180000, 40, TRUE,  FALSE,  70000, 'prov_demo_b'),
 (4, 'Gaseosa 500 ml',      120000, 50, TRUE,  FALSE,  60000, 'prov_demo_c'),
 (5, 'Limonada casera',     150000, 10, TRUE,  FALSE,  40000, 'prov_demo_c'),
 (6, 'Choripan',            280000, 12, TRUE,  FALSE, 130000, 'prov_demo_d'),
 (7, 'Brownie',             160000,  8, FALSE, FALSE,  70000, 'prov_demo_b'),   -- no disponible
 (8, 'Combo feria',         520000,  5, TRUE,  FALSE, 300000, 'prov_demo_a');   -- poco stock

INSERT INTO pedido (usuario, forma_pago, fecha) VALUES
 ('cliente_demo_01', 'EFECTIVO',      '2026-10-10 12:00:00+00'),
 ('cliente_demo_02', 'TRANSFERENCIA', '2026-10-10 12:30:00+00');
INSERT INTO detalle_pedido VALUES (1, 1, 2, 350000), (2, 3, 1, 180000);

-- Parada 5: la instantánea que viaja a la tablet ------------------
-- Solo columnas de producto (nada de costo, proveedor ni usuarios).
-- Incluye eliminados y no disponibles: son las "lápidas" que permiten
-- a la tablet saber que algo dejó de existir.
CREATE VIEW v_snapshot_movil AS
SELECT id,
       nombre,
       precio_centavos,
       stock,
       disponible,
       eliminado,
       to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS fecha_copia
FROM producto;
