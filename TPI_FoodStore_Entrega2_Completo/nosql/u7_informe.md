# TP Unidad 7 – NoSQL y nuevas formas de almacenamiento · Food Store

**Integrantes:** Agustín Ponti, David Rodrigues  **Repositorio:** https://github.com/AgustinPonti/TPI-FoodStore-Entrega2

## 1. Modelo documental (Consignas 1–3)

**Tablas PostgreSQL involucradas:** `pedido` (PK id; FK usuario_id), `detalle_pedido` (PK id; FK pedido_id, producto_id), `usuario` (PK id), `producto` (PK id). _Adaptar a los nombres reales._

**Colección `pedidos`:**

```
{
  _id: <pedido.id>,                 // ID de origen conservado
  fecha, estado, total,
  cliente:  { id, nombre, apellido, email },          // objeto embebido (copia)
  lineas: [ { detalle_id, producto_id, producto,       // arreglo embebido
              cantidad, precio_unitario } ]
}
```

**Reglas de integridad a conservar:**
1. `total` del pedido = Σ (cantidad × precio_unitario) de sus líneas (verificado con consulta antes y después).
2. Cada línea conserva el `precio_unitario` histórico y el `producto_id` de origen; ningún pedido queda sin líneas.

**Qué se embebió y por qué:** las líneas y los datos básicos del cliente se incluyen en el documento porque se leen siempre junto al pedido, las líneas no existen sin él y el precio histórico debe quedar congelado. El catálogo completo de productos y los datos completos de usuario quedan fuera (se referencian por id) porque cambian de forma independiente.

## 2. Consultas y verificación (Consignas 4–5)

Evidencias: _pegar capturas/salidas de `consultas_mongodb.js`_.

Umbral 4d: 5000, justificado como pedido de valor alto (≈ doble del ticket mínimo típico). _Ajustar a sus datos._

| Consulta | Cantidad PostgreSQL | Cantidad MongoDB | Coinciden IDs |
|---|---|---|---|
| Estado = ENTREGADO | _3 (esperado)_ | _3_ | _Sí/No_ |
| Producto = Gaseosa 500ml | _3 (esperado)_ | _3_ | _Sí/No_ |

Diferencias detectadas y correcciones: _completar (p. ej. mayúsculas/minúsculas en estado, nombre de producto con espacios, pedidos sin líneas)._

## 3. Evaluación con IA (Consignas 6–7)

**Prompt usado:** _"Food Store usa PostgreSQL con pedido/detalle_pedido normalizados. Casi siempre leemos el pedido completo con sus líneas y necesitamos coherencia entre cantidades y precios. Compará PostgreSQL y MongoDB para este subconjunto."_ Pegar el resumen de la respuesta (sin transcripción extensa).

**Contraste de dos afirmaciones** (ejemplos a verificar con ustedes mismos):
1. _"MongoDB permite leer el pedido completo en una sola operación"_ → verificado con `find` en el laboratorio; doc: MongoDB Manual, Embedding.
2. _"PostgreSQL garantiza integridad referencial con claves foráneas"_ → verificado con documentación oficial de PostgreSQL (constraints) y en MongoDB no existe equivalente nativo.

## Conclusión (≤ 200 palabras)

_Borrador:_ Para el subconjunto pedidos, MongoDB resulta adecuado como modelo de lectura: el pedido con sus líneas y precios históricos se recupera en un solo documento, sin joins, lo que simplifica el acceso frecuente a pedidos completos. Sin embargo, PostgreSQL ofrece integridad referencial, restricciones y transacciones multi-tabla que protegen la coherencia entre cantidades, precios y totales, y el resto de Food Store (productos, stock, usuarios) es altamente relacional. Recomendamos mantener PostgreSQL como fuente de verdad y, solo si el volumen de lecturas lo justifica, usar MongoDB como réplica de lectura para pedidos. Criterios: (1) patrón de acceso, (2) integridad y consistencia.
