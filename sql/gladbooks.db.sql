-- Set up main gladbooks database, schema and tables

CREATE DATABASE gladbooks;

CREATE SCHEMA gladbooks;

SET search_path TO gladbooks;

CREATE TABLE accounttype (
	id		SERIAL PRIMARY KEY,
	name		TEXT UNIQUE NOT NULL,
	range_min	INT4 NOT NULL,
	range_max	INT4 NOT NULL,
	next_id		INT4 NOT NULL DEFAULT 0,
	entered		timestamp with time zone default now()
);
-- we don't delete account types
CREATE RULE nodel_accounttype AS ON DELETE TO accounttype DO NOTHING;

CREATE TABLE account (
	id		INT4 PRIMARY KEY,
	accounttype	INT4 references accounttype(id) ON DELETE RESTRICT,
	description	TEXT,
	entered		timestamp with time zone default now(),
	authuser	TEXT,
	clientip	TEXT
);

CREATE TABLE instance (
	id		SERIAL PRIMARY KEY,
	name		TEXT UNIQUE NOT NULL,
	schema		VARCHAR(63) UNIQUE NOT NULL,
	entered		timestamp with time zone default now()
);
