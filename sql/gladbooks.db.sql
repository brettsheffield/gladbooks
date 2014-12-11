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
        oledger         INT4;
        odebit          NUMERIC;
        ocredit         NUMERIC;
BEGIN
        SELECT INTO priorentries COUNT(id) FROM bankdetail
                WHERE bank = NEW.bank;
        IF priorentries > 0 THEN
                -- This isn't our first time, so use previous values 
                SELECT INTO
                        otransactdate, odescription, oaccount, opaymenttype,
                        oledger, odebit, ocredit
                        transactdate, description, account, paymenttype,
                        ledger, debit, credit
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
                IF NEW.ledger IS NULL THEN
                        NEW.ledger := oledger;
                END IF;
                IF NEW.ledger = 0 THEN
                        NEW.ledger := NULL;
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

CREATE OR REPLACE FUNCTION accountinsert()
RETURNS TRIGGER AS
$$
BEGIN
	UPDATE accounttype SET last_id = NEW.id
	WHERE accounttype=NEW.accounttype;
        RETURN NULL; /* after, so result ignored */
END;
$$ LANGUAGE 'plpgsql';

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


CREATE OR REPLACE FUNCTION ledger_id_last()
returns int4 AS
$$
DECLARE
        last_pk int4;
BEGIN
        SELECT INTO last_pk ledger_pk FROM ledger_pk_counter;
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
                        NEW.terms := 14;
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

CREATE OR REPLACE FUNCTION productdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        oaccount        INT4;
        oshortname	TEXT;
        odescription	TEXT;
        oprice_buy      NUMERIC;
        oprice_sell     NUMERIC;
        omargin		NUMERIC;
        omarkup		NUMERIC;
        ois_available	boolean;
        ois_offered	boolean;
BEGIN
        SELECT INTO priorentries COUNT(id) FROM productdetail
                WHERE product = NEW.product;
        IF priorentries > 0 THEN
                -- This isn't our first time, so use previous values 
                SELECT INTO
                        oaccount, oshortname, odescription, oprice_buy,
			oprice_sell, omargin, omarkup, ois_available,
			ois_offered
                        account, shortname, description, price_buy,
			price_sell, margin, markup, is_available,
			is_offered
                FROM productdetail WHERE id IN (
                        SELECT MAX(id)
                        FROM productdetail
                        GROUP BY product
                )
                AND product = NEW.product;

                IF NEW.account IS NULL THEN
                        NEW.account := oaccount;
                END IF;
                IF NEW.shortname IS NULL THEN
                        NEW.shortname := oshortname;
                END IF;
                IF NEW.description IS NULL THEN
                        NEW.description := odescription;
                END IF;
                IF NEW.price_buy IS NULL THEN
                        NEW.price_buy := oprice_buy;
                END IF;
                IF NEW.price_sell IS NULL THEN
                        NEW.price_sell := oprice_sell;
                END IF;
                IF NEW.margin IS NULL THEN
                        NEW.margin := omargin;
                END IF;
                IF NEW.markup IS NULL THEN
                        NEW.markup := omarkup;
                END IF;
                IF NEW.is_available IS NULL THEN
                        NEW.is_available := ois_available;
                END IF;
                IF NEW.is_offered IS NULL THEN
                        NEW.is_offered := ois_offered;
                END IF;
        END IF;
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- trigger to ensure business has a related organisation, 
-- creating one if required
CREATE OR REPLACE FUNCTION businessorganisation()
RETURNS TRIGGER AS
$$
DECLARE
	neworgcode		TEXT;
BEGIN
	IF NEW.organisation IS NULL THEN
		INSERT INTO organisation DEFAULT VALUES;
		INSERT INTO organisationdetail(name) VALUES (NEW.name);
		NEW.organisation = 
			currval(pg_get_serial_sequence('organisation','id'));
		SELECT orgcode INTO neworgcode FROM organisation 
		WHERE id =
			currval(pg_get_serial_sequence('organisation','id'));
		PERFORM create_business_dirs(neworgcode);
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
	ledgerid	INT4;
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

	SELECT ledger_id_last() INTO ledgerid;

	-- update bank entry, if applicable --
	IF bankid is not null THEN
		EXECUTE 'INSERT INTO bankdetail (bank, ledger) VALUES ' ||
		format('(''%s'',''%s'');', bankid, ledgerid);
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
        x		INT4;
