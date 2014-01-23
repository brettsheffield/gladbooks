-- SQL to safely upgrade older database versions to the latest
-- We need to apply updates to the main gladbooks schema, as well as
-- every instance and every business within each instance.

SET search_path = gladbooks;

-- First, create a table in the main gladbooks schema to track upgrades
CREATE TABLE IF NOT EXISTS upgrade (
	id		INT4 PRIMARY KEY,
	updated		timestamp with time zone default now()
);

-- Create the upgrade functions
CREATE OR REPLACE FUNCTION upgrade_business(businessid INT4)
RETURNS INT4 AS
$$
BEGIN
	RAISE INFO '--- Processing business: % ---', businessid;

	-- Run each business upgrade
	PERFORM upgrade_0001();
	PERFORM upgrade_0002();
	PERFORM upgrade_0004();
	PERFORM upgrade_0005();
	PERFORM upgrade_0006();
	PERFORM upgrade_0007();
	PERFORM upgrade_0008();
	PERFORM upgrade_0011();
	PERFORM upgrade_0012();
	--PERFORM upgrade_0013();
	PERFORM upgrade_0014();
	PERFORM upgrade_0015();
	PERFORM upgrade_0016();
	PERFORM upgrade_0017();
        
	RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_instance(inst TEXT)
RETURNS INT4 AS
$$
DECLARE
	businesses	INT4;
	b		RECORD;
	spath		TEXT;
BEGIN
	RAISE INFO '********** Processing instance: % **********', inst;

	-- Run each instance upgrade
	PERFORM upgrade_0000();
	PERFORM upgrade_0009();
	PERFORM upgrade_0010();

	-- Get count of businesses in this instance
	EXECUTE 'SELECT COUNT(id) FROM '
		|| quote_ident('gladbooks_' || inst) || '.business;'
	INTO businesses;

	RAISE INFO 'Processing % businesses in instance %', businesses, inst;

	-- Loop through businesses
	FOR b IN
		EXECUTE 'SELECT * FROM '
		|| quote_ident('gladbooks_' || inst) || '.business;'
	LOOP
		EXECUTE 'SET search_path TO gladbooks_' || inst|| '_' || b.id
			|| ',gladbooks_' || inst || ',gladbooks';
		PERFORM upgrade_business(b.id);
	END LOOP;

	RETURN businesses; -- return number of businesses processed
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_database()
RETURNS INT4 AS
$$
DECLARE
	vnum		INT4 = 24; -- New version (increment this)
	instances	INT4;
	inst		TEXT;
	oldv		INT4;
BEGIN
	RAISE INFO 'Starting upgrade...';

	EXECUTE 'SELECT MAX(id) FROM upgrade;' INTO oldv;

	IF oldv >= vnum THEN
		RAISE INFO 'Database is already version %.  Upgrade aborted.', oldv;
		RETURN oldv;
	END IF;

	-- Perform upgrades on gladbooks schema
	RAISE INFO '******** Upgrading gladbooks schema ********';
	PERFORM upgrade_0003();
	PERFORM upgrade_0008b();

	EXECUTE 'SELECT COUNT(id) FROM instance;' INTO instances;
	RAISE INFO 'Found % instances', instances;

	-- Loop through instances
	FOR inst IN
		SELECT id FROM instance
	LOOP
		EXECUTE 'SET search_path TO ' || quote_ident('gladbooks_' || inst) || ',gladbooks';
		PERFORM upgrade_instance(inst);
	END LOOP;

	-- Update version number
	EXECUTE 'INSERT INTO upgrade (id) VALUES ($1);' USING vnum;

	RAISE INFO 'Database upgrades complete.';

	EXECUTE 'SELECT MAX(id) FROM upgrade;' INTO vnum;

	RETURN vnum; -- RETURN version number
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_test()
RETURNS INT4 AS
$$
BEGIN
	RAISE INFO 'Test: %', current_business();

	RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0000()
