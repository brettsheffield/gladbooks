/* test of postgresql shared library function */
CREATE FUNCTION test(TEXT) RETURNS INT4
	AS 'gladbooks', 'test'
	LANGUAGE C STRICT;

CREATE FUNCTION create_salesinvoice_tex(TEXT) RETURNS INT4
	AS 'gladbooks', 'create_salesinvoice_tex'
	LANGUAGE C STRICT;