BEGIN
        idlen := 8;
        x := 0;
        neworgcode := regexp_replace(organisation_name,'[^a-zA-Z0-9]+','','g');
        neworgcode := substr(neworgcode, 1, idlen);
        neworgcode := upper(neworgcode);
        SELECT INTO conflicts COUNT(id) FROM organisation
                WHERE orgcode = neworgcode;
        WHILE conflicts != 0 OR char_length(neworgcode) < idlen LOOP
                neworgcode = substr(neworgcode, 1, idlen - 1);
		x := x + 1;
                neworgcode = neworgcode || chr(x + 64);
                SELECT INTO conflicts COUNT(id) FROM organisation
                        WHERE orgcode LIKE neworgcode || '%';
                IF x > 25 THEN
                        idlen := idlen + 1;
        		x := 0;
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
	-- create entry in organisationsequence if not exists
        SELECT INTO next_pk id FROM organisationsequence
                WHERE id = organisation_id;
	IF next_pk IS NULL THEN
		INSERT INTO organisationsequence(id) VALUES (organisation_id);
	END IF;

        UPDATE organisationsequence SET purchaseorder = purchaseorder + 1
                WHERE id = organisation_id;
        SELECT INTO next_pk purchaseorder FROM organisationsequence
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
	-- create entry in organisationsequence if not exists
        SELECT INTO next_pk id FROM organisationsequence
                WHERE id = organisation_id;
	IF next_pk IS NULL THEN
		INSERT INTO organisationsequence(id) VALUES (organisation_id);
	END IF;

        UPDATE organisationsequence SET purchaseinvoice = purchaseinvoice + 1
                WHERE id = organisation_id;
        SELECT INTO next_pk purchaseinvoice FROM organisationsequence
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
	-- create entry in organisationsequence if not exists
        SELECT INTO next_pk id FROM organisationsequence
                WHERE id = organisation_id;
	IF next_pk IS NULL THEN
		INSERT INTO organisationsequence(id) VALUES (organisation_id);
	END IF;

        UPDATE organisationsequence SET salesorder = salesorder + 1
                WHERE id = organisation_id;
        SELECT INTO next_pk salesorder FROM organisationsequence
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
	-- create entry in organisationsequence if not exists
        SELECT INTO next_pk id FROM organisationsequence
                WHERE id = organisation_id;
	IF next_pk IS NULL THEN
		INSERT INTO organisationsequence(id) VALUES (organisation_id);
	END IF;

        UPDATE organisationsequence SET salesinvoice = salesinvoice + 1
                WHERE id = organisation_id;
        SELECT INTO next_pk salesinvoice FROM organisationsequence
                WHERE id = organisation_id;
        RETURN next_pk;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION set_organisation_salesinvoice()
RETURNS TRIGGER AS
$$
BEGIN
	IF NEW.invoicenum IS NULL THEN
            NEW.invoicenum = organisation_salesinvoice_next(NEW.organisation);
	ELSE
	    UPDATE organisationsequence
	    SET salesinvoice = GREATEST(NEW.invoicenum,salesinvoice)
	    	WHERE id = NEW.organisation;
	END IF;
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION business_year_end()
RETURNS TRIGGER AS
$$
BEGIN
	IF NEW.period_end IS NULL THEN
		-- default period_end to one year after period_start
		NEW.period_end
		    = NEW.period_start + INTERVAL '1 year' - INTERVAL '1 day';
	END IF;
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
	end_date                DATE;
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
		-- do not issue 'once' invoices before start_date
		IF so.start_date > DATE(NOW()) THEN
			so_due := '0';
		ELSE
			so_due := '1';
		END IF;
	ELSE
		-- ensure we don't issue future dated invoices
		end_date := COALESCE(so.end_date, DATE(NOW()));
		IF end_date > DATE(NOW()) THEN
			end_date := DATE(NOW());
		END IF;
		so_due := periods_between(so.years,so.months,so.days,so.start_date,end_date);
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
		RAISE NOTICE 'too many salesinvoices exist for salesorder %', soid;
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
	IF NOT FOUND THEN
		RAISE EXCEPTION 'salesorder details not found';
	END IF;
	IF r_so.organisation IS NULL THEN
		RAISE EXCEPTION 'organisation for salesorder cannot be null';
	END IF;

	taxpoint := taxpoint(r_so.years, r_so.months, r_so.days, r_so.start_date, period);
	endpoint := periodenddate(r_so.years, r_so.months, r_so.days, r_so.start_date, period);

	-- fetch terms for organisation --
	SELECT terms INTO termdays FROM organisation_current
	WHERE id = r_so.organisation;

	terminterval := termdays || ' days';
	due := DATE(NOW()) + terminterval::interval;

	INSERT INTO salesinvoice (organisation) VALUES (r_so.organisation)
	RETURNING currval(pg_get_serial_sequence('salesinvoice','id')) 
	INTO si_id;

	IF si_id IS NULL THEN
		RAISE EXCEPTION 'Failed to INSERT salesinvoice';
	END IF;

	-- salesinvoiceitem
	--TODO: linetext macro substitution
	FOR r_soi IN
		SELECT 
			soi.product,
			COALESCE(soi.linetext, p.description) AS linetext,
			soi.discount,
			COALESCE(soi.price, p.price_sell, '0.00') as price,
			soi.qty
		FROM salesorderitem_current soi
		INNER JOIN product_current p ON p.product = soi.product
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
			roundhalfeven(r_soi.price, 2),
			r_soi.qty
		);
	END LOOP;

	INSERT INTO salesinvoicedetail (
		salesorder, period, ponumber, 
		taxpoint, endpoint, due
	) VALUES (
		so_id, period, r_so.ponumber, 
		taxpoint, COALESCE(endpoint,taxpoint), due
	);

	PERFORM create_salesinvoice_tex(si_id);

	IF NOT FOUND THEN
		RAISE EXCEPTION 'Failed to create .tex';
	END IF;

	PERFORM post_salesinvoice(si_id);  -- post to ledger
	PERFORM mail_salesinvoice(si_id);  -- email pdf

	RETURN true;
