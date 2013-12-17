<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" indent="yes" />

<xsl:template match="resources">
	<div class="bank suggestions">
		<xsl:apply-templates select="row"/>
	</div>
</xsl:template>
<xsl:template match="row">
	<div class="tr bank suggestion ledger">
		<div class="td id">
			<xsl:value-of select="id"/>
		</div>
		<div class="td transactdate">
			<xsl:value-of select="transactdate"/>
		</div>
		<div class="td description">
			<xsl:value-of select="description"/>&#160;
		</div>
		<div class="td debit">
			<xsl:value-of select="debit"/>
		</div>
		<div class="td credit">
			<xsl:value-of select="credit"/>
		</div>
	</div>
</xsl:template>

</xsl:stylesheet>
