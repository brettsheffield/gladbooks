-- per business --

SET search_path TO gladbooks_bacs_1,gladbooks_bacs,gladbooks;

DROP VIEW salesorderlist;
CREATE VIEW salesorderlist AS
SELECT
        sod.salesorder as id,
        o.name AS customer,
        o.orgcode || '/' || lpad(CAST(so.ordernum AS TEXT), 5, '0') AS order,
        sod.ponumber,
        sod.description,
        sod.cycle,
        sod.start_date,
        sod.end_date
FROM salesorderdetail sod
INNER JOIN salesorder so ON so.id = sod.salesorder
INNER JOIN organisation_current o ON o.id = so.organisation
WHERE sod.salesorder IN (
        SELECT MAX(id)
        FROM salesorderdetail
        GROUP BY salesorder
)
AND sod.is_open = 'true'
AND sod.is_deleted = 'false'
;

