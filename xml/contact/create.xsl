<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

        <xsl:variable name="authuser" select="request/authuser" />
        <xsl:variable name="clientip" select="request/clientip" />

        <xsl:template match="request">
                <xsl:apply-templates select="data/contact"/>
        </xsl:template>

	<xsl:template match="contact">
		<xsl:text>BEGIN;</xsl:text>
		<xsl:text>INSERT INTO contact (authuser, clientip) VALUES ('</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>

		<xsl:text>INSERT INTO contactdetail (contact, name, authuser, clientip) VALUES (currval(pg_get_serial_sequence('contact','id')),'</xsl:text>
		<xsl:value-of select="@name"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
		<xsl:text>COMMIT;</xsl:text>
	</xsl:template>

</xsl:stylesheet>