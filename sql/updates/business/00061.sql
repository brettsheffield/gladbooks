DROP VIEW purchaseinvoice_current;
CREATE OR REPLACE VIEW purchaseinvoice_current AS
SELECT
        pi.id,
        pid.id as detailid,
        organisation,
        invoicenum,
        ref,
        ponumber,
        description,
        taxpoint,
        endpoint,
        issued,
        journal,
        due,
        subtotal,
        tax,
        total,
        pdf,
        pid.updated,
        pid.authuser,
        pid.clientip
FROM purchaseinvoice pi
INNER JOIN purchaseinvoicedetail pid ON pi.id = pid.purchaseinvoice
WHERE id IN (
        SELECT MAX(id)
        FROM purchaseinvoicedetail
        GROUP BY purchaseinvoice
);
