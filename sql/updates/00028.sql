-- update 00028
-- 2014-01-24 - Brett Sheffield
-- Applies to gladbooks schema
-- replaces FUNCTION create_salesinvoice_tex()

SET search_path TO gladbooks;

BEGIN;

-- create_salesinvoice_tex()
-- create xelatex source from salesinvoice
-- RETURNS TEXT tex source
CREATE OR REPLACE FUNCTION create_salesinvoice_tex(si_id INT4)
RETURNS INT4 AS $$
DECLARE
	r		RECORD;
	item		RECORD;
	lineitems	TEXT;
	taxes		TEXT;
	customer	TEXT;
	tex		INT4;
	fieldcount	INT4;
	businesscode	TEXT;
BEGIN

	/* salesinvoice data */
	SELECT * FROM salesinvoice_current WHERE salesinvoice=si_id INTO r;

	IF NOT FOUND THEN
		RAISE EXCEPTION 'Invoice id % does not exist', si_id;
	END IF;

	/* fetch lineitems */
	lineitems := '';
	FOR item IN
	SELECT * FROM salesinvoiceitem_display WHERE salesinvoice=si_id
	LOOP
		lineitems := lineitems || item.qty || ' x ' || 
		texquote(replacemacros(item.linetext, r.taxpoint, r.endpoint))
		|| ' @ ' || to_char(item.price, '999G999G999G999G990D90') || ' & ' || 
		to_char(item.linetotal, '999G999G999G999G990D90' ) || '\\' || E'\n';
	END LOOP;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No lineitems for invoice %', si_id; 
	END IF;

	/* fetch taxes */
	taxes := '';
	FOR item IN
	SELECT * FROM salesinvoice_tax WHERE salesinvoice=si_id
	LOOP
		taxes := taxes || item.taxname || ' (' || item.rate || '\%)' 
		|| ' on ' || to_char(item.nett, '999G999G999G999G990D90') || ' & ' || 
		to_char(item.total, '999G999G999G999G990D90') || '\\' || E'\n';
	END LOOP;

	/* fetch customer billing contact */
	SELECT * FROM contact_billing WHERE organisation=r.organisation
	INTO item;
	IF NOT FOUND THEN
		RAISE INFO 'No billcontact set for organisation %', 
			r.orgcode;
		SELECT name FROM organisation_current 
		WHERE id = r.organisation
		INTO item;
		customer := E'\t' || '{' || item.name || '}' || E'\n' ||
			E'\t' || '{}' || E'\n' ||
			E'\t' || '{}' || E'\n' ||
			E'\t' || '{}' || E'\n' ||
			E'\t' || '{}' || E'\n' ||
			E'\t' || '{}' || E'\n' ||
			E'\t' || '{}' || E'\n' ||
			E'\t' || '{}' || E'\n';
	ELSE
		/* fill in full customer details */
		customer := E'\t' || '{' || item.name || '}' || E'\n';
		customer := E'\t' || '{' || item.orgname || '}' || E'\n';
		fieldcount := 2;
		IF item.line_1 IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.line_1 || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		IF item.line_2 IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.line_2 || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		IF item.line_3 IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.line_3 || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		IF item.town IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.town || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		IF item.county IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.county || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		IF item.country IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.country || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		IF item.postcode IS NOT NULL THEN
			customer := customer || E'\t' || '{' ||
				item.postcode || '}' || E'\n';
			fieldcount := fieldcount + 1;
		END IF;
		WHILE fieldcount < 9 LOOP
			customer := customer || E'\t' || '{}' || E'\n';
			fieldcount := fieldcount + 1;
		END LOOP;
	END IF;

	/* write the .tex file to disk */
	PERFORM write_salesinvoice_tex(
		'/var/spool/gladbooks/' || current_business_code(),
		'/etc/gladbooks/conf.d/' || current_business_code(),
		'/etc/gladbooks/conf.d/' || current_business_code()
		|| '/SI-template.tex',
		r.orgcode,
		r.invoicenum,
		to_char(r.taxpoint, 'DD Month YYYY'),
		to_char(r.issued, 'DD Month YYYY'),
		to_char(r.due, 'DD Month YYYY'),
		COALESCE(r.ponumber, ''),
		to_char(r.subtotal, '999G999G999G999G990D90'),
		to_char(r.tax, '999G999G999G999G990D90'),
		to_char(r.total, '999G999G999G999G990D90'),
		lineitems,
		taxes,
		customer
	);
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Failed to write .tex';
	END IF;

	RETURN '0';
END;
$$ LANGUAGE 'plpgsql';

INSERT INTO upgrade (id) VALUES (28);

COMMIT;
