-- update 00032
-- 2014-05-19 - Brett Sheffield
-- Applies to business schemas
-- adds TRIGGER product_tax_insert

BEGIN;

CREATE TRIGGER product_tax_insert AFTER INSERT ON product_tax
FOR EACH ROW EXECUTE PROCEDURE product_tax_vatcheck();

INSERT INTO upgrade (id) VALUES (32);

COMMIT;
