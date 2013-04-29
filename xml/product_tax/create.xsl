<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

        <xsl:variable name="authuser" select="request/authuser" />
        <xsl:variable name="clientip" select="request/clientip" />
        <xsl:variable name="instance" select="request/instance" />
        <xsl:variable name="business" select="request/business" />

        <xsl:template match="request">
                <xsl:apply-templates select="data"/>
        </xsl:template>

	<xsl:template match="data">
		<xsl:text>BEGIN;</xsl:text>

		<xsl:for-each select="tax">
			<xsl:call-template name="tax"/>
		</xsl:for-each>

		<xsl:text>COMMIT;</xsl:text>
	</xsl:template>

	<xsl:template name="tax">
		<xsl:text>INSERT INTO gladbooks_</xsl:text>
		<xsl:copy-of select="$instance"/>
		<xsl:text>_</xsl:text>
		<xsl:copy-of select="$business"/>
		<xsl:text>.product_tax (product, tax, is_applicable, authuser, clientip) VALUES ('</xsl:text>
		<xsl:value-of select="../product"/>
		<xsl:text>','</xsl:text>
		<xsl:value-of select="../tax"/>
		<xsl:text>','true',</xsl:text>
       		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
	</xsl:template>

</xsl:stylesheet>
