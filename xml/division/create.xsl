<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

        <xsl:variable name="authuser" select="request/authuser" />
        <xsl:variable name="clientip" select="request/clientip" />
        <xsl:variable name="instance" select="request/instance" />
        <xsl:variable name="business" select="request/business" />
	<xsl:variable name="id" select="request/id" />

	<xsl:include href="../cleanQuote.xsl"/>
	<xsl:include href="../setSearchPath.xsl"/>

        <xsl:template match="request">
                <xsl:apply-templates select="data/division"/>
        </xsl:template>

	<xsl:template match="division">
		<xsl:call-template name="setSearchPath"/>

		<xsl:text>BEGIN;</xsl:text>
		<xsl:text>INSERT INTO division (name, authuser, clientip) VALUES ('</xsl:text>

		<xsl:call-template name="cleanQuote">
			<xsl:with-param name="string">
				<xsl:value-of select="name"/>
			</xsl:with-param>
		</xsl:call-template>

		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
		<xsl:text>COMMIT;</xsl:text>
		<xsl:text>SELECT id,name FROM division </xsl:text>
		<xsl:text>WHERE id=</xsl:text>
		<xsl:choose>
			<xsl:when test="$id">
				<xsl:text>'</xsl:text>
				<xsl:value-of select="$id"/>
				<xsl:text>';</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>currval(pg_get_serial_sequence('division','id'));</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>
