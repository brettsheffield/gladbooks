CREATE OR REPLACE FUNCTION purchaseinvoicedetailupdate()
RETURNS TRIGGER AS
$$
DECLARE
        priorentries    INT4;
        r_old           RECORD;
BEGIN
        SELECT INTO priorentries COUNT(id) FROM purchaseinvoicedetail
                WHERE purchaseinvoice = NEW.purchaseinvoice;
        IF priorentries > 0 THEN
                -- This isn't our first time, so use previous values 
                SELECT * INTO r_old
                FROM purchaseinvoicedetail WHERE id IN (
                        SELECT MAX(id)
                        FROM purchaseinvoicedetail
                        GROUP BY purchaseinvoice
                )
                AND purchaseinvoice = NEW.purchaseinvoice;

                IF NEW.purchaseorder IS NULL THEN
                        NEW.purchaseorder := r_old.purchaseorder;
                END IF;
                IF NEW.period IS NULL THEN
                        NEW.period := r_old.period;
                END IF;
                IF NEW.ref IS NULL THEN
                        NEW.ref := r_old.ref;
                END IF;
                IF NEW.ponumber IS NULL THEN
                        NEW.ponumber := r_old.ponumber;
                END IF;
                IF NEW.description IS NULL THEN
                        NEW.description := r_old.description;
                END IF;
                IF NEW.taxpoint IS NULL THEN
                        NEW.taxpoint := r_old.taxpoint;
                END IF;
                IF NEW.endpoint IS NULL THEN
                        NEW.endpoint := r_old.endpoint;
                END IF;
                IF NEW.issued IS NULL THEN
                        NEW.issued := r_old.issued;
                END IF;
                IF NEW.journal IS NULL THEN
                        NEW.journal := r_old.journal;
                END IF;
                IF NEW.due IS NULL THEN
                        NEW.due := r_old.due;
                END IF;
                IF NEW.subtotal IS NULL THEN
                        NEW.subtotal := r_old.subtotal;
                END IF;
                IF NEW.tax IS NULL THEN
                        NEW.tax := r_old.tax;
                END IF;
                IF NEW.total IS NULL THEN
                        NEW.total := r_old.total;
                END IF;
                IF NEW.pdf IS NULL THEN
                        NEW.pdf := r_old.pdf;
                END IF;
        END IF;
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';