RETURNS INT4 AS
$$
DECLARE
	spath	TEXT;
	lastupgrade	INT4;
BEGIN
	-- Create a table to track upgrades to this instance
	SHOW search_path INTO spath;
	--RAISE INFO 'search_path: %', spath;
	EXECUTE '
	CREATE TABLE IF NOT EXISTS instance_upgrade (
		id		INT4 PRIMARY KEY,
		updated		timestamp with time zone default now()
	);
	';

	SELECT MAX(id) INTO lastupgrade FROM instance_upgrade;
	IF lastupgrade >= 0 THEN
		RAISE INFO '0000 - (skipping)';
		RETURN 0;
	END IF;
	RAISE INFO '0000 - Create a table to track upgrades to this instance';

	-- record upgrade
	EXECUTE 'INSERT INTO instance_upgrade(id) VALUES(0);';

	RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0001()
RETURNS INT4 AS
$$
DECLARE
	lastupgrade	INT4;
BEGIN
	-- Create a table to track upgrades to this business
	EXECUTE '
	CREATE TABLE IF NOT EXISTS business_upgrade (
		id		INT4 PRIMARY KEY,
		updated		timestamp with time zone default now()
	);
	';

	EXECUTE 'SELECT MAX(id) FROM business_upgrade;' INTO lastupgrade;

	IF lastupgrade >= 1 THEN
		RAISE INFO '0001 - (skipping)';
		RETURN 0;
	END IF;

	RAISE INFO '0001 - Create a table to track upgrades to this business';

	-- record upgrade
	EXECUTE 'INSERT INTO business_upgrade(id) VALUES(1);';

	RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

-- 0002 - update salesorder_current view to fix #82
-- applies to each business
CREATE OR REPLACE FUNCTION upgrade_0002()
RETURNS INT4 AS
$$
DECLARE
	spath		TEXT;
	lastupgrade	INT4;
BEGIN
	SHOW search_path INTO spath;
	--RAISE INFO 'search_path: %', spath;
	EXECUTE 'SELECT MAX(id) FROM business_upgrade;' INTO lastupgrade;

	IF lastupgrade >= 2 THEN
		RAISE INFO '0002 - (skipping)';
		RETURN 0;
	END IF;

	RAISE INFO '0002 - update salesorder_current view to fix #82';

	EXECUTE 'DROP VIEW IF EXISTS salesorder_current;';

	EXECUTE '
	CREATE VIEW salesorder_current AS
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
		roundhalfeven(SUM(COALESCE(soi.price, p.price_sell) * soi.qty),2) AS price,
		roundhalfeven(COALESCE(tx.tax, ''0.00''),2) as tax,
		roundhalfeven(SUM(COALESCE(soi.price, p.price_sell) * soi.qty) +
				COALESCE(tx.tax, ''0.00''),2) AS total
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
		sod.is_deleted
	;
	';

	RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

-- 0003 - update create_salesinvoice() to fix #93
-- applies to main gladbooks schema only
CREATE OR REPLACE FUNCTION upgrade_0003()
RETURNS INT4 AS
$$
BEGIN
	
	RAISE INFO '0003 - update create_salesinvoice() to fix #93';

	EXECUTE '
CREATE OR REPLACE FUNCTION create_salesinvoice(so_id INT4, period INT4)
RETURNS boolean AS $create_salesinvoice$
DECLARE
        r_so            RECORD;
        r_soi           RECORD;
        r_tax           RECORD;
        taxpoint        DATE;
        endpoint        DATE;
        due             DATE;
        termdays        INT4;
        terminterval    TEXT;
        si_id           INT4;
