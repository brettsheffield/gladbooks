DROP VIEW salesstatement;
CREATE VIEW salesstatement AS
SELECT
        'ORG_NAME' as type,
        o.id,
        NULL AS salesinvoice,
        '0001-01-01' AS taxpoint,
        NULL AS issued,
        NULL AS due,
        o.name || ' (' || o.orgcode || ')' AS ref,
        NULL AS subtotal,
        NULL AS tax,
        NULL AS total
FROM organisation_current o
UNION
SELECT
        'SI' as type,
        si.organisation AS id,
        si.salesinvoice,
        DATE(si.taxpoint) AS taxpoint,
        DATE(si.issued) AS issued,
        DATE(si.due) as due,
        'Invoice: ' || si.ref AS ref,
        format_accounting(si.subtotal) AS subtotal,
        format_accounting(si.tax) AS tax,
        format_accounting(si.total) AS total
FROM salesinvoice_current si
UNION
SELECT
        'SP' AS type,
        sp.organisation AS id,
        NULL AS salesinvoice,
        DATE(transactdate) AS taxpoint,
        NULL AS issued,
        NULL AS due,
        'Payment Received' AS ref,
        NULL AS subtotal,
        NULL AS tax,
        format_accounting(amount) AS total
FROM salespayment_current sp
UNION
SELECT
        'TOTAL' AS type,
        o.id AS id,
        NULL AS salesinvoice,
        NULL AS taxpoint,
        NULL AS issued,
        NULL AS due,
        'Total Amount Due' AS ref,
        NULL AS subtotal,
        NULL AS tax,
        format_accounting(
                COALESCE(oi.invoiced, 0) - COALESCE(op.paid,0)
        ) AS total
FROM organisation o
LEFT JOIN organisation_invoiced oi ON o.id = oi.id
LEFT JOIN organisation_paid op ON o.id = op.id
ORDER BY taxpoint ASC
;
