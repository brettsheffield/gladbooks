CREATE OR REPLACE VIEW salesorderlist AS
SELECT
        so.id,
        o.name AS customer,
        o.orgcode || '/' || lpad(CAST(so.ordernum AS TEXT), 5, '0') AS order,
        so.ponumber,
        so.description as comment,
        so.cycle,
        so.start_date,
        so.end_date,
        so.created,
        so.modified
FROM salesorder_current so
INNER JOIN organisation_current o ON o.id = so.organisation
WHERE so.is_open = 'true'
AND so.is_deleted = 'false'
;
