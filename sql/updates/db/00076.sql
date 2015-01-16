CREATE OR REPLACE FUNCTION businessorganisation()
RETURNS TRIGGER AS
$$
DECLARE
        neworgcode              TEXT;
BEGIN
        IF NEW.organisation IS NULL THEN
                -- organisation needs a default contact
                INSERT INTO contact DEFAULT VALUES;
                INSERT INTO contactdetail(name) VALUES (NEW.name);

                INSERT INTO organisation DEFAULT VALUES;
                INSERT INTO organisationdetail(name,billcontact) VALUES (
                        NEW.name,currval(pg_get_serial_sequence('contact','id'))
                );
                NEW.organisation =
                        currval(pg_get_serial_sequence('organisation','id'));
                SELECT orgcode INTO neworgcode FROM organisation
                WHERE id =
                        currval(pg_get_serial_sequence('organisation','id'));
                PERFORM create_business_dirs(neworgcode);
        END IF;

        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';
