CREATE OR REPLACE VIEW organisationstatement AS
SELECT
        'SI' as type,
        si.organisation AS id,
        si.id AS lineid,
        DATE(si.taxpoint) AS taxpoint,
        DATE(si.issued) AS issued,
        DATE(si.due) as due,
        si.ref AS ref,
        'Invoice: ' || si.ref AS description,
        format_accounting(si.subtotal) AS subtotal,
        format_accounting(si.tax) AS tax,
        format_accounting(si.total) AS total
FROM salesinvoice_current si
UNION
SELECT
        'SP' AS type,
        sp.organisation AS id,
        sp.id AS lineid,
        DATE(transactdate) AS taxpoint,
        NULL AS issued,
        NULL AS due,
        'Payment Received' AS ref,
        'Payment Received' AS description,
        NULL AS subtotal,
        NULL AS tax,
        format_accounting(amount) AS total
FROM salespayment_current sp
UNION
SELECT
        'TOTAL' AS type,
        o.id AS id,
        NULL AS lineid,
        NULL AS taxpoint,
        NULL AS issued,
        NULL AS due,
        'Total Amount Due' AS ref,
        'Total Amount Due' AS description,
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
