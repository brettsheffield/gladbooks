CREATE OR REPLACE FUNCTION post_salesinvoice_quick(si_id INT8)
RETURNS INT4 AS $$
DECLARE
        r_si            RECORD;
        r_tax           RECORD;
        r_item          RECORD;
        code            NUMERIC;
        d               NUMERIC;
        c               NUMERIC;
        cashbasis       BOOLEAN;
        period_s        DATE;
        period_e        DATE;
BEGIN
        -- fetch salesinvoice details
        SELECT si.salesinvoice,
               COALESCE(si.taxpoint,si.issued) AS taxpoint,
               si.subtotal, si.tax, si.total, si.ref
        INTO r_si
        FROM salesinvoice_current si
        WHERE si.salesinvoice=si_id;

        SELECT vatcashbasis INTO cashbasis FROM business WHERE id=current_business();

        -- get dates for current tax year
        SELECT period_start, period_end INTO period_s, period_e
        FROM business_year
        WHERE id IN (SELECT MAX(id) FROM business_year GROUP BY business)
        AND business = current_business();

        -- only post invoices from current period
        IF r_si.taxpoint < period_s THEN
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

        IF (cashbasis) THEN
                code = '2205'; -- cash basis, post to holding account
        ELSE
                code = '2200';
        END IF;
        RAISE INFO 'Account: % Debit: % Credit %', code, d, c;
        INSERT INTO ledger (account, debit, credit) VALUES (code, d, c);

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
