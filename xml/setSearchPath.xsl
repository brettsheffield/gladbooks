<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template name="setSearchPath">
 <xsl:text>SET search_path TO gladbooks_</xsl:text>
  <xsl:copy-of select="$instance"/>
  <xsl:text>_</xsl:text>
  <xsl:copy-of select="$business"/>
  <xsl:text>,gladbooks_</xsl:text>
  <xsl:copy-of select="$instance"/>
  <xsl:text>,gladbooks;</xsl:text>
 </xsl:template>
</xsl:stylesheet>
