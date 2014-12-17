CREATE OR REPLACE FUNCTION salesorderdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        osalesorder     INT4;
        oquotenumber    INT4;
        oponumber       TEXT;
        odescription    TEXT;
        ocycle          INT4;
        ostart_date     timestamp with time zone;
        oend_date       timestamp with time zone;
        ois_open        boolean;
        ois_deleted     boolean;
BEGIN
        SELECT INTO priorentries COUNT(id) FROM salesorderdetail
                WHERE salesorder = NEW.salesorder;
        IF priorentries > 0 THEN
                -- This isn't our first time, so use previous values 
                SELECT INTO
                        osalesorder, oquotenumber, oponumber, odescription,
                        ocycle, ostart_date, oend_date, ois_open, ois_deleted
                        salesorder, quotenumber, ponumber, description,
                        cycle, start_date, end_date, is_open, is_deleted
                FROM salesorderdetail WHERE id IN (
                        SELECT MAX(id)
                        FROM salesorderdetail
                        GROUP BY salesorder
                )
                AND salesorder = NEW.salesorder;

                IF NEW.salesorder IS NULL THEN
                        NEW.salesorder := osalesorder;
                END IF;
                IF NEW.quotenumber IS NULL THEN
                        NEW.quotenumber := oquotenumber;
                END IF;
                IF NEW.ponumber IS NULL THEN
                        NEW.ponumber := oponumber;
                END IF;
                IF NEW.description IS NULL THEN
                        NEW.description := odescription;
                END IF;
                IF NEW.cycle IS NULL THEN
                        NEW.cycle := ocycle;
                END IF;
                IF NEW.start_date_null THEN
                        NEW.start_date := NULL;
                ELSIF NEW.start_date IS NULL THEN
                        NEW.start_date := ostart_date;
                END IF;
                IF NEW.end_date_null THEN
                        NEW.end_date := NULL;
                ELSIF NEW.end_date IS NULL THEN
                        NEW.end_date := oend_date;
                END IF;
                IF NEW.is_open IS NULL THEN
                        NEW.is_open := ois_open;
                END IF;
                IF NEW.is_deleted IS NULL THEN
                        NEW.is_deleted := ois_deleted;
                END IF;
        ELSE
                /* set defaults */
                IF NEW.cycle IS NULL THEN
                        NEW.cycle := '0';
                END IF;
        END IF;
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';
