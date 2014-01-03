<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:include href="sort.xsl"/>
	<xsl:include href="term.xsl"/>
	<xsl:include href="field.xsl"/>

	<xsl:template match="collection">
		<xsl:text>SELECT * FROM </xsl:text>

		<!-- replace with real view/table names -->
		<xsl:choose>
			<xsl:when test="@type = 'contact'">
				<xsl:text>contact_current</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@type"/>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:apply-templates select="field"/>
		<xsl:apply-templates select="sort"/>
		<xsl:text>;</xsl:text>
	</xsl:template>

</xsl:stylesheet>
