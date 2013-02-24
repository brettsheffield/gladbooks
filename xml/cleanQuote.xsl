<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:param name="apostrophe">&apos;</xsl:param>

<xsl:template name="cleanQuote">
  <xsl:param name="string" />
    <xsl:if test="contains($string, $apostrophe)"><xsl:value-of select="substring-before($string, $apostrophe)" />&apos;&apos;<xsl:call-template name="cleanQuote"><xsl:with-param name="string"><xsl:value-of select="substring-after($string, $apostrophe)" /></xsl:with-param></xsl:call-template></xsl:if>
       <xsl:if test="not(contains($string, $apostrophe))"><xsl:value-of select="$string" /></xsl:if>
</xsl:template>

</xsl:stylesheet>
