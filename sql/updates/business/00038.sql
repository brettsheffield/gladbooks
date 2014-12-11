CREATE OR REPLACE VIEW customer AS
SELECT *
FROM organisation_current
WHERE id IN (SELECT organisation FROM salesinvoice_current);

CREATE OR REPLACE VIEW accountsreceivable AS
SELECT
        o.id,
        o.name,
        o.orgcode,
        format_accounting(
                COALESCE(oi.invoiced, 0) - COALESCE(op.paid,0)
        ) AS total
FROM customer o
LEFT JOIN organisation_invoiced oi ON o.id = oi.id
LEFT JOIN organisation_paid op ON o.id = op.id
ORDER BY o.id ASC
;
