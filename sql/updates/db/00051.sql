CREATE OR REPLACE FUNCTION purchaseorderitemdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        opurchaseorder     INT4;
        oproduct        INT4;
        olinetext       TEXT;
        odiscount       NUMERIC;
        oprice          NUMERIC;
        oqty            NUMERIC;
        ois_deleted     boolean;
BEGIN
        SELECT INTO priorentries COUNT(id) FROM purchaseorderitemdetail
                WHERE purchaseorderitem = NEW.purchaseorderitem;
        IF priorentries > 0 THEN
                -- This isn't our first time, so use previous values 
                SELECT INTO
                        opurchaseorder, oproduct, olinetext, odiscount, oprice,
                        oqty, ois_deleted
                        purchaseorder, product, linetext, discount, price,
                        qty, is_deleted
                FROM purchaseorderitemdetail WHERE id IN (
                        SELECT MAX(id)
                        FROM purchaseorderitemdetail
                        GROUP BY purchaseorderitem
                )
                AND purchaseorderitem = NEW.purchaseorderitem;

                IF NEW.purchaseorder IS NULL THEN
                        NEW.purchaseorder := opurchaseorder;
                END IF;
                IF NEW.product IS NULL THEN
                        NEW.product := oproduct;
                END IF;
                IF NEW.linetext IS NULL THEN
                        NEW.linetext := olinetext;
                END IF;
                IF NEW.discount IS NULL THEN
                        NEW.discount := odiscount;
                END IF;
                IF NEW.price IS NULL THEN
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
