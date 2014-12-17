DROP VIEW purchaseorderitem_current;
CREATE VIEW purchaseorderitem_current AS
SELECT
        poi.id,
        poid.id as detailid,
        poi.uuid,
        purchaseorder,
        product,
        linetext,
        price,
        qty,
        poid.updated,
        poid.authuser,
        poid.clientip
FROM purchaseorderitem poi
INNER JOIN purchaseorderitemdetail poid ON poi.id = poid.purchaseorderitem
WHERE poid.id IN (
        SELECT MAX(id)
        FROM purchaseorderitemdetail
        GROUP BY purchaseorderitem
)
AND poid.is_deleted = false;
