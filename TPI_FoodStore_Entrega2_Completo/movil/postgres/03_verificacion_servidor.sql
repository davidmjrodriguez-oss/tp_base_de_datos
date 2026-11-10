-- ============================================================
-- Verificación: la simulación de la tablet no creó pedidos ni movió stock.
-- Se corre al principio (línea base) y al final; tienen que dar igual.
-- ============================================================
SELECT (SELECT count(*) FROM pedido)                      AS pedidos,
       (SELECT count(*) FROM detalle_pedido)              AS detalles,
       (SELECT sum(stock) FROM producto)                  AS stock_total,
       (SELECT md5(string_agg(id || ':' || stock, ',' ORDER BY id))
          FROM producto)                                  AS huella_stock;
