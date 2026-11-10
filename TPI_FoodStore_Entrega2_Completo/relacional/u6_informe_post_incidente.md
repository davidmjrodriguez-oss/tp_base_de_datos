# Informe Post-Incidente · Simulacro de Desastre · Food Store

**Unidad:** 6 · Mantenimiento de una Base de Datos  
**Motor:** PostgreSQL 16+  
**Fecha:** 2026-11-09  
**Responsable:** Agustin Ponti  
**Base de prueba:** `food_store_sana` → `food_store_restaurada`

---

## 1. Resumen del incidente simulado

Se simuló una pérdida total del servidor de base de datos del entorno de pruebas
Food Store (corrupción catastrófica de disco o falla del servidor). La base de
producción se considera destruida y debe restaurarse desde el último respaldo
disponible contra reloj.

---

## 2. Procedimiento ejecutado

| Paso | Acción | Resultado |
|------|--------|-----------|
| 1 | Crear base de origen `food_store_sana` con datos de ejemplo (6 tablas, 2 pedidos, 3 detalles) | ✅ OK |
| 2 | Generar respaldo con `pg_dump -F c -b` (formato custom, comprimido, con large objects) | ✅ OK |
| 3 | Simular desastre: `DROP DATABASE` de la base de destino + `CREATE DATABASE` vacía | ✅ OK |
| 4 | Restaurar con `pg_restore -v` midiendo el tiempo | ✅ OK |
| 5 | Verificar integridad: conteo de filas, huella MD5, FK huérfanas, prueba de lectura/escritura | ✅ OK |

---

## 3. Tiempo de restauración

| Métrica | Valor |
|---------|-------|
| Tamaño del archivo de respaldo | ~15 KB (base de prueba pequeña) |
| Tiempo de `pg_dump` (respaldo) | < 1 segundo |
| Tiempo de `pg_restore` (restauración) | < 1 segundo |
| Tiempo total del simulacro (paso 1 a paso 5) | < 10 segundos |
| RTO objetivo (Recovery Time Objective) | < 5 minutos para bases de producción reales |
| RPO objetivo (Recovery Point Objective) | < 1 hora (respaldos horarios de WAL) |

**Nota:** En una base de producción real de Food Store (varios GB, miles de pedidos),
el tiempo de restauración dependerá del tamaño del respaldo, la velocidad de disco
y si se usa formato custom (`pg_restore`) o SQL plano (`psql`). Se recomienda
probar con la base real en entorno de staging antes de considerar el plan válido.

---

## 4. Resultados de verificación

### 4.1 Conteo de filas tras restauración

| Tabla | Filas esperadas | Filas restauradas | ¿Coinciden? |
|-------|-----------------|-------------------|-------------|
| categoria | 3 | 3 | ✅ |
| producto | 3 | 3 | ✅ |
| etiqueta | 3 | 3 | ✅ |
| producto_etiqueta | 3 | 3 | ✅ |
| pedido | 2 | 2 | ✅ |
| detalle_pedido | 3 | 3 | ✅ |

### 4.2 Huella MD5 (productos)

- Antes del desastre: `md5(string_agg(id||':'||nombre,...))` sobre `food_store_sana`
- Después de restauración: mismo valor sobre `food_store_restaurada` → ✅ Coinciden

### 4.3 Integridad referencial (FK huérfanas)

Todas las consultas de verificación devolvieron **0 filas** → ✅ No hay huérfanas

### 4.4 Prueba de lectura/escritura

Inserción de prueba dentro de transacción con rollback → ✅ La base restaurada acepta escrituras

---

## 5. Decisiones de diseño del plan de mantenimiento

| Decisión | Justificación |
|----------|---------------|
| `pg_dump -F c` (formato custom) | Permite restauración selectiva y es más compacto que SQL plano |
| Respaldo completo diario a las 02:00 | Ventana de bajo uso; cubre el 100% de los datos |
| Archivado de WAL cada 30 min | Permite PITR (Point-in-Time Recovery) y reduce el RPO a < 1 hora |
| VACUUM (no FULL) semanal | No bloquea lecturas; suficiente para carga OLTP de Food Store |
| VACUUM FULL solo en ventanas de mantenimiento | Bloquea la tabla; solo para reducción de bloat severo |
| ANALYZE tras cargas masivas | Mantiene las estadísticas del optimizador actualizadas |

---

## 6. Lecciones aprendidas y mejoras

1. **Probar con datos reales:** El simulacro se ejecutó sobre una base de prueba pequeña. Es obligatorio repetirlo con una copia de la base de producción en staging antes del despliegue.
2. **Automatizar la verificación:** El paso 5 (verificación de integridad) debe incluirse en el script de restauración para fallar rápido si algo falta.
3. **Documentar credenciales:** El usuario y contraseña de `pg_dump`/`pg_restore` deben estar en un archivo de credenciales protegido (`.pgpass`), no en el script.
4. **Retención de respaldos:** Mantener al menos 7 respaldos diarios, 4 semanales y 12 mensuales para cubrir diferentes escenarios de recuperación.

---

## 7. Conclusión

El simulacro de desastre se ejecutó con éxito: la base se restauró desde el respaldo
en menos de 1 segundo (entorno de prueba), todas las tablas conservaron sus datos,
la integridad referencial se mantuvo intacta y la base aceptó operaciones de lectura
y escritura tras la restauración. El plan de mantenimiento de la Unidad 6 se
considera **válido para entornos de prueba**; para producción se debe validar con
la base real y medir el tiempo de restauración bajo carga.

**Firma / fecha:** Agustín Ponti, David Rodrigues  2026-11-09