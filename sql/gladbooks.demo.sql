SET search_path TO gladbooks;

-- Add a demo tax
INSERT INTO tax VALUES (DEFAULT);
INSERT INTO taxdetail (account, name) VALUES ('2202', 'The Boris Tax');
INSERT INTO taxrate VALUES (DEFAULT);
INSERT INTO taxratedetail (rate, valid_from, valid_to) VALUES ('6.66', NULL, NULL);

-- create an instance
SELECT create_instance('demo');
INSERT INTO gladbooks_demo.relationship (id, name) VALUES (0, 'contact');
INSERT INTO gladbooks_demo.relationship (name) VALUES ('billing');
INSERT INTO gladbooks_demo.relationship (name) VALUES ('shipping');

-- set search path to demo instance
SET search_path TO gladbooks_demo,gladbooks;

-- create demo user
INSERT INTO username (id, instance) VALUES ('demouser', 'demo');

-- create some businesses
BEGIN;
	SELECT create_business('demo', 'Libre Llamas Ltd', '2013-04-01');
END;

-- set search path to business 1
SET search_path TO gladbooks_demo_1,gladbooks_demo,gladbooks;

-- create some products
INSERT INTO product DEFAULT VALUES;
INSERT INTO productdetail (account, shortname, description, price_buy, price_sell) VALUES ('4000', 'Consultancy', 'Consultancy Services', '500.00', '995.00');
INSERT INTO product_tax (product, tax) VALUES (currval(pg_get_serial_sequence('product','id')), '1');
INSERT INTO product_tax (product, tax) VALUES (currval(pg_get_serial_sequence('product','id')), currval(pg_get_serial_sequence('tax','id')));

INSERT INTO product DEFAULT VALUES;
INSERT INTO productdetail (account, shortname, description, price_buy, price_sell) VALUES ('4000', 'Oranges', 'Navel Oranges', '0.04', '0.50');
INSERT INTO product_tax (product, tax) VALUES (currval(pg_get_serial_sequence('product','id')), '1');

INSERT INTO product DEFAULT VALUES;
INSERT INTO productdetail (account, shortname, description, price_buy, price_sell) VALUES ('4000', 'Gold', 'Gold (ounces)', '839.12', '845.35');
INSERT INTO product_tax (product, tax) VALUES (currval(pg_get_serial_sequence('product','id')), '1');

INSERT INTO product DEFAULT VALUES;
INSERT INTO productdetail (account, shortname, description, price_buy, price_sell) VALUES ('4000', 'Frankincense', 'Frankincense (25 gm)', '3.49', '5.99');
INSERT INTO product_tax (product, tax) VALUES (currval(pg_get_serial_sequence('product','id')), '1');

INSERT INTO product DEFAULT VALUES;
INSERT INTO productdetail (account, shortname, description, price_buy, price_sell) VALUES ('4000', 'Myrrh', 'Myrrh Aromatheraphy Oil (10mL)', '3.00', '9.99');
INSERT INTO product_tax (product, tax) VALUES (currval(pg_get_serial_sequence('product','id')), '1');

INSERT INTO organisation VALUES (DEFAULT);
INSERT INTO organisationdetail (name) VALUES ('Tropicana Fruitarium');

INSERT INTO contact (authuser, clientip) VALUES ('demouser','127.0.0.1');
INSERT INTO contactdetail (contact,name,line_1,line_2,line_3,town,county,country,postcode,email,phone,phonealt,mobile,fax,authuser,clientip) VALUES (currval(pg_get_serial_sequence('contact','id')),'Ms Test Contact','Line 1','Line 2','Line 3','Townsville','County','Grand Europia','EU01 23RO','someone@example.com','01234 5678','0123 123','333 3333','456 4567','demouser','127.0.0.1');

INSERT INTO organisation_contact(organisation, contact, relationship) 
VALUES ( currval(pg_get_serial_sequence('organisation','id')), currval(pg_get_serial_sequence('contact','id')), '0');

INSERT INTO contact (authuser, clientip) VALUES ('testdata','127.0.0.1');
INSERT INTO contactdetail (contact,name,line_1,line_2,line_3,town,county,country,postcode,email,phone,phonealt,mobile,fax,authuser,clientip) VALUES (currval(pg_get_serial_sequence('contact','id')),'Tropicana Accounts','Harbour Street','','','Puna''auia','','French Polynesia','','someone@example.com','01234 5678','0123 123','333 3333','456 4567','demouser','127.0.0.1');

INSERT INTO organisation_contact(organisation, contact, relationship) 
VALUES ( currval(pg_get_serial_sequence('organisation','id')), currval(pg_get_serial_sequence('contact','id')), '1');

INSERT INTO contact (authuser, clientip) VALUES ('testdata','127.0.0.1');

INSERT INTO organisation VALUES (DEFAULT);
INSERT INTO organisationdetail (name) VALUES ('Universal Exports');

INSERT INTO contact (authuser, clientip) VALUES ('testdata','127.0.0.1');
INSERT INTO contactdetail (contact,name,line_1,line_2,line_3,town,county,country,postcode,email,phone,phonealt,mobile,fax,authuser,clientip) VALUES (currval(pg_get_serial_sequence('contact','id')),'Miss Moneypenny','Pinewood Studios','Pinewood Road','Iver Heath','SL0 0NH','Buckinghamshire','United Kingdom','','someone@example.com','01234 5678','0123 123','333 3333','456 4567','demouser','127.0.0.1');

INSERT INTO organisation_contact(organisation, contact, relationship) 
VALUES ( currval(pg_get_serial_sequence('organisation','id')), currval(pg_get_serial_sequence('contact','id')), '1');
