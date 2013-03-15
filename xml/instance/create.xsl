<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

        <xsl:variable name="authuser" select="request/authuser" />
        <xsl:variable name="clientip" select="request/clientip" />

	<xsl:include href="../cleanQuote.xsl"/>

        <xsl:template match="request">
                <xsl:apply-templates select="data/instance"/>
        </xsl:template>

	<xsl:template match="instance">
                <!-- Set postgres schema search_path -->
                <xsl:text>SET search_path TO gladbooks;</xsl:text>

		<xsl:text>BEGIN;</xsl:text>
		<xsl:text>SELECT create_instance('</xsl:text>
		<xsl:call-template name="cleanQuote">
			<xsl:with-param name="string">
				<xsl:value-of select="@name"/>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:text>');</xsl:text>
		<xsl:text>COMMIT;</xsl:text>
	</xsl:template>

</xsl:stylesheet>
