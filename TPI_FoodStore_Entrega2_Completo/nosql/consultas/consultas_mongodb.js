// ============================================================================
// TP Unidad 7 · NoSQL · Food Store · Consultas documentales sobre MongoDB
// Motor: MongoDB (base documental adoptada por la cátedra)
// Colección: pedidos
//
// Estructura del documento (ver modelo en u7_informe.md):
// {
//   _id: <pedido.id>,
//   fecha, estado, total,
//   cliente: { id, nombre, apellido, email },   // objeto embebido
//   lineas: [ { detalle_id, producto_id, producto, cantidad, precio_unitario } ]
// }
// ============================================================================

// --------------------------------------------------------------------------
// Consulta 1: Pedidos con estado = ENTREGADO
// Comparar con PostgreSQL: cantidad de pedidos ENTREGADOS y sus IDs
// --------------------------------------------------------------------------
print('=== Consulta 1: Pedidos ENTREGADO ===');
var entregados = db.pedidos.find({ estado: 'ENTREGADO' }).toArray();
printjson(entregados);
print('Cantidad MongoDB: ' + entregados.length);
print('Esperado PostgreSQL: 3 (ajustar a datos reales)');
print('');

// --------------------------------------------------------------------------
// Consulta 2: Pedidos que contienen un producto específico (Gaseosa 500 ml)
// --------------------------------------------------------------------------
print('=== Consulta 2: Pedidos con producto "Gaseosa 500 ml" ===');
var gaseosa = db.pedidos.find({ 'lineas.producto': /Gaseosa 500 ml/i }).toArray();
printjson(gaseosa);
print('Cantidad MongoDB: ' + gaseosa.length);
print('Esperado PostgreSQL: 3 (ajustar a datos reales)');
print('');

// --------------------------------------------------------------------------
// Consulta 3: Pedidos de valor alto (umbral 4d ≈ doble del ticket mínimo)
// --------------------------------------------------------------------------
print('=== Consulta 3: Pedidos de valor alto (total > 4000) ===');
var valorAlto = db.pedidos.find({ total: { $gt: 4000 } }).sort({ total: -1 }).toArray();
printjson(valorAlto);
print('Cantidad MongoDB: ' + valorAlto.length);
print('');

// --------------------------------------------------------------------------
// Consulta 4: Total vendido por estado (agregación)
// Verifica coherencia: total del pedido = Σ (cantidad × precio_unitario)
// --------------------------------------------------------------------------
print('=== Consulta 4: Total vendido por estado (agregación) ===');
var porEstado = db.pedidos.aggregate([
  { $group: { _id: '$estado', cantidad: { $sum: 1 }, total_vendido: { $sum: '$total' } } },
  { $sort: { _id: 1 } }
]).toArray();
printjson(porEstado);
print('');

// --------------------------------------------------------------------------
// Consulta 5: Verificación de integridad - totales vs líneas
// Cada línea: subtotal = cantidad × precio_unitario
// Suma de subtotales debe coincidir con total del pedido
// --------------------------------------------------------------------------
print('=== Consulta 5: Verificación de integridad de totales ===');
var inconsistencias = db.pedidos.aggregate([
  {
    $project: {
      _id: 1,
      total_declarado: '$total',
      total_calculado: {
        $sum: {
          $map: {
            input: '$lineas',
            as: 'l',
            in: { $multiply: ['$$l.cantidad', '$$l.precio_unitario'] }
          }
        }
      },
      num_lineas: { $size: '$lineas' }
    }
  },
  {
    $match: {
      $expr: { $ne: ['$total_declarado', '$total_calculado'] }
    }
  }
]).toArray();
printjson(inconsistencias);
print('Inconsistencias encontradas: ' + inconsistencias.length + ' (esperado: 0)');
print('');

// --------------------------------------------------------------------------
// Consulta 6: Pedidos sin líneas (debería ser 0)
// --------------------------------------------------------------------------
print('=== Consulta 6: Pedidos sin líneas ===');
var sinLineas = db.pedidos.find({ $or: [{ lineas: { $exists: false } }, { lineas: { $eq: [] } }] }).toArray();
printjson(sinLineas);
print('Cantidad: ' + sinLineas.length + ' (esperado: 0)');
print('');

// --------------------------------------------------------------------------
// Consulta 7: Cliente con más pedidos (top clientes)
// --------------------------------------------------------------------------
print('=== Consulta 7: Top clientes por cantidad de pedidos ===');
var topClientes = db.pedidos.aggregate([
  { $group: { _id: '$cliente.id', nombre: { $first: '$cliente.nombre' }, cantidad_pedidos: { $sum: 1 }, total_gastado: { $sum: '$total' } } },
  { $sort: { cantidad_pedidos: -1 } },
  { $limit: 5 }
]).toArray();
printjson(topClientes);
print('');

// --------------------------------------------------------------------------
// Consulta 8: Ingresos por mes (agregación temporal)
// --------------------------------------------------------------------------
print('=== Consulta 8: Ingresos por mes ===');
var ingresosMes = db.pedidos.aggregate([
  { $match: { estado: 'ENTREGADO' } },
  {
    $group: {
      _id: { $substr: ['$fecha', 0, 7] },  // YYYY-MM
      total_mes: { $sum: '$total' },
      pedidos_mes: { $sum: 1 }
    }
  },
  { $sort: { _id: 1 } }
]).toArray();
printjson(ingresosMes);

// ============================================================================
// Fin de consultas MongoDB
// ============================================================================