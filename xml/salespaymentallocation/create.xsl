<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

        <xsl:variable name="authuser" select="request/authuser" />
        <xsl:variable name="clientip" select="request/clientip" />
        <xsl:variable name="instance" select="request/instance" />
        <xsl:variable name="business" select="request/business" />

	<xsl:include href="../cleanQuote.xsl"/>
	<xsl:include href="../setSearchPath.xsl"/>
	<xsl:include href="salespaymentallocation.xsl"/>

        <xsl:template match="request">
		<xsl:call-template name="setSearchPath"/>
		<xsl:text>BEGIN;</xsl:text>
                <xsl:apply-templates select="data/salespaymentallocation"/>
		<xsl:text>COMMIT;</xsl:text>
        </xsl:template>

</xsl:stylesheet>
