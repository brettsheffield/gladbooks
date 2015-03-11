-- returns number of invoices already raised against this sales order
CREATE OR REPLACE FUNCTION salesorderinvoices(soid INT4)
RETURNS INT4 as $$
DECLARE
        so_raised               INT4;
        
BEGIN
        SELECT COUNT(*) INTO so_raised
        FROM salesinvoicedetail
        WHERE id IN (
                SELECT MAX(id)
                FROM salesinvoicedetail
                GROUP BY salesinvoice
        )
        AND salesorder = soid;

        RETURN so_raised;
END;
$$ LANGUAGE 'plpgsql';
