BEGIN;
INSERT INTO account (accounttype, description) VALUES ('1', 'Bank Account 1');
INSERT INTO account (accounttype, description) VALUES ('1', 'Bank Account 2');
INSERT INTO account (accounttype, description) VALUES ('1', 'Accounts Receivable');
INSERT INTO account (accounttype, description) VALUES ('2', 'Accounts Payable');
INSERT INTO account (accounttype, description) VALUES ('3', 'Owner''s Equity');
INSERT INTO account (accounttype, description) VALUES ('4', 'Product 1');
INSERT INTO account (accounttype, description) VALUES ('4', 'Product 2');
INSERT INTO account (accounttype, description) VALUES ('5', 'Materials');
INSERT INTO account (accounttype, description) VALUES ('5', 'Utilities');
INSERT INTO account (id, accounttype, description) VALUES (45, '2', 'test');

INSERT INTO organisation VALUES (DEFAULT);
INSERT INTO organisationdetail (organisation, name)
	VALUES (currval(pg_get_serial_sequence('organisation','id')), 'This is a test company! With some garbage£ & spaces''');

INSERT INTO contact (authuser, clientip) VALUES ('testdata','127.0.0.1');
INSERT INTO contactdetail (contact,name,line_1,line_2,line_3,town,county,country,postcode,email,phone,phonealt,mobile,fax,authuser,clientip) VALUES (currval(pg_get_serial_sequence('contact','id')),'Ms Test Contact','Line 1','Line 2','Line 3','Townsville','County','Grand Europia','EU01 23RO','someone@example.com','01234 5678','0123 123','333 3333','456 4567','betty','127.0.0.1');

COMMIT;
