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
	vnum		INT4 = 1; -- New version (increment this)
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

-------------------------------------------------------------------------------
-- Start a transaction so upgrades are atomic
BEGIN WORK;

LOCK TABLE upgrade IN EXCLUSIVE MODE;
SELECT upgrade_database() AS version;

-- Commit our changes and release locks
COMMIT WORK;
