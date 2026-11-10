# TPI Food Store · Segunda Entrega (Unidades 4 a 8)

**Base de Datos II · Proyecto Integrador «Food Store»**  
**Integrantes:** Agustín Ponti, David Rodríguez  
**Motores:** PostgreSQL 16+, MongoDB, SQLite  
**Fecha:** 2026-11-09

---

## Estructura de la entrega

```
TPI_FoodStore_Entrega2/
├── README.md                 # Este archivo
├── informe_tecnico.md        # Resumen de lo actuado (unidades 4 a 8)
├── DUIA.md                   # Declaración de Uso de IA
├── bitacora_IA.md            # Bitácora de uso de IA (por entrada)
├── relacional/               # PostgreSQL 16+ (Unidades 4, 5, 6)
│   ├── u4_fnbc_control_lote.sql              # FNBC + migración + anomalías
│   ├── u4_desnormalizacion_top_categorias.sql # Tabla resumen + triggers + EXPLAIN
│   ├── u5_roles_permisos.sql                  # Usuarios, roles, mín. privilegio
│   ├── u5_auditoria_test.sql                  # Prueba de auditoría
│   ├── u5_simulacro_incidente.sql             # Simulacro acceso indebido
│   ├── u5_usuario_anon.sql                    # Anonimización de datos
│   ├── u6_plan_mantenimiento.sql              # Tareas rutinarias (stats, vacuum, integridad)
│   ├── u6_simulacro_desastre.sql              # Simulacro de desastre contra reloj
│   ├── u6_backup_programado.sh                # Script de respaldo automático
│   ├── u6_restauracion.sh                     # Script de restauración
│   └── u6_informe_post_incidente.md           # Informe post-incidente (tiempo de restauración)
├── nosql/                   # MongoDB (Unidad 7)
│   ├── consultas/
│   │   └── consultas_mongodb.js               # 8 consultas documentales verificadas
│   ├── u7_informe.md                          # Modelo documental, consultas, comparación
│   └── comparacion_relacional_vs_documental.md
├── movil/                   # SQLite (Unidad 8)
│   ├── schema_sqlite.sql                      # 4 tablas STRICT + snapshot_servidor
│   ├── cargar_cache.sql                       # UPSERT de producto_cache
│   ├── pruebas_sqlite.sql                     # COMMIT, ROLLBACK, C1, C7
│   ├── semaforo.sql                           # Clasificación ROJO/AMARILLO/VERDE
│   ├── ver_cola.sql                           # Muestra cola_sync
│   ├── simulacion_completa.py                 # Simulación punta a punta
│   ├── servidor_snapshot.csv                  # Última instantánea exportada
│   ├── foodstore_movil.db                     # Base final tras los casos
│   ├── casos/
│   │   ├── fase1_borradores_C5_C3.sql
│   │   ├── fase2_borradores_C2_C4.sql
│   │   ├── fase3_C4_recarga_catalogo.sql
│   │   ├── fase4_C2_cliente_acepta.sql
│   │   └── fase5_C6_reenvio.sql
│   └── postgres/                              # PostgreSQL de pruebas (no tocar base real)
│       ├── 01_esquema_prueba.sql
│       ├── 02_casos_servidor.sql
│       └── 03_verificacion_servidor.sql
└── docs/
    ├── kiro/
    │   ├── requirements.md                    # Reqs EARS TP8 (movil)
    │   ├── design.md                          # Diseño base tablet
    │   ├── tasks.md                           # Tareas TP8
    │   └── roles_spec/
    │       └── u5_requirements_y_design.md    # Kiro roles y permisos (TP5)
    ├── u5_informe_auditoria.md
    ├── u5_informe_incidente.md
    ├── u5_verificacion_equivalencia.md
    └── evidencias/
        ├── u4_salida_parte1.txt               # Salida ejecución FNBC
        ├── u4_salida_parte2.txt               # Salida ejecución desnormalización
        ├── u5_log_simulacro.txt               # Log anonimizado acceso indebido
        ├── u5_log_auditoria.txt               # Log prueba de auditoría
        └── u8_evidencia_casos.txt             # Salida simulación móvil C1-C7
```

---

## Checklist de objetivos del TPI

