CREATE OR REPLACE VIEW salesorder_current AS
SELECT
        so.id,
        so.organisation,
        so.ordernum,
        sod.salesorder,
        sod.quotenumber,
        sod.ponumber,
        sod.description,
        sod.cycle,
        sod.start_date,
        sod.end_date,
        sod.is_open,
        sod.is_deleted,
        roundhalfeven(SUM(COALESCE(soi.price, p.price_sell, '0.00') * soi.qty),2) AS price,
        roundhalfeven(COALESCE(tx.tax, '0.00'),2) as tax,
        roundhalfeven(SUM(COALESCE(soi.price, p.price_sell, '0.00') * soi.qty) +
                        COALESCE(tx.tax, '0.00'),2) AS total
FROM salesorder so
INNER JOIN salesorderdetail sod ON so.id = sod.salesorder
LEFT JOIN salesorderitem_current soi ON so.id = soi.salesorder
INNER JOIN product_current p ON p.product = soi.product
LEFT JOIN salesorder_tax tx ON sod.salesorder = tx.salesorder
WHERE sod.id IN (
        SELECT MAX(id)
        FROM salesorderdetail
        GROUP BY salesorder
)
GROUP BY so.id, so.organisation, so.ordernum, tx.tax,
        sod.salesorder,
        sod.quotenumber,
        sod.ponumber,
        sod.description,
        sod.cycle,
        sod.start_date,
        sod.end_date,
        sod.is_open,
        sod.is_deleted
;

