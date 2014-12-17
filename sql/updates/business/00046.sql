CREATE OR REPLACE VIEW salesorderitem_current AS
SELECT
        soi.id,
        soid.id AS detailid,
        uuid,
        salesorder,
        product,
        linetext,
        discount,
        price,
        qty,
        soid.updated,
        soid.authuser,
        soid.clientip
FROM salesorderitem soi
INNER JOIN salesorderitemdetail soid ON soi.id = soid.salesorderitem
WHERE soid.id IN (
        SELECT MAX(id)
        FROM salesorderitemdetail
        GROUP BY salesorderitem
)
AND is_deleted = false;
