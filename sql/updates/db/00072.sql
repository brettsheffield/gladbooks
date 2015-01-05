CREATE OR REPLACE FUNCTION prepare_vat_return(start_date DATE, end_date DATE)
RETURNS INT4 AS
$$
DECLARE
        q1      TEXT;
        q2      TEXT;
        q3      TEXT;
        q4      TEXT;
        q5      TEXT;
        q6      TEXT;
        q7      TEXT;
        q8      TEXT;
        q9      TEXT;
        a1      NUMERIC;
        a2      NUMERIC;
        a3      NUMERIC;
        a4      NUMERIC;
        a5      NUMERIC;
        a6      NUMERIC;
        a7      NUMERIC;
        a8      NUMERIC;
        a9      NUMERIC;
        cash    BOOLEAN;
BEGIN
        DROP TABLE IF EXISTS vatreport;
        CREATE TEMP TABLE vatreport(
                box INTEGER NOT NULL UNIQUE,
                q TEXT,
                a NUMERIC
        );
        
        -- Find out if we we are reporting VAT on a cash basis
        SELECT vatcashbasis INTO cash FROM business WHERE id=current_business();

        q1 := 'VAT due in this period on sales and other outputs';
        q2 := 'VAT due in this period on acquisitions from other EC Member States';
        q3 := 'Total VAT due (the sum of boxes 1 and 2)';
        q4 := 'VAT reclaimed in this period on purchases and other inputs (including acquisitions from the EC)';
        q5 := 'Net VAT to be paid to Customs or reclaimed by you (Difference between boxes 3 and 4)';
        q6 := 'Total value of sales and all other outputs excluding any VAT. Include your box 8 figure.';
        q7 := 'Total value of purchases and all other inputs excluding any VAT.  Include your box 9 figure.';
        q8 := 'Total value of all supplies of goods and related costs, excluding and VAT, to other EC Member States';
        q9 := 'Total value of acquisitions of goods and related costs excluding any VAT, from other EC Member States';
      
        SELECT COALESCE(SUM(l.credit),'0.00') - COALESCE(SUM(l.debit),'0.00') INTO a1 
        FROM journal j
        INNER JOIN ledger l ON j.id = l.journal
        WHERE j.transactdate BETWEEN start_date AND end_date
        AND l.account = '2200';
        
        a2 := '0.00'; -- TODO

        a3 := a1 + a2;

        SELECT COALESCE(SUM(l.debit),'0.00') - COALESCE(SUM(l.credit),'0.00') INTO a4 
        FROM journal j
        INNER JOIN ledger l ON j.id = l.journal
        WHERE j.transactdate BETWEEN start_date AND end_date
        AND l.account = '2201';
        
        a5 := a3 - a4;

        SELECT COALESCE(SUM(subtotal),'0.00') INTO a6
        FROM salesinvoice_current
        WHERE taxpoint BETWEEN start_date AND end_date;

        SELECT COALESCE(SUM(subtotal),'0.00') INTO a7
        FROM purchaseinvoice_current
        WHERE taxpoint BETWEEN start_date AND end_date;

        a8 := '0.00'; -- TODO
        a9 := '0.00'; -- TODO

        INSERT INTO vatreport (box,q,a) VALUES ('1', q1, a1);
        INSERT INTO vatreport (box,q,a) VALUES ('2', q2, a2);
        INSERT INTO vatreport (box,q,a) VALUES ('3', q3, a3);
        INSERT INTO vatreport (box,q,a) VALUES ('4', q4, a4);
        INSERT INTO vatreport (box,q,a) VALUES ('5', q5, a5);
        INSERT INTO vatreport (box,q,a) VALUES ('6', q6, a6);
        INSERT INTO vatreport (box,q,a) VALUES ('7', q7, a7);
        INSERT INTO vatreport (box,q,a) VALUES ('8', q8, a8);
        INSERT INTO vatreport (box,q,a) VALUES ('9', q9, a9);

        RETURN '0';
END;
$$ LANGUAGE 'plpgsql';
