# To setup/reset a fresh gladbooks database:
#
.PHONY: dropdb db reset instance business businessdata testdata functions upgrade

all: db functions instance instance business businessdata testdata

db:
	createdb gladbooks
	psql gladbooks < gladbooks.db.sql 

instance:
	psql gladbooks < gladbooks.instance.sql

business:
	psql gladbooks < gladbooks.business.sql

businessdata:
	psql gladbooks < gladbooks.business.data.sql

testdata:
	psql gladbooks < gladbooks-testdata.sql

functions:
	psql gladbooks < gladbooks.functions.sql

demo:
	psql gladbooks < gladbooks.demo.sql

dropdb:
	dropdb gladbooks

reset: dropdb all

upgrade:
	psql -v VERBOSITY=terse gladbooks < gladbooks.upgrades.sql
	#psql -v VERBOSITY=terse gladbooks -c "DROP FUNCTION IF EXISTS create_business(instance VARCHAR(63), business VARCHAR(63), period_start DATE);"
	#psql gladbooks < gladbooks.business.sql
	#psql -v VERBOSITY=terse gladbooks < updates/00027.sql
	#psql -v VERBOSITY=terse gladbooks < updates/00028.sql
	#psql -v VERBOSITY=terse gladbooks < updates/00029.sql
	psql -v VERBOSITY=terse gladbooks < updates/00030.sql
	psql -v VERBOSITY=terse gladbooks < updates/00031.sql

