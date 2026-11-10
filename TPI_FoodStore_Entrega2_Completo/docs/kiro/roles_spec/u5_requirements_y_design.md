# Especificación Kiro - Roles y Permisos Food Store

## Requirements
El sistema requiere segmentar los accesos bajo el principio de mínimo privilegio para mitigar accesos indebidos a datos sensibles de los clientes. Se definen 4 perfiles de grupo y 2 de conexión.

## Design
*   **rol_app_lectura**: Habilita acceso de solo lectura (SELECT) en tablas públicas. Necesario para que el frontend renderice los catálogos.
*   **rol_app_escritura**: Habilita inserción, actualización y borrado (INSERT, UPDATE, DELETE). Necesario para el backend y gestión de pedidos.
*   **rol_soporte**: Permite acceder a datos operativos sin otorgar control sobre la infraestructura de la base de datos.
*   **rol_reportes**: Habilita lectura de datos agregados. Restringe el acceso a nivel de columna (ej. omite emails).
*   **app_web**: Rol de conexión principal de la aplicación.
*   **admin_datos**: Rol de conexión administrativo para gestión de información por el equipo.
