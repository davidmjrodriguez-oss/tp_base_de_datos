# Requisitos · Food Store móvil (TP8)

Notación EARS. Cada requisito indica el caso que lo prueba.
Regla de oro: el móvil propone, el servidor dispone.

**REQ-01** WHEN el precio actual del servidor es distinto del precio visto en el borrador (y no hay rojo)
THE SYSTEM SHALL marcar la solicitud como CONFLICTO y guardar el motivo.
Se prueba con: **C2**

**REQ-02** WHEN algún ítem del borrador pide más unidades que el stock de la instantánea, o el producto no existe, no está disponible o fue dado de baja
THE SYSTEM SHALL marcar la solicitud como RECHAZADO (el rojo gana sobre el amarillo).
Se prueba con: **C3** y **C4**

**REQ-03** WHEN todos los ítems coinciden con la instantánea (existen, están disponibles, alcanza el stock y el precio es el mismo)
THE SYSTEM SHALL marcar la solicitud como SIMULADO_APROBADO, que no es una venta y no modifica PostgreSQL.
Se prueba con: **C5**

**REQ-04** WHEN llega una solicitud con un UUID que ya existe en cola_sync, o se repite la simulación
THE SYSTEM SHALL rechazar el duplicado por clave primaria y no reevaluar solicitudes que ya no están en PENDIENTE.
Se prueba con: **C6**

**REQ-05** WHEN la tablet está sin conexión
THE SYSTEM SHALL mostrar el catálogo disponible desde producto_cache.
Se prueba con: **C1**

**REQ-06** IF una cantidad es 0 o el producto no existe en producto_cache
THEN THE SYSTEM SHALL fallar con error y no dejar filas nuevas.
Se prueba con: **C7**