END;
$$ LANGUAGE 'plpgsql';

-- email PDF of salesinvoice to billing contacts
-- create email table entries, then trigger clerkd
-- TODO: check settings table to determine if autobilling on
CREATE OR REPLACE FUNCTION mail_salesinvoice(si_id INT4)
RETURNS INT4 AS $$
DECLARE
	billingname	TEXT;
	billingemail	TEXT;
	bodytext	TEXT;
	filename	TEXT;
	r		RECORD;
	r_to		RECORD;
BEGIN
	SELECT * INTO r FROM salesinvoice_current WHERE salesinvoice=si_id;

	-- select sender from business table
	SELECT billsendername, billsendermail INTO billingname, billingemail
	FROM business WHERE id = current_business();

	-- TODO: include content of invoice in body
	bodytext := 'Your invoice is attached';

	INSERT INTO email DEFAULT VALUES;
	INSERT INTO emaildetail (sendername, sendermail, body) 
	VALUES (billingname, billingemail, bodytext);
	INSERT INTO emailheader (header, value)
	VALUES ('Subject', 'Sales Invoice ' || r.ref);
	INSERT INTO emailheader (header, value)
	VALUES ('From', billingemail);
	INSERT INTO emailheader (header, value)
	VALUES ('X-Gladbooks-SalesInvoice', r.ref);

	-- attach file
	filename := '/var/spool/gladbooks/' || current_business_code() ||
		'/SI-'|| r.orgcode || '-' || to_char(r.invoicenum, 'FM0000') ||
		'.pdf';
	INSERT INTO emailpart (file) VALUES (filename);

	-- add billing contacts
	FOR r_to IN
		SELECT id, name, email FROM contact_current
		WHERE id IN (
			SELECT contact
			FROM organisation_contact
			WHERE relationship='1'
			AND organisation=r.organisation
		)
	LOOP
		INSERT INTO emailrecipient (
			contact, emailname, emailaddress, is_to
		) VALUES (r_to.contact, r_to.name, r_to.email, 'true');
	END LOOP;

	RETURN '0';
END;
$$ LANGUAGE 'plpgsql';

-- replace %%%MACRO%%% macros in document
CREATE OR REPLACE FUNCTION replacemacros(rawstr TEXT, taxpoint TIMESTAMP, endpoint TIMESTAMP)
RETURNS TEXT AS $$
DECLARE
	cooked	TEXT;
