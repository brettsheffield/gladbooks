<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

<xsl:include href="display.xsl"/>

<xsl:template name="displayfields">
	<xsl:param name="collection"/>
	<xsl:text>'</xsl:text>
	<xsl:element name="div">
		<xsl:attribute name="class">
			<xsl:text>tr </xsl:text>
			<xsl:value-of select="$collection"/>
		</xsl:attribute>
		<xsl:text>'</xsl:text>
		<xsl:apply-templates select="display"/>
		<xsl:text> || '</xsl:text>
	</xsl:element>
	<xsl:text>'</xsl:text>
</xsl:template>

</xsl:stylesheet>
