CREATE OR REPLACE FUNCTION productdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        oaccount        INT4;
        oshortname      TEXT;
        odescription    TEXT;
        oprice_buy      NUMERIC;
        oprice_sell     NUMERIC;
        omargin         NUMERIC;
        omarkup         NUMERIC;
        ois_available   boolean;
        ois_offered     boolean;
BEGIN
        SELECT INTO priorentries COUNT(id) FROM productdetail
                WHERE product = NEW.product;
        IF priorentries > 0 THEN
                -- This isn't our first time, so use previous values 
                SELECT INTO
                        oaccount, oshortname, odescription, oprice_buy,
                        oprice_sell, omargin, omarkup, ois_available,
                        ois_offered
                        account, shortname, description, price_buy,
                        price_sell, margin, markup, is_available,
                        is_offered
                FROM productdetail WHERE id IN (
                        SELECT MAX(id)
                        FROM productdetail
                        GROUP BY product
                )
                AND product = NEW.product;

                IF NEW.account IS NULL THEN
                        NEW.account := oaccount;
                END IF;
                IF NEW.shortname IS NULL THEN
                        NEW.shortname := oshortname;
                END IF;
                IF NEW.description IS NULL THEN
                        NEW.description := odescription;
                END IF;
                IF NEW.price_buy IS NULL THEN
                        NEW.price_buy := oprice_buy;
                END IF;
                IF NEW.price_sell IS NULL THEN
                        NEW.price_sell := oprice_sell;
                END IF;
                IF NEW.margin IS NULL THEN
                        NEW.margin := omargin;
                END IF;
                IF NEW.markup IS NULL THEN
                        NEW.markup := omarkup;
                END IF;
                IF NEW.is_available IS NULL THEN
                        NEW.is_available := ois_available;
                END IF;
                IF NEW.is_offered IS NULL THEN
                        NEW.is_offered := ois_offered;
                END IF;
        END IF;

        -- ensure shortname hasn't been used for a different product
        -- can't just use a key here
        SELECT INTO priorentries COUNT(id) FROM product_current
        WHERE product != NEW.product
        AND shortname = NEW.shortname;
        IF priorentries > 0 THEN
                RAISE EXCEPTION 'Product shortname "%" must be unique', NEW.shortname;
        END IF;

        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';
