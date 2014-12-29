CREATE OR REPLACE FUNCTION salesorderitemdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        osalesorder     INT4;
        oproduct        INT4;
        olinetext       TEXT;
        odiscount       NUMERIC;
        oprice          NUMERIC;
        oqty            NUMERIC;
        ois_deleted     boolean;
BEGIN
        SELECT INTO priorentries COUNT(id) FROM salesorderitemdetail
                WHERE salesorderitem = NEW.salesorderitem;
        IF priorentries > 0 THEN
                -- This isn't our first time, so use previous values 
                SELECT INTO
                        osalesorder, oproduct, olinetext, odiscount, oprice,
                        oqty, ois_deleted
                        salesorder, product, linetext, discount, price,
                        qty, is_deleted
                FROM salesorderitemdetail WHERE id IN (
                        SELECT MAX(id)
                        FROM salesorderitemdetail
                        GROUP BY salesorderitem
                )
                AND salesorderitem = NEW.salesorderitem;

                IF NEW.salesorder IS NULL THEN
                        NEW.salesorder := osalesorder;
                END IF;
                IF NEW.product IS NULL THEN
                        NEW.product := oproduct;
                END IF;
                IF NEW.linetext IS NULL THEN
                        NEW.linetext := olinetext;
                END IF;
                IF NEW.discount_null THEN
                        NEW.discount := NULL;
                ELSIF NEW.discount IS NULL THEN
                        NEW.discount := odiscount;
                END IF;
                IF NEW.price_null THEN
                        NEW.price := NULL;
                ELSIF NEW.price IS NULL THEN
                        NEW.price := oprice;
                END IF;
                IF NEW.qty IS NULL THEN
                        NEW.qty := oqty;
                END IF;
                IF NEW.is_deleted IS NULL THEN
                        NEW.is_deleted := ois_deleted;
                END IF;
        ELSE
                /* set defaults */
        END IF;
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';
