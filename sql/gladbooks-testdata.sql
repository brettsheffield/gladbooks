SET search_path TO gladbooks_default,gladbooks;
SELECT create_business('default', 'default');

SET search_path TO gladbooks_default_default,gladbooks_default,gladbooks;
SELECT default_data('default', 'default');

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

INSERT INTO organisation VALUES (DEFAULT);
INSERT INTO organisationdetail (organisation, name)
	VALUES (currval(pg_get_serial_sequence('organisation','id')), 'This is a test company! With some garbage£ & spaces''');

INSERT INTO contact (authuser, clientip) VALUES ('testdata','127.0.0.1');
INSERT INTO contactdetail (contact,name,line_1,line_2,line_3,town,county,country,postcode,email,phone,phonealt,mobile,fax,authuser,clientip) VALUES (currval(pg_get_serial_sequence('contact','id')),'Ms Test Contact','Line 1','Line 2','Line 3','Townsville','County','Grand Europia','EU01 23RO','someone@example.com','01234 5678','0123 123','333 3333','456 4567','betty','127.0.0.1');

COMMIT;