BEGIN

	-- %%%DAY%%%
	cooked = replace(rawstr, '%%%DAY%%%', to_char(taxpoint, 'DD'));

	-- %%%MONTH%%%
	cooked = replace(cooked, '%%%MONTH-2%%%',
		to_char(taxpoint - interval '2 months', 'Month'));
	cooked = replace(cooked, '%%%MONTH-1%%%',
		to_char(taxpoint - interval '1 month', 'Month'));
	cooked = replace(cooked, '%%%MONTH%%%', to_char(taxpoint, 'Month'));
	cooked = replace(cooked, '%%%MONTH+1%%%',
		to_char(taxpoint + interval '1 month', 'Month'));
	cooked = replace(cooked, '%%%MONTH+2%%%',
		to_char(taxpoint + interval '2 months', 'Month'));
	cooked = replace(cooked, '%%%MONTH+3%%%',
		to_char(taxpoint + interval '3 months', 'Month'));
	cooked = replace(cooked, '%%%MONTH+4%%%',
		to_char(taxpoint + interval '4 months', 'Month'));
	cooked = replace(cooked, '%%%MONTH+6%%%',
		to_char(taxpoint + interval '5 months', 'Month'));
	cooked = replace(cooked, '%%%MONTH+7%%%',
		to_char(taxpoint + interval '7 months', 'Month'));
	cooked = replace(cooked, '%%%MONTH+8%%%',
		to_char(taxpoint + interval '8 months', 'Month'));
	cooked = replace(cooked, '%%%MONTH+9%%%',
		to_char(taxpoint + interval '9 months', 'Month'));
	cooked = replace(cooked, '%%%MONTH+10%%%',
		to_char(taxpoint + interval '10 months', 'Month'));
	cooked = replace(cooked, '%%%MONTH+11%%%',
		to_char(taxpoint + interval '11 months', 'Month'));
	cooked = replace(cooked, '%%%MONTH+12%%%',
		to_char(taxpoint + interval '12 months', 'Month'));

	-- %%%YEAR%%%
	cooked = replace(cooked, '%%%YEAR-1%%%',
		to_char(taxpoint - interval '1 year', 'YYYY'));
	cooked = replace(cooked, '%%%YEAR%%%', to_char(taxpoint, 'YYYY'));
	cooked = replace(cooked, '%%%YEAR+1%%%',
		to_char(taxpoint + interval '1 year', 'YYYY'));
	cooked = replace(cooked, '%%%YEAR+2%%%',
		to_char(taxpoint + interval '2 years', 'YYYY'));
	cooked = replace(cooked, '%%%YEAR+3%%%',
		to_char(taxpoint + interval '3 years', 'YYYY'));

	-- %%%PERIOD%%%
	cooked = replace(cooked, '%%%PERIOD%%%', to_char(taxpoint, 'YYYY-MM-DD') || ' to ' || to_char(endpoint, 'YYYY-MM-DD'));


	RETURN cooked;
END;
$$ LANGUAGE 'plpgsql';

-- quote special characters in LaTeX string
CREATE OR REPLACE FUNCTION texquote(rawstr TEXT)
RETURNS TEXT AS $$
DECLARE
	cooked	TEXT;
