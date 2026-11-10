#!/usr/bin/env python3
"""
Food Store · TP8 · Corre TODA la simulación de punta a punta (opcional).

Hace lo mismo que el README paso a paso, pero automático y con la salida
parecida a la de sqlite3. Sirve cuando no hay sqlite3 en la terminal.
Requiere: psql con acceso a la base de PRUEBAS `foodstore_prueba` y Python 3.
Uso (desde la carpeta movil/):   python3 simulacion_completa.py > ../docs/evidencia_casos.txt
Solo usa datos inventados. Nunca toca la base real.
"""
import csv
import os
import sqlite3
import subprocess
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
PG = os.path.join(AQUI, "..", "postgres")
DB = os.path.join(AQUI, "foodstore_movil.db")
CSV = os.path.join(AQUI, "servidor_snapshot.csv")
PGDB = os.environ.get("PGDATABASE", "foodstore_prueba")


def titulo(texto):
    print("\n" + "#" * 72 + f"\n# {texto}\n" + "#" * 72)


def psql(*args):
    r = subprocess.run(["psql", "-d", PGDB, "-X", *args], capture_output=True, text=True, cwd=AQUI)
    if r.returncode != 0:
        sys.exit(f"psql falló: {r.stderr}")
    print(r.stdout.rstrip())


def exportar_snapshot():
    comando = f"\\copy (SELECT * FROM v_snapshot_movil ORDER BY id) TO '{CSV}' CSV HEADER"
    print(f"psql> {comando}")
    psql("-c", comando)


def importar_snapshot(con):
    # equivalente a:  .import --csv --skip 1 servidor_snapshot.csv snapshot_servidor
    print(".import --csv --skip 1 servidor_snapshot.csv snapshot_servidor")
    con.execute("DELETE FROM snapshot_servidor")
    with open(CSV, newline="", encoding="utf-8") as f:
        filas = list(csv.reader(f))[1:]
    con.executemany("INSERT INTO snapshot_servidor VALUES (?,?,?,?,?,?,?)", filas)
    fecha = con.execute("SELECT max(fecha_copia) FROM snapshot_servidor").fetchone()[0]
    print(f"-- {len(filas)} filas importadas · fecha de la copia: {fecha}")


def mostrar(cur):
    if cur.description is None:
        return
    cols = [d[0] for d in cur.description]
    filas = cur.fetchall()
    print(" | ".join(cols))
    for fila in filas:
        print(" | ".join("" if v is None else str(v) for v in fila))
    if not filas:
        print("(0 filas)")


def correr(con, ruta):
    """Ejecuta un .sql mostrando resultados y errores, como sqlite3 (soporta .print)."""
    print(f"sqlite> .read {os.path.relpath(ruta, AQUI)}")
    buffer = ""
    with open(ruta, encoding="utf-8") as f:
        for linea in f:
            solo_comentarios = all(l.strip() == "" or l.strip().startswith("--") for l in buffer.splitlines())
            if solo_comentarios and linea.lstrip().startswith(".print"):
                print(linea.strip()[len(".print"):].strip().strip("'"))
                buffer = ""
                continue
            buffer += linea
            if sqlite3.complete_statement(buffer):
                sentencia, buffer = buffer.strip(), ""
                try:
                    mostrar(con.execute(sentencia))
                except sqlite3.Error as e:
                    print(f"Error: {e}")


def consulta(con, sql):
    print(f"sqlite> {sql}")
    mostrar(con.execute(sql))


def main():
    titulo("0. PostgreSQL de pruebas: esquema + línea base")
    psql("-q", "-f", os.path.join(PG, "01_esquema_prueba.sql"))
    print("-- Línea base ANTES de la simulación:")
    psql("-f", os.path.join(PG, "03_verificacion_servidor.sql"))

    titulo("1. Base de la tablet desde cero + instantánea inicial + catálogo")
    if os.path.exists(DB):
        os.remove(DB)
    con = sqlite3.connect(DB, isolation_level=None)  # autocommit: BEGIN/COMMIT los manejan los scripts
    correr(con, os.path.join(AQUI, "schema_sqlite.sql"))
    exportar_snapshot()
    importar_snapshot(con)
    correr(con, os.path.join(AQUI, "cargar_cache.sql"))
    consulta(con, "SELECT count(*) AS productos_en_cache, min(fecha_copia) AS fecha_de_la_copia FROM producto_cache")

    titulo("2. Consigna 1.c · pruebas (COMMIT, ROLLBACK, C1, C7)")
    correr(con, os.path.join(AQUI, "pruebas_sqlite.sql"))

    titulo("3. C5 y C3 (instantánea inicial)")
    correr(con, os.path.join(AQUI, "casos", "fase1_borradores_C5_C3.sql"))
    correr(con, os.path.join(AQUI, "semaforo.sql"))
    correr(con, os.path.join(AQUI, "ver_cola.sql"))

    titulo("4. C2 y C4: borradores, cambio en el servidor, instantánea nueva, semáforo")
    correr(con, os.path.join(AQUI, "casos", "fase2_borradores_C2_C4.sql"))
    print("-- El preparador cambia la copia del servidor (la tablet no toca nada):")
    psql("-f", os.path.join(PG, "02_casos_servidor.sql"))
    exportar_snapshot()
    importar_snapshot(con)
    correr(con, os.path.join(AQUI, "semaforo.sql"))
    correr(con, os.path.join(AQUI, "ver_cola.sql"))

    titulo("5. C4: recargar el catálogo (la fila queda, deja de verse)")
    correr(con, os.path.join(AQUI, "cargar_cache.sql"))
    correr(con, os.path.join(AQUI, "casos", "fase3_C4_recarga_catalogo.sql"))

    titulo("6. C2: el cliente acepta el precio nuevo -> solicitud nueva")
    correr(con, os.path.join(AQUI, "casos", "fase4_C2_cliente_acepta.sql"))
    correr(con, os.path.join(AQUI, "semaforo.sql"))
    correr(con, os.path.join(AQUI, "ver_cola.sql"))

    titulo("7. C6: reenviar la misma solicitud (mismo UUID)")
    consulta(con, "SELECT count(*) AS filas_en_cola FROM cola_sync")
    correr(con, os.path.join(AQUI, "casos", "fase5_C6_reenvio.sql"))
    consulta(con, "SELECT count(*) AS filas_en_cola_despues FROM cola_sync")
    antes = con.execute("SELECT group_concat(solicitud_uuid || estado || ifnull(motivo,''), '|') "
                        "FROM (SELECT * FROM cola_sync ORDER BY rowid)").fetchone()[0]
    print("-- Repetir la simulación (semáforo otra vez):")
    correr(con, os.path.join(AQUI, "semaforo.sql"))
    despues = con.execute("SELECT group_concat(solicitud_uuid || estado || ifnull(motivo,''), '|') "
                          "FROM (SELECT * FROM cola_sync ORDER BY rowid)").fetchone()[0]
    print(f"cola idéntica antes y después de repetir la simulación: {antes == despues}")
    correr(con, os.path.join(AQUI, "ver_cola.sql"))

    titulo("8. PostgreSQL: pedidos y stock NO cambiaron")
    psql("-f", os.path.join(PG, "03_verificacion_servidor.sql"))
    print("-- Cambios deliberados del preparador (C2 y C4), ninguno hecho por la tablet:")
    psql("-c", "SELECT id, nombre, precio_centavos, stock, disponible, eliminado FROM producto "
               "WHERE id IN (3, 6) ORDER BY id")

    con.execute("PRAGMA integrity_check")
    con.close()


if __name__ == "__main__":
    main()
