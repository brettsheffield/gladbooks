CREATE OR REPLACE VIEW salesorderlist AS
SELECT
        sod.salesorder as id,
        o.name AS customer,
        o.orgcode || '/' || lpad(CAST(so.ordernum AS TEXT), 5, '0') AS order,
        sod.ponumber,
        sod.description as comment,
        sod.cycle,
        sod.start_date,
        sod.end_date
FROM salesorderdetail sod
INNER JOIN salesorder so ON so.id = sod.salesorder
INNER JOIN organisation_current o ON o.id = so.organisation
WHERE sod.id IN (
        SELECT MAX(id)
        FROM salesorderdetail
        GROUP BY salesorder
)
AND sod.is_open = 'true'
AND sod.is_deleted = 'false'
;

