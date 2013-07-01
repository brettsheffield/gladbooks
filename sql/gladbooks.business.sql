-- create tables in this business schema.

SET search_path TO gladbooks;

-- wrap business creation in a function for convenience --
CREATE OR REPLACE FUNCTION create_business(instance VARCHAR(63), business VARCHAR(63))
RETURNS TEXT AS
$$
DECLARE
	business_id INT4;
BEGIN

--

INSERT INTO business (name, instance) VALUES (business, instance);
SELECT INTO business_id currval(pg_get_serial_sequence('business', 'id'));

EXECUTE 'CREATE SCHEMA gladbooks_' || instance || '_' || business_id;

EXECUTE 'SET search_path TO gladbooks_' || instance || '_' || business_id || ',gladbooks_' || instance || ',gladbooks';

--

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

CREATE TRIGGER set_account_id BEFORE INSERT ON account
FOR EACH ROW EXECUTE PROCEDURE set_account_id();

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

CREATE TABLE ledger (
	id		INT4 DEFAULT ledger_id_next(),
	journal		INT4 references journal(id) ON DELETE RESTRICT
			NOT NULL,
	account		INT4 references account(id) ON DELETE RESTRICT
			NOT NULL,
	division	INT4 references division(id) ON DELETE RESTRICT
			NOT NULL DEFAULT 0,
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

CREATE TABLE paymenttype (
	id		SERIAL PRIMARY KEY,
	name		TEXT
);

CREATE TABLE bank (
	id		SERIAL PRIMARY KEY,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE bankdetail (
	id		SERIAL PRIMARY KEY,
	bank		INT4 references bank(id) ON DELETE RESTRICT,
	transactdate	date NOT NULL,
	description	TEXT,
	account		INT4 references account(id) ON DELETE RESTRICT
			NOT NULL,
	paymenttype	INT4 references paymenttype(id) ON DELETE RESTRICT
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

CREATE TABLE product (
        id              SERIAL PRIMARY KEY,
	import_id	INT4,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT,
	UNIQUE (import_id)
);

CREATE TABLE productdetail (
        id              SERIAL PRIMARY KEY,
        product         INT4 references product(id) ON DELETE RESTRICT
                        NOT NULL,
        account         INT4 references account(id) ON DELETE RESTRICT
                        NOT NULL,
        shortname       TEXT NOT NULL,
        description     TEXT NOT NULL,
        price_buy       NUMERIC,
        price_sell      NUMERIC,
        margin          NUMERIC,
        markup          NUMERIC,
        is_available    boolean DEFAULT true,
        is_offered      boolean DEFAULT true,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE product_tax (
        id              SERIAL PRIMARY KEY,
        product         INT4 references product(id) ON DELETE RESTRICT
                        NOT NULL,
        tax             INT4 references tax(id) ON DELETE RESTRICT NOT NULL,
        is_applicable   boolean DEFAULT true,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
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
	qty		NUMERIC DEFAULT '1',
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
	salesorder	INT4 references salesorder(id),
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

CREATE TABLE salesinvoiceitem (
	id		SERIAL PRIMARY KEY,
	salesinvoice	INT4 references salesinvoice(id) NOT NULL,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salesinvoiceitemdetail (
	id		SERIAL PRIMARY KEY,
	salesinvoiceitem	INT4 references salesinvoiceitem(id) NOT NULL,
	salesinvoice	INT4 references salesinvoice(id) NOT NULL,
	product		INT4 references product(id) NOT NULL,
	linetext	TEXT,
	discount	NUMERIC,
	price		NUMERIC,
	qty		NUMERIC DEFAULT '1',
	is_deleted	boolean DEFAULT false,
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
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salespaymentdetail (
	id		SERIAL PRIMARY KEY,
	salespayment	INT4 references salespayment(id) NOT NULL,
	paymenttype	INT4 references paymenttype(id) NOT NULL,
	organisation	INT4 references organisation(id) NOT NULL,
	transactdate	date,
	amount		NUMERIC,
	description	TEXT,
	journal		INT4 references journal(id),
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salespaymentallocation (
	id		SERIAL PRIMARY KEY,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salespaymentallocationdetail (
	id		SERIAL PRIMARY KEY,
	salespaymentallocation	INT4 references salespayment(id) NOT NULL,
	salespayment	INT4 references salespayment(id) NOT NULL,
	salesinvoice	INT4 references salesinvoice(id) NOT NULL,
	amount		NUMERIC,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

-- TODO: trigger to ensure sum of amounts in salespaymentallocation do not exceed amount of salespayment --

CREATE TRIGGER set_organisation_purchaseorder BEFORE INSERT ON purchaseorder
FOR EACH ROW EXECUTE PROCEDURE set_organisation_purchaseorder();

CREATE TRIGGER set_organisation_purchaseinvoice
BEFORE INSERT ON purchaseinvoice
FOR EACH ROW EXECUTE PROCEDURE set_organisation_purchaseinvoice();

CREATE TRIGGER set_organisation_salesorder
BEFORE INSERT ON salesorder
FOR EACH ROW EXECUTE PROCEDURE set_organisation_salesorder();

CREATE TRIGGER set_organisation_salesinvoice
BEFORE INSERT ON salesinvoice
FOR EACH ROW EXECUTE PROCEDURE set_organisation_salesinvoice();

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

-- views --

CREATE VIEW accountlist AS
SELECT
        a.id as nominalcode,
        a.description as account,
        at.name as type
FROM account a
INNER JOIN accounttype at ON at.id = a.accounttype
ORDER by a.id ASC
;

CREATE OR REPLACE VIEW balancesheet AS
        SELECT
                account,
                description,
                format_accounting(sum(debit)) AS debit,
                format_accounting(sum(credit)) AS credit,
                format_accounting(sum(coalesce(debit,0)) - sum(coalesce(credit,0))) AS total
        FROM ledger l
        INNER JOIN account a ON a.id=l.account
        GROUP BY account, description, division, department
UNION
        SELECT
                NULL as account,
                text 'TOTAL' AS description,
                format_accounting(sum(debit)) AS debit,
                format_accounting(sum(credit)) AS credit,
                format_accounting(sum(coalesce(debit,0)) - sum(coalesce(credit,0))) AS total
        FROM ledger l
        ORDER BY account ASC
;

CREATE OR REPLACE VIEW profitandloss AS
SELECT
        account,
        description,
        amount
FROM (
        SELECT
                0 as lineorder,
                NULL as account,
                text 'Revenue' as description,
                NULL AS amount
UNION
        SELECT
                1 as lineorder,
                account,
                description,
                format_accounting(
                        coalesce(sum(credit),0) - coalesce(sum(debit),0))
                AS amount
        FROM ledger l
        INNER JOIN account a ON a.id=l.account
        WHERE account BETWEEN 4000 AND 4999
        GROUP BY account, description
UNION
        SELECT
                2 as lineorder,
                NULL as account,
                text 'Total Revenue' as description,
                format_accounting(
                        coalesce(sum(credit),0) - coalesce(sum(debit),0))
                AS amount
        FROM ledger
        WHERE account BETWEEN 4000 AND 4999
UNION
        SELECT
                3 as lineorder,
                NULL as account,
                text 'Expenditure' as description,
                NULL AS amount
UNION
        SELECT
                4 as lineorder,
                account,
                description,
                format_accounting(
                        coalesce(sum(debit),0) - coalesce(sum(credit),0))
                AS amount
        FROM ledger l
        INNER JOIN account a ON a.id=l.account
        WHERE account BETWEEN 5000 AND 8999
        GROUP BY account, description
UNION
        SELECT
                5 as lineorder,
                NULL as account,
                text 'Total Expenditure' as description,
                format_accounting(
                        coalesce(sum(debit),0) - coalesce(sum(credit),0))
                AS amount
        FROM ledger
        WHERE account BETWEEN 5000 AND 8999
UNION
        SELECT
                6 as lineorder,
                NULL as account,
                text 'Total Profit / (Loss)' as description,
                format_accounting(
                        coalesce(sum(credit),0) - coalesce(sum(debit),0))
                AS amount
        FROM ledger
        WHERE account BETWEEN 4000 AND 8999
ORDER BY lineorder, account ASC
) a
;

CREATE OR REPLACE VIEW productlist AS
SELECT
        product as id,
	account,
        shortname,
        description,
	price_buy,
	price_sell
FROM productdetail
WHERE id IN (
        SELECT MAX(id)
        FROM productdetail
        GROUP BY product
)
ORDER BY shortname ASC
;

CREATE OR REPLACE VIEW salesorderlist AS
SELECT
        sod.salesorder as id,
        so.organisation AS customer,
        o.orgcode || '/' || lpad(CAST(so.ordernum AS TEXT), 5, '0') AS order,
        sod.ponumber,
        sod.description,
        sod.cycle,
        sod.start_date,
        sod.end_date
FROM salesorderdetail sod
INNER JOIN salesorder so ON so.id = sod.salesorder
INNER JOIN organisation o ON o.id = so.organisation
WHERE sod.id IN (
        SELECT MAX(id)
        FROM salesorderdetail
        GROUP BY salesorder
)
AND sod.is_open = 'true'
AND sod.is_deleted = 'false'
;

CREATE OR REPLACE VIEW salesorderview AS
SELECT
        sod.salesorder as id,
        od.name || '(' || o.orgcode || ')' AS customer,
        o.orgcode || '/' || lpad(CAST(so.ordernum AS TEXT), 5, '0') AS order,
        sod.ponumber,
        sod.description,
        sod.cycle,
        sod.start_date,
        sod.end_date
FROM salesorderdetail sod
INNER JOIN salesorder so ON so.id = sod.salesorder
INNER JOIN organisation o ON o.id = so.organisation
INNER JOIN organisationdetail od ON o.id = od.organisation
WHERE sod.id IN (
        SELECT MAX(id)
        FROM salesorderdetail
        GROUP BY salesorder
)
AND sod.is_open = 'true'
AND sod.is_deleted = 'false'
;

CREATE OR REPLACE VIEW salesorderitemview AS
SELECT
	soid.salesorderitem as id,
	soid.salesorder,
	soid.product,
	soid.linetext,
	soid.discount,
	soid.price,
	soid.qty
FROM salesorderitemdetail soid
WHERE soid.id IN (
	SELECT MAX(id)
	FROM salesorderitemdetail
	GROUP BY salesorderitem
)
AND soid.is_deleted = 'false'
;

EXECUTE 'SELECT default_data(''' || instance || ''',''' || business_id || ''')';

RETURN business;

END;
$$ LANGUAGE 'plpgsql';
