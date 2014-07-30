-- update 00031
-- 2014-05-19 - Brett Sheffield
-- Applies to gladbooks schema
-- adds FUNCTION product_tax_vatcheck()

SET search_path TO gladbooks;

BEGIN;
CREATE OR REPLACE FUNCTION product_tax_vatcheck()
RETURNS TRIGGER AS $$
DECLARE
        vatcount        INT4;
BEGIN
        SELECT INTO vatcount COUNT(*) FROM product_tax WHERE id IN (
                SELECT MAX(id)
                FROM product_tax WHERE tax IN (1,2,3)
                GROUP BY product,tax
        )
        AND product=NEW.product
        AND is_applicable = TRUE
        GROUP BY product;
        
        IF vatcount > 1 THEN
                RAISE EXCEPTION 'Cannot apply more than one VAT rate to a product.';
                RETURN NULL;
        END IF;
        
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

INSERT INTO upgrade (id) VALUES (31);

COMMIT;
