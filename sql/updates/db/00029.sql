-- update 00029
-- 2014-01-24 - Brett Sheffield
-- Applies to gladbooks schema
-- replaces FUNCTION mail_salesinvoice()

SET search_path TO gladbooks;

BEGIN;

-- email PDF of salesinvoice to billing contacts
-- create email table entries, then trigger clerkd
-- TODO: check settings table to determine if autobilling on
CREATE OR REPLACE FUNCTION mail_salesinvoice(si_id INT4)
RETURNS INT4 AS $$
DECLARE
	billingname	TEXT;
	billingemail	TEXT;
	bodytext	TEXT;
	filename	TEXT;
	r		RECORD;
	r_to		RECORD;
BEGIN
	SELECT * INTO r FROM salesinvoice_current WHERE salesinvoice=si_id;

	-- select sender from business table
	SELECT billsendername, billsendermail INTO billingname, billingemail
	FROM business WHERE id = current_business();

	-- TODO: include content of invoice in body
	bodytext := 'Your invoice is attached';

	INSERT INTO email DEFAULT VALUES;
	INSERT INTO emaildetail (sendername, sendermail, body) 
	VALUES (billingname, billingemail, bodytext);
	INSERT INTO emailheader (header, value)
	VALUES ('Subject', 'Sales Invoice ' || r.ref);
	INSERT INTO emailheader (header, value)
	VALUES ('From', billingemail);
	INSERT INTO emailheader (header, value)
	VALUES ('X-Gladbooks-SalesInvoice', r.ref);

	-- attach file
	filename := '/var/spool/gladbooks/' || current_business_code() ||
		'/SI-'|| r.orgcode || '-' || to_char(r.invoicenum, 'FM0000') ||
		'.pdf';
	INSERT INTO emailpart (file) VALUES (filename);

	-- add billing contacts
	FOR r_to IN
		SELECT id, name, email FROM contact_current
		WHERE id IN (
			SELECT contact
			FROM organisation_contact
			WHERE relationship='1'
			AND organisation=r.organisation
		)
	LOOP
		INSERT INTO emailrecipient (
			contact, emailname, emailaddress, is_to
		) VALUES (r_to.contact, r_to.name, r_to.email, 'true');
	END LOOP;

	RETURN '0';
END;
$$ LANGUAGE 'plpgsql';

INSERT INTO upgrade (id) VALUES (29);

COMMIT;
