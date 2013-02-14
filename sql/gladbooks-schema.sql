CREATE TABLE accounttype (
	id		char(1) PRIMARY KEY,
	name		TEXT UNIQUE,
	entered		timestamp with time zone default now()
);

CREATE TABLE account (
	id		INT4 PRIMARY KEY,
	type		char(1) references accounttype(id) ON DELETE RESTRICT,
	description	TEXT,
	entered		timestamp with time zone default now()
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
	entered		timestamp with time zone default now()
);

CREATE TABLE division (
	id              SERIAL PRIMARY KEY,
	name		TEXT UNIQUE,
	entered		timestamp with time zone default now()
);

CREATE TABLE journal (
	id		SERIAL PRIMARY KEY,
	transactdate	date,
	description	TEXT,
	entered		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);
CREATE RULE journal_del AS ON DELETE TO journal DO NOTHING;

CREATE TABLE ledger (
	id		SERIAL PRIMARY KEY,
	journal		INT4 references journal(id) ON DELETE RESTRICT,
	account		INT4 references account(id) ON DELETE RESTRICT,
	division	INT4 references division(id) ON DELETE RESTRICT
			DEFAULT 0,
	department	INT4 references department(id) ON DELETE RESTRICT
			DEFAULT 0,
	debit		NUMERIC,
	credit		NUMERIC,
	entered		timestamp with time zone default now()
);
CREATE RULE ledger_del AS ON DELETE TO ledger DO NOTHING;

CREATE TABLE term (
	id		SERIAL PRIMARY KEY,
	termname	TEXT NOT NULL UNIQUE,
	days		INT4 DEFAULT 0,
	months		INT4 DEFAULT 0,
	years		INT4 DEFAULT 0,
	is_available	boolean DEFAULT true,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

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
	orgcode		TEXT,
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
	term		INT4 references term(id) ON DELETE RESTRICT
			DEFAULT 0,
	billcontact	INT4 references contact(id) ON DELETE RESTRICT,
	is_active	boolean DEFAULT true NOT NULL,
	is_suspended	boolean DEFAULT false NOT NULL,
	is_vatreg	boolean DEFAULT false NOT NULL,
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
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE purchaseinvoicedetail (
	id		SERIAL PRIMARY KEY,
	purchaseinvoice	INT4 references purchaseinvoice(id) NOT NULL,
	organisation	INT4 references organisation(id) NOT NULL,
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
	order		INT4 NOT NULL,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT,
	UNIQUE (organisation, order),
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
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salesorderdetail (
	id		SERIAL PRIMARY KEY,
	salesorder	INT4 references salesorder(id) NOT NULL,
	organisation	INT4 references organisation(id) NOT NULL,
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
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salesinvoicedetail (
	id		SERIAL PRIMARY KEY,
	salesinvoice	INT4 references salesinvoice(id) NOT NULL,
	salesorder	INT4 references salesorder(id) NOT NULL,
	period		INT4,
	organisation	INT4 references organisation(id) NOT NULL,
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
			RAISE EXCEPTION 'Invalid Account Type "%s"', NEW.type;
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

CREATE CONSTRAINT TRIGGER trig_check_ledger_balance
	AFTER INSERT
	ON ledger
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE check_ledger_balance()
;

CREATE CONSTRAINT TRIGGER trig_check_transaction_balance
	AFTER INSERT
	ON ledger
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE check_transaction_balance()
;

-- Default data for accounttype --
INSERT INTO accounttype (id, name) VALUES ('a', 'assets');
INSERT INTO accounttype (id, name) VALUES ('l', 'liabilities');
INSERT INTO accounttype (id, name) VALUES ('c', 'capital');
INSERT INTO accounttype (id, name) VALUES ('r', 'revenue');
INSERT INTO accounttype (id, name) VALUES ('e', 'expenditure');

INSERT INTO department (id, name) VALUES (0, 'default');
INSERT INTO division (id, name) VALUES (0, 'default');
