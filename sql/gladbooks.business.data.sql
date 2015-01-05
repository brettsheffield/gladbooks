SET search_path TO gladbooks;

CREATE OR REPLACE FUNCTION default_data(instance VARCHAR(63), business INT4)
RETURNS void AS
$$

BEGIN

EXECUTE 'SET search_path TO gladbooks_' || instance || '_' || business || ',gladbooks_' || instance || ',gladbooks';
--

-- Default data --
INSERT INTO accounttype (id, name, range_min, range_max, next_id)
	VALUES ('0000', 'Fixed Assets', '0000', '0999', '0000');
INSERT INTO accounttype (id, name, range_min, range_max, next_id)
	VALUES ('1000','Current Assets', '1000', '1999', '1000');
INSERT INTO accounttype (id, name, range_min, range_max, next_id)
	VALUES ('2000','Current Liabilities', '2000', '2499', '2000');
INSERT INTO accounttype (id, name, range_min, range_max, next_id)
	VALUES ('2500','Long Term Liabilities', '2500', '2999', '2500');
INSERT INTO accounttype (id, name, range_min, range_max, next_id)
	VALUES ('3000','Capital and Reserves', '3000', '3999', '3000');
INSERT INTO accounttype (id, name, range_min, range_max, next_id)
	VALUES ('4000','Revenue', '4000', '4999', '4000');
INSERT INTO accounttype (id, name, range_min, range_max, next_id)
	VALUES ('5000','Expenditure', '5000', '5999', '5000');
INSERT INTO accounttype (id, name, range_min, range_max, next_id)
	VALUES ('6000','Direct Expenses', '6000', '6999', '6000');
INSERT INTO accounttype (id, name, range_min, range_max, next_id)
	VALUES ('7000','Overheads', '7000', '7999', '7000');
INSERT INTO accounttype (id, name, range_min, range_max, next_id)
	VALUES ('8000','Depreciation and Sundries', '8000', '8999', '8000');
INSERT INTO accounttype (id, name, range_min, range_max, next_id)
	VALUES ('9000','Suspense Accounts', '9000', '9999', '9000');

INSERT INTO department (id, name) VALUES (0, 'default');
INSERT INTO division (id, name) VALUES (0, 'default');

--INSERT INTO relationship (id, name) VALUES (0, 'contact');
--INSERT INTO relationship (name) VALUES ('billing');
--INSERT INTO relationship (name) VALUES ('shipping');

--INSERT INTO cycle (id,cyclename,days,months,years) VALUES (0,'never',0,0,0);
--INSERT INTO cycle (cyclename) VALUES ('once');
--INSERT INTO cycle (cyclename,days,months,years) VALUES ('daily',1,0,0);
--INSERT INTO cycle (cyclename,days,months,years) VALUES ('monthly',0,1,0);
--INSERT INTO cycle (cyclename,days,months,years) VALUES ('bi-monthly',0,2,0);
--INSERT INTO cycle (cyclename,days,months,years) VALUES ('quarterly',0,3,0);
--INSERT INTO cycle (cyclename,days,months,years) VALUES ('half-yearly',0,6,0);
--INSERT INTO cycle (cyclename,days,months,years) VALUES ('annual',0,0,1);

-- Reserved nominal codes
INSERT INTO account (id, accounttype, description)
	VALUES ('1000', '1000', 'Current Account');
INSERT INTO account (id, accounttype, description)
	VALUES ('1100', '1000', 'Debtors Control');
INSERT INTO account (id, accounttype, description)
	VALUES ('2100', '2000', 'Creditors Control');
INSERT INTO account (id, accounttype, description)
	VALUES ('2200', '2000', 'Output VAT (Sales)');
INSERT INTO account (id, accounttype, description)
	VALUES ('2201', '2000', 'Input VAT (Purchases)');
INSERT INTO account (id, accounttype, description)
	VALUES ('2202', '2000', 'VAT Liability');
INSERT INTO account (id, accounttype, description)
	VALUES ('2205', '2000', 'Output VAT (Sales) - Holding Account');
INSERT INTO account (id, accounttype, description)
	VALUES ('2206', '2000', 'Input VAT (Purchases) - Holding Account');
INSERT INTO account (id, accounttype, description)
	VALUES ('2210', '2000', 'PAYE Liability');
INSERT INTO account (id, accounttype, description)
	VALUES ('2211', '2000', 'NI Liability');
INSERT INTO account (id, accounttype, description)
	VALUES ('2220', '2000', 'Wages Liability');
INSERT INTO account (id, accounttype, description)
	VALUES ('2230', '2000', 'Pension Liability');
INSERT INTO account (id, accounttype, description)
	VALUES ('3000', '3000', 'Share Capital');
INSERT INTO account (id, accounttype, description)
	VALUES ('3200', '3000', 'Retained Earnings');
INSERT INTO account (id, accounttype, description)
	VALUES ('4000', '4000', 'General Revenues');
INSERT INTO account (id, accounttype, description)
	VALUES ('5000', '5000', 'General Expenditure');
INSERT INTO account (id, accounttype, description)
	VALUES ('5100', '5000', 'Shipping');
INSERT INTO account (id, accounttype, description)
	VALUES ('7501', '7000', 'Postage and Shipping');
INSERT INTO account (id, accounttype, description)
	VALUES ('9999', '9000', 'Suspense Account');


--INSERT INTO paymenttype (name) VALUES ('cash');
--INSERT INTO paymenttype (name) VALUES ('cheque');
--INSERT INTO paymenttype (name) VALUES ('bank transfer');

--
END;
$$ LANGUAGE 'plpgsql';
