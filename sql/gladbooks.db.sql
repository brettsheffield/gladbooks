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

CREATE TABLE paymenttype (
        id              SERIAL PRIMARY KEY,
        name            TEXT
);

CREATE OR REPLACE FUNCTION bankdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        otransactdate   date;
        odescription    TEXT;
        oaccount        INT4;
        opaymenttype    INT4;
        ojournal        INT4;
        odebit          NUMERIC;
        ocredit         NUMERIC;
BEGIN
        SELECT INTO priorentries COUNT(id) FROM bankdetail
                WHERE bank = NEW.bank;
        IF priorentries > 0 THEN
                -- This isn't our first time, so use previous values 
                SELECT INTO
                        otransactdate, odescription, oaccount, opaymenttype,
                        ojournal, odebit, ocredit
                        transactdate, description, account, paymenttype,
                        journal, debit, credit
                FROM bankdetail WHERE id IN (
                        SELECT MAX(id)
                        FROM bankdetail
                        GROUP BY bank
                )
                AND bank = NEW.bank;

                IF NEW.transactdate IS NULL THEN
                        NEW.transactdate := otransactdate;
                END IF;
                IF NEW.description IS NULL THEN
                        NEW.description := odescription;
                END IF;
                IF NEW.account IS NULL THEN
                        NEW.account := oaccount;
                END IF;
                IF NEW.paymenttype IS NULL THEN
                        NEW.paymenttype := opaymenttype;
                END IF;
                IF NEW.journal IS NULL THEN
                        NEW.journal := ojournal;
                END IF;
                IF NEW.debit IS NULL THEN
                        NEW.debit := odebit;
                END IF;
                IF NEW.credit IS NULL THEN
                        NEW.credit := ocredit;
                END IF;
        END IF;
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

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

CREATE TABLE username (
        id              VARCHAR(63) PRIMARY KEY,
	instance	VARCHAR(63) references instance(id) ON DELETE RESTRICT,
        entered         timestamp with time zone default now()
);
CREATE RULE nodel_username AS ON DELETE TO username DO NOTHING;

CREATE TABLE groupname (
        id              SERIAL PRIMARY KEY,
        groupname       TEXT UNIQUE NOT NULL,
        entered         timestamp with time zone default now()
);
CREATE RULE nodel_groupname AS ON DELETE TO groupname DO NOTHING;

