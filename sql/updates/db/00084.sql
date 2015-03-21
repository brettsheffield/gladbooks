CREATE OR REPLACE FUNCTION check_payment_allocation()
RETURNS trigger AS $$
DECLARE
        payment         NUMERIC;
        allocated       NUMERIC;
        invoicetotal    NUMERIC;
        type            TEXT;
        paymentid       INT4;
        idtable         TEXT;
        detailtable     TEXT;
BEGIN
        type := quote_ident(TG_ARGV[0]);
        paymentid := NEW.payment;

        -- check arguments --
        IF type <> 'sales' AND type <> 'purchase' THEN
                RAISE EXCEPTION '%I() called with invalid type', TG_NAME;
        END IF;

        -- find amount of payment --
        idtable := type || 'payment';
        detailtable := idtable || 'detail';
        EXECUTE format('SELECT amount FROM %I WHERE id IN ', detailtable) ||
        format('(SELECT MAX(id) FROM %I GROUP BY %I) ',detailtable,idtable) ||
        format('AND %I=''%s'';', idtable, paymentid)
        INTO payment;

        -- how much have we allocated? --
        idtable = type || 'paymentallocation';
        detailtable := idtable || 'detail';
        EXECUTE 'SELECT SUM(amount) ' ||
        format('FROM %I WHERE id IN ', detailtable) ||
        format('(SELECT MAX(id) FROM %I GROUP BY %I) ',detailtable,idtable) ||
        format('AND payment=''%s'';', paymentid)
        INTO allocated;

        IF allocated > payment THEN
                RAISE EXCEPTION 'payment over-allocated';
        END IF;

        -- check we're not allocating more than the amount of the invoice
        detailtable := type || 'invoice_current';
        EXECUTE 'SELECT total ' ||
        format('FROM %I ', detailtable) ||
        format('WHERE id = ''%s''', NEW.salesinvoice)
        INTO invoicetotal;

        IF NEW.amount > invoicetotal THEN
                RAISE EXCEPTION 'Cannot allocate more than total of invoice';
        END IF;

        RETURN NEW;

END;
$$ LANGUAGE plpgsql;
