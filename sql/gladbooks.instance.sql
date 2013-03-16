-- Create tables for new instance schema.

SET search_path TO gladbooks;

-- wrap instance creation in a function for convenience --
CREATE OR REPLACE FUNCTION create_instance(instance VARCHAR(63))
RETURNS TEXT AS
$$
BEGIN

--

INSERT INTO instance (id) VALUES (instance);

EXECUTE 'CREATE SCHEMA ' || quote_ident('gladbooks_' || instance);

EXECUTE 'SET search_path TO ' || quote_ident('gladbooks_' || instance) || ',gladbooks';

-- a business represents a distinct set of accounting ledgers
CREATE TABLE business (
	id              SERIAL PRIMARY KEY,
	name		TEXT UNIQUE NOT NULL,
	instance	VARCHAR(63) references instance(id) ON DELETE RESTRICT,
	entered         timestamp with time zone default now()
);
CREATE RULE nodel_business AS ON DELETE TO business DO NOTHING;

CREATE TABLE username (
	id              SERIAL PRIMARY KEY,
	username        TEXT UNIQUE NOT NULL,
	entered         timestamp with time zone default now()
);
CREATE RULE nodel_username AS ON DELETE TO username DO NOTHING;

CREATE TABLE groupname (
	id              SERIAL PRIMARY KEY,
	groupname	TEXT UNIQUE NOT NULL,
	entered         timestamp with time zone default now()
);
CREATE RULE nodel_groupname AS ON DELETE TO groupname DO NOTHING;

CREATE TABLE membership (
	username	INT4 references username(id) ON DELETE RESTRICT,
	groupname	INT4 references groupname(id) ON DELETE RESTRICT,
	entered         timestamp with time zone default now(),
	CONSTRAINT membership_pk PRIMARY KEY (username, groupname)
);

-- each instance can create and modify its own default charts which 
-- are used when creating businesses for this instance
CREATE TABLE chart (
	id              SERIAL PRIMARY KEY,
	name		TEXT UNIQUE NOT NULL,
	entered         timestamp with time zone default now()
);

CREATE TABLE nominalcode (
	chart		INT4 references chart(id) ON DELETE CASCADE,
	account		INT4 NOT NULL,
	name		TEXT NOT NULL DEFAULT '',
	description	TEXT NOT NULL DEFAULT '',
	entered         timestamp with time zone default now(),
	CONSTRAINT nominalcode_pk PRIMARY KEY (chart, account)
);

CREATE TABLE contact (
        id              SERIAL PRIMARY KEY,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE contactdetail (
        id              SERIAL PRIMARY KEY,
        contact         INT4 references contact(id) ON DELETE RESTRICT,
        is_active       boolean DEFAULT true,
        is_deleted      boolean DEFAULT false,
        name            TEXT NOT NULL,
        line_1          TEXT,
        line_2          TEXT,
        line_3          TEXT,
        town            TEXT,
        county          TEXT,
        country         TEXT,
        postcode        TEXT,
        email           TEXT,
        phone           TEXT,
        phonealt        TEXT,
        mobile          TEXT,
        fax             TEXT,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TRIGGER contactdetailupdate BEFORE INSERT ON contactdetail
FOR EACH ROW EXECUTE PROCEDURE contactdetailupdate();

CREATE TABLE organisation (
        id              SERIAL PRIMARY KEY,
        orgcode         TEXT DEFAULT NULL,
        purchaseorder   INT4 NOT NULL DEFAULT 0,
        purchaseinvoice INT4 NOT NULL DEFAULT 0,
        salesorder      INT4 NOT NULL DEFAULT 0,
        salesinvoice    INT4 NOT NULL DEFAULT 0,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT,
        UNIQUE (orgcode)
);

CREATE TABLE organisationdetail (
        id              SERIAL PRIMARY KEY,
        organisation    INT4 references organisation(id)
                        ON DELETE RESTRICT,
        name            TEXT NOT NULL,
        terms           INT4 NOT NULL,
        billcontact     INT4 references contact(id) ON DELETE RESTRICT,
        is_active       boolean NOT NULL,
        is_suspended    boolean NOT NULL,
        is_vatreg       boolean NOT NULL,
        vatnumber       TEXT,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TRIGGER set_orgcode BEFORE INSERT ON organisationdetail
FOR EACH ROW EXECUTE PROCEDURE set_orgcode();

CREATE TRIGGER organisationdetailupdate BEFORE INSERT ON organisationdetail
FOR EACH ROW EXECUTE PROCEDURE organisationdetailupdate();

CREATE TABLE organisation_contact (
        id              SERIAL PRIMARY KEY,
        organisation    INT4 references organisation(id)
                        ON DELETE RESTRICT,
        contact         INT4 references contact(id) ON DELETE RESTRICT,
        is_billing      boolean DEFAULT false,
        is_shipping     boolean DEFAULT false,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE product (
        id              SERIAL PRIMARY KEY,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE productdetail (
        id              SERIAL PRIMARY KEY,
        product         INT4 references product(id) ON DELETE RESTRICT
                        NOT NULL,
        shortname       TEXT NOT NULL UNIQUE,
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

-- views --
CREATE OR REPLACE VIEW contactdetailview AS
SELECT
        contact as id,
        is_active,
        is_deleted,
        name,
        line_1,
        line_2,
        line_3,
        town,
        county,
        country,
        postcode,
        email,
        phone,
        phonealt,
        mobile,
        fax
FROM contactdetail
WHERE id IN (
        SELECT MAX(id)
        FROM contactdetail
        GROUP BY contact
)
ORDER BY contact ASC
;

CREATE OR REPLACE VIEW contactlist AS
SELECT
        contact as id,
        name
FROM contactdetail
WHERE id IN (
        SELECT MAX(id)
        FROM contactdetail
        GROUP BY contact
)
ORDER BY contact ASC
;

CREATE OR REPLACE VIEW organisationlist AS
SELECT
        organisation as id,
        orgcode,
        name
FROM organisationdetail od
INNER JOIN organisation o ON o.id = od.organisation
WHERE od.id IN (

        SELECT MAX(id)
        FROM organisationdetail
        GROUP BY organisation
)
ORDER BY organisation ASC
;


RETURN instance;

END;
$$ LANGUAGE 'plpgsql';

SELECT create_instance('default');
SELECT create_instance('test');
