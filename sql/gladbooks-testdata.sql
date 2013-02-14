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

INSERT INTO cycle (id,cyclename,days,months,years) VALUES (0,'never',0,0,0);
INSERT INTO cycle (cyclename) VALUES ('once');
INSERT INTO cycle (cyclename,days,months,years) VALUES ('daily',1,0,0);
INSERT INTO cycle (cyclename,days,months,years) VALUES ('monthly',0,1,0);
INSERT INTO cycle (cyclename,days,months,years) VALUES ('bi-monthly',0,2,0);
INSERT INTO cycle (cyclename,days,months,years) VALUES ('quarterly',0,3,0);
INSERT INTO cycle (cyclename,days,months,years) VALUES ('half-yearly',0,6,0);
INSERT INTO cycle (cyclename,days,months,years) VALUES ('annual',0,0,1);

COMMIT;
