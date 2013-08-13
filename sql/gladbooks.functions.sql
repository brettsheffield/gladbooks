SET search_path TO gladbooks;

/* test of postgresql shared library function */
CREATE FUNCTION test(TEXT) RETURNS INT4
	AS 'gladbooks', 'test'
	LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION create_business_dirs(
	orgcode		TEXT
) RETURNS INT4
	AS 'gladbooks', 'create_business_dirs'
	LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION write_salesinvoice_tex(
	spooldir	TEXT,
	template	TEXT,
	orgcode		TEXT,
	invoicenum      INT4,
	taxpoint	TEXT,
	issued		TEXT,
	due		TEXT,
	ponumber	TEXT,
	subtotal	TEXT,
	tax		TEXT,
	total		TEXT,
	lineitems	TEXT,
	taxes		TEXT,
	customer	TEXT
) RETURNS INT4
	AS 'gladbooks', 'write_salesinvoice_tex'
	LANGUAGE C STRICT;
