<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:template match="sort">
		<xsl:if test="position() = '1'">
			<xsl:text> ORDER BY </xsl:text>
		</xsl:if>
		<xsl:value-of select="@field"/>
		<xsl:if test="@order">
			<xsl:text> </xsl:text>
			<xsl:value-of select="@order"/>
		</xsl:if>
		<xsl:if test="position() != last()">
			<xsl:text>, </xsl:text>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
