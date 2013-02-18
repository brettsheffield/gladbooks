BEGIN;
INSERT INTO account (type, description) VALUES ('a', 'Bank Account 1');
INSERT INTO account (type, description) VALUES ('a', 'Bank Account 2');
INSERT INTO account (type, description) VALUES ('a', 'Accounts Receivable');
INSERT INTO account (type, description) VALUES ('l', 'Accounts Payable');
INSERT INTO account (type, description) VALUES ('l', 'VAT');
INSERT INTO account (type, description) VALUES ('c', 'Owner''s Equity');
INSERT INTO account (type, description) VALUES ('r', 'Product 1');
INSERT INTO account (type, description) VALUES ('r', 'Product 2');
INSERT INTO account (type, description) VALUES ('e', 'Materials');
INSERT INTO account (type, description) VALUES ('e', 'Utilities');

INSERT INTO organisation VALUES (DEFAULT);
INSERT INTO organisationdetail (organisation, name)
	VALUES (currval(pg_get_serial_sequence('organisation','id')), 'This is a test company! With some garbage£ & spaces''');

INSERT INTO contact (authuser, clientip) VALUES ('testdata','127.0.0.1');
INSERT INTO contactdetail (contact,name,line_1,line_2,line_3,town,county,country,postcode,email,phone,phonealt,mobile,fax,authuser,clientip) VALUES (currval(pg_get_serial_sequence('contact','id')),'Ms Test Contact','Line 1','Line 2','Line 3','Townsville','County','Grand Europia','EU01 23RO','someone@example.com','01234 5678','0123 123','333 3333','456 4567','betty','127.0.0.1');

COMMIT;
