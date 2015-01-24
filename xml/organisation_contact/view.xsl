<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" indent="yes" />

<xsl:template match="resources">
        <xsl:apply-templates select="row"/>
</xsl:template>
<xsl:template match="row">
	<div class="tr">
                <input name="id" type="hidden" value="{id}"/>
		<div class="td xml-name">
			<xsl:value-of select="name"/>
		</div>
		<div class="td xml-email">
			<xsl:value-of select="description"/>
		</div>
		<div class="td xml-phone">
			<xsl:value-of select="phone"/>
		</div>
		<div class="td xml-mobile">
			<xsl:value-of select="mobile"/>
		</div>
		<div class="td xml-type">
			<xsl:value-of select="type"/>
		</div>
	</div>
</xsl:template>

</xsl:stylesheet>
