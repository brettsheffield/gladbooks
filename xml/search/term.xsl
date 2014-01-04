<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:template match="term[@type = 'date']">
		<xsl:param name="field"/>
		<xsl:param name="type"/>
		<xsl:param name="match"/>

		<xsl:choose>
		<xsl:when test="$type = 'numeric'">
			<!-- field is numeric but term is date -->
			<xsl:text>false</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$field"/>
			<xsl:value-of select="$match"/>
			<xsl:text>'</xsl:text>
			<xsl:if test="$type = 'text'">
				<xsl:text>%</xsl:text>
			</xsl:if>
			<xsl:value-of select="."/>
			<xsl:if test="$type = 'text'">
				<xsl:text>%</xsl:text>
			</xsl:if>
			<xsl:text>'</xsl:text>
		</xsl:otherwise>
		</xsl:choose>

		<xsl:if test="position() != last()">
			<xsl:text> OR </xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="term[@type = 'numeric']">
		<xsl:param name="field"/>
		<xsl:param name="type"/>
		<xsl:param name="match"/>

		<xsl:choose>
		<xsl:when test="$type = 'date'">
			<!-- field is date, but term is numeric -->
			<xsl:text>false</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$field"/>
			<xsl:value-of select="$match"/>
			<xsl:text>'</xsl:text>
			<xsl:if test="$type = 'text'">
				<xsl:text>%</xsl:text>
			</xsl:if>
			<xsl:value-of select="."/>
			<xsl:if test="$type = 'text'">
				<xsl:text>%</xsl:text>
			</xsl:if>
			<xsl:text>'</xsl:text>
		</xsl:otherwise>
		</xsl:choose>

		<xsl:if test="position() != last()">
			<xsl:text> OR </xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="term[@type = 'text'] | term[not(@type)]">
		<xsl:param name="field"/>
		<xsl:param name="type"/>
		<xsl:param name="match"/>

		<xsl:choose>
		<xsl:when test="$type = 'numeric' or $type = 'date'">
			<!-- field is number or date, but term isn't - skip -->
			<xsl:text>false</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$field"/>
			<xsl:value-of select="$match"/>
			<xsl:text>'</xsl:text>
			<xsl:if test="$type = 'text'">
				<xsl:text>%</xsl:text>
			</xsl:if>
			<xsl:value-of select="."/>
			<xsl:if test="$type = 'text'">
				<xsl:text>%</xsl:text>
			</xsl:if>
			<xsl:text>'</xsl:text>
		</xsl:otherwise>
		</xsl:choose>

		<xsl:if test="position() != last()">
			<xsl:text> OR </xsl:text>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