BEGIN
	cooked = replace(rawstr, '\', '\\');
	cooked = replace(cooked, '$', '\$');
	cooked = replace(cooked, '%', '\%');
	cooked = replace(cooked, '^', '\^');
	cooked = replace(cooked, '&', '\&');
	cooked = replace(cooked, '~', '\~');
	cooked = replace(cooked, '#', '\#');
	cooked = replace(cooked, '{', '\{');
	cooked = replace(cooked, '}', '\}');

	-- TODO: handle directional quotes

	RETURN cooked;
END;
$$ LANGUAGE 'plpgsql';

-- return orgcode of organisation for current business
CREATE OR REPLACE FUNCTION current_business_code()
RETURNS TEXT AS $$
DECLARE
	businesscode	TEXT;
BEGIN
	SELECT o.orgcode INTO businesscode 
	FROM organisation o
	INNER JOIN business b ON o.id = b.organisation
	WHERE b.id = current_business();

	RETURN businesscode;
END;
$$ LANGUAGE 'plpgsql';

-- create_salesinvoice_tex()
-- create xelatex source from salesinvoice
-- RETURNS TEXT tex source
CREATE OR REPLACE FUNCTION create_salesinvoice_tex(si_id INT4)
RETURNS INT4 AS $$
DECLARE
	r		RECORD;
	item		RECORD;
	lineitems	TEXT;
	taxes		TEXT;
	customer	TEXT;
	tex		INT4;
	fieldcount	INT4;
	businesscode	TEXT;
BEGIN

	/* salesinvoice data */
	SELECT * FROM salesinvoice_current WHERE salesinvoice=si_id INTO r;

	IF NOT FOUND THEN
		RAISE EXCEPTION 'Invoice id % does not exist', si_id;
	END IF;

	/* fetch lineitems */
	lineitems := '';
	FOR item IN
	SELECT * FROM salesinvoiceitem_display WHERE salesinvoice=si_id
	LOOP
		lineitems := lineitems || item.qty || ' x ' || 
		texquote(replacemacros(item.linetext, r.taxpoint, r.endpoint))
		|| ' @ ' || to_char(item.price, '999G999G999G999G990D90') || ' & ' || 
		to_char(item.linetotal, '999G999G999G999G990D90' ) || '\\' || E'\n';
	END LOOP;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No lineitems for invoice %', si_id; 
	END IF;

	/* fetch taxes */
	taxes := '';
	FOR item IN
	SELECT * FROM salesinvoice_tax WHERE salesinvoice=si_id
	LOOP
		taxes := taxes || item.taxname || ' (' || item.rate || '\%)' 
		|| ' on ' || to_char(item.nett, '999G999G999G999G990D90') || ' & ' || 
		to_char(item.total, '999G999G999G999G990D90') || '\\' || E'\n';
	END LOOP;

	/* fetch customer billing contact */
	SELECT * FROM contact_billing WHERE organisation=r.organisation
	INTO item;
	IF NOT FOUND THEN
		RAISE INFO 'No billcontact set for organisation %', 
			r.orgcode;
		SELECT name FROM organisation_current 
		WHERE id = r.organisation
		INTO item;
		customer := E'\t' || '{' || item.name || '}' || E'\n' ||
			E'\t' || '{}' || E'\n' ||
			E'\t' || '{}' || E'\n' ||
			E'\t' || '{}' || E'\n' ||
			E'\t' || '{}' || E'\n' ||
			E'\t' || '{}' || E'\n' ||
			E'\t' || '{}' || E'\n' ||
			E'\t' || '{}' || E'\n';
	ELSE
		/* fill in full customer details */
		customer := E'\t' || '{' || item.name || '}' || E'\n';
		customer := E'\t' || '{' || item.orgname || '}' || E'\n';
		fieldcount := 2;
		IF item.line_1 IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.line_1 || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		IF item.line_2 IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.line_2 || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		IF item.line_3 IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.line_3 || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		IF item.town IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.town || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		IF item.county IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.county || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		IF item.country IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.country || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		IF item.postcode IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.postcode || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		WHILE fieldcount < 9 LOOP
			customer := customer || E'\t' || '{}' || E'\n';
			fieldcount := fieldcount + 1;
		END LOOP;
	END IF;

	/* write the .tex file to disk */
	PERFORM write_salesinvoice_tex(
		'/var/spool/gladbooks/' || current_business_code(),
		'/etc/gladbooks/conf.d/' || current_business_code(),
		'/etc/gladbooks/conf.d/' || current_business_code()
		|| '/SI-template.tex',
		r.orgcode,
		r.invoicenum,
		to_char(r.taxpoint, 'DD Month YYYY'),
		to_char(r.issued, 'DD Month YYYY'),
		to_char(r.due, 'DD Month YYYY'),
		COALESCE(r.ponumber, ''),
		to_char(r.subtotal, '999G999G999G999G990D90'),
		to_char(r.tax, '999G999G999G999G990D90'),
		to_char(r.total, '999G999G999G999G990D90'),
		lineitems,
		taxes,
		customer
	);
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Failed to write .tex';
	END IF;

	RETURN '0';
END;
$$ LANGUAGE 'plpgsql';

-- for testing only
CREATE OR REPLACE FUNCTION delete_invoice(si_id INT8)
RETURNS INT8 AS $$
BEGIN
	-- TODO: delete from journal & ledger

	DELETE FROM salesinvoiceitemdetail WHERE salesinvoice=si_id;
	DELETE FROM salesinvoicedetail WHERE salesinvoice=si_id;
	DELETE FROM salesinvoice WHERE id=si_id;

	RETURN '0';
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION delete_all_invoices()
RETURNS INT8 AS $$
BEGIN
	-- TODO: delete from journal & ledger

	DELETE FROM salesinvoiceitemdetail;
	DELETE FROM salesinvoicedetail;
	DELETE FROM salesinvoice;

	RETURN '0';
END;
$$ LANGUAGE 'plpgsql';

-- post_salesinvoice() - post salesinvoice to journal
-- RETURN INT4, 0=success
CREATE OR REPLACE FUNCTION post_salesinvoice(si_id INT8)
RETURNS INT4 AS $$
DECLARE
	r_si		RECORD;
	r_tax		RECORD;
	r_item		RECORD;
	d		NUMERIC;
	c		NUMERIC;
BEGIN
	-- fetch salesinvoice details
	SELECT si.salesinvoice, si.taxpoint, si.subtotal, si.total, si.ref
	INTO r_si
	FROM salesinvoice_current si
	WHERE si.salesinvoice=si_id;

	-- create journal entry
	INSERT INTO journal (transactdate, description) 
	VALUES (r_si.taxpoint, 'Sales Invoice ' || r_si.ref);

	IF (r_si.total > 0) THEN
		d = r_si.total;
		c = '0.00';
	ELSE
		d = '0.00';
		c = r_si.total;
	END IF;

	-- TODO: divisions and departments

	-- 1100 = Debtors Control Account
	RAISE INFO 'Account: % Debit: % Credit %', '1100', d, c;
	INSERT INTO ledger (account, debit, credit) VALUES ('1100', d, c);
	
	-- post tax details to ledger
	FOR r_tax IN
	SELECT sit.salesinvoice, sit.account, sit.total
	FROM salesinvoice_tax sit WHERE sit.salesinvoice=si_id
	LOOP
		IF (r_tax.total < 0) THEN
			d = r_tax.total;
			c = '0.00';
		ELSE
			d = '0.00';
			c = r_tax.total;
		END IF;
		RAISE INFO 'Account: % Debit: % Credit %',r_tax.account, d, c;
		INSERT INTO ledger (account, debit, credit) 
		VALUES (r_tax.account, d, c);
	END LOOP;


	-- post product details to ledger
	FOR r_item IN
	SELECT sii.salesinvoice, p.account, sii.linetotal
	FROM salesinvoiceitem_display sii
	RIGHT JOIN product_current p ON p.product = sii.product
	WHERE sii.salesinvoice=si_id
	LOOP
		IF (r_item.linetotal < 0) THEN
			d = r_item.linetotal;
			c = '0.00';
		ELSE
			d = '0.00';
			c = r_item.linetotal;
		END IF;
		RAISE INFO 'Account: % Debit: % Credit %',r_item.account,d,c;
		INSERT INTO ledger (account, debit, credit) 
		VALUES (r_item.account, d, c);
	END LOOP;

	RETURN '0';
END;
$$ LANGUAGE 'plpgsql';

-- post_salesinvoice() - post salesinvoice to journal
-- RETURN INT4, 0=success
CREATE OR REPLACE FUNCTION post_salesinvoice_quick(si_id INT8)
RETURNS INT4 AS $$
DECLARE
	r_si		RECORD;
	r_tax		RECORD;
	r_item		RECORD;
	d		NUMERIC;
	c		NUMERIC;
BEGIN
	-- fetch salesinvoice details
	SELECT si.salesinvoice, 
	       COALESCE(si.taxpoint,si.issued) AS taxpoint,
	       si.subtotal, si.tax, si.total, si.ref
	INTO r_si
	FROM salesinvoice_current si
	WHERE si.salesinvoice=si_id;

	-- only post invoices from current period
	-- TODO: pull this date from business.period_start
	IF r_si.taxpoint < '2013-04-01' THEN
		RETURN 0;
	END IF;

	-- create journal entry
	INSERT INTO journal (transactdate, description) 
	VALUES (r_si.taxpoint, 'Sales Invoice ' || r_si.ref);

	IF (r_si.total > 0) THEN
		d = r_si.total;
		c = '0.00';
	ELSE
		d = '0.00';
		c = r_si.total;
	END IF;

	-- 1100 = Debtors Control Account
	RAISE INFO 'Account: % Debit: % Credit %', '1100', d, c;
	INSERT INTO ledger (account, debit, credit) VALUES ('1100', d, c);
	
	-- post tax to ledger (quick version, assume Standard Rate VAT)
	IF (r_si.tax < 0) THEN
		d = r_si.tax;
		c = '0.00';
	ELSE
		d = '0.00';
		c = r_si.tax;
	END IF;
	RAISE INFO 'Account: 2202 Debit: % Credit %', d, c;
	INSERT INTO ledger (account, debit, credit) VALUES ('2202', d, c);

	-- post nett amount to 4000 General Revenue
	IF (r_si.subtotal < 0) THEN
		d = r_si.subtotal;
		c = '0.00';
	ELSE
		d = '0.00';
		c = r_si.subtotal;
	END IF;
	RAISE INFO 'Account: 4000 Debit: % Credit %', d, c;
	INSERT INTO ledger (account, debit, credit) VALUES ('4000', d, c);

	RETURN '0';
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
		account,
		taxname,
		rate,
		nett,
		total
	) 
	SELECT
		si.salesinvoice,
		t.account as account,
		t.name as taxname,
		tr.rate,
		sii.price * sii.qty AS nett,
		roundhalfeven(SUM(sii.price * sii.qty) * tr.rate/100, 2) AS total
	FROM salesinvoice_current si 
	LEFT JOIN salesinvoiceitem_current sii ON si.salesinvoice = sii.salesinvoice
	INNER JOIN (
		SELECT * FROM product_tax WHERE is_applicable='t'
		AND id IN (SELECT MAX(id) FROM product_tax GROUP BY product, tax)
	) pt ON sii.product = pt.product
	INNER JOIN taxrate_current tr ON tr.tax = pt.tax
	INNER JOIN tax_current t ON t.tax = pt.tax
	WHERE 
	(tr.valid_from <= si.taxpoint OR tr.valid_from IS NULL)
	AND (tr.valid_to >= si.taxpoint OR  tr.valid_to IS NULL)
	AND si.salesinvoice = NEW.salesinvoice
	GROUP BY si.salesinvoice,t.account,t.name,sii.price, sii.qty,tr.rate
	ORDER BY tr.rate DESC
	;

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

	WHILE jump <= end_date LOOP
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
			RAISE NOTICE 'start_date is null on recurring salesorder';
			RETURN NULL;
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

