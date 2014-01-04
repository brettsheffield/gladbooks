<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" indent="yes" disable-output-escaping="yes" />

<xsl:template match="resources">
	<xsl:apply-templates select="row"/>
</xsl:template>

<xsl:template match="row">
	<xsl:value-of select="result"/>
</xsl:template>

</xsl:stylesheet>
