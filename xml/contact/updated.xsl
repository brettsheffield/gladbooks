<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

<xsl:variable name="authuser" select="request/authuser" />
<xsl:variable name="clientip" select="request/clientip" />
<xsl:variable name="instance" select="request/instance" />
<xsl:variable name="business" select="request/business" />

<xsl:include href="../setSearchPath.xsl"/>

<xsl:template match="/">
	<xsl:call-template name="setSearchPath"/>
	<xsl:text>SELECT * FROM (</xsl:text>
		<xsl:text>SELECT contact AS id,</xsl:text>
		<xsl:text>name,</xsl:text>
		<xsl:text>line_1,</xsl:text>
		<xsl:text>line_2,</xsl:text>
		<xsl:text>line_3,</xsl:text>
		<xsl:text>town,</xsl:text>
		<xsl:text>county,</xsl:text>
		<xsl:text>country,</xsl:text>
		<xsl:text>postcode,</xsl:text>
		<xsl:text>email,</xsl:text>
		<xsl:text>phone,</xsl:text>
		<xsl:text>phonealt,</xsl:text>
		<xsl:text>mobile,</xsl:text>
		<xsl:text>fax </xsl:text>
		<xsl:text>FROM contact_current</xsl:text>
	<xsl:text>) t </xsl:text>
</xsl:template>

</xsl:stylesheet>
