DROP TRIGGER IF EXISTS purchaseorderdetailupdate
ON purchaseorderdetail;
CREATE TRIGGER purchaseorderdetailupdate BEFORE INSERT
ON purchaseorderdetail
FOR EACH ROW EXECUTE PROCEDURE purchaseorderdetailupdate();

DROP TRIGGER IF EXISTS purchaseorderitemdetailupdate
ON purchaseorderitemdetail;
CREATE TRIGGER purchaseorderitemdetailupdate BEFORE INSERT
ON purchaseorderitemdetail
FOR EACH ROW EXECUTE PROCEDURE purchaseorderitemdetailupdate();
