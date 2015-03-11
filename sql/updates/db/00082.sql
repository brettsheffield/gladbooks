-- mark salesorder closed if it wasn't already
-- return number of salesorders closed
CREATE OR REPLACE FUNCTION close_salesorder(soid INT4)
RETURNS INT4 as $$
DECLARE
        so_count        INT4;
BEGIN
        SELECT COUNT(id) INTO so_count FROM salesorder_current WHERE id = soid AND is_open;
        IF so_count = '1' THEN
                INSERT INTO salesorderdetail (salesorder, is_open) VALUES (soid, 'false');
        END IF;
        RETURN so_count;
END;
$$ LANGUAGE 'plpgsql';
