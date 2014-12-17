ALTER TABLE purchaseorderdetail ADD COLUMN quotenumber INT4 UNIQUE;
ALTER TABLE purchaseorderdetail ADD COLUMN ponumber TEXT;
ALTER TABLE purchaseorderitemdetail ADD COLUMN discount NUMERIC;
