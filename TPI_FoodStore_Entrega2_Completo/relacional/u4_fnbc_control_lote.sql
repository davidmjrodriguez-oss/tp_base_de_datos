-- =====================================================================
-- TP Unidad 4 - Parte 1: Análisis y aplicación de la FNBC
-- Caso: ControlLoteAlmacen (Food Store, extensión mayorista)
-- Motor: PostgreSQL 16.  Ejecutar con:  psql -d <base> -f tp_fnbc_control_lote.sql
-- El script es re-ejecutable (limpia lo que crea).
-- =====================================================================

\set ON_ERROR_STOP on
\pset pager off

-- ---------------------------------------------------------------------
-- 0. Limpieza y tablas maestras mínimas (se asumen existentes en el TP)
-- ---------------------------------------------------------------------
DROP VIEW  IF EXISTS v_control_lote_almacen CASCADE;
DROP TABLE IF EXISTS control_lote, responsable_deposito, control_lote_almacen CASCADE;
DROP TABLE IF EXISTS lote, deposito, usuario CASCADE;
DROP FUNCTION IF EXISTS fn_chk_unico_responsable_por_lote_deposito() CASCADE;
DROP FUNCTION IF EXISTS fn_chk_cambio_deposito_responsable() CASCADE;

CREATE TABLE lote     (id BIGINT PRIMARY KEY, codigo VARCHAR(30) NOT NULL);
CREATE TABLE deposito (id BIGINT PRIMARY KEY, nombre VARCHAR(60) NOT NULL);
CREATE TABLE usuario  (id BIGINT PRIMARY KEY, nombre VARCHAR(60) NOT NULL);

INSERT INTO lote     VALUES (501,'L-501'),(502,'L-502'),(503,'L-503'),(504,'L-504');
INSERT INTO deposito VALUES (30,'Depósito Norte'),(31,'Depósito Sur'),(32,'Depósito Este');
INSERT INTO usuario  VALUES (801,'Responsable 801'),(802,'Responsable 802'),(803,'Responsable 803');

-- ---------------------------------------------------------------------
-- 1. Esquema original e instancia de ejemplo (tal cual el enunciado)
-- ---------------------------------------------------------------------
CREATE TABLE control_lote_almacen (
    lote_id                BIGINT NOT NULL REFERENCES lote(id),
    deposito_id            BIGINT NOT NULL REFERENCES deposito(id),
    responsable_control_id BIGINT NOT NULL REFERENCES usuario(id),
    PRIMARY KEY (lote_id, deposito_id)
);

INSERT INTO control_lote_almacen VALUES
    (501, 30, 801),
    (502, 30, 801),
    (503, 31, 802);

\echo
\echo '=== 1. Instancia original ==='
SELECT * FROM control_lote_almacen ORDER BY lote_id;

-- ---------------------------------------------------------------------
-- 2. Evidencia de las dependencias funcionales y de la violación de FNBC
--    DF1: {LoteID, DepositoID} -> ResponsableControlID   (es la PK)
--    DF2: ResponsableControlID -> DepositoID             (violatoria)
-- ---------------------------------------------------------------------
\echo
\echo '=== 2a. DF2 se cumple en la instancia: ningún responsable en >1 depósito (debe dar 0 filas) ==='
SELECT responsable_control_id
FROM control_lote_almacen
GROUP BY responsable_control_id
HAVING COUNT(DISTINCT deposito_id) > 1;

\echo
\echo '=== 2b. El determinante de DF2 NO es superclave: se repite (801 aparece 2 veces) ==='
SELECT responsable_control_id, COUNT(*) AS apariciones
FROM control_lote_almacen
GROUP BY responsable_control_id
HAVING COUNT(*) > 1;

\echo
\echo '=== 2c. Redundancia: el hecho "801 pertenece al depósito 30" está almacenado varias veces ==='
SELECT responsable_control_id, deposito_id, COUNT(*) AS veces_repetido
FROM control_lote_almacen
GROUP BY responsable_control_id, deposito_id
ORDER BY 1;

-- ---------------------------------------------------------------------
-- 3. Las tres anomalías clásicas sobre la instancia (cada una se revierte)
-- ---------------------------------------------------------------------
\echo
\echo '=== 3a. ANOMALÍA DE INSERCIÓN ==='
\echo 'Registrar que el responsable 803 pertenece al depósito 32, sin que aún controle ningún lote:'
DO $$
BEGIN
    BEGIN
        INSERT INTO control_lote_almacen (lote_id, deposito_id, responsable_control_id)
        VALUES (NULL, 32, 803);
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'RECHAZADO: %', SQLERRM;
    END;
