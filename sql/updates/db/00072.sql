CREATE OR REPLACE FUNCTION prepare_vat_return(start_date DATE, end_date DATE)
RETURNS INT4 AS
$$
DECLARE
        q1     TEXT;
        q2     TEXT;
        q3     TEXT;
        q4     TEXT;
        q5     TEXT;
        q6     TEXT;
        q7     TEXT;
        q8     TEXT;
        q9     TEXT;
        a1     NUMERIC;
        a2     NUMERIC;
        a3     NUMERIC;
        a4     NUMERIC;
        a5     NUMERIC;
        a6     NUMERIC;
        a7     NUMERIC;
        a8     NUMERIC;
        a9     NUMERIC;
BEGIN
        DROP TABLE IF EXISTS vatreport;
        CREATE TEMP TABLE vatreport(
                box INTEGER NOT NULL UNIQUE,
                q TEXT,
                a NUMERIC
        );

        q1 := 'VAT due in this period on sales and other outputs';
        q2 := 'VAT due in this period on acquisitions from other EC Member States';
        q3 := 'Total VAT due (the sum of boxes 1 and 2)';
        q4 := 'VAT reclaimed in this period on purchases and other inputs (including acquisitions from the EC)';
        q5 := 'Net VAT to be paid to Customs or reclaimed by you (Difference between boxes 3 and 4)';
        q6 := 'Total value of sales and all other outputs excluding any VAT. Include your box 8 figure.';
        q7 := 'Total value of purchases and all other inputs excluding any VAT.  Include your box 9 figure.';
        q8 := 'Total value of all supplies of goods and related costs, excluding and VAT, to other EC Member States';
        q9 := 'Total value of acquisitions of goods and related costs excluding any VAT, from other EC Member States';
        
        -- TODO: calculate on cash basis if required
        SELECT SUM(tax) INTO a1
        FROM salesinvoice_current
        WHERE taxpoint BETWEEN start_date AND end_date;

        a2 := '0.00'; -- TODO

        a3 := a1 + a2;

        -- TODO: calculate on cash basis if required
        SELECT SUM(tax) INTO a4
        FROM purchaseinvoice_current
        WHERE taxpoint BETWEEN start_date AND end_date;

        a5 := a3 - a4;

        SELECT SUM(subtotal) INTO a6
        FROM salesinvoice_current
        WHERE taxpoint BETWEEN start_date AND end_date;

        SELECT SUM(subtotal) INTO a7
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