BEGIN
        -- fetch the salesorder and cycle info --
        SELECT so.*, c.years, c.months, c.days INTO r_so
        FROM salesorder_current so
        INNER JOIN cycle c ON so.cycle = c.id
        WHERE so.salesorder=so_id;
        IF NOT FOUND THEN
                RAISE EXCEPTION ''salesorder details not found'';
        END IF;
        IF r_so.organisation IS NULL THEN
                RAISE EXCEPTION ''organisation for salesorder cannot be null'';
        END IF;

        taxpoint := taxpoint(r_so.years, r_so.months, r_so.days, r_so.start_date, period);
        endpoint := periodenddate(r_so.years, r_so.months, r_so.days, r_so.start_date, period);

        -- fetch terms for organisation --
        SELECT terms INTO termdays FROM organisation_current
        WHERE organisation = r_so.organisation;

        terminterval := termdays || '' days'';
        due := DATE(NOW()) + terminterval::interval;

        INSERT INTO salesinvoice (organisation) VALUES (r_so.organisation)
        RETURNING currval(pg_get_serial_sequence(''salesinvoice'',''id''))
        INTO si_id;

        IF si_id IS NULL THEN
                RAISE EXCEPTION ''Failed to INSERT salesinvoice'';
        END IF;

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
                RAISE EXCEPTION ''Failed to create .tex'';
        END IF;

        PERFORM post_salesinvoice(si_id);  -- post to ledger
        PERFORM mail_salesinvoice(si_id);  -- email pdf

        RETURN true;
END;
$create_salesinvoice$ LANGUAGE ''plpgsql'';

	';
	RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0004()
RETURNS INT4 AS
$$
BEGIN
	RAISE INFO '0004 - replace journal with ledger in bankdetail table';

	ALTER TABLE bankdetail DROP COLUMN IF EXISTS journal CASCADE;
	BEGIN
		ALTER TABLE bankdetail ADD COLUMN ledger INT4 references ledger(id)
	ON DELETE RESTRICT;
	EXCEPTION
		WHEN duplicate_column THEN RAISE NOTICE 'column ledger already exists in bankdetail. Skipping';
	END;

	RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0005()
RETURNS INT4 AS
$$
BEGIN
	RAISE INFO '0005 - create bank_current view';

	-- replace bank_current view
	CREATE OR REPLACE VIEW bank_current AS
	SELECT * FROM bankdetail
	WHERE id IN (
	        SELECT MAX(id)
		FROM bankdetail
		GROUP BY bank
	);

	RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0006()
RETURNS INT4 AS
$$
BEGIN

        RAISE INFO '0006 - CREATE VIEW salesinvoice_unpaid';

        EXECUTE '
CREATE OR REPLACE VIEW salesinvoice_unpaid AS
SELECT  sic.id,
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
        COALESCE(SUM(sip.amount), ''0.00'') AS paid
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
        sic.total
HAVING COALESCE(SUM(sip.amount), ''0.00'') < sic.total
;
        ';

        RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0007()
RETURNS INT4 AS
$$
BEGIN

        RAISE INFO '0007 - CREATE TRIGGER productdetailupdate';

        EXECUTE '
DROP TRIGGER IF EXISTS productdetailupdate ON productdetail;
CREATE TRIGGER productdetailupdate BEFORE INSERT ON productdetail
FOR EACH ROW EXECUTE PROCEDURE productdetailupdate();
        ';

        RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0008()
RETURNS INT4 AS
$$
BEGIN

        RAISE INFO '0008 - ALTER TABLE accounttype';

	BEGIN
		ALTER TABLE accounttype ADD COLUMN last_id INT4;
	EXCEPTION WHEN duplicate_column THEN
		--
	END;
        RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0008b()
RETURNS INT4 AS
$$
BEGIN

        RAISE INFO '0008b - UPDATE TRIGGER accountinsert';

	DROP TRIGGER IF EXISTS accountinsert ON account;
	CREATE TRIGGER accountinsert AFTER INSERT ON account
	FOR EACH ROW EXECUTE PROCEDURE accountinsert();

        RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0009()
RETURNS INT4 AS
$$
DECLARE
	lastupgrade	INT4;
BEGIN
	SELECT MAX(id) INTO lastupgrade FROM upgrade;
	IF lastupgrade >= 9 THEN
		RAISE INFO '0009 - (skipping)';
		RETURN 0;
	END IF;

        RAISE INFO '0009 - CREATE VIEW contact_current';

        EXECUTE '
