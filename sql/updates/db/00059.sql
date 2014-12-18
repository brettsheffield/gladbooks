CREATE OR REPLACE FUNCTION producttaxupdate()
RETURNS TRIGGER AS
$$
BEGIN
        -- Applying a tax of -1 (VAT Exempt) means we should remove all VAT
        IF NEW.tax = -1 THEN
                DELETE FROM product_tax 
                WHERE product = NEW.product
                AND tax IN (1,2,3);
                RETURN NULL;
        END IF;

        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';
