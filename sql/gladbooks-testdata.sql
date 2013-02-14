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
	VALUES (currval(pg_get_serial_sequence('organisation','id')), 'This is my very first! COmpany');

COMMIT;