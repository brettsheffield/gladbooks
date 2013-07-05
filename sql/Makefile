# To setup/reset a fresh gladbooks database:
#
.PHONY: dropdb db reset instance business businessdata testdata functions

all: db instance instance business businessdata testdata functions

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

dropdb:
	dropdb gladbooks

reset: dropdb all