-- Return currently selected business (determined by search_path)
CREATE OR REPLACE FUNCTION current_business()
RETURNS INT4 AS
$$
DECLARE
	i	INT4;
BEGIN
	EXECUTE 'SELECT business FROM settings' INTO i;
	RETURN i;
END;
$$ LANGUAGE 'plpgsql';

-- Return currently selected instance (determined by search_path)
CREATE OR REPLACE FUNCTION current_instance()
RETURNS TEXT AS
$$
DECLARE
	i	TEXT;
BEGIN
	EXECUTE 'SELECT instance FROM settings' INTO i;
	RETURN i;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION emailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        osendername     TEXT;
        osendermail     TEXT;
        obody           TEXT;
        oemailafter     timestamp with time zone;
        osent           timestamp with time zone;
        ois_deleted     boolean;
BEGIN
        SELECT INTO priorentries COUNT(id) FROM emaildetail
                WHERE email=NEW.email;
        IF priorentries > 0 THEN
                -- This isn't our first time, so use previous values
                SELECT INTO osendername, osendermail, obody, oemailafter, osent, ois_deleted
                        sendername, sendermail, body, emailafter, sent, is_deleted
                FROM email_current
                WHERE email=NEW.email;
        END IF;

        IF NEW.sendername IS NULL THEN
                NEW.sendername:= osendername;
        END IF;
        IF NEW.sendermail IS NULL THEN
                NEW.sendermail:= osendermail;
        END IF;
        IF NEW.body IS NULL THEN
                NEW.body := obody;
        END IF;
        IF NEW.emailafter IS NULL THEN
		IF priorentries > 0 THEN
	                NEW.emailafter := oemailafter;
		ELSE
			-- default
			NEW.emailafter := NOW();
		END IF;
        END IF;
        IF NEW.sent IS NULL THEN
                NEW.sent := osent;
        END IF;
        IF NEW.is_deleted IS NULL THEN
		IF priorentries > 0 THEN
	                NEW.is_deleted := ois_deleted;
		ELSE
			-- default
			NEW.is_deleted := false;
        	END IF;
        END IF;

        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION email_sent(
        email INT4,
        senttime TIMESTAMP default now()
) RETURNS INT4 AS $$
BEGIN
        INSERT INTO emaildetail (email, sent) VALUES (email, senttime);
        RETURN '0';
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION product_tax_vatcheck()
RETURNS TRIGGER AS $$
DECLARE
	vatcount        INT4;
