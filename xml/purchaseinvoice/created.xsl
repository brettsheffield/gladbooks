<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

        <xsl:variable name="authuser" select="request/authuser" />
        <xsl:variable name="clientip" select="request/clientip" />
	<xsl:variable name="instance" select="request/instance" />
	<xsl:variable name="business" select="request/business" />

	<xsl:include href="../setSearchPath.xsl"/>

	<xsl:template match="/">
		<xsl:call-template name="setSearchPath"/>
                <xsl:text>SELECT pi.id, o.name AS organisation, ref, ponumber, description, taxpoint, due, subtotal, tax, total, pi.updated, pi.authuser, pi.clientip </xsl:text>
                <xsl:text>FROM purchaseinvoice_current pi </xsl:text>
                <xsl:text>INNER JOIN organisation_current o </xsl:text>
                <xsl:text>ON o.id = pi.organisation </xsl:text>
		<xsl:text>WHERE pi.id=currval(pg_get_serial_sequence('purchaseinvoice','id'));</xsl:text>
	</xsl:template>

</xsl:stylesheet>
