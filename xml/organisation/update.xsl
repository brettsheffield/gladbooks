<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

        <xsl:variable name="authuser" select="request/authuser" />
        <xsl:variable name="clientip" select="request/clientip" />

        <xsl:template match="request">
                <xsl:apply-templates select="data/organisation"/>
        </xsl:template>

	<xsl:template match="organisation">
		<xsl:text>BEGIN;</xsl:text>
		<xsl:text>INSERT INTO organisationdetail (organisation,</xsl:text>
		<xsl:choose>
			<xsl:when test="@name">
				<xsl:text>name,</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="@vatnumber">
				<xsl:text>vatnumber,</xsl:text>
			</xsl:when>
		</xsl:choose>

		<xsl:text>authuser,clientip) VALUES ('</xsl:text>
		<xsl:value-of select="@id"/>
		<xsl:text>','</xsl:text>

		<xsl:choose>
			<xsl:when test="@name">
				<xsl:value-of select="@name"/>
				<xsl:text>','</xsl:text>
			</xsl:when>
		</xsl:choose>

		<xsl:choose>
			<xsl:when test="@vatnumber">
				<xsl:value-of select="@vatnumber"/>
				<xsl:text>','</xsl:text>
			</xsl:when>
		</xsl:choose>

		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
		<xsl:text>COMMIT;</xsl:text>
	</xsl:template>

</xsl:stylesheet>
