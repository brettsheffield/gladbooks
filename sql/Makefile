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
