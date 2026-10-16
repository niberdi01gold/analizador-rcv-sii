-- =====================================================================
-- 03 · Transformar: del staging a las tablas limpias (Lecciones 3 y 4)
-- Las filas con RUT inválido, fecha imposible, fecha fuera del período o
-- montos no numéricos quedan fuera. ON CONFLICT hace la carga repetible.
-- =====================================================================

-- ---------------------------------------------------------------- compras
INSERT INTO proveedor (rut, razon_social)
SELECT DISTINCT rut_proveedor, razon_social
FROM stg_compra
WHERE rut_valido(rut_proveedor)
ON CONFLICT (rut) DO NOTHING;

INSERT INTO factura (tipo_doc, proveedor_id, folio, fecha, periodo, neto, iva, total)
SELECT s.tipo_doc::smallint,
       p.id,
       a_numero(s.folio),
       a_fecha(s.fecha_docto),
       s.periodo,
       a_numero(s.monto_neto),
       a_numero(s.monto_iva),
       a_numero(s.monto_total)
FROM stg_compra s
JOIN proveedor p ON p.rut = s.rut_proveedor
WHERE a_fecha(s.fecha_docto) < s.periodo + interval '1 month'
  AND a_numero(s.monto_neto)  IS NOT NULL
  AND a_numero(s.monto_iva)   IS NOT NULL
  AND a_numero(s.monto_total) IS NOT NULL
ON CONFLICT (tipo_doc, proveedor_id, folio) DO NOTHING;

-- ----------------------------------------------------------------- ventas
INSERT INTO cliente (rut, razon_social)
SELECT DISTINCT rut_cliente, razon_social
FROM stg_venta
WHERE rut_valido(rut_cliente)
ON CONFLICT (rut) DO NOTHING;

INSERT INTO venta (tipo_doc, cliente_id, folio, fecha, periodo, neto, iva, total)
SELECT s.tipo_doc::smallint,
       c.id,
       a_numero(s.folio),
       a_fecha(s.fecha_docto),
       s.periodo,
       a_numero(s.monto_neto),
       a_numero(s.monto_iva),
       a_numero(s.monto_total)
FROM stg_venta s
JOIN cliente c ON c.rut = s.rut_cliente
WHERE a_fecha(s.fecha_docto) < s.periodo + interval '1 month'
  AND a_numero(s.monto_neto)  IS NOT NULL
  AND a_numero(s.monto_iva)   IS NOT NULL
  AND a_numero(s.monto_total) IS NOT NULL
ON CONFLICT (tipo_doc, cliente_id, folio) DO NOTHING;
