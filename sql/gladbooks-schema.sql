CREATE TABLE accounttype (
	id		char(1) PRIMARY KEY,
	name		TEXT UNIQUE,
	entered		timestamp with time zone default now()
);
-- we don't delete account types
CREATE RULE nodel_accounttype AS ON DELETE TO accounttype DO NOTHING;

CREATE TABLE account (
	id		INT4 PRIMARY KEY,
	type		char(1) references accounttype(id) ON DELETE RESTRICT,
	description	TEXT,
	entered		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);
-- separate sequences for each account type --
CREATE SEQUENCE account_id_a_seq MINVALUE 1000 MAXVALUE 1999 OWNED BY account.id;
CREATE SEQUENCE account_id_l_seq MINVALUE 2000 MAXVALUE 2999 OWNED BY account.id;
CREATE SEQUENCE account_id_c_seq MINVALUE 3000 MAXVALUE 3999 OWNED BY account.id;
CREATE SEQUENCE account_id_r_seq MINVALUE 4000 MAXVALUE 4999 OWNED BY account.id;
CREATE SEQUENCE account_id_e_seq MINVALUE 5000 MAXVALUE 5999 OWNED BY account.id;

CREATE TABLE department (
	id              SERIAL PRIMARY KEY,
	name		TEXT UNIQUE,
	entered		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE division (
	id              SERIAL PRIMARY KEY,
	name		TEXT UNIQUE,
	entered		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

-- for auditing we want journal and ledger primary keys to be sequential
-- with no gaps, so an ordinary sequence won't do.
-- using the method suggested at: http://www.varlena.com/GeneralBits/130.php

-- unique, contiguous sequence for journal primary key
CREATE TABLE journal_pk_counter (
	journal_pk	INT4
);
INSERT INTO journal_pk_counter VALUES (0);
CREATE RULE noins_journal_pk_counter AS ON INSERT TO journal_pk_counter
	DO NOTHING;
CREATE RULE nodel_journal_pk_counter AS ON DELETE TO journal_pk_counter
	DO NOTHING;

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

CREATE TABLE journal (
	id		INT4 DEFAULT journal_id_next(),
	transactdate	date,
	description	TEXT,
	entered		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT,
	CONSTRAINT journal_pk PRIMARY KEY (id)
);

-- prevent deletes from journal table
CREATE RULE journal_del AS ON DELETE TO journal DO NOTHING;

-- unique, contiguous sequence for ledger primary key
CREATE TABLE ledger_pk_counter (
	ledger_pk	INT4
);
INSERT INTO ledger_pk_counter VALUES (0);
CREATE RULE noins_ledger_pk_counter AS ON INSERT TO ledger_pk_counter
	DO NOTHING;
CREATE RULE nodel_ledger_pk_counter AS ON DELETE TO ledger_pk_counter
	DO NOTHING;

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

CREATE TABLE ledger (
	id		INT4 DEFAULT ledger_id_next(),
	journal		INT4 references journal(id) ON DELETE RESTRICT,
	account		INT4 references account(id) ON DELETE RESTRICT,
	division	INT4 references division(id) ON DELETE RESTRICT
			DEFAULT 0,
	department	INT4 references department(id) ON DELETE RESTRICT
			DEFAULT 0,
	debit		NUMERIC,
	credit		NUMERIC,
	entered		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT,
	CONSTRAINT ledger_pk PRIMARY KEY (id)
);

-- prevent deletes from ledger table
CREATE RULE ledger_del AS ON DELETE TO ledger DO NOTHING;

CREATE TABLE contact (
	id		SERIAL PRIMARY KEY,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE contactdetail (
	id		SERIAL PRIMARY KEY,
	contact		INT4 references contact(id) ON DELETE RESTRICT,
	is_active	boolean DEFAULT true,
	is_deleted	boolean DEFAULT false,
	name		TEXT NOT NULL,
	line_1		TEXT,
	line_2		TEXT,
	line_3		TEXT,
	town		TEXT,
	county		TEXT,
	country		TEXT,
	postcode	TEXT,
	email		TEXT,
	phone		TEXT,
	phonealt	TEXT,
	mobile		TEXT,
	fax		TEXT,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE organisation (
	id		SERIAL PRIMARY KEY,
	orgcode		TEXT DEFAULT NULL,
	purchaseorder	INT4 NOT NULL DEFAULT 0,
	purchaseinvoice	INT4 NOT NULL DEFAULT 0,
	salesorder	INT4 NOT NULL DEFAULT 0,
	salesinvoice	INT4 NOT NULL DEFAULT 0,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT,
	UNIQUE (orgcode)
);

CREATE TABLE organisationdetail (
	id		SERIAL PRIMARY KEY,
	organisation	INT4 references organisation(id)
			ON DELETE RESTRICT,
	name		TEXT NOT NULL,
	terms		INT4 NOT NULL,
	billcontact	INT4 references contact(id) ON DELETE RESTRICT,
	is_active	boolean NOT NULL,
	is_suspended	boolean NOT NULL,
	is_vatreg	boolean NOT NULL,
	vatnumber	TEXT,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE organisation_contact (
	id		SERIAL PRIMARY KEY,
	organisation	INT4 references organisation(id)
			ON DELETE RESTRICT,
	contact		INT4 references contact(id) ON DELETE RESTRICT,
	is_billing	boolean DEFAULT false,
	is_shipping	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE cycle (
	id		SERIAL PRIMARY KEY,
	cyclename	TEXT NOT NULL,
	days		INT4 DEFAULT 0,
	months		INT4 DEFAULT 0,
	years		INT4 DEFAULT 0,
	is_available	boolean DEFAULT true,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE bank (
	id		SERIAL PRIMARY KEY,
	transactdate	date NOT NULL,
	description	TEXT,
	account		INT4 references account(id) ON DELETE RESTRICT
			NOT NULL,
	journal		INT4 references journal(id) ON DELETE RESTRICT,
	debit		NUMERIC,
	credit		NUMERIC,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE email (
	id		SERIAL PRIMARY KEY,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE emaildetail (
	id		SERIAL PRIMARY KEY,
	email		INT4 references email(id) ON DELETE RESTRICT,
	sender		TEXT,
	body		TEXT,
	emailafter	timestamp with time zone default now(),
	sent		timestamp with time zone,
	is_deleted	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE emailheader (
	id		SERIAL PRIMARY KEY,
	email		INT4 references email(id) ON DELETE RESTRICT,
	header		TEXT NOT NULL,
	value		TEXT NOT NULL,
	is_deleted	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE emailpart (
	id		SERIAL PRIMARY KEY,
	email		INT4 references email(id) ON DELETE RESTRICT,
	file		TEXT,
	is_deleted	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

-- NOTE: references contactdetail, NOT contact, so we keep a record of the
-- actual email address that was used at the time of sending.
CREATE TABLE emailrecipient (
	id		SERIAL PRIMARY KEY,
	email		INT4 references email(id) ON DELETE RESTRICT,
	contactdetail	INT4 references contactdetail(id) ON DELETE RESTRICT,
	is_to		boolean DEFAULT false,
	is_cc		boolean DEFAULT false,
	is_bcc		boolean DEFAULT false,
	is_deleted	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE tax (
	id		SERIAL PRIMARY KEY,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE taxdetail (
	id		SERIAL PRIMARY KEY,
	tax		INT4 references tax(id) ON DELETE RESTRICT,
	account		INT4 references account(id) ON DELETE RESTRICT,
	name		TEXT NOT NULL,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE taxrate (
	id		SERIAL PRIMARY KEY,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE taxratedetail (
	id		SERIAL PRIMARY KEY,
	taxrate		INT4 references taxrate(id) ON DELETE RESTRICT
			NOT NULL,
	tax		INT4 references tax(id) ON DELETE RESTRICT NOT NULL,
	rate		NUMERIC,
	valid_from	timestamp,
	valid_to	timestamp,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE product (
	id		SERIAL PRIMARY KEY,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE productdetail (
	id		SERIAL PRIMARY KEY,
	product		INT4 references product(id) ON DELETE RESTRICT
			NOT NULL,
	shortname	TEXT NOT NULL UNIQUE,
	description	TEXT NOT NULL,
	price_buy	NUMERIC,
	price_sell	NUMERIC,
	margin		NUMERIC,
	markup		NUMERIC,
	is_available	boolean DEFAULT true,
	is_offered	boolean DEFAULT true,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE product_tax (
	id		SERIAL PRIMARY KEY,
	product		INT4 references product(id) ON DELETE RESTRICT
			NOT NULL,
	tax		INT4 references tax(id) ON DELETE RESTRICT NOT NULL,
	is_applicable	boolean DEFAULT true,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE purchaseinvoice (
	id		SERIAL PRIMARY KEY,
	organisation	INT4 references organisation(id) NOT NULL,
	invoicenum	INT4 NOT NULL,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT,
	UNIQUE (organisation, invoicenum)
);

CREATE TABLE purchaseinvoicedetail (
	id		SERIAL PRIMARY KEY,
	purchaseinvoice	INT4 references purchaseinvoice(id) NOT NULL,
	journal		INT4 references journal(id),
	subtotal	NUMERIC,
	tax		NUMERIC,
	total		NUMERIC,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE purchaseorder (
	id		SERIAL PRIMARY KEY,
	organisation	INT4 NOT NULL,
	ordernum	INT4 NOT NULL,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT,
	UNIQUE (organisation, ordernum),
	CONSTRAINT purchaseorder_fkey_organisation
		FOREIGN KEY (organisation) REFERENCES organisation(id)
);

CREATE TABLE purchaseorderdetail (
	id		SERIAL PRIMARY KEY,
	purchaseorder	INT4 NOT NULL,
	purchaseinvoice	INT4,
	cycle		INT4,
	start_date	date,
	end_date	date,
	is_open		boolean DEFAULT true,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT,
	CONSTRAINT purchaseorderdetail_fkey_purchaseorder
		FOREIGN KEY (purchaseorder) REFERENCES purchaseorder(id),
	CONSTRAINT purchaseorderdetail_fkey_purchaseinvoice
		FOREIGN KEY (purchaseinvoice) REFERENCES purchaseinvoice(id),
	CONSTRAINT purchaseorderdetail_fkey_cycle
		FOREIGN KEY (cycle) REFERENCES cycle(id)
);

CREATE TABLE purchaseorderitem (
	id		SERIAL PRIMARY KEY,
	purchaseorder	INT4 REFERENCES purchaseorder(id) NOT NULL,
	product		INT4 REFERENCES product(id) NOT NULL,
	price		NUMERIC,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE purchasepayment (
	id		SERIAL PRIMARY KEY,
	organisation	INT4 references organisation(id) NOT NULL,
	amount		NUMERIC NOT NULL,
	journal		INT4 references journal(id),
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salesorder (
	id		SERIAL PRIMARY KEY,
	organisation	INT4 references organisation(id) NOT NULL,
	ordernum	INT4 NOT NULL,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT,
	UNIQUE (organisation, ordernum)
);

CREATE TABLE salesorderdetail (
	id		SERIAL PRIMARY KEY,
	salesorder	INT4 references salesorder(id) NOT NULL,
	quotenumber	INT4 UNIQUE,
	ponumber	TEXT,
	description	TEXT,
	cycle		INT4 references cycle(id) NOT NULL DEFAULT 0,
	start_date	date,
	end_date	date,
	is_open		boolean DEFAULT true,
	is_deleted	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salesorderitem (
	id		SERIAL PRIMARY KEY,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salesorderitemdetail (
	id		SERIAL PRIMARY KEY,
	salesorderitem	INT4 references salesorderitem(id) NOT NULL,
	salesorder	INT4 references salesorder(id) NOT NULL,
	product		INT4 references product(id) NOT NULL,
	linetext	TEXT,
	discount	NUMERIC,
	price		NUMERIC,
	is_deleted	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salesorderitem_tax (
	id		SERIAL PRIMARY KEY,
	tax		INT4 references tax(id) NOT NULL,
	salesorderitem	INT4 references salesorderitem(id) NOT NULL,
	commenttext	TEXT,
	is_applied	boolean DEFAULT true,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salesinvoice (
	id		SERIAL PRIMARY KEY,
	organisation	INT4 references organisation(id) NOT NULL,
	invoicenum	INT4 NOT NULL,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT,
	UNIQUE (organisation, invoicenum)
);

CREATE TABLE salesinvoicedetail (
	id		SERIAL PRIMARY KEY,
	salesinvoice	INT4 references salesinvoice(id) NOT NULL,
	salesorder	INT4 references salesorder(id) NOT NULL,
	period		INT4,
	ponumber	TEXT,
	taxpoint	date,
	endpoint	date,
	issued		timestamp with time zone default now(),
	due		date,
	subtotal	NUMERIC,
	tax		NUMERIC,
	total		NUMERIC,
	pdf		TEXT,
	emailtext	TEXT,
	emailafter	timestamp with time zone default now(),
	sent		timestamp with time zone,
	confirmstring	TEXT,
	journal		INT4 references journal(id),
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

-- NOTE: references salesorderitemdetail NOT salesorderitem, 
-- as the salesorder may be edited between recurring invoices and we need a 
-- permanent record of the exact details on the invoice at the time it was
-- issued.
CREATE TABLE salesinvoiceitem (
	id		SERIAL PRIMARY KEY,
	salesinvoice	INT4 references salesinvoice(id) NOT NULL,
	salesorderitemdetail	INT4 references salesorderitemdetail(id)
			ON DELETE RESTRICT NOT NULL,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salesinvoiceitem_tax (
	id		SERIAL PRIMARY KEY,
	salesinvoice	INT4 references salesinvoice(id) ON DELETE RESTRICT
			NOT NULL,
	taxrate		INT4 references taxrate(id) ON DELETE RESTRICT
			NOT NULL,
	nett		NUMERIC,
	total		NUMERIC,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salespayment (
	id		SERIAL PRIMARY KEY,
	organisation	INT4 references organisation(id) NOT NULL,
	amount		NUMERIC,
	journal		INT4 references journal(id),
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

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
	NEW.ordernum = organisation_purchaseorder_next(NEW.organisation);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER set_organisation_purchaseorder BEFORE INSERT ON purchaseorder
FOR EACH ROW EXECUTE PROCEDURE set_organisation_purchaseorder();

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
	NEW.invoicenum = organisation_purchaseinvoice_next(NEW.organisation);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER set_organisation_purchaseinvoice
BEFORE INSERT ON purchaseinvoice
FOR EACH ROW EXECUTE PROCEDURE set_organisation_purchaseinvoice();

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

CREATE TRIGGER set_organisation_salesorder
BEFORE INSERT ON salesorder
FOR EACH ROW EXECUTE PROCEDURE set_organisation_salesorder();


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

CREATE TRIGGER set_organisation_salesinvoice
BEFORE INSERT ON salesinvoice
FOR EACH ROW EXECUTE PROCEDURE set_organisation_salesinvoice();

-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Gladbooks Default Org ID style 8+ char based on organisation name
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION organisation_orgcode(organisation_name TEXT)
RETURNS TEXT AS
$$
DECLARE
	neworgcode	TEXT;
	conflicts	INT4; 
	idlen		INT4;
BEGIN
	idlen = 8;
	neworgcode = regexp_replace(organisation_name, '[^a-zA-Z0-9]+','','g');
	neworgcode = substr(neworgcode, 1, idlen);
	neworgcode = upper(neworgcode);
	SELECT INTO conflicts COUNT(id) FROM organisation
		WHERE orgcode = neworgcode;
	WHILE conflicts != 0 OR char_length(neworgcode) < idlen LOOP
		neworgcode = substr(neworgcode, 1, idlen - 1);
		neworgcode = concat(neworgcode, chr(int4(random() * 25 + 65)));
		SELECT INTO conflicts COUNT(id) FROM organisation
			WHERE orgcode LIKE CONCAT(neworgcode,'%');
		IF conflicts > 25 THEN
			idlen = idlen + 1;
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

CREATE TRIGGER set_orgcode BEFORE INSERT ON organisationdetail
FOR EACH ROW EXECUTE PROCEDURE set_orgcode();

-- when INSERTing into organisationdetail, check for previous records
-- for this organisation, and use those values in place of any values
-- not supplied.
CREATE OR REPLACE FUNCTION organisationdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
	priorentries	INT4;
	oname		TEXT;
	oterms		INT4;
	obillcontact	INT4;
	ois_active	boolean;
	ois_suspended	boolean;
	ois_vatreg	boolean;
	ovatnumber	TEXT;
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

CREATE TRIGGER organisationdetailupdate BEFORE INSERT ON organisationdetail
FOR EACH ROW EXECUTE PROCEDURE organisationdetailupdate();
-- ---------------------------------------------------------------------------

-- when INSERTing into contactdetail, check for previous records
-- for this contact, and use those values in place of any values
-- not supplied.
CREATE OR REPLACE FUNCTION contactdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
	priorentries	INT4;
	ois_active	boolean;
	ois_deleted	boolean;
	oname		TEXT;
	oline_1		TEXT;
	oline_2		TEXT;
	oline_3		TEXT;
	otown		TEXT;
	ocounty		TEXT;
	ocountry	TEXT;
	opostcode	TEXT;
	oemail		TEXT;
	ophone		TEXT;
	ophonealt	TEXT;
	omobile		TEXT;
	ofax		TEXT;
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
			NEW.is_active = ois_active;
		END IF;
		IF NEW.is_deleted IS NULL THEN
			NEW.is_deleted = ois_deleted;
		END IF;
		IF NEW.name IS NULL THEN
			NEW.name = oname;
		END IF;
		IF NEW.line_1 IS NULL THEN
			NEW.line_1 = oline_1;
		END IF;
		IF NEW.line_2 IS NULL THEN
			NEW.line_2 = oline_2;
		END IF;
		IF NEW.line_3 IS NULL THEN
			NEW.line_3 = oline_3;
		END IF;
		IF NEW.town IS NULL THEN
			NEW.town = otown;
		END IF;
		IF NEW.county IS NULL THEN
			NEW.county = ocounty;
		END IF;
		IF NEW.country IS NULL THEN
			NEW.country = ocountry;
		END IF;
		IF NEW.postcode IS NULL THEN
			NEW.postcode = opostcode;
		END IF;
		IF NEW.email IS NULL THEN
			NEW.email = oemail;
		END IF;
		IF NEW.phone IS NULL THEN
			NEW.phone = ophone;
		END IF;
		IF NEW.phonealt IS NULL THEN
			NEW.phonealt = ophonealt;
		END IF;
		IF NEW.mobile IS NULL THEN
			NEW.mobile = omobile;
		END IF;
		IF NEW.fax IS NULL THEN
			NEW.fax = ofax;
		END IF;
	ELSE
		/* set defaults */
		IF NEW.is_active IS NULL THEN
			NEW.is_active = 'true';
		END IF;
		IF NEW.is_deleted IS NULL THEN
			NEW.is_deleted = 'false';
		END IF;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER contactdetailupdate BEFORE INSERT ON contactdetail
FOR EACH ROW EXECUTE PROCEDURE contactdetailupdate();
-- ---------------------------------------------------------------------------

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

CREATE CONSTRAINT TRIGGER trig_check_ledger_balance
	AFTER INSERT
	ON ledger
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE check_ledger_balance()
;

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

CREATE CONSTRAINT TRIGGER trig_check_transaction_balance
	AFTER INSERT
	ON ledger
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE check_transaction_balance()
;

-- set account id in the correct range based on account type
CREATE OR REPLACE FUNCTION set_account_id()
RETURNS trigger AS $get_account_id$
	BEGIN
		IF NEW.type = 'a' THEN
			SELECT nextval('account_id_a_seq') INTO NEW.id;
		ELSIF NEW.type = 'l' THEN
			SELECT nextval('account_id_l_seq') INTO NEW.id;
		ELSIF NEW.type = 'c' THEN
			SELECT nextval('account_id_c_seq') INTO NEW.id;
		ELSIF NEW.type = 'r' THEN
			SELECT nextval('account_id_r_seq') INTO NEW.id;
		ELSIF NEW.type = 'e' THEN
			SELECT nextval('account_id_e_seq') INTO NEW.id;
		ELSE
			RAISE EXCEPTION 'Invalid Account Type "%"', NEW.type;
		END IF;
		RETURN NEW;
	END;
$get_account_id$ LANGUAGE plpgsql;

CREATE TRIGGER trig_set_account_id
	BEFORE INSERT
	ON account
	FOR EACH ROW
	EXECUTE PROCEDURE set_account_id()
;

-- Default data --
INSERT INTO accounttype (id, name) VALUES ('a', 'assets');
INSERT INTO accounttype (id, name) VALUES ('l', 'liabilities');
INSERT INTO accounttype (id, name) VALUES ('c', 'capital');
INSERT INTO accounttype (id, name) VALUES ('r', 'revenue');
INSERT INTO accounttype (id, name) VALUES ('e', 'expenditure');

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

