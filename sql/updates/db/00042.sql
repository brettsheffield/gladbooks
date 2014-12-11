CREATE OR REPLACE FUNCTION reversejournal(journalid INT4)
RETURNS INT4 AS $$
DECLARE
	r_journal       RECORD;
	r_ledger        RECORD;
	journaldesc     TEXT;

BEGIN
	SELECT * INTO r_journal FROM journal j WHERE j.id=journalid;

	IF r_journal.reverseid IS NOT NULL THEN
		RAISE NOTICE 'Reversing journal % already exists.', r_journal.reverseid;
		RETURN '1';
	END IF;

	journaldesc := 'Reverse Journal #' || journalid;

	INSERT INTO journal (transactdate, description)
	VALUES (r_journal.transactdate, journaldesc);

	FOR r_ledger IN
		SELECT * FROM ledger WHERE journal=journalid
	LOOP
		INSERT INTO ledger (journal, account, division, department, debit, credit)
		VALUES (journal_id_last(), r_ledger.account, r_ledger.division, r_ledger.department, r_ledger.credit, r_ledger.debit);
	END LOOP;

	UPDATE journal SET reverseid=journal_id_last() WHERE journal.id=journalid;

	RETURN '0';
END;
$$ LANGUAGE 'plpgsql';
