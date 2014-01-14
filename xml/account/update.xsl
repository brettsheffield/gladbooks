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
	<xsl:apply-templates select="data/account"/>
</xsl:template>

<xsl:template match="account">
	<xsl:call-template name="setSearchPath"/>

	<xsl:text>BEGIN;</xsl:text>
	<xsl:text>UPDATE account SET </xsl:text>

	<xsl:apply-templates select="*"/>
	<xsl:text>WHERE id='</xsl:text>
	<xsl:value-of select="$id"/>
	<xsl:text>'</xsl:text>

	<xsl:text>;COMMIT;</xsl:text>

	<!-- return the record we just updated -->
	<xsl:text>SELECT a.id, a.accounttype </xsl:text>
	<xsl:text>AS type, a.description </xsl:text>
	<xsl:text>FROM account a </xsl:text>
	<xsl:text>WHERE id='</xsl:text>
	<xsl:value-of select="$id"/>
	<xsl:text>';</xsl:text>

</xsl:template>

<xsl:template match="*">
	<xsl:value-of select="name()"/>
	<xsl:text>='</xsl:text>

	<xsl:call-template name="cleanQuote">
		<xsl:with-param name="string">
			<xsl:value-of select="."/>
		</xsl:with-param>
	</xsl:call-template>
	<xsl:text>'</xsl:text>
	<xsl:if test="position() != last()">
		<xsl:text>,</xsl:text>
	</xsl:if>

</xsl:template>

</xsl:stylesheet>
