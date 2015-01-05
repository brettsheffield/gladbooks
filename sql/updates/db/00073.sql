CREATE OR REPLACE FUNCTION post_purchaseinvoice(pi_id INT8)
RETURNS INT4 AS $$
DECLARE
        r_pi            RECORD;
        code            NUMERIC;
        d               NUMERIC;
        c               NUMERIC;
        cashbasis       BOOLEAN;
BEGIN

        SELECT pi.id, o.orgcode, pi.invoicenum, pi.ref, pi.taxpoint, pi.subtotal, pi.tax, pi.total
        INTO r_pi
        FROM purchaseinvoice_current pi
        INNER JOIN organisation_current o ON o.id = pi.organisation
        WHERE pi.id = pi_id;

        SELECT vatcashbasis INTO cashbasis FROM business WHERE id=current_business();

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

        IF (cashbasis) THEN
                code = '2206'; -- cash basis, post to holding account
        ELSE
                code = '2201';
        END IF;
        RAISE INFO 'Account: % Debit: % Credit %', code, d, c;
        INSERT INTO ledger (account, debit, credit) VALUES (code, d, c);

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

CREATE OR REPLACE FUNCTION post_salesinvoice(si_id INT8)
RETURNS INT4 AS $$
DECLARE
        r_si            RECORD;
        r_tax           RECORD;
        r_item          RECORD;
        code            NUMERIC;
        d               NUMERIC;
        c               NUMERIC;
        cashbasis       BOOLEAN;
BEGIN
        -- fetch salesinvoice details
        SELECT si.salesinvoice, si.taxpoint, si.subtotal, si.total, si.ref
        INTO r_si
        FROM salesinvoice_current si
        WHERE si.salesinvoice=si_id;

        SELECT vatcashbasis INTO cashbasis FROM business WHERE id=current_business();

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

        -- TODO: divisions and departments

        -- 1100 = Debtors Control Account
        RAISE INFO 'Account: % Debit: % Credit %', '1100', d, c;
        INSERT INTO ledger (account, debit, credit) VALUES ('1100', d, c);

        -- post tax details to ledger
        FOR r_tax IN
        SELECT sit.salesinvoice, sit.account, sit.total
        FROM salesinvoice_tax sit WHERE sit.salesinvoice=si_id
        LOOP
                IF (r_tax.total < 0) THEN
                        d = r_tax.total;
                        c = NULL;
                ELSE
                        d = NULL;
                        c = r_tax.total;
                END IF;
                -- If VAT, select account to post to
                IF (r_tax.account = '2202') THEN
                        IF (cashbasis) THEN
                                code = '2205'; -- cash basis, post to holding account
                        ELSE
                                code = '2200';
                        END IF;
                ELSE
                        code = r_tax.account;
                END IF;
                RAISE INFO 'Account: % Debit: % Credit %', code, d, c;
                INSERT INTO ledger (account, debit, credit)
                VALUES (code, d, c);
        END LOOP;


        -- post product details to ledger
        FOR r_item IN
        SELECT sii.salesinvoice, p.account, sii.linetotal
        FROM salesinvoiceitem_display sii
        RIGHT JOIN product_current p ON p.product = sii.product
        WHERE sii.salesinvoice=si_id
        LOOP
                IF (r_item.linetotal < 0) THEN
                        d = r_item.linetotal;
                        c = NULL;
                ELSE
                        d = NULL;
                        c = r_item.linetotal;
                END IF;
                RAISE INFO 'Account: % Debit: % Credit %',r_item.account,d,c;
                INSERT INTO ledger (account, debit, credit)
                VALUES (r_item.account, d, c);
        END LOOP;

        RETURN '0';
END;
$$ LANGUAGE 'plpgsql';

-- post_salesinvoice() - post salesinvoice to journal
-- RETURN INT4, 0=success
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
BEGIN
        -- fetch salesinvoice details
        SELECT si.salesinvoice,
               COALESCE(si.taxpoint,si.issued) AS taxpoint,
               si.subtotal, si.tax, si.total, si.ref
        INTO r_si
        FROM salesinvoice_current si
        WHERE si.salesinvoice=si_id;

        SELECT vatcashbasis INTO cashbasis FROM business WHERE id=current_business();

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
