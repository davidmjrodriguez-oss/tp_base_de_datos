#!/bin/bash
# =============================================================================
# Script de restauración · Food Store · PostgreSQL 16+
-- Automatizado con OpenCode (revisión de código)
-- Uso: ./restaurar_food_store.sh <archivo_backup> [nombre_base_destino]
# =============================================================================

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Uso: $0 <archivo_backup> [nombre_base_destino]"
    echo "Ejemplo: $0 C:\respaldos\food_store_20261109_020000.backup food_store_restaurada"
    exit 1
fi

ARCHIVO_BACKUP="$1"
DB_DESTINO="${2:-food_store_restaurada}"
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"

if [ ! -f "$ARCHIVO_BACKUP" ]; then
    echo "ERROR: El archivo de respaldo no existe: $ARCHIVO_BACKUP"
    exit 1
fi

echo "=== Inicio de restauración: $(date) ==="
echo "Archivo de respaldo: $ARCHIVO_BACKUP"
echo "Base de destino: $DB_DESTINO"

# 1. Crear base de destino (si no existe)
createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_DESTINO" 2>/dev/null || true

# 2. Restaurar desde el respaldo
pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -d "$DB_DESTINO" \
    -v "$ARCHIVO_BACKUP"

if [ $? -eq 0 ]; then
    echo "=== Restauración completada con éxito: $(date) ==="
else
    echo "=== ERROR en la restauración: $(date) ==="
    exit 1
fi

# 3. Verificación rápida de integridad
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DESTINO" -c "
    SELECT 'categoria' AS tabla, count(*) AS filas FROM categoria
    UNION ALL SELECT 'producto', count(*) FROM producto
    UNION ALL SELECT 'pedido', count(*) FROM pedido
    UNION ALL SELECT 'detalle_pedido', count(*) FROM detalle_pedido;
"

echo "=== Fin de restauración: $(date) ==="