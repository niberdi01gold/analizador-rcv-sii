-- =====================================================================
-- 05 · Alertas automáticas (Lección 5)
-- Cada regla es un CTE con nombre; la vista las une con UNION ALL.
-- Uso:  SELECT * FROM alertas ORDER BY severidad, periodo;
-- =====================================================================

CREATE VIEW alertas AS
WITH
duplicados AS (
    SELECT 'posible duplicado'::text AS regla, 'alta'::text AS severidad,
           b.periodo, p.razon_social, b.folio, b.total,
           'repite el total del folio ' || a.folio AS detalle
    FROM factura a
    JOIN factura b
      ON  b.proveedor_id = a.proveedor_id
      AND b.tipo_doc     = a.tipo_doc
      AND b.total        = a.total
      AND b.folio        > a.folio
      AND b.fecha BETWEEN a.fecha AND a.fecha + 7
    JOIN proveedor p ON p.id = a.proveedor_id
),
iva_malo AS (
    SELECT 'IVA inconsistente', 'media', f.periodo, p.razon_social, f.folio, f.total,
           'IVA ' || f.iva || ', esperado ' || round(f.neto * 0.19)
    FROM factura f
    JOIN proveedor p ON p.id = f.proveedor_id
    WHERE f.tipo_doc IN (33, 61) AND abs(f.iva - round(f.neto * 0.19)) > 2
    UNION ALL
    SELECT 'IVA inconsistente', 'media', v.periodo, c.razon_social, v.folio, v.total,
           'IVA ' || v.iva || ', esperado ' || round(v.neto * 0.19)
    FROM venta v
    JOIN cliente c ON c.id = v.cliente_id
    WHERE v.tipo_doc IN (33, 61) AND abs(v.iva - round(v.neto * 0.19)) > 2
),
historia AS (
    SELECT p.razon_social, f.periodo, f.folio, f.total,
           count(*)             OVER w AS facturas_previas,
           avg(f.total)         OVER w AS promedio_previo,
           stddev_samp(f.total) OVER w AS desviacion_previa
    FROM factura f
    JOIN proveedor p ON p.id = f.proveedor_id
    WHERE f.tipo_doc = 33
    WINDOW w AS (PARTITION BY f.proveedor_id ORDER BY f.fecha, f.id
                 ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)
),
atipicos AS (
    SELECT 'monto atípico', 'media', periodo, razon_social, folio, total,
           round(total / promedio_previo, 1) || ' veces su promedio'
    FROM historia
    WHERE facturas_previas >= 5
      AND total > promedio_previo + 3 * desviacion_previa
      AND total >= promedio_previo * 2.5
),
primera AS (
    SELECT DISTINCT ON (f.proveedor_id) f.proveedor_id, f.periodo, f.folio, f.total
    FROM factura f
    ORDER BY f.proveedor_id, f.fecha, f.id
),
nuevos AS (
    SELECT 'proveedor nuevo con monto alto', 'media', pr.periodo, p.razon_social, pr.folio, pr.total,
           'primera factura del proveedor'
    FROM primera pr
    JOIN proveedor p ON p.id = pr.proveedor_id
    WHERE pr.periodo > (SELECT min(periodo) FROM factura)
      AND pr.total > (SELECT percentile_cont(0.9) WITHIN GROUP (ORDER BY total)
                      FROM factura WHERE tipo_doc = 33)
),
nc_huerfanas AS (
    SELECT 'nota de crédito sin factura', 'media', nc.periodo, p.razon_social, nc.folio, nc.total,
           'no hay facturas previas de este proveedor'
    FROM factura nc
    JOIN proveedor p ON p.id = nc.proveedor_id
    WHERE nc.tipo_doc = 61
      AND NOT EXISTS (
          SELECT 1 FROM factura f
          WHERE f.proveedor_id = nc.proveedor_id
            AND f.tipo_doc IN (33, 34)
            AND f.fecha <= nc.fecha)
)
SELECT * FROM duplicados
UNION ALL SELECT * FROM iva_malo
UNION ALL SELECT * FROM atipicos
UNION ALL SELECT * FROM nuevos
UNION ALL SELECT * FROM nc_huerfanas;