CREATE TABLE membership (
        username        VARCHAR(63) references username(id) ON DELETE RESTRICT,
        groupname       INT4 references groupname(id) ON DELETE RESTRICT,
        entered         timestamp with time zone default now(),
        CONSTRAINT membership_pk PRIMARY KEY (username, groupname)
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

CREATE TABLE relationship (
        id              SERIAL PRIMARY KEY,
        name            TEXT NOT NULL UNIQUE,
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
        tax             INT4 references tax(id) ON DELETE RESTRICT NOT NULL
		DEFAULT currval(pg_get_serial_sequence('tax','id')),
        account         INT4 references account(id) ON DELETE RESTRICT,
        name            TEXT NOT NULL,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE OR REPLACE VIEW tax_current AS
SELECT * FROM taxdetail
WHERE id IN (
	SELECT MAX(id)
	FROM taxdetail
	GROUP BY tax
);

CREATE TABLE taxrate (
        id              SERIAL PRIMARY KEY,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE taxratedetail (
        id              SERIAL PRIMARY KEY,
        taxrate         INT4 references taxrate(id) ON DELETE RESTRICT NOT NULL
		DEFAULT currval(pg_get_serial_sequence('taxrate','id')),
        tax             INT4 references tax(id) ON DELETE RESTRICT NOT NULL
		DEFAULT currval(pg_get_serial_sequence('tax','id')),
        rate            NUMERIC,
        valid_from      timestamp,
        valid_to        timestamp,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE OR REPLACE VIEW taxrate_current AS
SELECT * FROM taxratedetail
WHERE id IN (
	SELECT MAX(id)
	FROM taxratedetail
	GROUP BY taxrate
);

-- Round half to even, aka. "bankers" rounding --
-- amount: number to round
-- dp: number of decimal places to round to
-- RETURN NUMERIC rounded number
CREATE OR REPLACE FUNCTION roundhalfeven(amount NUMERIC, dp INT4)
RETURNS NUMERIC AS
$$
DECLARE
	a	NUMERIC; /* somewhere to work */
	lastp	NUMERIC; /* the decimal digit *after* the one to round */
	penp	NUMERIC; /* the decimal digit we're rounding at */
BEGIN
	lastp := (trunc(amount, dp + 1) - trunc(amount, dp)) * power(10, dp + 1);
	penp := (trunc(amount, dp) - trunc(amount, dp - 1)) * power(10, dp);
	IF lastp = '5' THEN
		IF penp % 2 <> 0 THEN
			a := trunc(amount, dp) + power(10, -dp); /* round up */
		ELSE
			a := trunc(amount, dp); /* round down */
		END IF;
	ELSIF lastp < '5' THEN
		a := trunc(amount, dp); /* no need to round, just truncate */
	ELSE
		a := trunc(amount, dp) + power(10, -dp); /* round up */
	END IF;

	/* return the requested number of decimal places */
	a := a + ('0.' || rpad('0',dp,'0'))::NUMERIC;

	RETURN a;
END;
$$ LANGUAGE 'plpgsql';

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
                        NEW.name := oname;
                END IF;
                IF NEW.terms IS NULL THEN
                        NEW.terms := oterms;
                END IF;
                IF NEW.billcontact IS NULL THEN
                        NEW.billcontact := obillcontact;
                END IF;
                IF NEW.is_active IS NULL THEN
                        NEW.is_active := ois_active;
                END IF;
                IF NEW.is_suspended IS NULL THEN
                        NEW.is_suspended := ois_suspended;
                END IF;
                IF NEW.is_vatreg IS NULL THEN
                        NEW.is_vatreg := ois_vatreg;
                END IF;
                IF NEW.vatnumber IS NULL THEN
                        NEW.vatnumber := ovatnumber;
                END IF;
        ELSE
                /* set defaults */
                IF NEW.terms IS NULL THEN
                        NEW.terms := 30;
                END IF;
                IF NEW.is_active IS NULL THEN
                        NEW.is_active := 'true';
                END IF;
                IF NEW.is_suspended IS NULL THEN
                        NEW.is_suspended := 'false';
                END IF;
                IF NEW.is_vatreg IS NULL THEN
                        NEW.is_vatreg := 'false';
                END IF;
        END IF;
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- when INSERTing into contactdetail, check for previous records
-- for this contact, and use those values in place of any values
-- not supplied.
CREATE OR REPLACE FUNCTION contactdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        ois_active      boolean;
        ois_deleted     boolean;
        oname           TEXT;
        oline_1         TEXT;
        oline_2         TEXT;
        oline_3         TEXT;
        otown           TEXT;
        ocounty         TEXT;
        ocountry        TEXT;
        opostcode       TEXT;
        oemail          TEXT;
        ophone          TEXT;
        ophonealt       TEXT;
        omobile         TEXT;
        ofax            TEXT;
BEGIN
        SELECT INTO priorentries COUNT(id) FROM contactdetail
                WHERE contact = NEW.contact;
        IF priorentries > 0 THEN
                -- This isn't our first time, so use previous values 
                SELECT INTO
                        ois_active, ois_deleted, oname, oline_1, oline_2,
                        oline_3, otown, ocounty, ocountry, opostcode, oemail,
                        ophone, ophonealt, omobile, ofax

                        is_active, is_deleted, name, line_1, line_2,
                        line_3, town, county, country, postcode, email,
                        phone, phonealt, mobile, fax

                FROM contactdetail WHERE id IN (
                        SELECT MAX(id)
                        FROM contactdetail
                        GROUP BY contact
                )
                AND contact = NEW.contact;

                IF NEW.is_active IS NULL THEN
                        NEW.is_active := ois_active;
                END IF;
                IF NEW.is_deleted IS NULL THEN
                        NEW.is_deleted := ois_deleted;
                END IF;
                IF NEW.name IS NULL THEN
                        NEW.name := oname;
                END IF;
                IF NEW.line_1 IS NULL THEN
                        NEW.line_1 := oline_1;
                END IF;
                IF NEW.line_2 IS NULL THEN
                        NEW.line_2 := oline_2;
                END IF;
                IF NEW.line_3 IS NULL THEN
                        NEW.line_3 := oline_3;
                END IF;
                IF NEW.town IS NULL THEN
                        NEW.town := otown;
                END IF;
                IF NEW.county IS NULL THEN
                        NEW.county := ocounty;
                END IF;
                IF NEW.country IS NULL THEN
                        NEW.country := ocountry;
                END IF;
                IF NEW.postcode IS NULL THEN
                        NEW.postcode := opostcode;
                END IF;
                IF NEW.email IS NULL THEN
                        NEW.email := oemail;
                END IF;
                IF NEW.phone IS NULL THEN
                        NEW.phone := ophone;
                END IF;
                IF NEW.phonealt IS NULL THEN
                        NEW.phonealt := ophonealt;
                END IF;
                IF NEW.mobile IS NULL THEN
                        NEW.mobile := omobile;
                END IF;
                IF NEW.fax IS NULL THEN
                        NEW.fax := ofax;
                END IF;
        ELSE
                /* set defaults */
                IF NEW.is_active IS NULL THEN
                        NEW.is_active := 'true';
                END IF;
                IF NEW.is_deleted IS NULL THEN
                        NEW.is_deleted := 'false';
                END IF;
        END IF;
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';


-- createpayment() - create a sales/purchasepayment from a bank entry --
-- 	type:  'sales' or 'purchase'
-- 	bank: id from bank table
-- 	organisation: id from organisation table
-- RETURNS INT4 id of new row
CREATE OR REPLACE FUNCTION createpayment(type TEXT, bankid INT4, organisation INT4)
RETURNS INT4 AS
$$
DECLARE
	idtable		TEXT;
	detailtable	TEXT;
	baccount	INT4;
	bpaymenttype	INT4;
	btransactdate	DATE;
	bdescription	TEXT;
	bdebit		NUMERIC;
	bcredit		NUMERIC;
	payment		NUMERIC;
	paymentid	INT4;
	ifound		INT4;
BEGIN
	-- check arguments --
	IF type <> 'sales' AND type <> 'purchase' THEN
		RAISE EXCEPTION 'createpayment() called with invalid type';
	END IF;
	
	idtable = type || 'payment';
	detailtable = idtable || 'detail';

	-- get bank entry details --
	SELECT INTO
		bpaymenttype, btransactdate, bdebit, bcredit, bdescription,
		baccount
		paymenttype, transactdate, debit, credit, 
		COALESCE(description, ''), account
	FROM bankdetail
	WHERE id IN (
		SELECT MAX(id)
		FROM bankdetail
		GROUP BY bank
	)
	AND bank = bankid;

	IF btransactdate IS NULL THEN
		RAISE EXCEPTION 'createpayment() called with invalid bankid';
	END IF;

	-- check that there isn't already an entry with this bankid --
	EXECUTE format('SELECT id FROM %I WHERE id IN (SELECT MAX(id) FROM %I GROUP BY %I) AND bank=''%s'';', 
	detailtable, detailtable, idtable, bankid);
	GET DIAGNOSTICS ifound = ROW_COUNT;
	IF ifound > 0 THEN
		RAISE EXCEPTION 'bank entry already present';
	END IF;

	-- calculate payment with correct sign --
	IF type = 'sales' THEN
		payment = COALESCE(bdebit, '0') - COALESCE(bcredit, '0');
	ELSE
		payment = COALESCE(bcredit, '0') - COALESCE(bdebit, '0');
	END IF;

	-- create payment entry --
	EXECUTE format('INSERT INTO %I DEFAULT VALUES;', idtable);

	EXECUTE format('SELECT currval(pg_get_serial_sequence(''%I'',''id''));',
	idtable) INTO paymentid;

	EXECUTE format('
	INSERT INTO %I (
		%I,
		paymenttype,
		organisation,
		bankaccount,
		bank,
		transactdate,
		amount,
		description
	) VALUES (
		currval(pg_get_serial_sequence(''%I'',''id'')),
		''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s''
	);', detailtable, idtable, idtable, bpaymenttype,
	organisation, baccount, bankid, btransactdate, payment, bdescription
	);

	-- return id of new payment entry --
	RETURN paymentid;
END;
$$ LANGUAGE 'plpgsql';


-- postpayment() - create a journal entry from a sales/purchasepayment --
--      type:  'sales' or 'purchase'
--      paymentid: id from sales/purchasepayment table
-- RETURNS INT4 id of new row
CREATE OR REPLACE FUNCTION postpayment(type TEXT, paymentid INT4)
RETURNS INT4 AS
$$
DECLARE
        idtable         TEXT;
	detailtable     TEXT;
	journalid	INT4;
	accountid	INT4;
	transactdate	DATE;
	description	TEXT;
	bankaccount	INT4;
	bankid		INT4;
	amount		NUMERIC;
	dc1		TEXT;
	dc2		TEXT;
BEGIN
	-- type gives us which account code to post against --
	IF type = 'sales' THEN
		accountid := '1100'; -- 1100 = Debtors Control Account
	ELSIF type = 'purchase' THEN
		accountid := '2100'; -- 2100 = Creditors Control Account
	ELSE
		RAISE EXCEPTION 'postpayment() called with invalid type';
	END IF;

	-- which tables are we using? --
	idtable := type || 'payment';
	detailtable := idtable || 'detail';

	-- fetch details of payment --
	EXECUTE 'SELECT transactdate, description, amount, bankaccount, bank ' ||
	format ('FROM %I WHERE id IN (', detailtable) ||
	format ('SELECT MAX(id) FROM %I GROUP BY %I', detailtable, idtable) ||
	format (') AND %I = ''%s'';', idtable, paymentid)
	INTO transactdate, description, amount, bankaccount, bankid;

	-- work out debits & credits --
	IF type = 'sales' THEN
		/* positive sales payments are credit
		  (decrease the asset) */
		IF amount > 0 THEN
			dc1 := 'credit';
			dc2 := 'debit';
		ELSE
			dc1 := 'debit';
			dc2 := 'credit';
		END IF;
	ELSE 
		/* positive purchase payments are debits 
		   (decrease the liability) */
		IF amount > 0 THEN
			dc1 := 'debit';
			dc2 := 'credit';
		ELSE
			dc1 := 'credit';
			dc2 := 'debit';
		END IF;
	END IF;
	
	-- entry in journal table --
	EXECUTE 'INSERT INTO journal (transactdate,description) VALUES ' ||
	format('(''%s'',''%s'');', transactdate, description);

	SELECT journal_id_last() INTO journalid;

	-- ledger lines --
	EXECUTE format('INSERT INTO ledger (journal, account, %I) ', dc1) ||
	'VALUES (journal_id_last(),' ||
	format('''%s'',''%s'');', accountid, ABS(amount));

	EXECUTE format('INSERT INTO ledger (journal, account, %I) ', dc2) ||
	'VALUES (journal_id_last(),' ||
	format('''%s'',''%s'');', bankaccount, ABS(amount));

	-- update bank entry, if applicable --
	IF bankid is not null THEN
		EXECUTE 'INSERT INTO bankdetail (bank, journal) VALUES ' ||
		format('(''%s'',''%s'');', bankid, journalid);
	END IF;

	-- return id of new journal entry --
	RETURN journalid;
END;
$$ LANGUAGE 'plpgsql';

-- ---------------------------------------------------------------------------
-- Gladbooks Default Org ID style 8+ char based on organisation name
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION organisation_orgcode(organisation_name TEXT)
RETURNS TEXT AS
$$
DECLARE
        neworgcode      TEXT;
        conflicts       INT4;
        idlen           INT4;
BEGIN
        idlen := 8;
        neworgcode := regexp_replace(organisation_name,'[^a-zA-Z0-9]+','','g');
        neworgcode := substr(neworgcode, 1, idlen);
        neworgcode := upper(neworgcode);
        SELECT INTO conflicts COUNT(id) FROM organisation
                WHERE orgcode = neworgcode;
        WHILE conflicts != 0 OR char_length(neworgcode) < idlen LOOP
                neworgcode = substr(neworgcode, 1, idlen - 1);
                neworgcode = neworgcode || chr(int4(random() * 25 + 65));
                SELECT INTO conflicts COUNT(id) FROM organisation
                        WHERE orgcode LIKE neworgcode || '%';
                IF conflicts > 25 THEN
                        idlen := idlen + 1;
                END IF;
        END LOOP;
        RETURN neworgcode;
END;
$$ LANGUAGE 'plpgsql';

-- the first time we write to organisationdetail with a new organisation
-- we set the orgcode in organisation based on organisationdetail.name
CREATE OR REPLACE FUNCTION set_orgcode()
RETURNS TRIGGER AS
$$
BEGIN
        UPDATE organisation SET orgcode = organisation_orgcode(NEW.name)
                WHERE id = NEW.organisation AND orgcode IS NULL;
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- ---------------------------------------------------------------------------
-- each organisation has its own unique gapless sequences for orders, invoices
-- etc.
-- ---------------------------------------------------------------------------

-- purchase order sequences

CREATE OR REPLACE FUNCTION organisation_purchaseorder_next(organisation_id INT4)
RETURNS INT4 AS
$$
DECLARE
        next_pk INT4;
BEGIN
        UPDATE organisation SET purchaseorder = purchaseorder + 1
                WHERE id = organisation_id;
        SELECT INTO next_pk purchaseorder FROM organisation
                WHERE id = organisation_id;
        RETURN next_pk;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION set_organisation_purchaseorder()
RETURNS TRIGGER AS
$$
BEGIN
        NEW.ordernum := organisation_purchaseorder_next(NEW.organisation);
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- purchase invoice sequences

CREATE OR REPLACE FUNCTION organisation_purchaseinvoice_next(organisation_id INT4)
RETURNS INT4 AS
$$
DECLARE
        next_pk INT4;
BEGIN
        UPDATE organisation SET purchaseinvoice = purchaseinvoice + 1
                WHERE id = organisation_id;
        SELECT INTO next_pk purchaseinvoice FROM organisation
                WHERE id = organisation_id;
        RETURN next_pk;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION set_organisation_purchaseinvoice()
RETURNS TRIGGER AS
$$
BEGIN
        NEW.invoicenum := organisation_purchaseinvoice_next(NEW.organisation);
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- salesorder sequences

CREATE OR REPLACE FUNCTION organisation_salesorder_next(organisation_id INT4)
RETURNS INT4 AS
$$
DECLARE
        next_pk INT4;
BEGIN
        UPDATE organisation SET salesorder = salesorder + 1
                WHERE id = organisation_id;
        SELECT INTO next_pk salesorder FROM organisation
                WHERE id = organisation_id;
        RETURN next_pk;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION set_organisation_salesorder()
RETURNS TRIGGER AS
$$
BEGIN
        NEW.ordernum = organisation_salesorder_next(NEW.organisation);
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- salesinvoice sequences

CREATE OR REPLACE FUNCTION organisation_salesinvoice_next(organisation_id INT4)
RETURNS INT4 AS
$$
DECLARE
        next_pk INT4;
BEGIN
        UPDATE organisation SET salesinvoice = salesinvoice + 1
                WHERE id = organisation_id;
        SELECT INTO next_pk salesinvoice FROM organisation
                WHERE id = organisation_id;
        RETURN next_pk;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION set_organisation_salesinvoice()
RETURNS TRIGGER AS
$$
BEGIN
        NEW.invoicenum = organisation_salesinvoice_next(NEW.organisation);
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- ensure ledger table debits and credits are in balance
CREATE OR REPLACE FUNCTION check_ledger_balance()
RETURNS trigger AS $check_ledger_balance$
        DECLARE
                balance NUMERIC;

        BEGIN
                SELECT SUM(debit) - SUM(credit) INTO balance FROM ledger;
                IF balance <> 0 THEN
                        RAISE EXCEPTION 'ledger does not balance';
                END IF;
                RETURN NEW;
        END;
$check_ledger_balance$ LANGUAGE plpgsql;

-- ensure the ledger entries for a new journal balance
CREATE OR REPLACE FUNCTION check_transaction_balance()
RETURNS trigger AS $check_transaction_balance$
        DECLARE
                balance NUMERIC;

        BEGIN
                SELECT SUM(debit) - SUM(credit) INTO balance
                FROM ledger
                WHERE journal=currval(pg_get_serial_sequence('journal','id'));
                IF balance <> 0 THEN
                        RAISE EXCEPTION 'transaction does not balance';
                END IF;
                RETURN NEW;
        END;
$check_transaction_balance$ LANGUAGE plpgsql;

-- ensure payment allocations do not exceed amount of payment
CREATE OR REPLACE FUNCTION check_payment_allocation()
RETURNS trigger AS $check_payment_allocation$
DECLARE
	payment		NUMERIC;
	allocated	NUMERIC;
	type		TEXT;
	paymentid	INT4;
	idtable		TEXT;
	detailtable	TEXT;
BEGIN
	type := quote_ident(TG_ARGV[0]);
	paymentid := NEW.payment;

        -- check arguments --
	IF type <> 'sales' AND type <> 'purchase' THEN
		RAISE EXCEPTION '%I() called with invalid type', TG_NAME;
	END IF;

	-- find amount of payment --
	idtable := type || 'payment';
	detailtable := idtable || 'detail';
	EXECUTE format('SELECT amount FROM %I WHERE id IN ', detailtable) ||
	format('(SELECT MAX(id) FROM %I GROUP BY %I) ',detailtable,idtable) ||
	format('AND %I=''%s'';', idtable, paymentid)
	INTO payment;

	-- how much have we allocated? --
	idtable = type || 'paymentallocation';
	detailtable := idtable || 'detail';
	EXECUTE 'SELECT SUM(amount) ' ||
	format('FROM %I WHERE id IN ', detailtable) ||
	format('(SELECT MAX(id) FROM %I GROUP BY %I) ',detailtable,idtable) ||
	format('AND payment=''%s'';', paymentid)
	INTO allocated;

	IF allocated > payment THEN
		RAISE EXCEPTION 'payment over-allocated';
	END IF;

	RETURN NEW;

END;
$check_payment_allocation$ LANGUAGE plpgsql;

-- trigger to ensure each period is only issued once per salesorder
CREATE OR REPLACE FUNCTION check_salesorder_period()
RETURNS trigger AS $$
DECLARE
BEGIN
	PERFORM id
	FROM salesinvoicedetail
	WHERE id IN (
		SELECT MAX(id)
		FROM salesinvoicedetail
		GROUP BY salesinvoice
	)
	AND period = NEW.period
	AND salesorder = NEW.salesorder;
	IF FOUND THEN
		RAISE EXCEPTION 'salesinvoice with period % already exists for salesorder %', NEW.period, NEW.salesorder;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';


-- process_salesorders() - create salesinvoices from open salesorders --
-- RETURN INT4 number of salesorders processed --
CREATE OR REPLACE FUNCTION process_salesorders()
RETURNS INT4 as $process_salesorders$
DECLARE
	sos	INT4;
	so	RECORD;
BEGIN
	sos := '0';

	FOR so IN 
		SELECT * FROM salesorderdetail
		WHERE id IN (
			SELECT MAX(id)
			FROM salesorderdetail
			GROUP BY salesorder
		)
		AND is_open = true
		AND is_deleted = false
		AND cycle > 0
	LOOP
		PERFORM process_salesorder(so.salesorder);
		sos := sos + 1;
	END LOOP;
	
	RETURN sos;
END;
$process_salesorders$ LANGUAGE 'plpgsql';

-- process_salesorder() - create missing salesinvoices for a given salesorder
-- RETURN INT4 number of salesinvoices generated
CREATE OR REPLACE FUNCTION process_salesorder(soid INT4)
RETURNS INT4 as $$
DECLARE
	so			RECORD;
	so_due			INT4;
	so_raised		INT4;
	periods_unissued	INT4;
	period			INT4;
BEGIN
	RAISE NOTICE 'Processing salesorder';

	-- fetch the salesorder and cycle info --
	SELECT sod.*, c.years, c.months, c.days INTO so
	FROM salesorderdetail sod
	INNER JOIN cycle c ON sod.cycle = c.id
	WHERE sod.id IN (
	   SELECT MAX(id)
	   FROM salesorderdetail
	   WHERE salesorder=soid
	);

	-- figure out how many salesinvoices there should be --
	IF so.cycle = '1' THEN
		so_due := '1';
	ELSE
		so_due := periods_between(so.years,so.months,so.days,so.start_date, COALESCE(so.end_date, DATE(NOW())));
	END IF;

	-- fetch invoices already raised against this salesorder --
	SELECT COUNT(*) INTO so_raised
	FROM salesinvoicedetail
	WHERE id IN (
		SELECT MAX(id)
		FROM salesinvoicedetail
		GROUP BY salesinvoice
	)
	AND salesorder = soid;

	RAISE NOTICE '% / % invoices raised', so_raised, so_due;

	periods_unissued := so_due - so_raised;

	IF periods_unissued > 0 THEN
		-- first, work out which periods are missing --
		FOR period IN
			SELECT generate_series(1, so_due) AS period
			EXCEPT
			SELECT soid.period
			FROM salesinvoicedetail soid
			WHERE id IN (
				SELECT MAX(id)
				FROM salesinvoicedetail
				GROUP BY salesinvoice
			)
			AND salesorder = so.salesorder
			ORDER BY period 
		LOOP
			RAISE NOTICE 'Issue period: %', period;
			PERFORM create_salesinvoice(soid, period);
		END LOOP;
	ELSIF periods_unissued < 0 THEN
		RAISE EXCEPTION 'too many salesinvoices exist for salesorder %', soid;
	END IF;

	RETURN periods_unissued;
END;
$$ LANGUAGE 'plpgsql';

-- create_salesinvoice()
-- create a salesinvoice from a salesorder for the given period
-- RETURNS BOOLEAN success/fail
CREATE OR REPLACE FUNCTION create_salesinvoice(so_id INT4, period INT4)
RETURNS boolean AS $$
DECLARE
	r_so		RECORD;
	r_soi		RECORD;
	r_tax		RECORD;
	taxpoint	DATE;
	endpoint	DATE;
	due		DATE;
	termdays	INT4;
	terminterval	TEXT;
	si_id		INT4;
BEGIN
	-- fetch the salesorder and cycle info --
	-- FIXME: this is inefficient
	-- - we had this information in process_salesorder()
	SELECT so.*, c.years, c.months, c.days INTO r_so
	FROM salesorder_current so
	INNER JOIN cycle c ON so.cycle = c.id
	WHERE so.salesorder=so_id;

	taxpoint := taxpoint(r_so.years, r_so.months, r_so.days, r_so.start_date, period);
	endpoint := periodenddate(r_so.years, r_so.months, r_so.days, r_so.start_date, period);

	RAISE NOTICE 'Start Date is: %', r_so.start_date;
	RAISE NOTICE 'Period is: %', period;
	RAISE NOTICE 'Tax Point is: %', taxpoint;
	RAISE NOTICE 'Period End Date is: %', endpoint;

	-- fetch terms for organisation --
	SELECT terms INTO termdays FROM organisation_current
	WHERE organisation = r_so.organisation;

	terminterval := termdays || ' days';
	due := taxpoint + terminterval::interval;

	INSERT INTO salesinvoice (organisation) VALUES (r_so.organisation);

	-- salesinvoiceitem
	--TODO: linetext macro substitution
	FOR r_soi IN
		SELECT 
			soi.product,
			COALESCE(soi.linetext, p.description) AS linetext,
			soi.discount,
			COALESCE(soi.price, p.price_sell) as price,
			soi.qty
		FROM salesorderitem_current soi
		INNER JOIN product_current p ON p.id = soi.product
		WHERE salesorder = so_id
	LOOP
		INSERT INTO salesinvoiceitem DEFAULT VALUES;
		INSERT INTO salesinvoiceitemdetail (
			product,
			linetext,
			discount,
			price,
			qty
		) VALUES (
			r_soi.product,
			r_soi.linetext,
			r_soi.discount,
			r_soi.price,
			r_soi.qty
		);
	END LOOP;

	INSERT INTO salesinvoicedetail (
		salesorder, period, ponumber, 
		taxpoint, endpoint, due
	) VALUES (
		so_id, period, r_so.ponumber, 
		taxpoint, endpoint, due
	);

	RETURN true;
END;
$$ LANGUAGE 'plpgsql';

-- salesorder_nextissuedate() - return the date when the salesorder will next
-- be issued
-- RETURN DATE
CREATE OR REPLACE FUNCTION salesorder_nextissuedate(so INT4)
RETURNS DATE AS $$
DECLARE
	nextissue	DATE;
	socycle		INT4;
	lastperiod	INT4;
	so_cycle	INT4;
	so_start_date	DATE;
	so_years	INT4;
	so_months	INT4;
	so_days		INT4;
BEGIN
	-- check which cycle this salesorder is on --
	SELECT sod.cycle, sod.start_date, c.years, c.months, c.days 
	INTO so_cycle, so_start_date, so_years, so_months, so_days
	FROM salesorderdetail sod
	INNER JOIN cycle c ON c.id = sod.cycle
	WHERE sod.id IN (
		SELECT MAX(id)
		FROM salesorderdetail
		GROUP BY salesorder
	)
	AND sod.salesorder = so;
	IF NOT FOUND THEN
		RETURN NULL;
	END IF;

	IF so_cycle = '0' THEN
		RETURN NULL; 		/* never */
	ELSIF so_cycle = '1' THEN
		RETURN DATE(NOW()); 	/* once => today */
	END IF;

	-- recurring salesorder: which was the last period issued? --
	SELECT MAX(period) INTO lastperiod
	FROM salesinvoice_current
	WHERE salesorder = so;

	SELECT taxpoint(so_years, so_months, so_days, so_start_date, lastperiod + 1) INTO nextissue;

	RETURN nextissue;
END;
$$ LANGUAGE 'plpgsql';


-- trigger to update totals and tax for salesinvoice
CREATE OR REPLACE FUNCTION updatesalesinvoicetotals()
RETURNS trigger AS $$
DECLARE
BEGIN
	-- set subtotal for this invoice --
	/*
	SELECT SUM(price * qty) INTO NEW.subtotal
	FROM salesinvoiceitem_current
	WHERE salesinvoice = NEW.salesinvoice;
	*/

	-- salesinvoice_tax - record taxes charged for future reference
	-- the rates and dates in the tax tables may change, and we want
	-- a permanent record of what taxes were applied to *this* invoice
	INSERT INTO salesinvoice_tax (
		salesinvoice,
		taxname,
		rate,
		nett,
		total
	) 
	SELECT
		sii.salesinvoice,
		t.name AS taxname,
		tr.rate,
		SUM(sii.price * sii.qty) AS nett,
		roundhalfeven(SUM(sii.price * sii.qty) * tr.rate/100, 2) AS total
	FROM
		salesinvoice_current si
		LEFT JOIN salesinvoiceitem_current sii 
		ON si.salesinvoice = sii.salesinvoice
		LEFT JOIN product_tax pt ON sii.product = pt.product
		INNER JOIN tax_current t ON t.tax = pt.tax
		INNER JOIN taxrate_current tr ON tr.tax = pt.tax
	WHERE (tr.valid_from <= si.taxpoint OR tr.valid_from IS NULL)
	AND (tr.valid_to >= si.taxpoint OR  tr.valid_to IS NULL)
	AND si.salesinvoice = NEW.salesinvoice
	GROUP BY sii.salesinvoice, t.name, tr.rate
	;

	--NEW.total := NEW.subtotal + NEW.tax;

        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';


-- calculate the number of periods or part thereof 
-- between start_date and end_date --
-- RETURNS INT4    "    "    "       "         "            "      --
CREATE OR REPLACE FUNCTION periods_between(years INT4, months INT4, days INT4, start_date DATE, end_date DATE)
RETURNS INT4 as $$
DECLARE
	jump		DATE;
	periods		INT4;
	y_interval	TEXT;
	m_interval	TEXT;
	d_interval	TEXT;
BEGIN

	jump := start_date;
	periods := 0;

	y_interval := years || ' year';
	m_interval := months ||' month';
	d_interval := days || ' day';

	WHILE jump < end_date LOOP
		jump := jump + y_interval::interval;
		jump := jump + m_interval::interval;
		jump := jump + d_interval::interval;
		periods := periods + 1;
	END LOOP;

	RETURN periods;
END;
$$ LANGUAGE 'plpgsql';

-- taxpoint()
-- calculate the taxpoint based on the start date and periods elapsed
-- tax point for period 1 is the start date, otherwise jump forward 
-- the appropriate number of periods to find the date
-- RETURNS DATE taxpoint
CREATE OR REPLACE FUNCTION taxpoint(years INT4, months INT4, days INT4, start_date DATE, period INT4)
RETURNS DATE as $$
DECLARE
	taxpoint	DATE;
	y_interval	TEXT;
	m_interval	TEXT;
	d_interval	TEXT;
BEGIN
	IF start_date IS NULL THEN
		IF COALESCE(years, '0') <> '0' 
		OR COALESCE(months, '0') <> '0' 
		OR COALESCE(days, '0') <> '0' 
		THEN
			RAISE EXCEPTION 'start_date is null on recurring salesorder';
		END IF;
		RETURN DATE(NOW()); -- no start date, tax point is today
	END IF;

	period := period - 1;
	taxpoint := start_date;

	y_interval := period * COALESCE(years, '0') || ' year';
	m_interval := period * COALESCE(months, '0') || ' month';
	d_interval := period * COALESCE(days, '0') || ' day';

	taxpoint := taxpoint + y_interval::interval;
	taxpoint := taxpoint + m_interval::interval;
	taxpoint := taxpoint + d_interval::interval;

	RETURN taxpoint;
END;
$$ LANGUAGE 'plpgsql';

-- periodenddate()
-- last day of the period => tax point of next period, less one day --
-- RETURNS DATE end_date
CREATE OR REPLACE FUNCTION periodenddate(years INT4, months INT4, days INT4, start_date DATE, period INT4)
RETURNS DATE as $$
DECLARE
	end_date	DATE;
	y_interval	TEXT;
	m_interval	TEXT;
	d_interval	TEXT;
BEGIN
	end_date := start_date;

	y_interval := period * COALESCE(years, '0') || ' year';
	m_interval := period * COALESCE(months, '0') || ' month';
	d_interval := period * COALESCE(days, '0') || ' day';

	end_date := end_date + y_interval::interval;
	end_date := end_date + m_interval::interval;
	end_date := end_date + d_interval::interval;
	end_date := end_date - interval '1 day';

	RETURN end_date;
END;
$$ LANGUAGE 'plpgsql';

-- Numbers can be beautiful --
CREATE OR REPLACE FUNCTION format_accounting(amount NUMERIC)
RETURNS TEXT AS
$$
DECLARE
        pretty  TEXT;
BEGIN
        SELECT INTO pretty to_char(amount, '9,999,999,990.00PR');
        -- Angle brackets?  Seriously?  Why?
        pretty = replace(pretty, '<', '(');
        pretty = replace(pretty, '>', ')');
        IF amount > 0 THEN
                -- add trailing space for positive numbers
                pretty = pretty || ' ';
        END IF;
        RETURN pretty;
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

-- Relationships
INSERT INTO relationship (id, name) VALUES (0, 'contact');
INSERT INTO relationship (name) VALUES ('billing');
INSERT INTO relationship (name) VALUES ('shipping');
