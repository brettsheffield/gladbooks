CREATE TABLE accounttype (
	id		char(1) PRIMARY KEY,
	name		TEXT,
	entered		timestamp with time zone default now()
);

CREATE TABLE account (
	id		INT4 PRIMARY KEY,
	type		char(1) references accounttype(id) ON DELETE RESTRICT,
	description	TEXT,
	entered		timestamp with time zone default now()
);
-- separate sequences for each account type --
CREATE SEQUENCE account_id_a_seq MINVALUE 1000 MAXVALUE 1999 OWNED BY account.id;
CREATE SEQUENCE account_id_l_seq MINVALUE 2000 MAXVALUE 2999 OWNED BY account.id;
CREATE SEQUENCE account_id_c_seq MINVALUE 3000 MAXVALUE 3999 OWNED BY account.id;
CREATE SEQUENCE account_id_r_seq MINVALUE 4000 MAXVALUE 4999 OWNED BY account.id;
CREATE SEQUENCE account_id_e_seq MINVALUE 5000 MAXVALUE 5999 OWNED BY account.id;

CREATE TABLE department (
	id              SERIAL PRIMARY KEY,
	name		TEXT,
	entered		timestamp with time zone default now()
);

CREATE TABLE division (
	id              SERIAL PRIMARY KEY,
	name		TEXT,
	entered		timestamp with time zone default now()
);

CREATE TABLE journal (
	id		SERIAL PRIMARY KEY,
	transactdate	date,
	description	TEXT,
	entered		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE ledger (
	id		SERIAL PRIMARY KEY,
	journal		INT4 references journal(id) ON DELETE RESTRICT,
	account		INT4 references account(id) ON DELETE RESTRICT,
	division	INT4 references division(id) ON DELETE RESTRICT
			DEFAULT 0,
	department	INT4 references department(id) ON DELETE RESTRICT
			DEFAULT 0,
	debit		NUMERIC,
	credit		NUMERIC,
	entered		timestamp with time zone default now()
);

CREATE OR REPLACE FUNCTION check_ledger_balance()
RETURNS trigger AS $check_ledger_balance$
	DECLARE
		balance NUMERIC;

	BEGIN
		SELECT SUM(debit) - SUM(credit) INTO balance FROM ledger;
		IF balance <> 0 THEN
			RAISE EXCEPTION 'ledger does not balance';
		END IF;
		RETURN NEW;
	END;
$check_ledger_balance$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_transaction_balance()
RETURNS trigger AS $check_transaction_balance$
	DECLARE
		balance NUMERIC;

	BEGIN
		SELECT SUM(debit) - SUM(credit) INTO balance
		FROM ledger
		WHERE journal=currval(pg_get_serial_sequence('journal','id'));
		IF balance <> 0 THEN
			RAISE EXCEPTION 'transaction does not balance';
		END IF;
		RETURN NEW;
	END;
$check_transaction_balance$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_account_id()
RETURNS trigger AS $get_account_id$
	BEGIN
		IF NEW.type = 'a' THEN
			SELECT nextval('account_id_a_seq') INTO NEW.id;
		ELSIF NEW.type = 'l' THEN
			SELECT nextval('account_id_l_seq') INTO NEW.id;
		ELSIF NEW.type = 'c' THEN
			SELECT nextval('account_id_c_seq') INTO NEW.id;
		ELSIF NEW.type = 'r' THEN
			SELECT nextval('account_id_r_seq') INTO NEW.id;
		ELSIF NEW.type = 'e' THEN
			SELECT nextval('account_id_e_seq') INTO NEW.id;
		ELSE
			RAISE EXCEPTION 'Invalid Account Type "%s"', NEW.type;
		END IF;
		RETURN NEW;
	END;
$get_account_id$ LANGUAGE plpgsql;

CREATE TRIGGER trig_set_account_id
	BEFORE INSERT
	ON account
	FOR EACH ROW
	EXECUTE PROCEDURE set_account_id()
;

CREATE CONSTRAINT TRIGGER trig_check_ledger_balance
	AFTER INSERT
	ON ledger
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE check_ledger_balance()
;

CREATE CONSTRAINT TRIGGER trig_check_transaction_balance
	AFTER INSERT
	ON ledger
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE check_transaction_balance()
;

-- Default data for accounttype --
INSERT INTO accounttype (id, name) VALUES ('a', 'assets');
INSERT INTO accounttype (id, name) VALUES ('l', 'liabilities');
INSERT INTO accounttype (id, name) VALUES ('c', 'capital');
INSERT INTO accounttype (id, name) VALUES ('r', 'revenue');
INSERT INTO accounttype (id, name) VALUES ('e', 'expenditure');

INSERT INTO department (id, name) VALUES (0, 'default');
INSERT INTO division (id, name) VALUES (0, 'default');