END $$;

\echo
\echo '=== 3b. ANOMALÍA DE BORRADO ==='
BEGIN;
\echo 'Antes: ¿sabemos a qué depósito pertenece el responsable 802?'
SELECT DISTINCT deposito_id FROM control_lote_almacen WHERE responsable_control_id = 802;
DELETE FROM control_lote_almacen WHERE lote_id = 503;   -- se retira el único lote que controlaba 802
\echo 'Después de borrar el lote 503: el dato "802 pertenece al depósito 31" desapareció (debe dar 0 filas)'
SELECT DISTINCT deposito_id FROM control_lote_almacen WHERE responsable_control_id = 802;
ROLLBACK;

\echo
\echo '=== 3c. ANOMALÍA DE ACTUALIZACIÓN ==='
BEGIN;
\echo 'Se traslada el responsable 801 al depósito 31, pero se actualiza solo la fila del lote 501:'
UPDATE control_lote_almacen SET deposito_id = 31 WHERE lote_id = 501 AND responsable_control_id = 801;
\echo 'Resultado: 801 queda en dos depósitos a la vez (DF2 violada, la base no lo impide):'
SELECT * FROM control_lote_almacen WHERE responsable_control_id = 801 ORDER BY lote_id;
SELECT responsable_control_id, COUNT(DISTINCT deposito_id) AS depositos_distintos
FROM control_lote_almacen GROUP BY responsable_control_id HAVING COUNT(DISTINCT deposito_id) > 1;
ROLLBACK;

-- ---------------------------------------------------------------------
-- 4. Descomposición sin pérdida (algoritmo FNBC)
--    Dependencia violatoria X -> Y con X = {ResponsableControlID}, Y = {DepositoID}
--      R1 = X u Y   = (ResponsableControlID, DepositoID)
--      R2 = R - Y   = (LoteID, ResponsableControlID)
--    Atributo común: ResponsableControlID, que es clave (superclave) de R1.
-- ---------------------------------------------------------------------
CREATE TABLE responsable_deposito (
    responsable_control_id BIGINT PRIMARY KEY REFERENCES usuario(id),
    deposito_id            BIGINT NOT NULL REFERENCES deposito(id)
);

CREATE TABLE control_lote (
    lote_id                BIGINT NOT NULL REFERENCES lote(id),
    responsable_control_id BIGINT NOT NULL REFERENCES responsable_deposito(responsable_control_id),
    PRIMARY KEY (lote_id, responsable_control_id)
);

CREATE INDEX idx_control_lote_responsable ON control_lote (responsable_control_id);

-- Vista de compatibilidad: reconstruye la relación original con una reunión natural
-- (el único atributo en común es responsable_control_id).
CREATE VIEW v_control_lote_almacen AS
SELECT cl.lote_id,
       rd.deposito_id,
       cl.responsable_control_id
FROM control_lote cl
NATURAL JOIN responsable_deposito rd;

-- ---------------------------------------------------------------------
-- 4 bis. Preservación de la DF1 original {Lote, Depósito} -> Responsable.
--   La descomposición en FNBC es sin pérdida pero NO siempre preserva
--   dependencias: DF1 ya no cabe en una sola tabla. Se vuelve a imponer
--   con triggers, para que no se pueda asignar a un mismo lote dos
--   responsables distintos del mismo depósito.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_chk_unico_responsable_por_lote_deposito() RETURNS trigger AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM control_lote otro
        JOIN responsable_deposito rd_otro ON rd_otro.responsable_control_id = otro.responsable_control_id
        JOIN responsable_deposito rd_nuevo ON rd_nuevo.responsable_control_id = NEW.responsable_control_id
        WHERE otro.lote_id = NEW.lote_id
          AND otro.responsable_control_id <> NEW.responsable_control_id
          AND rd_otro.deposito_id = rd_nuevo.deposito_id
    ) THEN
        RAISE EXCEPTION 'El lote % ya tiene otro responsable de control en el mismo depósito (viola LoteID,DepositoID -> ResponsableControlID)', NEW.lote_id;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_control_lote_unico_resp
BEFORE INSERT OR UPDATE ON control_lote
FOR EACH ROW EXECUTE FUNCTION fn_chk_unico_responsable_por_lote_deposito();

