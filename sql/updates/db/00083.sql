-- process_salesorder() - create missing salesinvoices for a given salesorder
-- RETURN INT4 number of salesinvoices generated
CREATE OR REPLACE FUNCTION process_salesorder(soid INT4)
RETURNS INT4 as $$
DECLARE
        so                      RECORD;
        so_due                  INT4;
        so_raised               INT4;
        periods_unissued        INT4;
        period                  INT4;
        end_date                DATE;
BEGIN
        RAISE NOTICE 'Processing salesorder';

        -- fetch the salesorder and cycle info --
        SELECT sod.*, c.years, c.months, c.days INTO so
        FROM salesorderdetail sod
        INNER JOIN cycle c ON sod.cycle = c.id
        WHERE sod.id IN (
           SELECT MAX(id)
           FROM salesorderdetail
           WHERE salesorder=soid
        );

        -- figure out how many salesinvoices there should be --
        IF so.cycle = '1' THEN
                -- do not issue 'once' invoices before start_date
                IF so.start_date > DATE(NOW()) THEN
                        so_due := '0';
                ELSE
                        so_due := '1';
                END IF;
        ELSE
                -- ensure we don't issue future dated invoices
                end_date := COALESCE(so.end_date, DATE(NOW()));
                IF end_date > DATE(NOW()) THEN
                        end_date := DATE(NOW());
                END IF;
                so_due := periods_between(so.years,so.months,so.days,so.start_date,end_date);
        END IF;

        -- fetch invoices already raised against this salesorder --
        SELECT salesorderinvoices(soid) INTO so_raised;

        RAISE NOTICE '% / % invoices raised', so_raised, so_due;

        periods_unissued := so_due - so_raised;

        IF periods_unissued > 0 THEN
                -- first, work out which periods are missing --
                FOR period IN
                        SELECT generate_series(1, so_due) AS period
                        EXCEPT
                        SELECT soid.period
                        FROM salesinvoicedetail soid
                        WHERE id IN (
                                SELECT MAX(id)
                                FROM salesinvoicedetail
                                GROUP BY salesinvoice
                        )
                        AND salesorder = so.salesorder
                        ORDER BY period
                LOOP
                        RAISE NOTICE 'Issue period: %', period;
                        PERFORM create_salesinvoice(soid, period);
                END LOOP;
        ELSIF periods_unissued < 0 THEN
                RAISE NOTICE 'too many salesinvoices exist for salesorder %', soid;
        END IF;
        -- close salesorder if all invoices raised
        IF so.end_date IS NOT NULL OR so.cycle = 1 THEN
                IF so.end_date < DATE(NOW()) OR so.cycle = 1 THEN
                        SELECT salesorderinvoices(soid) INTO so_raised;
                        IF so_raised = so_due THEN
                                PERFORM close_salesorder(soid);
                        END IF;
                END IF;
        END IF;

        RETURN periods_unissued;
END;
$$ LANGUAGE 'plpgsql';
