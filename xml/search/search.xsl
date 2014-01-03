<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:include href="collection.xsl"/>

	<xsl:template match="search">
		<xsl:text>CREATE TEMP SEQUENCE sorted;</xsl:text>
		<xsl:apply-templates select="collection">
			<xsl:with-param name="collections" select="count(collection)"/>
		</xsl:apply-templates>
		<xsl:text>DROP SEQUENCE sorted;</xsl:text>
	</xsl:template>

</xsl:stylesheet>