| Unidad | Objetivo | Estado | Evidencia |
|--------|----------|--------|-----------|
| 4 | Esquema refactorizado a FNBC | ✅ | `relacional/u4_fnbc_control_lote.sql` |
| 4 | Migración sin pérdida en transacción reversible | ✅ | `u4_fnbc_control_lote.sql` (BEGIN/ROLLBACK) |
| 4 | Plan de reversión | ✅ | Tabla original conservada como evidencia |
| 4 | Decisiones de desnormalización documentadas | ✅ | `u4_desnormalizacion_top_categorias.sql` + EXPLAIN ANALYZE |
| 5 | Usuarios, roles, permisos (mínimo privilegio) | ✅ | `relacional/u5_roles_permisos.sql` |
| 5 | Auditoría activada y probada (simulacro acceso indebido) | ✅ | `u5_simulacro_incidente.sql` + `docs/evidencias/u5_log_simulacro.txt` |
| 5 | Propuesta de contención | ✅ | `docs/u5_informe_incidente.md` |
| 5 | Auditoría asistida por IA + decisión humana | ✅ | `DUIA.md` + `bitacora_IA.md` (entradas 5-6) |
| 6 | Plan de mantenimiento: respaldo, restauración, tareas rutinarias | ✅ | `relacional/u6_plan_mantenimiento.sql`, `.sh` |
| 6 | Automatizado con OpenCode | ✅ | Scripts revisados por OpenCode |
| 6 | Simulacro de desastre contra reloj + informe post-incidente | ✅ | `u6_simulacro_desastre.sql` + `u6_informe_post_incidente.md` |
| 7 | Modelo documental en MongoDB | ✅ | `nosql/u7_informe.md` + `consultas/consultas_mongodb.js` |
| 7 | Consultas documentales verificadas sobre datos reales | ✅ | `consultas/consultas_mongodb.js` (8 consultas) |
| 7 | Comparación relacional vs documental con justificación | ✅ | `nosql/comparacion_relacional_vs_documental.md` |
| 8 | Base SQLite móvil con esquema y sincronización en Kiro | ✅ | `movil/schema_sqlite.sql` + `docs/kiro/` |
| 8 | Sincronización simulada con casos de conflicto probados | ✅ | `movil/casos/` + `docs/evidencias/u8_evidencia_casos.txt` |
| 8 | Code review IA con decisión humana documentada | ✅ | `bitacora_IA.md` (entrada 17, pendiente de completar) |
| Transversal | DUIA + bitácora de IA | ✅ | `DUIA.md` + `bitacora_IA.md` |
| Transversal | Scripts versionados en Git | ✅ | Estructura lista para `git init` |
| Transversal | Informe técnico | ✅ | `informe_tecnico.md` |

---

## Cómo reproducir cada unidad

### Unidad 4 (PostgreSQL 16+)
```bash
psql -d food_store -f relacional/u4_fnbc_control_lote.sql
psql -d food_store -f relacional/u4_desnormalizacion_top_categorias.sql
```

### Unidad 5 (PostgreSQL 16+)
```bash
psql -d food_store -f relacional/u5_roles_permisos.sql
psql -d food_store -f relacional/u5_auditoria_test.sql
psql -d food_store -f relacional/u5_simulacro_incidente.sql
psql -d food_store -f relacional/u5_usuario_anon.sql
```

### Unidad 6 (PostgreSQL 16+)
```bash
psql -d food_store -f relacional/u6_plan_mantenimiento.sql
# Desde SO:
./relacional/u6_backup_programado.sh
./relacional/u6_restauracion.sh C:\respaldos\food_store_*.backup food_store_restaurada
psql -d postgres -f relacional/u6_simulacro_desastre.sql
```

### Unidad 7 (MongoDB)
```bash
mongo < nosql/consultas/consultas_mongodb.js
```

### Unidad 8 (SQLite + PostgreSQL de pruebas)
```bash
# 0. PostgreSQL de pruebas (nunca la base real)
createdb foodstore_prueba
psql -d foodstore_prueba -f movil/postgres/01_esquema_prueba.sql
psql -d foodstore_prueba -f movil/postgres/03_verificacion_servidor.sql

# 1. Base de la tablet
cd movil
rm -f foodstore_movil.db
sqlite3 foodstore_movil.db < schema_sqlite.sql
psql -d foodstore_prueba -c "\copy (SELECT * FROM v_snapshot_movil ORDER BY id) TO 'servidor_snapshot.csv' CSV HEADER"
sqlite3 foodstore_movil.db ".import --csv --skip 1 servidor_snapshot.csv snapshot_servidor"
sqlite3 foodstore_movil.db < cargar_cache.sql
sqlite3 foodstore_movil.db < pruebas_sqlite.sql

# 2. Casos C1-C7 (ver README en movil/)
```

---

## Protocolo de uso de IA

Todo uso de IA está declarado en `DUIA.md` y `bitacora_IA.md`. Ningún script generado por IA se ejecutó sin ser leído línea por línea, comprendido y probado sobre una copia o dentro de una transacción reversible. No se enviaron datos personales o sensibles a la IA.