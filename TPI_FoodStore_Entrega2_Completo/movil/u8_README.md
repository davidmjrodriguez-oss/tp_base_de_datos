# Food Store · TP8 · La base de la tablet

Base de Datos II · TUP · UTN · 2026. La tablet del food truck guarda borradores sin señal; PostgreSQL decide.
**El móvil propone, el servidor dispone.** `SIMULADO_APROBADO` no es una venta.

## Estructura
```
food-store/
├── README.md
├── movil/                       # SQLite (la tablet)
│   ├── schema_sqlite.sql        # consigna 1.b (incluye snapshot_servidor)
│   ├── cargar_cache.sql         # UPSERT de producto_cache desde la instantánea
│   ├── pruebas_sqlite.sql       # consigna 1.c (COMMIT, ROLLBACK, C1, C7)
│   ├── semaforo.sql             # consigna 2.b
│   ├── ver_cola.sql             # muestra cola_sync
│   ├── casos/                   # C5/C3, C2/C4, recarga, aceptación C2, C6
│   ├── simulacion_completa.py   # (opcional) corre todo de punta a punta
│   ├── servidor_snapshot.csv    # consigna 2.a (última instantánea exportada)
│   └── foodstore_movil.db       # base final tras los casos
├── postgres/                    # PostgreSQL de PRUEBAS (datos inventados)
│   ├── 01_esquema_prueba.sql    # tablas + vista v_snapshot_movil
│   ├── 02_casos_servidor.sql    # cambios del preparador para C2 y C4
│   └── 03_verificacion_servidor.sql
└── docs/
    ├── informe.pdf              # 1.a, 2.c, 3.a, 3.b y 3.c
    ├── evidencia_casos.txt      # salida real de la simulación
    ├── kiro/                    # requirements.md · design.md · tasks.md
    ├── bitacora_ia.md
    └── DUIA.md
```

## Orden para crear todo desde cero
Requisitos: PostgreSQL 16+, SQLite 3.37+ (`sqlite3`), todo sobre una **copia de pruebas**.

```bash
# 0. PostgreSQL de pruebas (nunca la base real)
createdb foodstore_prueba
psql -d foodstore_prueba -f postgres/01_esquema_prueba.sql
psql -d foodstore_prueba -f postgres/03_verificacion_servidor.sql     # línea base

# 1. Base de la tablet + instantánea inicial
cd movil
rm -f foodstore_movil.db
sqlite3 foodstore_movil.db < schema_sqlite.sql
psql -d foodstore_prueba -c "\copy (SELECT * FROM v_snapshot_movil ORDER BY id) TO 'servidor_snapshot.csv' CSV HEADER"
sqlite3 foodstore_movil.db ".import --csv --skip 1 servidor_snapshot.csv snapshot_servidor"
sqlite3 foodstore_movil.db < cargar_cache.sql
sqlite3 foodstore_movil.db < pruebas_sqlite.sql                       # 1.c (limpia sus datos al final)

# 2. C5 y C3
sqlite3 foodstore_movil.db < casos/fase1_borradores_C5_C3.sql
sqlite3 foodstore_movil.db < semaforo.sql
sqlite3 -header foodstore_movil.db < ver_cola.sql

# 3. C2 y C4: borradores, cambio en el servidor, instantánea nueva, semáforo
sqlite3 foodstore_movil.db < casos/fase2_borradores_C2_C4.sql
psql -d foodstore_prueba -f ../postgres/02_casos_servidor.sql
psql -d foodstore_prueba -c "\copy (SELECT * FROM v_snapshot_movil ORDER BY id) TO 'servidor_snapshot.csv' CSV HEADER"
sqlite3 foodstore_movil.db "DELETE FROM snapshot_servidor;"
sqlite3 foodstore_movil.db ".import --csv --skip 1 servidor_snapshot.csv snapshot_servidor"
sqlite3 foodstore_movil.db < semaforo.sql
sqlite3 -header foodstore_movil.db < ver_cola.sql

# 4. C4: recargar catálogo; C2: el cliente acepta
sqlite3 foodstore_movil.db < cargar_cache.sql
sqlite3 -header foodstore_movil.db < casos/fase3_C4_recarga_catalogo.sql
sqlite3 foodstore_movil.db < casos/fase4_C2_cliente_acepta.sql
sqlite3 foodstore_movil.db < semaforo.sql
sqlite3 -header foodstore_movil.db < ver_cola.sql

# 5. C6: mismo UUID → error de clave primaria; repetir el semáforo no cambia nada
sqlite3 foodstore_movil.db < casos/fase5_C6_reenvio.sql
sqlite3 foodstore_movil.db < semaforo.sql
sqlite3 -header foodstore_movil.db < ver_cola.sql

# 6. PostgreSQL: pedidos y stock sin cambios (comparar con la línea base)
psql -d foodstore_prueba -f ../postgres/03_verificacion_servidor.sql
```

Atajo sin `sqlite3` en la terminal: `cd movil && python3 simulacion_completa.py` ejecuta los mismos pasos y muestra la salida.

## Notas
- `PRAGMA foreign_keys = ON;` es por conexión: cada script lo repite. Sin eso, SQLite no controla las claves foráneas (se probó).
- Con `sqlite3`, un error dentro de un script no lo frena (salvo `.bail on`); los errores esperados de C6 y C7 aparecen en pantalla.
- Datos inventados; sin contraseñas, mails ni datos personales reales.