BEGIN
	SELECT INTO vatcount COUNT(*) FROM product_tax WHERE id IN (
		SELECT MAX(id)
		FROM product_tax WHERE tax IN (1,2,3)
		GROUP BY product,tax
	)
	AND product=NEW.product
	AND is_applicable = TRUE
	GROUP BY product;

	IF vatcount > 1 THEN
		RAISE EXCEPTION 'Cannot apply more than one VAT rate to a product.';
		RETURN NULL;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION salesorderdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        osalesorder     INT4;
        oquotenumber    INT4;
        oponumber       TEXT;
	odescription    TEXT;
        ocycle          INT4;
        ostart_date     timestamp with time zone;
        oend_date       timestamp with time zone;
        ois_open        boolean;
        ois_deleted     boolean;
BEGIN
        SELECT INTO priorentries COUNT(id) FROM salesorderdetail
                WHERE salesorder = NEW.salesorder;
        IF priorentries > 0 THEN
                -- This isn't our first time, so use previous values 
                SELECT INTO
		        osalesorder, oquotenumber, oponumber, odescription,
		        ocycle, ostart_date, oend_date, ois_open, ois_deleted
		        salesorder, quotenumber, ponumber, description,
		        cycle, start_date, end_date, is_open, is_deleted
                FROM salesorderdetail WHERE id IN (
                        SELECT MAX(id)
                        FROM salesorderdetail
                        GROUP BY salesorder
                )
                AND salesorder = NEW.salesorder;

                IF NEW.salesorder IS NULL THEN
                        NEW.salesorder := osalesorder;
                END IF;
                IF NEW.quotenumber IS NULL THEN
                        NEW.quotenumber := oquotenumber;
                END IF;
                IF NEW.ponumber IS NULL THEN
                        NEW.ponumber := oponumber;
                END IF;
                IF NEW.description IS NULL THEN
                        NEW.description := odescription;
                END IF;
                IF NEW.cycle IS NULL THEN
                        NEW.cycle := ocycle;
                END IF;
                IF NEW.start_date IS NULL THEN
                        NEW.start_date := ostart_date;
                END IF;
                IF NEW.end_date IS NULL THEN
                        NEW.end_date := oend_date;
                END IF;
                IF NEW.is_open IS NULL THEN
                        NEW.is_open := ois_open;
                END IF;
                IF NEW.is_deleted IS NULL THEN
                        NEW.is_deleted := ois_deleted;
                END IF;
        ELSE
                /* set defaults */
		IF NEW.cycle IS NULL THEN
			NEW.cycle := '0';
                END IF;
        END IF;
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION salesorderitemdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        osalesorder     INT4;
        oproduct        INT4;
        olinetext	TEXT;
        odiscount	NUMERIC;
        oprice		NUMERIC;
        oqty		NUMERIC;
        ois_deleted     boolean;
