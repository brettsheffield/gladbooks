<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:template match="display">
		<xsl:param name="collection"/>
		<xsl:variable name="divopen">&lt;div</xsl:variable>
		<xsl:variable name="divclose">&lt;/div&gt;</xsl:variable>
		<xsl:if test="position() = '1'">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="$divopen"/>
			<xsl:text> class="tr </xsl:text>
			<xsl:value-of select="$collection"/>
			<xsl:text>"&gt;' || </xsl:text>
		</xsl:if>
		<xsl:text>'</xsl:text>
		<xsl:value-of select="$divopen"/>
		<xsl:text> class="td </xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>"&gt;' || </xsl:text>
		<xsl:value-of select="."/>
		<xsl:text> || '</xsl:text>
		<xsl:value-of select="$divclose"/>
		<xsl:text>' </xsl:text>
		<xsl:if test="position() != last()">
			<xsl:text> || </xsl:text>
		</xsl:if>
		<xsl:if test="position() = last()">
			<xsl:text> || '</xsl:text>
			<xsl:value-of select="$divclose"/>
			<xsl:text>'</xsl:text>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
