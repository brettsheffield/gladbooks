ALTER TABLE purchaseorderdetail ADD COLUMN quotenumber INT4 UNIQUE;
ALTER TABLE purchaseorderdetail ADD COLUMN ponumber TEXT;
ALTER TABLE purchaseorderitemdetail ADD COLUMN discount NUMERIC;
ALTER TABLE purchaseorderdetail ADD COLUMN start_date_null boolean DEFAULT false;
ALTER TABLE purchaseorderdetail ADD COLUMN end_date_null boolean DEFAULT false;