BEGIN
        SELECT INTO priorentries COUNT(id) FROM salesorderitemdetail
                WHERE salesorderitem = NEW.salesorderitem;
        IF priorentries > 0 THEN
                -- This isn't our first time, so use previous values 
                SELECT INTO
		        osalesorder, oproduct, olinetext, odiscount, oprice,
			oqty, ois_deleted
		        salesorder, product, linetext, discount, price,
			qty, is_deleted
                FROM salesorderitemdetail WHERE id IN (
                        SELECT MAX(id)
                        FROM salesorderitemdetail
                        GROUP BY salesorderitem
                )
                AND salesorderitem = NEW.salesorderitem;

                IF NEW.salesorder IS NULL THEN
                        NEW.salesorder := osalesorder;
                END IF;
                IF NEW.product IS NULL THEN
                        NEW.product := oproduct;
                END IF;
                IF NEW.linetext IS NULL THEN
                        NEW.linetext := olinetext;
                END IF;
                IF NEW.discount IS NULL THEN
                        NEW.discount := odiscount;
                END IF;
                IF NEW.price IS NULL THEN
                        NEW.price := oprice;
                END IF;
                IF NEW.qty IS NULL THEN
                        NEW.qty := oqty;
                END IF;
                IF NEW.is_deleted IS NULL THEN
                        NEW.is_deleted := ois_deleted;
                END IF;
        ELSE
                /* set defaults */
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

-- Relationships
INSERT INTO relationship (id, name) VALUES (0, 'contact');
INSERT INTO relationship (name) VALUES ('billing');
INSERT INTO relationship (name) VALUES ('shipping');

-- Payment Types
INSERT INTO paymenttype (name) VALUES ('cash');
INSERT INTO paymenttype (name) VALUES ('cheque');
INSERT INTO paymenttype (name) VALUES ('bank transfer');

