CREATE OR REPLACE FUNCTION product_tax_vatcheck()
RETURNS TRIGGER AS $$
BEGIN
        -- Delete other VAT rates from this product.
        -- "There can be only one"
        DELETE FROM product_tax
        WHERE product = NEW.product
        AND tax IN (1,2,3)
        AND tax != NEW.tax;

        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';
