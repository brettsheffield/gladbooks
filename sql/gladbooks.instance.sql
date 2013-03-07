-- Create tables for new instance

-- a business represents a distinct set of accounting ledgers
CREATE TABLE business (
	id              SERIAL PRIMARY KEY,
	name		TEXT UNIQUE NOT NULL,
	schema          VARCHAR(63) UNIQUE NOT NULL,
	entered         timestamp with time zone default now()
);
CREATE RULE nodel_business AS ON DELETE TO business DO NOTHING;

CREATE TABLE username (
	id              SERIAL PRIMARY KEY,
	username        TEXT UNIQUE NOT NULL,
	entered         timestamp with time zone default now()
);
CREATE RULE nodel_username AS ON DELETE TO username DO NOTHING;

CREATE TABLE groupname (
	id              SERIAL PRIMARY KEY,
	groupname	TEXT UNIQUE NOT NULL,
	entered         timestamp with time zone default now()
);
CREATE RULE nodel_groupname AS ON DELETE TO groupname DO NOTHING;

CREATE TABLE membership (
	username	INT4 references username(id) ON DELETE RESTRICT,
	groupname	INT4 references groupname(id) ON DELETE RESTRICT,
	entered         timestamp with time zone default now(),
	CONSTRAINT membership_pk PRIMARY KEY (username, groupname)
);

-- each instance can create and modify its own default charts which 
-- are used when creating businesses for this instance
CREATE TABLE chart (
	id              SERIAL PRIMARY KEY,
	name		TEXT UNIQUE NOT NULL,
	entered         timestamp with time zone default now()
);

CREATE TABLE nominalcode (
	chart		INT4 references chart(id) ON DELETE CASCADE,
	account		INT4 NOT NULL,
	name		TEXT NOT NULL DEFAULT '',
	description	TEXT NOT NULL DEFAULT '',
	entered         timestamp with time zone default now(),
	CONSTRAINT nominalcode_pk PRIMARY KEY (chart, account)
);
