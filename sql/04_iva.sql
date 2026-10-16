-- =====================================================================
-- 04 · IVA mes a mes (Lección 4)
-- =====================================================================

-- Débito (ventas) y crédito (compras) por período. Las notas de crédito restan.
CREATE VIEW iva_mensual AS
WITH debito AS (
    SELECT v.periodo, sum(v.iva * t.signo)::bigint AS debito
    FROM venta v
    JOIN tipo_documento t ON t.codigo = v.tipo_doc
    GROUP BY v.periodo
),
credito AS (
    SELECT f.periodo, sum(f.iva * t.signo)::bigint AS credito
    FROM factura f
    JOIN tipo_documento t ON t.codigo = f.tipo_doc
    GROUP BY f.periodo
)
SELECT d.periodo, d.debito, c.credito
FROM debito d
JOIN credito c ON c.periodo = d.periodo;

-- IVA a pagar con arrastre de remanente de crédito fiscal (CTE recursivo).
CREATE VIEW posicion_iva AS
WITH RECURSIVE meses AS (
    SELECT row_number() OVER (ORDER BY periodo) AS n, periodo, debito, credito
    FROM iva_mensual
),
posicion AS (
    SELECT n, periodo, debito, credito,
           0::bigint                     AS remanente_anterior,
           greatest(debito - credito, 0) AS iva_a_pagar,
           greatest(credito - debito, 0) AS remanente_siguiente
    FROM meses
    WHERE n = 1

    UNION ALL

    SELECT m.n, m.periodo, m.debito, m.credito,
           p.remanente_siguiente,
           greatest(m.debito - m.credito - p.remanente_siguiente, 0),
           greatest(m.credito + p.remanente_siguiente - m.debito, 0)
    FROM posicion p
    JOIN meses m ON m.n = p.n + 1
)
SELECT periodo, debito, credito, remanente_anterior, iva_a_pagar, remanente_siguiente
FROM posicion;
