-- create tables in this business schema.

SET search_path TO gladbooks;

-- wrap business creation in a function for convenience --
CREATE OR REPLACE FUNCTION create_business(instance VARCHAR(63), business VARCHAR(63), period_start DATE)
RETURNS TEXT AS
$$
DECLARE
	business_id INT4;
BEGIN

--

INSERT INTO business (name, instance) VALUES (business, instance);
INSERT INTO business_year (business, period_start) 
VALUES (currval(pg_get_serial_sequence('business', 'id')), period_start);
SELECT INTO business_id currval(pg_get_serial_sequence('business', 'id'));

EXECUTE 'CREATE SCHEMA gladbooks_' || instance || '_' || business_id;

EXECUTE 'SET search_path TO gladbooks_' || instance || '_' || business_id || ',gladbooks_' || instance || ',gladbooks';

--
-- settings table - provides a bookmark as to which instance and business we are operating on in the current search_path
CREATE TABLE settings (
	business	INT4 NOT NULL references business(id)
			ON DELETE RESTRICT,
	instance	TEXT NOT NULL references instance(id)
			ON DELETE RESTRICT
);
INSERT INTO settings (business, instance) VALUES (business_id, instance);

CREATE TABLE accounttype (
	id		SERIAL PRIMARY KEY,
	name		TEXT UNIQUE NOT NULL,
	range_min	INT4 NOT NULL,
	range_max	INT4 NOT NULL,
	next_id		INT4 NOT NULL DEFAULT 0,
	last_id		INT4,
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
	reverseid	INT4 references journal(id) ON DELETE RESTRICT DEFAULT NULL,
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
			NOT NULL DEFAULT journal_id_last(),
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

CREATE TABLE bank (
	id		SERIAL PRIMARY KEY,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE bankdetail (
	id		SERIAL PRIMARY KEY,
	bank		INT4 references bank(id) ON DELETE RESTRICT NOT NULL,
	transactdate	date NOT NULL,
	description	TEXT,
	account		INT4 references account(id) ON DELETE RESTRICT
			NOT NULL,
	paymenttype	INT4 references paymenttype(id) ON DELETE RESTRICT
			NOT NULL,
	ledger		INT4 references ledger(id) ON DELETE RESTRICT,
	debit		NUMERIC,
	credit		NUMERIC,
	updated		timestamp with time zone default now(),
	is_deleted      boolean DEFAULT false,
	authuser	TEXT,
	clientip	TEXT
);

CREATE TRIGGER bankdetailupdate BEFORE INSERT ON bankdetail
FOR EACH ROW EXECUTE PROCEDURE bankdetailupdate();

CREATE OR REPLACE VIEW bank_current AS
SELECT * FROM bankdetail
WHERE id IN (
	SELECT MAX(id)
	FROM bankdetail
	GROUP BY bank
)
AND is_deleted = false;

CREATE TABLE email (
	id		SERIAL PRIMARY KEY,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE emaildetail (
	id		SERIAL PRIMARY KEY,
	email		INT4 references email(id) ON DELETE RESTRICT
			DEFAULT currval(pg_get_serial_sequence('email','id')),
	sendername	TEXT,
	sendermail	TEXT,
	body		TEXT,
	emailafter	timestamp with time zone,
	sent		timestamp with time zone,
	is_deleted	boolean,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TRIGGER emaildetailupdate BEFORE INSERT ON emaildetail
FOR EACH ROW EXECUTE PROCEDURE emailupdate();

CREATE OR REPLACE VIEW email_current AS
SELECT * FROM emaildetail
WHERE id IN (
	SELECT MAX(id)
	FROM emaildetail
	GROUP BY email
);

CREATE OR REPLACE VIEW email_unsent AS
SELECT * FROM email_current
WHERE sent IS NULL AND emailafter < NOW();

CREATE TABLE emailheader (
	id		SERIAL PRIMARY KEY,
	email		INT4 references email(id) ON DELETE RESTRICT
			DEFAULT currval(pg_get_serial_sequence('email','id')),
	header		TEXT NOT NULL,
	value		TEXT NOT NULL,
	is_deleted	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE emailpart (
	id		SERIAL PRIMARY KEY,
	email		INT4 references email(id) ON DELETE RESTRICT
			DEFAULT currval(pg_get_serial_sequence('email','id')),
	file		TEXT,
	is_deleted	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE emailrecipient (
	id		SERIAL PRIMARY KEY,
	email		INT4 references email(id) ON DELETE RESTRICT
			DEFAULT currval(pg_get_serial_sequence('email','id')),
	contact		INT4 references contact(id) ON DELETE RESTRICT,
	emailname	TEXT NOT NULL DEFAULT '',
	emailaddress	TEXT NOT NULL,
	is_to		boolean DEFAULT false,
	is_cc		boolean DEFAULT false,
	is_bcc		boolean DEFAULT false,
	is_deleted	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

-- whilst organisations exist at an instance level, sequences such as 
-- salesinvoice ids are individual to each business.  We track them here.
CREATE TABLE organisationsequence (
	id              INT4 PRIMARY KEY references organisation(id),
	purchaseorder   INT4 NOT NULL DEFAULT 0,
	purchaseinvoice INT4 NOT NULL DEFAULT 0,
	salesorder      INT4 NOT NULL DEFAULT 0,
	salesinvoice    INT4 NOT NULL DEFAULT 0
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
        product         INT4 references product(id) ON DELETE RESTRICT NOT NULL
		DEFAULT currval(pg_get_serial_sequence('product','id')),
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

CREATE TRIGGER productdetailupdate BEFORE INSERT ON productdetail
FOR EACH ROW EXECUTE PROCEDURE productdetailupdate();

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

CREATE TRIGGER product_tax_pre_insert BEFORE INSERT ON product_tax
FOR EACH ROW EXECUTE PROCEDURE producttaxupdate();

CREATE TRIGGER product_tax_insert AFTER INSERT ON product_tax
FOR EACH ROW EXECUTE PROCEDURE product_tax_vatcheck();

CREATE OR REPLACE VIEW product_current AS
SELECT
        p.id AS id, 
        pd.id AS detailid,
        pd.product,
        account,
        shortname,
        description,
        price_buy,
        price_sell,
        margin,
        markup,
        is_available,
        is_offered,
        pd.updated,
        pd.authuser,
        pd.clientip, 
        COALESCE(MIN(pt.tax),'-1') AS tax
FROM product p
INNER JOIN productdetail pd ON p.id = pd.product
LEFT JOIN product_tax pt ON p.id = pt.product
WHERE pd.id IN (
        SELECT MAX(id)
        FROM productdetail
        GROUP BY product
)
GROUP BY
        p.id,
        pd.id,
        account,
        shortname,       
        description,     
        price_buy,       
        price_sell,      
        margin,
        markup,
        is_available,    
        is_offered,      
        pd.updated,
        pd.authuser,
        pd.clientip
;

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
	quotenumber	INT4 UNIQUE,
	ponumber	TEXT,
	description	TEXT,
	cycle		INT4,
	start_date	date,
	start_date_null	boolean DEFAULT false,
	end_date	date,
	end_date_null	boolean DEFAULT false,
	is_open		boolean DEFAULT true,
	is_deleted	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT,
	CONSTRAINT purchaseorderdetail_fkey_purchaseorder
		FOREIGN KEY (purchaseorder) REFERENCES purchaseorder(id),
	CONSTRAINT purchaseorderdetail_fkey_cycle
		FOREIGN KEY (cycle) REFERENCES cycle(id)
);

CREATE OR REPLACE VIEW purchaseorderview AS
SELECT
        po.id,
        o.name || '(' || o.orgcode || ')' AS supplier,
        o.orgcode || '/' || lpad(CAST(po.ordernum AS TEXT), 5, '0') AS order,
        pod.description,
        pod.cycle,
        pod.start_date,
        pod.end_date
FROM purchaseorderdetail pod
INNER JOIN purchaseorder po ON po.id = pod.purchaseorder
INNER JOIN organisation_current o ON o.id = po.organisation
WHERE pod.id IN (
        SELECT MAX(id)
        FROM purchaseorderdetail
        GROUP BY purchaseorder
)
AND pod.is_open = 'true'
AND pod.is_deleted = 'false'
;

CREATE TABLE purchaseorderitem (
	id		SERIAL PRIMARY KEY,
        uuid            uuid,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE purchaseorderitemdetail (
	id		SERIAL PRIMARY KEY,
	purchaseorderitem INT4 references purchaseorderitem(id) NOT NULL,
	purchaseorder	INT4 REFERENCES purchaseorder(id) NOT NULL,
	product		INT4 REFERENCES product(id) NOT NULL,
	linetext	TEXT,
	discount	NUMERIC,
	discount_null	boolean DEFAULT false,
	price		NUMERIC,
	price_null	boolean DEFAULT false,
	qty		NUMERIC DEFAULT '1',
	is_deleted	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

DROP TRIGGER IF EXISTS purchaseorderdetailupdate
ON purchaseorderdetail;
CREATE TRIGGER purchaseorderdetailupdate BEFORE INSERT
ON purchaseorderdetail
FOR EACH ROW EXECUTE PROCEDURE purchaseorderdetailupdate();

DROP TRIGGER IF EXISTS purchaseorderitemdetailupdate
ON purchaseorderitemdetail;
CREATE TRIGGER purchaseorderitemdetailupdate BEFORE INSERT
ON purchaseorderitemdetail
FOR EACH ROW EXECUTE PROCEDURE purchaseorderitemdetailupdate();

CREATE OR REPLACE VIEW purchaseorderitem_current AS
SELECT 
        poi.id,
        poid.id as detailid,
        poi.uuid,
        purchaseorder,
        product,
        linetext,
        price,
        qty,
        poid.updated,
        poid.authuser,
        poid.clientip
FROM purchaseorderitem poi
INNER JOIN purchaseorderitemdetail poid ON poi.id = poid.purchaseorderitem 
WHERE poid.id IN (
	SELECT MAX(id)
	FROM purchaseorderitemdetail
	GROUP BY purchaseorderitem
)
AND poid.is_deleted = false;

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
	purchaseorder	INT4 references purchaseorder(id),
	period		INT4,
	ref             TEXT,
	ponumber	TEXT,
	description	TEXT,
	taxpoint	date,
	endpoint	date,
	issued		timestamp with time zone default now(),
	journal		INT4 references journal(id),
	due		date,
	subtotal	NUMERIC,
	tax		NUMERIC,
	total		NUMERIC,
	pdf		TEXT,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

DROP TRIGGER IF EXISTS purchaseinvoicedetailupdate
ON purchaseinvoicedetail;
CREATE TRIGGER purchaseinvoicedetailupdate BEFORE INSERT
ON purchaseinvoicedetail
FOR EACH ROW EXECUTE PROCEDURE purchaseinvoicedetailupdate();

CREATE TABLE purchaseinvoiceitem (
        id              SERIAL PRIMARY KEY,
        uuid            uuid,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE purchaseinvoiceitemdetail (
        id              SERIAL PRIMARY KEY,
        purchaseinvoiceitem        INT4 references purchaseinvoiceitem(id) NOT NULL
            DEFAULT currval(pg_get_serial_sequence('purchaseinvoiceitem','id')),
        purchaseinvoice    INT4 references purchaseinvoice(id) NOT NULL
            DEFAULT currval(pg_get_serial_sequence('purchaseinvoice','id')),
        product         INT4 references product(id) NOT NULL,
        linetext        TEXT,
        discount        NUMERIC,
        price           NUMERIC,
        qty             NUMERIC DEFAULT '1',
        is_deleted      boolean DEFAULT false,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE OR REPLACE VIEW purchaseinvoiceitem_current AS
SELECT 
        pii.id,
        pii.uuid,
        piid.id AS detailid,
        piid.purchaseinvoiceitem,
        piid.purchaseinvoice,
        piid.product,
        piid.linetext,
        piid.discount,
        piid.price,
        piid.qty,
        pii.updated AS created,
        piid.updated,
        piid.authuser,
        piid.clientip
FROM purchaseinvoiceitem pii 
INNER JOIN purchaseinvoiceitemdetail piid
ON pii.id = piid.purchaseinvoiceitem
WHERE piid.id IN (
        SELECT MAX(id)
        FROM purchaseinvoiceitemdetail
        GROUP BY purchaseinvoiceitem
)
AND is_deleted = false;

CREATE OR REPLACE VIEW purchaseinvoice_current AS
SELECT
        pi.id,
        pid.id as detailid,
        organisation,
        invoicenum,
        ref,
        ponumber,
        description,
        taxpoint,
        endpoint,
        issued,
        journal,
        due,
        subtotal,
        tax,
        total,
        pdf,
        pid.updated,
        pid.authuser,
        pid.clientip
FROM purchaseinvoice pi
INNER JOIN purchaseinvoicedetail pid ON pi.id = pid.purchaseinvoice 
WHERE pid.id IN (
	SELECT MAX(id)
	FROM purchaseinvoicedetail
	GROUP BY purchaseinvoice
);

CREATE TABLE purchasepayment (
	id		SERIAL PRIMARY KEY,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE purchasepaymentdetail (
	id		SERIAL PRIMARY KEY,
	purchasepayment	INT4 references purchasepayment(id) NOT NULL,
	paymenttype	INT4 references paymenttype(id) NOT NULL,
	organisation	INT4 references organisation(id) NOT NULL,
	bank		INT4 references bank(id),
	bankaccount	INT4 references account(id) NOT NULL,
	transactdate	date,
	amount		NUMERIC,
	description	TEXT,
	journal		INT4 references journal(id),
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE OR REPLACE VIEW purchasepayment_current AS
SELECT * FROM purchasepaymentdetail
WHERE id IN (
	SELECT MAX(id)
	FROM purchasepaymentdetail
	GROUP BY purchasepayment
);

CREATE OR REPLACE VIEW purchasepaymentlist AS
SELECT
	pp.purchasepayment AS id,
	pp.transactdate AS date,
	o.orgcode,
	pp.bankaccount as account,
	pp.amount,
	pp.updated

FROM purchasepayment_current pp
INNER JOIN organisation_current o ON o.id = pp.organisation
ORDER BY pp.id ASC;


CREATE TABLE purchasepaymentallocation (
	id		SERIAL PRIMARY KEY,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE purchasepaymentallocationdetail (
	id		SERIAL PRIMARY KEY,
	purchasepaymentallocation	INT4 references purchasepaymentallocation(id) NOT NULL,
	payment		INT4 references purchasepayment(id) NOT NULL,
	purchaseinvoice	INT4 references purchaseinvoice(id) NOT NULL,
	amount		NUMERIC,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE OR REPLACE VIEW purchasepaymentallocation_current AS
SELECT * FROM purchasepaymentallocationdetail
WHERE id IN (
	SELECT MAX(id)
	FROM purchasepaymentallocationdetail
	GROUP BY purchasepaymentallocation
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
	cycle		INT4 references cycle(id) NOT NULL,
	start_date	date,
	start_date_null	boolean DEFAULT false,
	end_date	date,
	end_date_null	boolean DEFAULT false,
	is_open		boolean DEFAULT true,
	is_deleted	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salesorderitem (
	id		SERIAL PRIMARY KEY,
        uuid            uuid,
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
	discount_null	boolean DEFAULT false,
	price		NUMERIC,
	price_null	boolean DEFAULT false,
	qty		NUMERIC DEFAULT '1',
	is_deleted	boolean DEFAULT false,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

DROP TRIGGER IF EXISTS salesorderdetailupdate 
ON salesorderdetail;
CREATE TRIGGER salesorderdetailupdate BEFORE INSERT 
ON salesorderdetail
FOR EACH ROW EXECUTE PROCEDURE salesorderdetailupdate();

DROP TRIGGER IF EXISTS salesorderitemdetailupdate 
ON salesorderitemdetail;
CREATE TRIGGER salesorderitemdetailupdate BEFORE INSERT 
ON salesorderitemdetail
FOR EACH ROW EXECUTE PROCEDURE salesorderitemdetailupdate();

CREATE OR REPLACE VIEW salesorderitem_current AS
SELECT 
	soi.id,
	soid.id AS detailid,
        uuid,
	salesorder,
	product,
	linetext,
	discount,
	price,
	qty,
	soid.updated,
	soid.authuser,
	soid.clientip
FROM salesorderitem soi
INNER JOIN salesorderitemdetail soid ON soi.id = soid.salesorderitem 
WHERE soid.id IN (
	SELECT MAX(id)
	FROM salesorderitemdetail
	GROUP BY salesorderitem
)
AND is_deleted = false;

CREATE OR REPLACE VIEW salesorder_tax AS
SELECT 	so.id AS salesorder,
	roundhalfeven(SUM(COALESCE(soi.price, p.price_sell, '0.00') * soi.qty * tr.rate/100),2) AS tax
FROM salesorder so
INNER JOIN salesorderdetail sod ON so.id = sod.salesorder
INNER JOIN salesorderitem_current soi ON so.id = soi.salesorder
INNER JOIN product_current p ON p.product = soi.product
LEFT JOIN (
	SELECT * FROM product_tax WHERE is_applicable = true
) pt ON p.product = pt.product
LEFT JOIN taxrate_current tr ON tr.tax = pt.tax
WHERE sod.id IN (
	SELECT MAX(id) FROM salesorderdetail GROUP BY salesorder
)
AND sod.is_deleted = false
AND (tr.valid_from <= salesorder_nextissuedate(so.id)
	OR tr.valid_from IS NULL)
AND (tr.valid_to >= salesorder_nextissuedate(so.id) OR tr.valid_to IS NULL)
GROUP BY so.id, so.organisation, so.ordernum;

CREATE OR REPLACE VIEW salesorder_current AS
SELECT
	so.id,
	so.organisation,
	so.ordernum,
	sod.salesorder,
	sod.quotenumber,
	sod.ponumber,
	sod.description,
	sod.cycle,
	sod.start_date,
	sod.end_date,
	sod.is_open,
	sod.is_deleted,
	roundhalfeven(SUM(COALESCE(soi.price, p.price_sell, '0.00') * soi.qty),2) AS price,
	roundhalfeven(COALESCE(tx.tax, '0.00'),2) as tax,
	roundhalfeven(SUM(COALESCE(soi.price, p.price_sell, '0.00') * soi.qty) +
	                COALESCE(tx.tax, '0.00'),2) AS total,
	so.updated AS created,
	sod.updated AS modified
FROM salesorder so
INNER JOIN salesorderdetail sod ON so.id = sod.salesorder
LEFT JOIN salesorderitem_current soi ON so.id = soi.salesorder
INNER JOIN product_current p ON p.product = soi.product
LEFT JOIN salesorder_tax tx ON sod.salesorder = tx.salesorder
WHERE sod.id IN (
	SELECT MAX(id)
	FROM salesorderdetail
	GROUP BY salesorder
)
GROUP BY so.id, so.organisation, so.ordernum, tx.tax,
	sod.salesorder,
	sod.quotenumber,
	sod.ponumber,
	sod.description,
	sod.cycle,
	sod.start_date,
	sod.end_date,
	sod.is_open,
	sod.is_deleted,
	sod.updated
;

/*  not used - intended for overriding taxes
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
*/

CREATE TABLE salesinvoice (
	id		SERIAL PRIMARY KEY,
	organisation	INT4 references organisation(id) NOT NULL,
	invoicenum	INT4 NOT NULL,
	import_id	TEXT,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT,
	UNIQUE (organisation, invoicenum)
);

CREATE TABLE salesinvoicedetail (
	id		SERIAL PRIMARY KEY,
	salesinvoice	INT4 references salesinvoice(id) NOT NULL
		DEFAULT currval(pg_get_serial_sequence('salesinvoice','id')),
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
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salesinvoiceitemdetail (
	id		SERIAL PRIMARY KEY,
	salesinvoiceitem	INT4 references salesinvoiceitem(id) NOT NULL
	    DEFAULT currval(pg_get_serial_sequence('salesinvoiceitem','id')),
	salesinvoice	INT4 references salesinvoice(id) NOT NULL
	    DEFAULT currval(pg_get_serial_sequence('salesinvoice','id')),
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

CREATE OR REPLACE VIEW salesinvoiceitem_current AS
SELECT * FROM salesinvoiceitemdetail
WHERE id IN (
	SELECT MAX(id)
	FROM salesinvoiceitemdetail
	GROUP BY salesinvoiceitem
)
AND is_deleted = false;

CREATE OR REPLACE VIEW salesinvoiceitem_display AS
SELECT 
	salesinvoiceitem as id,
	salesinvoice,
	siid.product,
	COALESCE(siid.linetext, p.description) as linetext,
	siid.discount,
	COALESCE(siid.price, p.price_sell, '0.00') as price,
	siid.qty,
	roundhalfeven(COALESCE(siid.price, p.price_sell, '0.00') * siid.qty, 2)
		as linetotal
FROM salesinvoiceitem_current siid
INNER JOIN product_current p ON p.product = siid.product
;

-- record taxes charged on an invoice as at the time it is issued --
-- updated by trigger on salesinvoicedetail table --
CREATE TABLE salesinvoice_tax (
	id		SERIAL PRIMARY KEY,
	salesinvoice	INT4 references salesinvoice(id) ON DELETE RESTRICT
			NOT NULL,
	account		NUMERIC,
	taxname		TEXT,
	rate		NUMERIC,
	nett		NUMERIC,
	total		NUMERIC,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE OR REPLACE VIEW salesinvoice_current AS
SELECT 	sod.id,
	sod.salesinvoice,
	sod.salesorder,
	sod.period,
	sod.ponumber,
	sod.taxpoint,
	sod.endpoint,
	sod.issued,
	sod.due,
	so.organisation,
	o.orgcode,
	so.invoicenum,
	o.orgcode || '/' || to_char(invoicenum, 'FM0000') AS ref,
        roundhalfeven(COALESCE(sod.subtotal, 
	SUM(COALESCE(soi.price, p.price_sell, '0.00') * soi.qty)),2) AS subtotal,
	COALESCE(sod.tax, sit.tax, '0.00') AS tax,
	roundhalfeven(COALESCE(sod.total, SUM(COALESCE(soi.price, p.price_sell, '0.00')
	* soi.qty) + COALESCE(sod.tax, sit.tax, '0.00')),2) AS total,
        date_part('day', current_timestamp - due) AS age
FROM salesinvoicedetail sod
INNER JOIN salesinvoice so ON so.id = sod.salesinvoice
LEFT JOIN salesinvoiceitem_current soi ON so.id = soi.salesinvoice
LEFT JOIN (
	SELECT sit.salesinvoice, SUM(sit.total) AS tax 
	FROM salesinvoice_tax sit 
	GROUP BY sit.salesinvoice
) sit ON so.id = sit.salesinvoice
LEFT JOIN product_current p ON p.product = soi.product
INNER JOIN organisation o ON o.id = so.organisation
GROUP BY sod.id, so.organisation, so.invoicenum, sit.tax, o.orgcode, sod.due;

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
	bank		INT4 references bank(id),
	bankaccount	INT4 references account(id) NOT NULL,
	transactdate	date,
	amount		NUMERIC,
	description	TEXT,
	journal		INT4 references journal(id),
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE OR REPLACE VIEW salespayment_current AS
SELECT * FROM salespaymentdetail
WHERE id IN (
	SELECT MAX(id)
	FROM salespaymentdetail
	GROUP BY salespayment
)
ORDER BY id ASC;

CREATE OR REPLACE VIEW salespaymentlist AS
SELECT 
	sp.salespayment AS id,
	sp.transactdate AS date,
	o.orgcode,
	sp.bankaccount as account,
	sp.amount,
	sp.updated

FROM salespayment_current sp
INNER JOIN organisation_current o ON o.id = sp.organisation
ORDER BY sp.id ASC;

CREATE TABLE salespaymentallocation (
	id		SERIAL PRIMARY KEY,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE salespaymentallocationdetail (
	id		SERIAL PRIMARY KEY,
	salespaymentallocation	INT4 references salespaymentallocation(id) NOT NULL,
	payment		INT4 references salespayment(id) NOT NULL,
	salesinvoice	INT4 references salesinvoice(id) NOT NULL,
	amount		NUMERIC,
	updated		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE OR REPLACE VIEW salespaymentallocation_current AS
SELECT * FROM salespaymentallocationdetail
WHERE id IN (
	SELECT MAX(id)
	FROM salespaymentallocationdetail
	GROUP BY salespaymentallocation
);

-- trigger to ensure sum of amounts in salespaymentallocation do not exceed amount of salespayment --

CREATE CONSTRAINT TRIGGER trig_check_purchasepayment_allocation
	AFTER INSERT
	ON purchasepaymentallocationdetail
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE check_payment_allocation('purchase')
;

CREATE CONSTRAINT TRIGGER trig_check_salespayment_allocation
	AFTER INSERT
	ON salespaymentallocationdetail
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE check_payment_allocation('sales')
;

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

CREATE TRIGGER trig_check_salesorder_period
	BEFORE INSERT OR UPDATE
        ON salesinvoicedetail
        FOR EACH ROW
        EXECUTE PROCEDURE check_salesorder_period()
;

CREATE TRIGGER trig_updatesalesinvoicetotals
	AFTER INSERT OR UPDATE
	ON salesinvoicedetail
	FOR EACH ROW
	EXECUTE PROCEDURE updatesalesinvoicetotals()
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

CREATE VIEW assetaccountlist AS
SELECT
        a.id as nominalcode,
        a.description as account,
        at.name as type
FROM account a
INNER JOIN accounttype at ON at.id = a.accounttype
WHERE a.accounttype = '1000'
ORDER by a.id ASC
;

CREATE VIEW revenueaccountlist AS
SELECT
        a.id as nominalcode,
        a.description as account,
        at.name as type
FROM account a
INNER JOIN accounttype at ON at.id = a.accounttype
WHERE a.accounttype = '4000'
ORDER by a.id ASC
;

CREATE OR REPLACE VIEW balancesheet AS
	-- assets
        SELECT
                account as sort,
                description || ' (' || account || ')' AS description,
		format_accounting(COALESCE(sum(debit), 0)
		- COALESCE(sum(credit), 0)) as total
        FROM ledger l
        INNER JOIN account a ON a.id=l.account
	WHERE account BETWEEN 0 AND 1999
        GROUP BY account, description, division, department
UNION
	-- total assets
	SELECT 
                1999 as sort,
                text 'TOTAL ASSETS' AS description,
		format_accounting(
			COALESCE(sum(debit), 0) - COALESCE(sum(credit), 0)
		) as total
        FROM ledger l
	WHERE account BETWEEN 0 AND 1999
UNION
	-- liabilities
        SELECT
                account as sort,
                description || ' (' || account || ')' AS description,
		format_accounting(
			COALESCE(sum(credit), 0) - COALESCE(sum(debit), 0)
		) as total
        FROM ledger l
        INNER JOIN account a ON a.id=l.account
	WHERE account BETWEEN 2000 AND 2999
        GROUP BY account, description, division, department
UNION
	-- total liabilities
	SELECT 
                2999 as sort,
                text 'TOTAL LIABILITIES' AS description,
		format_accounting(
			COALESCE(sum(credit), 0) - COALESCE(sum(debit), 0)
		) as total
        FROM ledger l
	WHERE account BETWEEN 2000 AND 2999
UNION
	-- capital
        SELECT
                account as sort,
                description || ' (' || account || ')' AS description,
		format_accounting(
			COALESCE(sum(credit), 0) - COALESCE(sum(debit), 0)
		) as total
        FROM ledger l
        INNER JOIN account a ON a.id=l.account
	WHERE account BETWEEN 3000 AND 3999
        GROUP BY account, description, division, department
UNION
	-- capital - unposted retained earnings (current period)
        SELECT
                3200 as sort,
                'Earnings (Current Period)' AS description,
		format_accounting(
			COALESCE(sum(credit), 0) - COALESCE(sum(debit), 0)
		) as total
        FROM ledger l
	WHERE account BETWEEN 4000 AND 9999
        GROUP BY sort, description, division, department
UNION
	-- total capital
	SELECT 
                3999 as sort,
                text 'TOTAL CAPITAL' AS description,
		format_accounting(
			COALESCE(sum(credit), 0) - COALESCE(sum(debit), 0)
		) as total
	FROM ledger l
		WHERE account BETWEEN 3000 AND 9999
UNION
        SELECT
                99999 as account,
                text 'TOTAL LIABILITES AND CAPITAL' AS description,
		format_accounting(
			COALESCE(sum(credit), 0) - COALESCE(sum(debit), 0)
		) as total
        FROM ledger l
	WHERE account BETWEEN 2000 AND 9999
ORDER BY sort ASC
;

CREATE OR REPLACE VIEW customer AS
SELECT *
FROM organisation_current
WHERE id IN (SELECT organisation FROM salesinvoice_current);

CREATE OR REPLACE VIEW salesinvoice_unpaid AS
SELECT 	sic.id,
	sic.salesinvoice,
	sic.salesorder,
	sic.period,
	sic.ponumber,
	sic.taxpoint,
	sic.endpoint,
	sic.issued,
	sic.due,
	sic.organisation,
	sic.orgcode,
	sic.invoicenum,
	sic.ref,
	sic.subtotal,
	sic.tax,
	sic.total,
	COALESCE(SUM(sip.amount), '0.00') AS paid,
        sic.age
FROM salesinvoice_current sic
LEFT JOIN salespaymentallocation_current sip
ON sic.id = sip.salesinvoice
GROUP BY
	sic.id,
	sic.salesinvoice,
	sic.salesorder,
	sic.period,
	sic.ponumber,
	sic.taxpoint,
	sic.endpoint,
	sic.issued,
	sic.due,
	sic.organisation,
	sic.orgcode,
	sic.invoicenum,
	sic.ref,
	sic.subtotal,
	sic.tax,
	sic.total,
        sic.age
HAVING COALESCE(SUM(sip.amount), '0.00') < sic.total
;

CREATE OR REPLACE VIEW ageddebtors AS 
SELECT
        si.organisation,
        COALESCE(sic.unpaid, '0.00') AS current,
        COALESCE(s30.unpaid, '0.00') AS days30,
        COALESCE(s60.unpaid, '0.00') AS days60,
        COALESCE(s90.unpaid, '0.00') AS days90,
        COALESCE(s91.unpaid, '0.00') AS days91,
        COALESCE(sic.unpaid, '0.00') +
        COALESCE(s30.unpaid, '0.00') +
        COALESCE(s60.unpaid, '0.00') +
        COALESCE(s90.unpaid, '0.00') +
        COALESCE(s91.unpaid, '0.00') AS total
FROM salesinvoice_unpaid si
LEFT JOIN (
        SELECT organisation, SUM(total) - SUM(paid) AS unpaid
        FROM salesinvoice_unpaid
        WHERE age <= 0 GROUP BY organisation
) sic ON si.organisation = sic.organisation
LEFT JOIN (
        SELECT organisation, SUM(total) - SUM(paid) AS unpaid
        FROM salesinvoice_unpaid
        WHERE age BETWEEN 1 AND 30
        GROUP BY organisation
) s30 ON si.organisation = s30.organisation
LEFT JOIN (
        SELECT organisation, SUM(total) - SUM(paid) AS unpaid
        FROM salesinvoice_unpaid
        WHERE age BETWEEN 31 AND 60
        GROUP BY organisation
) s60 ON si.organisation = s60.organisation
LEFT JOIN (
        SELECT organisation, SUM(total) - SUM(paid) AS unpaid
        FROM salesinvoice_unpaid
        WHERE age BETWEEN 61 AND 90
        GROUP BY organisation
) s90 ON si.organisation = s90.organisation
LEFT JOIN (
        SELECT organisation, SUM(total) - SUM(paid) AS unpaid
        FROM salesinvoice_unpaid
        WHERE age >= 91 
        GROUP BY organisation
) s91 ON si.organisation = s91.organisation
GROUP BY si.organisation, sic.unpaid, s30.unpaid, s60.unpaid, s90.unpaid, s91.unpaid
;

CREATE OR REPLACE VIEW trialbalance AS
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

CREATE OR REPLACE VIEW generalledger AS
SELECT
	l.id,
	j.id AS journal,
	j.transactdate as date,
	j.description AS narrative,
	a.description || '(' || l.account || ')' as account,
	l.division, l.department,
	format_accounting(l.debit) AS debit,
	format_accounting(l.credit) AS credit
FROM ledger l
INNER JOIN journal j ON j.id = l.journal
INNER JOIN account a ON a.id = l.account
;

CREATE OR REPLACE VIEW generalledger_search AS
SELECT
	l.id,
	j.id AS journal,
	j.transactdate as date,
	j.description AS narrative,
	a.description || '(' || l.account || ')' as account,
	l.division, l.department,
	l.debit AS debit,
	l.credit AS credit,
	format_accounting(l.debit) AS fdebit,
	format_accounting(l.credit) AS fcredit
FROM ledger l
INNER JOIN journal j ON j.id = l.journal
INNER JOIN account a ON a.id = l.account
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
        so.id,
        o.name AS customer,
        o.orgcode || '/' || lpad(CAST(so.ordernum AS TEXT), 5, '0') AS order,
        so.ponumber,
        so.description as comment,
        so.cycle,
        so.start_date,
        so.end_date,
	so.created,
	so.modified
FROM salesorder_current so
INNER JOIN organisation_current o ON o.id = so.organisation
WHERE so.is_open = 'true'
AND so.is_deleted = 'false'
;

CREATE OR REPLACE VIEW salesorderview AS
SELECT
        so.id,
        o.name || '(' || o.orgcode || ')' AS customer,
        o.orgcode || '/' || lpad(CAST(so.ordernum AS TEXT), 5, '0') AS order,
        sod.ponumber,
        sod.description,
        sod.cycle,
        sod.start_date,
        sod.end_date
FROM salesorderdetail sod
INNER JOIN salesorder so ON so.id = sod.salesorder
INNER JOIN organisation_current o ON o.id = so.organisation
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

CREATE OR REPLACE VIEW organisation_invoiced AS
SELECT o.id, SUM(COALESCE(si.total, 0)) as invoiced
FROM organisation o
LEFT JOIN salesinvoice_current si ON o.id = si.organisation
GROUP BY o.id;

CREATE OR REPLACE VIEW organisation_paid AS
SELECT o.id, SUM(COALESCE(sp.amount, 0)) as paid
FROM organisation o
LEFT JOIN salespayment_current sp ON o.id = sp.organisation
GROUP BY o.id;

CREATE OR REPLACE VIEW organisationstatement AS
SELECT
        'SI' as type,
        si.organisation AS id,
        si.id AS lineid,
        DATE(si.taxpoint) AS taxpoint,
        DATE(si.issued) AS issued,
        DATE(si.due) as due,
        si.ref AS ref,
        'Invoice: ' || si.ref AS description,
        format_accounting(si.subtotal) AS subtotal,
        format_accounting(si.tax) AS tax,
        format_accounting(si.total) AS total
FROM salesinvoice_current si
UNION
SELECT
        'SP' AS type,
        sp.organisation AS id,
        sp.id AS lineid,
        DATE(transactdate) AS taxpoint,
        NULL AS issued,
        NULL AS due,
        'Payment Received' AS ref,
        'Payment Received' AS description,
        NULL AS subtotal,
        NULL AS tax,
        format_accounting(amount) AS total
FROM salespayment_current sp
UNION
SELECT
        'TOTAL' AS type,
        o.id AS id,
        NULL AS lineid,
        NULL AS taxpoint,
        NULL AS issued,
        NULL AS due,
        'Total Amount Due' AS ref,
        'Total Amount Due' AS description,
        NULL AS subtotal,
        NULL AS tax,
        format_accounting(
                COALESCE(oi.invoiced, 0) - COALESCE(op.paid,0)
        ) AS total
FROM organisation o
LEFT JOIN organisation_invoiced oi ON o.id = oi.id
LEFT JOIN organisation_paid op ON o.id = op.id
ORDER BY taxpoint ASC, type ASC, lineid ASC
;

CREATE OR REPLACE VIEW salesstatement AS
SELECT
	'ORG_NAME' as type,
	o.id,
	NULL AS salesinvoice,
	'0001-01-01' AS taxpoint,
	NULL AS issued,
	NULL AS due,
	o.name || ' (' || o.orgcode || ')' AS ref,
	NULL AS subtotal,
	NULL AS tax,
	NULL AS total
FROM organisation_current o
UNION
SELECT
	'SI' as type,
	si.organisation AS id,
	si.salesinvoice,
	DATE(si.taxpoint) AS taxpoint,
	DATE(si.issued) AS issued,
	DATE(si.due) as due,
	'Invoice: ' || si.ref AS ref,
	format_accounting(si.subtotal) AS subtotal,
	format_accounting(si.tax) AS tax,
	format_accounting(si.total) AS total
FROM salesinvoice_current si
UNION
SELECT
	'SP' AS type,
	sp.organisation AS id,
	NULL AS salesinvoice,
	DATE(transactdate) AS taxpoint,
	NULL AS issued,
	NULL AS due,
	'Payment Received' AS ref,
	NULL AS subtotal,
	NULL AS tax,
	format_accounting(amount) AS total
FROM salespayment_current sp
UNION
SELECT
	'TOTAL' AS type,
	o.id AS id,
	NULL AS salesinvoice,
	NULL AS taxpoint,
	NULL AS issued,
	NULL AS due,
	'Total Amount Due' AS ref,
	NULL AS subtotal,
	NULL AS tax,
	format_accounting(
		COALESCE(oi.invoiced, 0) - COALESCE(op.paid,0)
	) AS total
FROM organisation o
LEFT JOIN organisation_invoiced oi ON o.id = oi.id
LEFT JOIN organisation_paid op ON o.id = op.id
ORDER BY taxpoint ASC
;

CREATE OR REPLACE VIEW accountsreceivable AS
SELECT
	o.id,
	o.name,
	o.orgcode,
	format_accounting(
		COALESCE(oi.invoiced, 0) - COALESCE(op.paid,0)
	) AS total
FROM customer o
LEFT JOIN organisation_invoiced oi ON o.id = oi.id
LEFT JOIN organisation_paid op ON o.id = op.id
ORDER BY o.id ASC
;

EXECUTE 'SELECT default_data(''' || instance || ''',''' || business_id || ''')';

RETURN business;

END;
$$ LANGUAGE 'plpgsql';