DROP VIEW IF EXISTS contact_billing;
DROP VIEW IF EXISTS contact_current;
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
);
CREATE VIEW contact_billing AS
SELECT c.*, oc.organisation, o.name as orgname
FROM contact_current c
INNER JOIN organisation_contact oc ON c.id = oc.contact
INNER JOIN organisation_current o ON o.organisation = oc.organisation
WHERE oc.relationship = ''1'';
        ';

        RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0010()
RETURNS INT4 AS
$$
DECLARE
	lastupgrade	INT4;
BEGIN
	SELECT MAX(id) INTO lastupgrade FROM instance_upgrade;
	IF lastupgrade >= 10 THEN
		RAISE INFO '0010 - (skipping)';
		RETURN 0;
	END IF;

        RAISE INFO '0010 - update organisation_current and dependencies';

        EXECUTE '
DROP VIEW IF EXISTS organisation_current CASCADE;
CREATE OR REPLACE VIEW organisation_current AS
SELECT
        od.organisation AS id,
        od.id AS detailid,
        o.orgcode,
        od.name,        
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
WHERE od.id IN (
        SELECT MAX(id)
        FROM organisationdetail
        GROUP BY organisation
);

CREATE OR REPLACE VIEW contact_billing AS
SELECT c.*, oc.organisation, o.name as orgname
FROM contact_current c
INNER JOIN organisation_contact oc ON c.id = oc.contact
INNER JOIN organisation_current o ON o.id = oc.organisation
WHERE oc.relationship = ''1'';
        ';

        RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0011()
RETURNS INT4 AS
$$
DECLARE
	lastupgrade	INT4;
BEGIN
	SELECT MAX(id) INTO lastupgrade FROM upgrade;
	IF lastupgrade >= 15 THEN
		RAISE INFO '0011 - (skipping)';
		RETURN 0;
	END IF;

        RAISE INFO '0011 - update organisation_current business dependencies';

        EXECUTE '
CREATE OR REPLACE VIEW salesstatement AS
SELECT
        ''ORG_NAME'' as type,
        o.id,
        NULL AS salesinvoice,
        ''0001-01-01'' AS taxpoint,
        NULL AS issued,
        NULL AS due,
        o.name || '' ('' || o.orgcode || '')'' AS ref,
        NULL AS subtotal,
        NULL AS tax,
        NULL AS total
FROM organisation_current o
UNION
SELECT
        ''SI'' as type,
        si.organisation AS id,
        si.salesinvoice,
        DATE(si.taxpoint) AS taxpoint,
        si.issued,
        si.due,
        ''Invoice: '' || si.ref AS ref,
        format_accounting(si.subtotal) AS subtotal,
        format_accounting(si.tax) AS tax,
        format_accounting(si.total) AS total
FROM salesinvoice_current si
UNION
SELECT
        ''SP'' AS type,
        sp.organisation AS id,
        NULL AS salesinvoice,
        DATE(transactdate) AS taxpoint,
        NULL AS issued,
        NULL AS due,
        ''Payment Received'' AS ref,
        NULL AS subtotal,
        NULL AS tax,
        format_accounting(amount) AS total
FROM salespayment_current sp
UNION
SELECT
        ''TOTAL'' AS type,
        o.id AS id,
        NULL AS salesinvoice,
        NULL AS taxpoint,
        NULL AS issued,
        NULL AS due,
        ''Total Amount Due'' AS ref,
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
FROM organisation_current o
LEFT JOIN organisation_invoiced oi ON o.id = oi.id
LEFT JOIN organisation_paid op ON o.id = op.id
ORDER BY o.id ASC
;

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

        ';

        RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0012()
RETURNS INT4 AS
$$
DECLARE
	lastupgrade	INT4;
