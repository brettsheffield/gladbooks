CREATE OR REPLACE FUNCTION post_purchaseinvoice(pi_id INT8)
RETURNS INT4 AS $$
DECLARE
        r_pi    RECORD;
        d               NUMERIC;
        c               NUMERIC;
BEGIN

        SELECT pi.id, o.orgcode, pi.invoicenum, pi.ref, pi.taxpoint, pi.subtotal, pi.tax, pi.total
        INTO r_pi
        FROM purchaseinvoice_current pi
        INNER JOIN organisation_current o ON o.id = pi.organisation
        WHERE pi.id = pi_id;

        -- create journal entry
        INSERT INTO journal (transactdate, description)
        VALUES (r_pi.taxpoint, 'Purchase Invoice (' || r_pi.orgcode  || ') ' || r_pi.ref);

        IF (r_pi.total > 0) THEN
                d = NULL;
                c = r_pi.total;
        ELSE
                d = r_pi.total;
                c = NULL;
        END IF;

        -- 2100 = Creditors Control Account
        RAISE INFO 'Account: % Debit: % Credit %', '2100', d, c;
        INSERT INTO ledger (account, debit, credit) VALUES ('2100', d, c);

        -- post tax to ledger
        IF (r_pi.tax < 0) THEN
                d = NULL;
                c = r_pi.tax;
        ELSE
                d = r_pi.tax;
                c = NULL;
        END IF;
        RAISE INFO 'Account: 2202 Debit: % Credit %', d, c;
        INSERT INTO ledger (account, debit, credit) VALUES ('2202', d, c);

        -- FIXME: where am I posting this?  Need account to be supplied.
        IF (r_pi.subtotal < 0) THEN
                d = NULL;
                c = r_pi.subtotal;
        ELSE
                d = r_pi.subtotal;
                c = NULL;
        END IF;
        RAISE INFO 'Account: 5000 Debit: % Credit %', d, c;
        INSERT INTO ledger (account, debit, credit) VALUES ('5000', d, c);

        INSERT INTO purchaseinvoicedetail(purchaseinvoice, journal)
        VALUES (pi_id, journal_id_last());

        RETURN '0';
END;
$$ LANGUAGE 'plpgsql';
