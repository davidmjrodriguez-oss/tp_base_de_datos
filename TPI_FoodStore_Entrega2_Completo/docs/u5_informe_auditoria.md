# Informe de Auditoría

**Configuración del Servidor (postgresql.conf)**
*   `log_connections = on`
*   `log_disconnections = on`
*   `log_statement = 'mod'`

**Análisis de Mecanismos de Auditoría**
*   **Información Útil**: El log nativo permite identificar la marca de tiempo (cuándo), el usuario conectado (quién), la IP o el socket de origen (desde dónde) y la consulta exacta ejecutada (qué).
*   **Limitaciones**: Con las herramientas nativas queda fuera el detalle granular de qué valores específicos contenía la fila afectada antes de un `UPDATE` o `DELETE`. Para obtener el detalle fila por fila, se requeriría configurar la extensión `pgaudit`.
*   **Seguridad del Archivo de Log**: El archivo de log es, en sí mismo, un activo altamente sensible porque revela la estructura de las tablas, consultas frecuentes y posibles intentos de inyección. Solo el administrador del motor de base de datos y los administradores del sistema operativo deben tener permisos de lectura sobre este archivo.
