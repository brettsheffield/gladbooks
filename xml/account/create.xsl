<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

        <xsl:variable name="authuser" select="request/authuser" />
        <xsl:variable name="clientip" select="request/clientip" />

        <xsl:template match="request">
                <xsl:apply-templates select="data/account"/>
        </xsl:template>

	<xsl:template match="account">
		<xsl:text>BEGIN;</xsl:text>
		<xsl:text>INSERT INTO account (accounttype, description, authuser, clientip) VALUES ('</xsl:text>
		<xsl:value-of select="@type"/>
		<xsl:text>','</xsl:text>
		<xsl:value-of select="@description"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
		<xsl:text>COMMIT;</xsl:text>
	</xsl:template>

</xsl:stylesheet>