BEGIN
	SELECT MAX(id) INTO lastupgrade FROM upgrade;
	IF lastupgrade >= 16 THEN
		RAISE INFO '0012 - (skipping)';
		RETURN 0;
	END IF;

        RAISE INFO '0012 - replace VIEW salesorderitem_current and dependencies';

        EXECUTE '
DROP VIEW IF EXISTS salesorderitem_current CASCADE;
CREATE VIEW salesorderitem_current AS
SELECT  
        salesorderitem AS id,
        id AS detailid,
        salesorder,
        product,
        linetext,
        discount,
        price,
        qty,
        updated,
        authuser,
        clientip
FROM salesorderitemdetail
WHERE id IN (
        SELECT MAX(id)
        FROM salesorderitemdetail
        GROUP BY salesorderitem
)
AND is_deleted = false;

CREATE OR REPLACE VIEW salesorder_tax AS
SELECT  so.id AS salesorder,
        roundhalfeven(SUM(COALESCE(soi.price, p.price_sell, ''0.00'') * soi.qty * tr.rate/100),2) AS tax
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
        roundhalfeven(SUM(COALESCE(soi.price, p.price_sell) * soi.qty),2) AS price,
        roundhalfeven(COALESCE(tx.tax, ''0.00''),2) as tax,
        roundhalfeven(SUM(COALESCE(soi.price, p.price_sell) * soi.qty) +
                        COALESCE(tx.tax, ''0.00''),2) AS total
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
        sod.is_deleted
;

        ';

        RETURN 0;
END;
$$ LANGUAGE 'plpgsql';


-- Bug? http://www.postgresql.org/message-id/509BEBD1.2090100@booksys.com

CREATE OR REPLACE FUNCTION upgrade_0013()
RETURNS INT4 AS
$$
BEGIN

        RAISE INFO '0013 - CREATE TRIGGER salesorderitemdetailupdate';

	DROP TRIGGER IF EXISTS salesorderitemdetailupdate 
	ON salesorderitemdetail;
	CREATE TRIGGER salesorderitemdetailupdate AFTER INSERT 
	ON salesorderitemdetail
	FOR EACH ROW EXECUTE PROCEDURE salesorderitemdetailupdate();

        RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0014()
RETURNS INT4 AS
$$
DECLARE
	lastupgrade	INT4;
BEGIN
	SELECT MAX(id) INTO lastupgrade FROM upgrade;
	IF lastupgrade >= 23 THEN
		RAISE INFO '0014 - (skipping)';
		RETURN 0;
	END IF;

        RAISE INFO '0014 - replace VIEW salesorderview';

        EXECUTE '
DROP VIEW IF EXISTS salesorderview;
CREATE OR REPLACE VIEW salesorderview AS
SELECT
        so.id,
        o.name || ''('' || o.orgcode || '')'' AS customer,
        o.orgcode || ''/'' || lpad(CAST(so.ordernum AS TEXT), 5, ''0'') AS order,
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
AND sod.is_open = ''true''
AND sod.is_deleted = ''false''
;
        ';

        RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0015()
RETURNS INT4 AS
$$
DECLARE
        lastupgrade     INT4;
BEGIN
        SELECT MAX(id) INTO lastupgrade FROM upgrade;
        IF lastupgrade >= 19 THEN
                RAISE INFO '0015 - (skipping)';
                RETURN 0;
        END IF;

        RAISE INFO '0015 - replace VIEW accountsreceivable';

        EXECUTE '
DROP VIEW IF EXISTS accountsreceivable;
CREATE VIEW accountsreceivable AS
SELECT
        o.id,
        o.name,
        o.orgcode,
        format_accounting(
                COALESCE(oi.invoiced, 0) - COALESCE(op.paid,0)
        ) AS total
FROM organisation_current o
LEFT JOIN organisation_invoiced oi ON o.id = oi.id
LEFT JOIN organisation_paid op ON o.id = op.id
ORDER BY o.id ASC
;
        ';

        RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION upgrade_0016()
RETURNS INT4 AS
$$
DECLARE
        lastupgrade     INT4;
