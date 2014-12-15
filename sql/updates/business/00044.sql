DROP TRIGGER IF EXISTS salesorderitemdetailupdate
ON salesorderitemdetail;
CREATE TRIGGER salesorderitemdetailupdate BEFORE INSERT
ON salesorderitemdetail
FOR EACH ROW EXECUTE PROCEDURE salesorderitemdetailupdate();
