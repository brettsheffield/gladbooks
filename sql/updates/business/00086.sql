CREATE OR REPLACE VIEW salesinvoice_unpaid AS
SELECT  sic.id,
        sic.salesinvoice,
        sic.salesorder,
        sic.period,
        sic.ponumber,
        sic.taxpoint,
        sic.endpoint,
        sic.issued,
        sic.due,
        sic.organisation,
        sic.orgcode,
        sic.invoicenum,
        sic.ref,
        sic.subtotal,
        sic.tax,
        sic.total,
        COALESCE(SUM(sip.amount), '0.00') AS paid,
        sic.age
FROM salesinvoice_current sic
LEFT JOIN salespaymentallocation_current sip
ON sic.id = sip.salesinvoice
GROUP BY
        sic.id,
        sic.salesinvoice,
        sic.salesorder,
        sic.period,
        sic.ponumber,
        sic.taxpoint,
        sic.endpoint,
        sic.issued,
        sic.due,
        sic.organisation,
        sic.orgcode,
        sic.invoicenum,
        sic.ref,
        sic.subtotal,
        sic.tax,
        sic.total,
        sic.age
HAVING COALESCE(SUM(sip.amount), '0.00') < sic.total
;