BEGIN
        SELECT MAX(id) INTO lastupgrade FROM upgrade;
        IF lastupgrade >= 20 THEN
                RAISE INFO '0016 - (skipping)';
                RETURN 0;
        END IF;

        RAISE INFO '0016 - replace VIEW salespaymentlist';

        EXECUTE '
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
        ';

        RETURN 0;
END;
$$ LANGUAGE 'plpgsql';

--
CREATE OR REPLACE FUNCTION upgrade_0017()
RETURNS INT4 AS
$$
DECLARE
        lastupgrade     INT4;
BEGIN
        SELECT MAX(id) INTO lastupgrade FROM upgrade;
        IF lastupgrade >= 24 THEN
                RAISE INFO '0017 - (skipping)';
                RETURN 0;
        END IF;

        RAISE INFO '0017 - CREATE VIEW purchaseorderview';

        EXECUTE '
CREATE OR REPLACE VIEW purchaseorderview AS
SELECT
        po.id,
        o.name || ''('' || o.orgcode || '')'' AS supplier,
        o.orgcode || ''/'' || lpad(CAST(po.ordernum AS TEXT), 5, ''0'') AS order,
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
AND pod.is_open = ''true''
AND pod.is_deleted = ''false''
;
        ';

        RETURN 0;
END;
$$ LANGUAGE 'plpgsql';


--

CREATE OR REPLACE FUNCTION accountinsert()
RETURNS TRIGGER AS
$$
BEGIN
        UPDATE accounttype SET last_id = NEW.id
        WHERE id=NEW.accounttype;
        RETURN NULL; /* after, so result ignored */
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION postpayment(type TEXT, paymentid INT4)
RETURNS INT4 AS
$$
DECLARE
        idtable         TEXT;
        detailtable     TEXT;
        journalid       INT4;
        ledgerid        INT4;
        accountid       INT4;
        transactdate    DATE;
        description     TEXT;
        bankaccount     INT4;
        bankid          INT4;
        amount          NUMERIC;
        dc1             TEXT;
        dc2             TEXT;
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

        SELECT journal_id_last() INTO ledgerid;

        -- update bank entry, if applicable --
        IF bankid is not null THEN
                EXECUTE 'INSERT INTO bankdetail (bank, ledger) VALUES ' ||
                format('(''%s'',''%s'');', bankid, ledgerid);
        END IF;

        -- return id of new journal entry --
        RETURN journalid;
END;
$$ LANGUAGE 'plpgsql';


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
                -- This isnt our first time, so use previous values 
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

CREATE OR REPLACE FUNCTION productdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        oaccount        INT4;
        oshortname      TEXT;
        odescription    TEXT;
        oprice_buy      NUMERIC;
        oprice_sell     NUMERIC;
        omargin         NUMERIC;
        omarkup         NUMERIC;
        ois_available   boolean;
        ois_offered     boolean;
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

CREATE OR REPLACE FUNCTION organisation_orgcode(organisation_name TEXT)
RETURNS TEXT AS
$$
DECLARE
        neworgcode      TEXT;
        conflicts       INT4;
        idlen           INT4;
        x               INT4;
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

CREATE OR REPLACE FUNCTION taxpoint(years INT4, months INT4, days INT4, start_date DATE, period INT4)
RETURNS DATE as $$
DECLARE
        taxpoint        DATE;
        y_interval      TEXT;
        m_interval      TEXT;
        d_interval      TEXT;
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

CREATE OR REPLACE FUNCTION salesorderitemdetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        osalesorder     INT4;
        oproduct        INT4;
        olinetext       TEXT;
        odiscount       NUMERIC;
        oprice          NUMERIC;
        oqty            NUMERIC;
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

-------------------------------------------------------------------------------
-- Start a transaction so upgrades are atomic
BEGIN WORK;

LOCK TABLE upgrade IN EXCLUSIVE MODE;
SELECT upgrade_database() AS version;

-- Commit our changes and release locks
COMMIT WORK;
