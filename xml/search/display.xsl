<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="html" disable-output-escaping="yes" />

<xsl:template match="display">
	<xsl:text> || '</xsl:text>
	<xsl:element name="div">
		<xsl:attribute name="class">
			<xsl:text>td </xsl:text>
			<xsl:choose>
				<xsl:when test="@as">
					<xsl:value-of select="@as"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
		<xsl:text>' || COALESCE(CAST(</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text> AS TEXT), '') || '</xsl:text>
	</xsl:element>
	<xsl:text>'</xsl:text>
</xsl:template>

</xsl:stylesheet>
