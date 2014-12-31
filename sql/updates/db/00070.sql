CREATE OR REPLACE FUNCTION post_salesinvoice_quick(si_id INT8)
RETURNS INT4 AS $$
DECLARE
        r_si            RECORD;
        r_tax           RECORD;
        r_item          RECORD;
        d               NUMERIC;
        c               NUMERIC;
BEGIN
        -- fetch salesinvoice details
        SELECT si.salesinvoice,
               COALESCE(si.taxpoint,si.issued) AS taxpoint,
               si.subtotal, si.tax, si.total, si.ref
        INTO r_si
        FROM salesinvoice_current si
        WHERE si.salesinvoice=si_id;

        -- only post invoices from current period
        -- TODO: pull this date from business.period_start
        IF r_si.taxpoint < '2013-04-01' THEN
                RETURN 0;
        END IF;

        -- create journal entry
        INSERT INTO journal (transactdate, description)
        VALUES (r_si.taxpoint, 'Sales Invoice ' || r_si.ref);

        IF (r_si.total > 0) THEN
                d = r_si.total;
                c = NULL;
        ELSE
                d = NULL;
                c = r_si.total;
        END IF;

        -- 1100 = Debtors Control Account
        RAISE INFO 'Account: % Debit: % Credit %', '1100', d, c;
        INSERT INTO ledger (account, debit, credit) VALUES ('1100', d, c);

        -- post tax to ledger (quick version, assume Standard Rate VAT)
        IF (r_si.tax < 0) THEN
                d = r_si.tax;
                c = NULL;
        ELSE
                d = NULL;
                c = r_si.tax;
        END IF;
        RAISE INFO 'Account: 2202 Debit: % Credit %', d, c;
        INSERT INTO ledger (account, debit, credit) VALUES ('2202', d, c);

        -- post nett amount to 4000 General Revenue
        IF (r_si.subtotal < 0) THEN
                d = r_si.subtotal;
                c = NULL;
        ELSE
                d = NULL;
                c = r_si.subtotal;
        END IF;
        RAISE INFO 'Account: 4000 Debit: % Credit %', d, c;
        INSERT INTO ledger (account, debit, credit) VALUES ('4000', d, c);

        RETURN '0';
END;
$$ LANGUAGE 'plpgsql';
