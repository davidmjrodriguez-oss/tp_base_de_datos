#!/bin/bash
# =============================================================================
# Script de respaldo programado · Food Store · PostgreSQL 16+
-- Automatizado con OpenCode (revisión de código)
-- Ejecutar vía cron (Linux) o Task Scheduler (Windows)
# =============================================================================

set -euo pipefail

# Configuración
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_NAME="food_store"
BACKUP_DIR="C:\respaldos"   # Windows: adaptar a la ruta real
RETENCION_DIAS=7

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVO_BACKUP="${BACKUP_DIR}/food_store_${TIMESTAMP}.backup"
ARCHIVO_LOG="${BACKUP_DIR}/backup_${TIMESTAMP}.log"

# Crear directorio de respaldos si no existe
mkdir -p "$BACKUP_DIR"

echo "=== Inicio de respaldo: $(date) ===" | tee -a "$ARCHIVO_LOG"

# Respaldo completo (formato custom, comprimido, con large objects)
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -d "$DB_NAME" \
    -F c -b -v \
    -f "$ARCHIVO_BACKUP" 2>&1 | tee -a "$ARCHIVO_LOG"

if [ $? -eq 0 ]; then
    echo "=== Respaldo completado: $(date) ===" | tee -a "$ARCHIVO_LOG"
    echo "Archivo: $ARCHIVO_BACKUP" | tee -a "$ARCHIVO_LOG"
else
    echo "=== ERROR en el respaldo: $(date) ===" | tee -a "$ARCHIVO_LOG"
    exit 1
fi

# Limpieza de respaldos antiguos (retención)
find "$BACKUP_DIR" -name "food_store_*.backup" -mtime +$RETENCION_DIAS -delete
find "$BACKUP_DIR" -name "backup_*.log" -mtime +$RETENCION_DIAS -delete

echo "=== Limpieza de respaldos antiguos completada ===" | tee -a "$ARCHIVO_LOG"

# Ejemplo de entrada en crontab (ejecutar diario a las 02:00):
# 0 2 * * * /ruta/al/script/backup_food_store.sh >> /var/log/food_store_backup.log 2>&1