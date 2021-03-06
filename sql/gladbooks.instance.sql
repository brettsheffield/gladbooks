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
        contact         INT4 NOT NULL 
                        references contact(id) ON DELETE RESTRICT,
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

CREATE OR REPLACE VIEW contact_current AS
SELECT 
	contact AS id,
	id AS detailid,
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
	fax,
	updated,
	authuser,
	clientip
FROM contactdetail
WHERE id IN (
	SELECT MAX(id)
	FROM contactdetail
	GROUP BY contact
)
AND is_deleted = false;

CREATE TABLE organisation (
        id              SERIAL PRIMARY KEY,
        orgcode         TEXT DEFAULT NULL,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT,
        UNIQUE (orgcode)
);

CREATE TABLE organisationdetail (
        id              SERIAL PRIMARY KEY,
        organisation    INT4 references organisation(id)
                        ON DELETE RESTRICT DEFAULT 
			currval(pg_get_serial_sequence('organisation','id')),
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

CREATE OR REPLACE VIEW organisation_current AS
SELECT
        od.organisation AS id,
        od.id AS detailid,
	o.orgcode,
        od.name,
        c.line_1,
        c.line_2,
        c.line_3,
        c.town,
        c.county,
        c.country,
        c.postcode,
        c.email,
        c.phone,
        c.phonealt,
        c.mobile,
        c.fax,
        od.terms,
        od.billcontact,
        od.is_active,
        od.is_suspended,
        od.is_vatreg,
        od.vatnumber,
        od.updated,
        od.authuser,
        od.clientip
FROM organisationdetail od
INNER JOIN organisation o ON o.id = od.organisation
LEFT JOIN contact_current c ON c.id = od.billcontact
WHERE od.id IN (
	SELECT MAX(id)
	FROM organisationdetail
	GROUP BY organisation
);

CREATE TABLE relationship (
	id		SERIAL PRIMARY KEY,
	name		TEXT NOT NULL UNIQUE,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

--INSERT INTO relationship (id, name) VALUES (0, 'contact');
--INSERT INTO relationship (name) VALUES ('billing');
--INSERT INTO relationship (name) VALUES ('shipping');

--CREATE TABLE relationship AS SELECT * FROM gladbooks.relationship;

CREATE TABLE organisation_contact (
        organisation    INT4 references organisation(id) ON DELETE RESTRICT,
        contact         INT4 references contact(id) ON DELETE RESTRICT,
        relationship    INT4 references relationship(id) ON DELETE RESTRICT,
	datefrom	timestamp with time zone,
	dateto		timestamp with time zone,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT,
	PRIMARY KEY (organisation, contact, relationship)
);

CREATE TABLE organisation_organisation (
        organisation    INT4 references organisation(id) ON DELETE RESTRICT,
        related         INT4 references organisation(id) ON DELETE RESTRICT,
        relationship    INT4 references relationship(id) ON DELETE RESTRICT,
	datefrom	timestamp with time zone,
	dateto		timestamp with time zone,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT,
	PRIMARY KEY (organisation, related, relationship)
);

/* FIXME: contact_billing should use billcontact, once we start
 * populating that field */
CREATE OR REPLACE VIEW contact_billing AS
SELECT c.*, oc.organisation, o.name as orgname
FROM contact_current c
INNER JOIN organisation_contact oc ON c.id = oc.contact
INNER JOIN organisation_current o ON o.id = oc.organisation
WHERE oc.relationship = '1';
/*
SELECT c.*, o.organisation
FROM contact_current c
INNER JOIN organisation_current o ON c.contact = o.billcontact
;
*/



-- a business represents a distinct set of accounting ledgers
CREATE TABLE business (
	id              SERIAL PRIMARY KEY,
	name		TEXT UNIQUE NOT NULL,
	instance	VARCHAR(63) references instance(id) ON DELETE RESTRICT,
	organisation	INT4 references organisation(id) ON DELETE RESTRICT 
			NOT NULL,
	vatcashbasis	boolean NOT NULL DEFAULT false,
	billsendername	TEXT DEFAULT 'Billing',
	billsendermail	TEXT DEFAULT '',
	entered         timestamp with time zone default now()
);
CREATE RULE nodel_business AS ON DELETE TO business DO NOTHING;

CREATE TRIGGER trig_businessorganisation BEFORE INSERT ON business
FOR EACH ROW EXECUTE PROCEDURE businessorganisation();

-- accounting period (not always exactly a year)
CREATE TABLE business_year (
	id		SERIAL PRIMARY KEY,
	business	INT4 references business(id) ON DELETE RESTRICT,
	period_start	DATE NOT NULL,
	period_end	DATE NOT NULL,
	entered         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);
CREATE TRIGGER trig_business_year BEFORE INSERT ON business_year
FOR EACH ROW EXECUTE PROCEDURE business_year_end();

CREATE OR REPLACE VIEW businessview AS
SELECT b.*, o.orgcode, byear.period_start, byear.period_end
FROM business b
INNER JOIN organisation o ON o.id = b.organisation
INNER JOIN (select * from business_year WHERE id IN (SELECT MAX(id) FROM business_year GROUP BY business)) byear ON b.id = byear.business
;

CREATE TABLE tag (
	id		TEXT PRIMARY KEY,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE mimetype (
	id		TEXT PRIMARY KEY,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE document (
	id		SERIAL PRIMARY KEY,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE documentdetail (
	id		SERIAL PRIMARY KEY,
	document	INT4 references document(id) ON DELETE RESTRICT
			NOT NULL,
	src		TEXT,
	path		TEXT,
	title		TEXT,
	subject		TEXT,
	description	TEXT,
	mimetype	TEXT references mimetype(id) ON DELETE RESTRICT,
	owner		INT4 references contact(id) ON DELETE CASCADE
			NOT NULL,
	permissions	BIT(8),
        is_deleted      boolean DEFAULT false,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);

CREATE TABLE document_tag (
	document	INT4 references document(id) ON DELETE CASCADE
			NOT NULL,
	tag		TEXT references tag(id) ON DELETE CASCADE
			NOT NULL
);

CREATE TABLE document_author (
	document	INT4 references document(id) ON DELETE CASCADE
			NOT NULL,
	author		INT4 references contact(id) ON DELETE CASCADE
			NOT NULL,
	PRIMARY KEY (document, author)
);



-- TODO: trigger to generate/verify sha1 on document table on INSERT --

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
        c.id,
        c.name
FROM contact_current c
LEFT JOIN organisation_current o ON c.id = o.billcontact 
WHERE o.billcontact IS NULL
AND c.is_deleted = false
ORDER BY c.name ASC
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
ORDER BY name ASC
;


RETURN instance;

END;
$$ LANGUAGE 'plpgsql';
