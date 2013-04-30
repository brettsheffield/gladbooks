
-- TODO: need to do this for all schemas --
ALTER TABLE productdetail DROP CONSTRAINT IF EXISTS productdetail_shortname_key;

-- per business --
CREATE OR REPLACE VIEW salesorderlist AS
SELECT
        salesorder as id,
        ponumber,
        description,
        cycle,
        start_date,
        end_date
FROM salesorderdetail
WHERE salesorder IN (
        SELECT MAX(id)
        FROM salesorderdetail
        GROUP BY salesorder
)
AND is_open = 'true'
AND is_deleted = 'false'
;

