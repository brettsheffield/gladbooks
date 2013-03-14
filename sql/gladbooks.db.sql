-- Set up main gladbooks database, schema and tables

CREATE SCHEMA gladbooks;

SET search_path TO gladbooks;

CREATE TABLE accounttype (
	id		SERIAL PRIMARY KEY,
	name		TEXT UNIQUE NOT NULL,
	range_min	INT4 NOT NULL,
	range_max	INT4 NOT NULL,
	next_id		INT4 NOT NULL DEFAULT 0,
	entered		timestamp with time zone default now()
);
-- we don't delete account types
CREATE RULE nodel_accounttype AS ON DELETE TO accounttype DO NOTHING;

CREATE TABLE account (
	id		INT4 PRIMARY KEY,
	accounttype	INT4 references accounttype(id) ON DELETE RESTRICT,
	description	TEXT,
	entered		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE department (
        id              SERIAL PRIMARY KEY,
        name            TEXT UNIQUE,
        entered         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE division (
        id              SERIAL PRIMARY KEY,
        name            TEXT UNIQUE,
        entered         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE instance (
	id		VARCHAR(63) PRIMARY KEY,
	entered		timestamp with time zone default now()
);

CREATE TABLE cycle (    
        id              SERIAL PRIMARY KEY,
        cyclename       TEXT NOT NULL,
        days            INT4 DEFAULT 0,
        months          INT4 DEFAULT 0,
        years           INT4 DEFAULT 0,
        is_available    boolean DEFAULT true,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE tax (
        id              SERIAL PRIMARY KEY,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE taxdetail (
        id              SERIAL PRIMARY KEY,
        tax             INT4 references tax(id) ON DELETE RESTRICT,
        account         INT4 references account(id) ON DELETE RESTRICT,
        name            TEXT NOT NULL,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE taxrate (
        id              SERIAL PRIMARY KEY,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE taxratedetail (
        id              SERIAL PRIMARY KEY,
        taxrate         INT4 references taxrate(id) ON DELETE RESTRICT
                        NOT NULL,
        tax             INT4 references tax(id) ON DELETE RESTRICT NOT NULL,
        rate            NUMERIC,
        valid_from      timestamp,
        valid_to        timestamp,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

-- contiguous sequences for account nominal codes - we don't want gaps
-- also need to skip over preassigned codes
CREATE OR REPLACE FUNCTION accountid_next(accounttypeid INT4)
RETURNS INT4 AS
$$
DECLARE
        next_pk INT4;
        used_pk INT4;
        min_pk INT4;
        max_pk INT4;
BEGIN
        LOOP
                -- grab the next code and ranges to check against
                SELECT INTO next_pk, min_pk,    max_pk
                            next_id, range_min, range_max
                        FROM accounttype WHERE id = accounttypeid;
                IF NOT FOUND THEN
                        RAISE EXCEPTION 'invalid account type';
                END IF;
                IF next_pk >= max_pk THEN
                        -- we've run out of codes for this type
                        RAISE EXCEPTION 'unable to assign nominal code % %', next_pk, max_pk;
                END IF;
                -- increment counter in accounttype table
                UPDATE accounttype SET next_id = next_id + 1
                        WHERE id = accounttypeid;
                -- check if this code has been manually assigned
                SELECT INTO used_pk id FROM account WHERE id = next_pk;
                IF NOT FOUND THEN
                        -- we've found a code, return it
                        RETURN next_pk;
                END IF;
        END LOOP;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION set_account_id()
RETURNS TRIGGER AS
$$
DECLARE
        code_min        INT4;
        code_max        INT4;
BEGIN
        IF NEW.id IS NOT NULL THEN
                -- account code was supplied, check it is within valid range
                SELECT INTO code_min, code_max range_min, range_max
                        FROM accounttype
                        WHERE id = NEW.accounttype;
                IF NOT FOUND THEN
                        RAISE EXCEPTION 'Invalid account type %',
                                NEW.accounttype;
                END IF;
                IF (NEW.id < code_min) OR (NEW.id > code_max) THEN
                        RAISE EXCEPTION 'Nominal code % is outside valid range (% - %) for account type %', NEW.id, code_min, code_max, NEW.accounttype;
                END IF;
        ELSE
                -- no account code supplied, get next available
                NEW.id = accountid_next(NEW.accounttype);
        END IF;
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER set_account_id BEFORE INSERT ON account
FOR EACH ROW EXECUTE PROCEDURE set_account_id();

CREATE OR REPLACE FUNCTION journal_id_next()
returns int4 AS
$$
DECLARE
        next_pk int4;
BEGIN
        UPDATE journal_pk_counter SET journal_pk = journal_pk + 1;
        SELECT INTO next_pk journal_pk FROM journal_pk_counter;
        RETURN next_pk;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION journal_id_last()
returns int4 AS
$$
DECLARE
        last_pk int4;
BEGIN
        SELECT INTO last_pk journal_pk FROM journal_pk_counter;
        RETURN last_pk;
END;
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION ledger_id_next()
returns int4 AS
$$
DECLARE
        next_pk int4;
BEGIN
        UPDATE ledger_pk_counter SET ledger_pk = ledger_pk + 1;
        SELECT INTO next_pk ledger_pk FROM ledger_pk_counter;
        RETURN next_pk;
END;
$$ LANGUAGE 'plpgsql';

-- when INSERTing into organisationdetail, check for previous records
-- for this organisation, and use those values in place of any values
-- not supplied.
CREATE OR REPLACE FUNCTION organisationdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        oname           TEXT;
        oterms          INT4;
        obillcontact    INT4;
        ois_active      boolean;
        ois_suspended   boolean;
        ois_vatreg      boolean;
        ovatnumber      TEXT;
BEGIN
        SELECT INTO priorentries COUNT(id) FROM organisationdetail
                WHERE organisation = NEW.organisation;
        IF priorentries > 0 THEN
                -- This isn't our first time, so use previous values 
                SELECT INTO
                        oname, oterms, obillcontact, ois_active, ois_suspended,
                        ois_vatreg, ovatnumber
                        name, terms, billcontact, is_active, is_suspended,
                        is_vatreg, vatnumber
                FROM organisationdetail WHERE id IN (
                        SELECT MAX(id)
                        FROM organisationdetail
                        GROUP BY organisation
                )
                AND organisation = NEW.organisation;

                IF NEW.name IS NULL THEN
                        NEW.name = oname;
                END IF;
                IF NEW.terms IS NULL THEN
                        NEW.terms = oterms;
                END IF;
                IF NEW.billcontact IS NULL THEN
                        NEW.billcontact = obillcontact;
                END IF;
                IF NEW.is_active IS NULL THEN
                        NEW.is_active = ois_active;
                END IF;
                IF NEW.is_suspended IS NULL THEN
                        NEW.is_suspended = ois_suspended;
                END IF;
                IF NEW.is_vatreg IS NULL THEN
                        NEW.is_vatreg = ois_vatreg;
                END IF;
                IF NEW.vatnumber IS NULL THEN
                        NEW.vatnumber = ovatnumber;
                END IF;
        ELSE
                /* set defaults */
                IF NEW.terms IS NULL THEN
                        NEW.terms = 30;
                END IF;
                IF NEW.is_active IS NULL THEN
                        NEW.is_active = 'true';
                END IF;
                IF NEW.is_suspended IS NULL THEN
                        NEW.is_suspended = 'false';
                END IF;
                IF NEW.is_vatreg IS NULL THEN
                        NEW.is_vatreg = 'false';
                END IF;
        END IF;
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';


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

INSERT INTO cycle (id,cyclename,days,months,years) VALUES (0,'never',0,0,0);
INSERT INTO cycle (cyclename) VALUES ('once');
INSERT INTO cycle (cyclename,days,months,years) VALUES ('daily',1,0,0);
INSERT INTO cycle (cyclename,days,months,years) VALUES ('monthly',0,1,0);
INSERT INTO cycle (cyclename,days,months,years) VALUES ('bi-monthly',0,2,0);
INSERT INTO cycle (cyclename,days,months,years) VALUES ('quarterly',0,3,0);
INSERT INTO cycle (cyclename,days,months,years) VALUES ('half-yearly',0,6,0);
INSERT INTO cycle (cyclename,days,months,years) VALUES ('annual',0,0,1);

-- Reserved nominal codes
INSERT INTO account (id, accounttype, description)
        VALUES ('1100', '1000', 'Debtors Control Account');
INSERT INTO account (id, accounttype, description)
        VALUES ('2100', '2000', 'Creditors Control Account');
INSERT INTO account (id, accounttype, description)
        VALUES ('2202', '2000', 'VAT Liability Account');
INSERT INTO account (id, accounttype, description)
        VALUES ('2210', '2000', 'PAYE Liability Account');
INSERT INTO account (id, accounttype, description)
        VALUES ('2211', '2000', 'NI Liability Account');
INSERT INTO account (id, accounttype, description)
        VALUES ('2220', '2000', 'Wages Liability Account');
INSERT INTO account (id, accounttype, description)
        VALUES ('2230', '2000', 'Pension Liability Account');
INSERT INTO account (id, accounttype, description)
        VALUES ('3000', '3000', 'Share Capital');
INSERT INTO account (id, accounttype, description)
        VALUES ('3200', '3000', 'Retained Earnings Account');
INSERT INTO account (id, accounttype, description)
        VALUES ('5100', '5000', 'Shipping');
INSERT INTO account (id, accounttype, description)
        VALUES ('7501', '7000', 'Postage and Shipping');
INSERT INTO account (id, accounttype, description)
        VALUES ('9999', '9000', 'Suspense Account');

-- Standard Rate VAT
INSERT INTO tax VALUES (DEFAULT);
INSERT INTO taxdetail (tax, account, name) VALUES (currval(pg_get_serial_sequence('tax', 'id')), '2202', 'Standard Rate VAT');

INSERT INTO taxrate VALUES (DEFAULT);
INSERT INTO taxratedetail (taxrate, tax, rate, valid_from, valid_to) VALUES (currval(pg_get_serial_sequence('taxrate', 'id')),currval(pg_get_serial_sequence('tax', 'id')),'17.5', NULL, '2008-12-31');

INSERT INTO taxrate VALUES (DEFAULT);
INSERT INTO taxratedetail (taxrate, tax, rate, valid_from, valid_to) VALUES (currval(pg_get_serial_sequence('taxrate', 'id')),currval(pg_get_serial_sequence('tax', 'id')),'15.0', '2009-01-01', '2009-12-31');

INSERT INTO taxrate VALUES (DEFAULT);
INSERT INTO taxratedetail (taxrate, tax, rate, valid_from, valid_to) VALUES (currval(pg_get_serial_sequence('taxrate', 'id')),currval(pg_get_serial_sequence('tax', 'id')),'17.5', '2010-01-01', '2010-12-31');

INSERT INTO taxrate VALUES (DEFAULT);
INSERT INTO taxratedetail (taxrate, tax, rate, valid_from, valid_to) VALUES (currval(pg_get_serial_sequence('taxrate', 'id')),currval(pg_get_serial_sequence('tax', 'id')),'20.0', '2011-01-01', NULL);


-- Reduced Rate VAT
INSERT INTO tax VALUES (DEFAULT);
INSERT INTO taxdetail (tax, account, name) VALUES (currval(pg_get_serial_sequence('tax', 'id')), '2202', 'Reduced Rate VAT');
INSERT INTO taxrate VALUES (DEFAULT);
INSERT INTO taxratedetail (taxrate, tax, rate, valid_from, valid_to) VALUES (currval(pg_get_serial_sequence('taxrate', 'id')),currval(pg_get_serial_sequence('tax', 'id')),'5.0', NULL, NULL);

-- Zero Rate VAT
INSERT INTO tax VALUES (DEFAULT);
INSERT INTO taxdetail (tax, account, name) VALUES (currval(pg_get_serial_sequence('tax', 'id')), '2202', 'Zero Rate VAT');
INSERT INTO taxrate VALUES (DEFAULT);
INSERT INTO taxratedetail (taxrate, tax, rate, valid_from, valid_to) VALUES (currval(pg_get_serial_sequence('taxrate', 'id')),currval(pg_get_serial_sequence('tax', 'id')),'0.0', NULL, NULL);

