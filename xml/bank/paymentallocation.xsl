<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:template match="paymentallocation">
		<xsl:param name="type"/>
		<xsl:text>INSERT INTO </xsl:text>
		<xsl:value-of select="$type"/>
		<xsl:text>paymentallocation(authuser,clientip) </xsl:text>
		<xsl:text>VALUES ('</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
		<xsl:text>INSERT INTO </xsl:text>
		<xsl:value-of select="$type"/>
		<xsl:text>paymentallocationdetail(</xsl:text>
		<xsl:value-of select="$type"/>
		<xsl:text>paymentallocation,payment,</xsl:text>
		<xsl:value-of select="$type"/>
		<xsl:text>invoice,amount,authuser,clientip) </xsl:text>
		<xsl:text>VALUES (</xsl:text>
		<xsl:text>currval(pg_get_serial_sequence('</xsl:text>
		<xsl:value-of select="$type"/>
		<xsl:text>paymentallocation','id')),</xsl:text>
		<xsl:text>currval(pg_get_serial_sequence('</xsl:text>
		<xsl:value-of select="$type"/>
		<xsl:text>payment','id')),'</xsl:text>
		<xsl:value-of select="invoice"/>
		<xsl:text>','</xsl:text>
		<xsl:value-of select="amount"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
	</xsl:template>

</xsl:stylesheet>
