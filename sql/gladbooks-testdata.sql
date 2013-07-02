SET search_path TO gladbooks;

-- Oh!  What a horrible way to do this!
-- But for the time to fix this properly
-- You belong in the create_instance() function, not here

SELECT create_instance('default');
INSERT INTO gladbooks_default.relationship (id, name) VALUES (0, 'contact');
INSERT INTO gladbooks_default.relationship (name) VALUES ('billing');
INSERT INTO gladbooks_default.relationship (name) VALUES ('shipping');
SELECT create_instance('test');
INSERT INTO gladbooks_test.relationship (id, name) VALUES (0, 'contact');
INSERT INTO gladbooks_test.relationship (name) VALUES ('billing');
INSERT INTO gladbooks_test.relationship (name) VALUES ('shipping');
SELECT create_instance('bacs');
INSERT INTO gladbooks_bacs.relationship (id, name) VALUES (0, 'contact');
INSERT INTO gladbooks_bacs.relationship (name) VALUES ('billing');
INSERT INTO gladbooks_bacs.relationship (name) VALUES ('shipping');

SET search_path TO gladbooks_test,gladbooks;

BEGIN;

SELECT create_business('test', 'test');

END;

SET search_path TO gladbooks_test_1,gladbooks_test,gladbooks;

BEGIN;

INSERT INTO account (accounttype, description) VALUES ('1000', 'Current Account');
INSERT INTO account (accounttype, description) VALUES ('1000', 'Savings Account');
INSERT INTO account (accounttype, description) VALUES ('1000', 'Petty Cash');
INSERT INTO account (accounttype, description) VALUES ('2000', 'Credit Cards');
INSERT INTO account (accounttype, description) VALUES ('4000', 'Product 1');
INSERT INTO account (accounttype, description) VALUES ('4000', 'Product 2');
INSERT INTO account (accounttype, description) VALUES ('5000', 'Materials');
INSERT INTO account (accounttype, description) VALUES ('6000', 'Travel');
INSERT INTO account (accounttype, description) VALUES ('6000', 'Accommodation');
INSERT INTO account (accounttype, description) VALUES ('7000', 'Utilities');
INSERT INTO account (accounttype, description) VALUES ('8000', 'Depreciation');

INSERT INTO product DEFAULT VALUES;
INSERT INTO productdetail (product, account, shortname, description) VALUES (currval(pg_get_serial_sequence('product','id')),'4000', 'Test Product', 'Description of Test Product');

INSERT INTO product DEFAULT VALUES;
INSERT INTO productdetail (product, account, shortname, description) VALUES (currval(pg_get_serial_sequence('product','id')),'4000', 'A 2nd Test Product', 'Description of Test Product');

INSERT INTO organisation VALUES (DEFAULT);
INSERT INTO organisationdetail (organisation, name)
	VALUES (currval(pg_get_serial_sequence('organisation','id')), 'This is a test company! With some garbage£ & spaces''');

INSERT INTO contact (authuser, clientip) VALUES ('testdata','127.0.0.1');
INSERT INTO contactdetail (contact,name,line_1,line_2,line_3,town,county,country,postcode,email,phone,phonealt,mobile,fax,authuser,clientip) VALUES (currval(pg_get_serial_sequence('contact','id')),'Ms Test Contact','Line 1','Line 2','Line 3','Townsville','County','Grand Europia','EU01 23RO','someone@example.com','01234 5678','0123 123','333 3333','456 4567','betty','127.0.0.1');

INSERT INTO username (id, instance) VALUES ('betty', 'test');
INSERT INTO username (id, instance) VALUES ('bacs', 'bacs');
INSERT INTO username (id, instance) VALUES ('alpha', 'test');

INSERT INTO salespayment (authuser, clientip) VALUES ('testdata','127.0.0.1');
INSERT INTO salespaymentdetail (salespayment,transactdate,paymenttype,organisation,bankaccount,amount,description,authuser,clientip) VALUES (currval(pg_get_serial_sequence('salespayment','id')),'2013-04-01','1','1','1000','120.00','a comment','testdata','127.0.0.1');

INSERT INTO purchasepayment (authuser, clientip) VALUES ('testdata','127.0.0.1');
INSERT INTO purchasepaymentdetail (purchasepayment,transactdate,paymenttype,organisation,bankaccount,amount,description,authuser,clientip) VALUES (currval(pg_get_serial_sequence('purchasepayment','id')),'2013-04-01','1','1','2000','120.00','a comment','testdata','127.0.0.1');

INSERT INTO salesorder (organisation) VALUES ('1');
INSERT INTO salesorderdetail (salesorder, cycle, start_date) VALUES (currval(pg_get_serial_sequence('salesorder','id')), '3', '2013-04-01');
INSERT INTO salesorderitem DEFAULT VALUES;
INSERT INTO salesorderitemdetail (salesorderitem, salesorder, product) VALUES (currval(pg_get_serial_sequence('salesorderitem','id')), currval(pg_get_serial_sequence('salesorder','id')), '1');

COMMIT;
