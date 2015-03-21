CREATE OR REPLACE VIEW salesinvoice_current AS
SELECT  sod.id,
        sod.salesinvoice,
        sod.salesorder,
        sod.period,
        sod.ponumber,
        sod.taxpoint,
        sod.endpoint,
        sod.issued,
        sod.due,
        so.organisation,
        o.orgcode,
        so.invoicenum,
        o.orgcode || '/' || to_char(invoicenum, 'FM0000') AS ref,
        roundhalfeven(COALESCE(sod.subtotal,
        SUM(COALESCE(soi.price, p.price_sell, '0.00') * soi.qty)),2) AS subtotal,
        COALESCE(sod.tax, sit.tax, '0.00') AS tax,
        roundhalfeven(COALESCE(sod.total, SUM(COALESCE(soi.price, p.price_sell, '0.00')
        * soi.qty) + COALESCE(sod.tax, sit.tax, '0.00')),2) AS total,
        date_part('day', current_timestamp - due) AS age
FROM salesinvoicedetail sod
INNER JOIN salesinvoice so ON so.id = sod.salesinvoice
LEFT JOIN salesinvoiceitem_current soi ON so.id = soi.salesinvoice
LEFT JOIN (
        SELECT sit.salesinvoice, SUM(sit.total) AS tax
        FROM salesinvoice_tax sit
        GROUP BY sit.salesinvoice
) sit ON so.id = sit.salesinvoice
LEFT JOIN product_current p ON p.product = soi.product
INNER JOIN organisation o ON o.id = so.organisation
GROUP BY sod.id, so.organisation, so.invoicenum, sit.tax, o.orgcode, sod.due;
