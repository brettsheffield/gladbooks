<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:include href="sort.xsl"/>
	<xsl:include href="term.xsl"/>

	<xsl:template match="field">
		<xsl:choose>
			<xsl:when test="position() = '1'">
				<xsl:text> WHERE </xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text> OR </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates select="../term">
			<xsl:with-param name="field" select="."/>
			<xsl:with-param name="or" select="''"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="../../term">
			<xsl:with-param name="field" select="."/>
			<xsl:with-param name="or" select="' OR '"/>
		</xsl:apply-templates>
	</xsl:template>

</xsl:stylesheet>
