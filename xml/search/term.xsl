<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:template match="term">
		<xsl:param name="field"/>
		<xsl:param name="or"/>
		<xsl:if test="position() = '1'">
			<xsl:value-of select="$or"/>
		</xsl:if>
		<xsl:value-of select="$field"/>
		<xsl:text> LIKE '%</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>%'</xsl:text>
		<xsl:if test="position() != last()">
			<xsl:text> OR </xsl:text>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
