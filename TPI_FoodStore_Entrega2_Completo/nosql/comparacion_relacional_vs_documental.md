# Comparación Relacional vs Documental · Food Store · Unidad 7

## Subconjunto modelado: Pedidos

| Aspecto | PostgreSQL (relacional) | MongoDB (documental) |
|---------|------------------------|----------------------|
| Estructura | `pedido` + `detalle_pedido` (tablas separadas, FK) | Colección `pedidos` con líneas embebidas |
| Lectura del pedido completo | Requiere JOIN entre `pedido` y `detalle_pedido` | Un solo `find()` por `_id` |
| Integridad referencial | FK nativas entre tablas | No hay FK nativas; se gestiona en aplicación |
| Precio histórico | Copia en `detalle_pedido.nombre_producto` / `precio_unitario` | Embebido en el array `lineas` |
| Transacciones multi-tabla | Soportadas (ACID) | Soportadas desde MongoDB 4.0+ (sesiones) |
| Esquema | Rígido (DDL obligatorio) | Flexible (documentos autocontenidos) |

## Decisión de tecnología seleccionada

**PostgreSQL se mantiene como fuente de verdad** para todo el dominio de Food Store
(productos, stock, pedidos, usuarios, categorías) porque:

1. El dominio es altamente relacional (categorías 1→N productos, productos N→N etiquetas, pedidos 1→N detalles).
2. Se requiere integridad referencial estricta (FK, restricciones de stock, transacciones todo-o-nada en pedidos).
3. El resto del sistema (API FastAPI, informes de negocio) ya está construido sobre PostgreSQL.

**MongoDB se usa solo como réplica de lectura para pedidos** si el volumen de lecturas lo justifica, porque:

1. El pedido con sus líneas y precios históricos se recupera en un solo documento, sin JOINs.
2. Es ideal para consultas de acceso frecuente a pedidos completos (pantalla de detalle de pedido, historial de cliente).
3. El precio histórico queda congelado en el documento, inmutable aunque cambie el catálogo.

## Criterios de selección

1. **Patrón de acceso:** MongoDB gana para lectura de pedidos completos; PostgreSQL gana para escritura y consultas analíticas complejas.
2. **Integridad y consistencia:** PostgreSQL ofrece FK nativas y transacciones multi-tabla más maduras.
3. **Criterio final:** Mantener PostgreSQL como fuente de verdad; usar MongoDB como réplica de lectura solo si el volumen de lecturas de pedidos justifica la complejidad adicional.