CREATE FUNCTION fn_chk_cambio_deposito_responsable() RETURNS trigger AS $$
BEGIN
    IF NEW.deposito_id IS DISTINCT FROM OLD.deposito_id AND EXISTS (
        SELECT 1
        FROM control_lote propio
        JOIN control_lote otro ON otro.lote_id = propio.lote_id
                              AND otro.responsable_control_id <> propio.responsable_control_id
        JOIN responsable_deposito rd_otro ON rd_otro.responsable_control_id = otro.responsable_control_id
        WHERE propio.responsable_control_id = NEW.responsable_control_id
          AND rd_otro.deposito_id = NEW.deposito_id
    ) THEN
        RAISE EXCEPTION 'Trasladar al responsable % al depósito % dejaría a un lote con dos responsables en el mismo depósito', NEW.responsable_control_id, NEW.deposito_id;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_responsable_deposito_cambio
BEFORE UPDATE OF deposito_id ON responsable_deposito
FOR EACH ROW EXECUTE FUNCTION fn_chk_cambio_deposito_responsable();

-- ---------------------------------------------------------------------
-- 5. Migración de la instancia de ejemplo (primero la tabla "padre")
-- ---------------------------------------------------------------------
INSERT INTO responsable_deposito (responsable_control_id, deposito_id)
SELECT DISTINCT responsable_control_id, deposito_id
FROM control_lote_almacen;

INSERT INTO control_lote (lote_id, responsable_control_id)
SELECT lote_id, responsable_control_id
FROM control_lote_almacen;

\echo
\echo '=== 5. Tablas descompuestas ==='
SELECT * FROM responsable_deposito ORDER BY 1;
SELECT * FROM control_lote ORDER BY 1, 2;

-- ---------------------------------------------------------------------
-- 6. Verificación de equivalencia: original vs. vista de compatibilidad
-- ---------------------------------------------------------------------
\echo
\echo '=== 6a. Original EXCEPT vista (debe dar 0 filas) ==='
SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen
EXCEPT
SELECT lote_id, deposito_id, responsable_control_id FROM v_control_lote_almacen;

\echo
\echo '=== 6b. Vista EXCEPT original (debe dar 0 filas: no hay tuplas espurias) ==='
SELECT lote_id, deposito_id, responsable_control_id FROM v_control_lote_almacen
EXCEPT
SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen;

\echo
\echo '=== 6c. Cantidad de filas: original vs vista (deben coincidir) ==='
SELECT (SELECT COUNT(*) FROM control_lote_almacen) AS filas_original,
       (SELECT COUNT(*) FROM v_control_lote_almacen) AS filas_vista;

\echo
\echo '=== 6d. Contenido de la vista de compatibilidad ==='
SELECT * FROM v_control_lote_almacen ORDER BY lote_id;

-- ---------------------------------------------------------------------
-- 7. Las anomalías ya no son posibles en el esquema descompuesto
-- ---------------------------------------------------------------------
\echo
\echo '=== 7a. Inserción: ahora se puede registrar 803 en el depósito 32 sin lote ==='
BEGIN;
INSERT INTO responsable_deposito VALUES (803, 32);
SELECT * FROM responsable_deposito WHERE responsable_control_id = 803;
ROLLBACK;

\echo
\echo '=== 7b. Borrado: al borrar el lote 503, el dato de 802 se conserva ==='
BEGIN;
DELETE FROM control_lote WHERE lote_id = 503;
SELECT * FROM responsable_deposito WHERE responsable_control_id = 802;
ROLLBACK;

\echo
\echo '=== 7c. Actualización: trasladar a 801 al depósito 31 es UN solo UPDATE y queda consistente ==='
BEGIN;
UPDATE responsable_deposito SET deposito_id = 31 WHERE responsable_control_id = 801;
SELECT * FROM v_control_lote_almacen WHERE responsable_control_id = 801 ORDER BY lote_id;
ROLLBACK;

\echo
\echo '=== 7d. La DF1 original sigue protegida: dos responsables del mismo depósito en un lote se rechazan ==='
BEGIN;
INSERT INTO usuario VALUES (804, 'Responsable 804');
INSERT INTO responsable_deposito VALUES (804, 30);        -- otro responsable del depósito 30
DO $$
BEGIN
    BEGIN
        INSERT INTO control_lote VALUES (501, 804);       -- el lote 501 ya lo controla 801 en el depósito 30
    EXCEPTION WHEN raise_exception THEN
        RAISE NOTICE 'RECHAZADO: %', SQLERRM;
    END;
END $$;
ROLLBACK;

-- Nota: control_lote_almacen (tabla original) se conserva a propósito como evidencia
-- de la migración. En un despliegue real se renombraría o eliminaría una vez validada
-- la migración, y las aplicaciones leerían v_control_lote_almacen.
