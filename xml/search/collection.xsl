<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:include href="sort.xsl"/>
	<xsl:include href="term.xsl"/>
	<xsl:include href="field.xsl"/>
	<xsl:include href="display.xsl"/>

	<xsl:template match="collection">
		<xsl:param name="collections"/>
		<xsl:if test="$collections > 1">
			<xsl:if test="position() = '1'">
				<xsl:text>SELECT q.sort,q.result </xsl:text>
				<xsl:text>FROM (</xsl:text>
			</xsl:if>
		</xsl:if>
		<xsl:text>(SELECT </xsl:text>
		<xsl:text>nextval('sorted') AS sort,result FROM (</xsl:text>
		<xsl:text>SELECT </xsl:text>
		<xsl:apply-templates select="display">
			<xsl:with-param name="collection" select="@type"/>
		</xsl:apply-templates>
		<xsl:text> AS result</xsl:text>
		<xsl:text> FROM </xsl:text>

		<!-- replace with real view/table names -->
		<xsl:choose>
			<xsl:when test="@type = 'contact'">
				<xsl:text>contact_current</xsl:text>
			</xsl:when>
			<xsl:when test="@type = 'organisation'">
				<xsl:text>organisation_current</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@type"/>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:apply-templates select="field"/>
		<xsl:apply-templates select="sort"/>
		<xsl:choose>
			<xsl:when test="position() = last()">
				<xsl:if test="$collections > 1">
					<xsl:text>) t</xsl:text>
					<xsl:value-of select="position()"/>
					<xsl:text>)) q ORDER BY q.sort</xsl:text>
				</xsl:if>
				<xsl:text>;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>) t</xsl:text>
				<xsl:value-of select="position()"/>
				<xsl:text>) UNION </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>
