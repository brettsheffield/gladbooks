
-- TODO: need to do this for all schemas --
ALTER TABLE productdetail DROP CONSTRAINT IF EXISTS productdetail_shortname_key;

-- per business --
CREATE OR REPLACE VIEW salesorderlist AS
SELECT
        sod.salesorder as id,
        so.organisation AS customer,
        o.orgcode || '/' || lpad(CAST(so.ordernum AS TEXT), 5, '0') AS order,
        sod.ponumber,
        sod.description,
        sod.cycle,
        sod.start_date,
        sod.end_date
FROM salesorderdetail sod
INNER JOIN salesorder so ON so.id = sod.salesorder
INNER JOIN organisation o ON o.id = so.organisation
WHERE sod.salesorder IN (
        SELECT MAX(id)
        FROM salesorderdetail
        GROUP BY salesorder
)
AND sod.is_open = 'true'
AND sod.is_deleted = 'false'
;

CREATE OR REPLACE VIEW salesorderview AS
SELECT
        sod.salesorder as id,
        od.name || '(' || o.orgcode || ')' AS customer,
        o.orgcode || '/' || lpad(CAST(so.ordernum AS TEXT), 5, '0') AS order,
        sod.ponumber,
        sod.description,
        sod.cycle,
        sod.start_date,
        sod.end_date
FROM salesorderdetail sod
INNER JOIN salesorder so ON so.id = sod.salesorder
INNER JOIN organisation o ON o.id = so.organisation
INNER JOIN organisationdetail od ON o.id = od.organisation
WHERE sod.salesorder IN (
        SELECT MAX(id)
        FROM salesorderdetail
        GROUP BY salesorder
)
AND sod.is_open = 'true'
AND sod.is_deleted = 'false'
;

CREATE OR REPLACE VIEW salesorderitemview AS
SELECT
        salesorderitem as id,
        product,
        linetext,
        discount,
        price,
        qty
FROM salesorderitemdetail soid
WHERE soid.salesorderitem IN (
        SELECT MAX(id)
        FROM salesorderitemdetail
        GROUP BY salesorderitem
)
AND is_deleted = 'false'
;

