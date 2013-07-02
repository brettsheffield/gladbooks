<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

        <xsl:variable name="authuser" select="request/authuser" />
        <xsl:variable name="clientip" select="request/clientip" />
        <xsl:variable name="instance" select="request/instance" />
        <xsl:variable name="business" select="request/business" />

	<xsl:include href="../cleanQuote.xsl"/>
	<xsl:include href="../setSearchPath.xsl"/>

        <xsl:template match="request">
                <xsl:apply-templates select="data/payment"/>
        </xsl:template>

	<xsl:template match="payment">
		<xsl:call-template name="setSearchPath"/>

		<xsl:text>SELECT createpayment('</xsl:text>
		<xsl:value-of select="@type"/>
		<xsl:text>','</xsl:text>
		<xsl:value-of select="bankid"/>
		<xsl:text>','</xsl:text>
		<xsl:value-of select="organisation"/>
		<xsl:text>');</xsl:text>
	</xsl:template>

</xsl:stylesheet>
