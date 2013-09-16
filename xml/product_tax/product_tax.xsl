<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />
	
	<xsl:template match="tax">
		<xsl:call-template name="setSearchPath"/>

		<xsl:text>INSERT INTO product_tax (product, tax, </xsl:text>
		<xsl:text>authuser, clientip) VALUES (</xsl:text>
		<xsl:choose>
			<xsl:when test="product">
				<xsl:text>'</xsl:text>
				<xsl:value-of select="product"/>
				<xsl:text>','</xsl:text>
			</xsl:when>
			<xsl:when test="../../product/@id">
				<xsl:text>'</xsl:text>
				<xsl:value-of select="@id"/>
				<xsl:text>','</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>currval(pg_get_serial_sequence('product','id')),'</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="@id"/>
		<xsl:text>','</xsl:text>
       		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
	</xsl:template>

</xsl:stylesheet>
