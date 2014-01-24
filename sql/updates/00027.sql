-- update 00027
-- 2014-01-24 - Brett Sheffield
-- Applies to gladbooks schema
-- replaces FUNCTION create_salesinvoice()

SET search_path TO gladbooks;

BEGIN;
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
		RAISE EXCEPTION 'Failed to create .tex';
	END IF;

	PERFORM post_salesinvoice(si_id);  -- post to ledger
	PERFORM mail_salesinvoice(si_id);  -- email pdf

	RETURN true;
END;
$$ LANGUAGE 'plpgsql';

INSERT INTO upgrade (id) VALUES (27);

COMMIT;
