ALTER TABLE purchaseorderitemdetail
ADD COLUMN discount_null boolean DEFAULT false,
ADD COLUMN price_null boolean DEFAULT false;
