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
	vnum		INT4 = 0; -- New version (increment this)
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

	-- record upgrade
	EXECUTE 'INSERT INTO business_upgrade(id) VALUES(2);';

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
