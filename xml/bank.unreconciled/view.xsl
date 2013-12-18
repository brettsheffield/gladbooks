<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" indent="yes" />

<xsl:template match="resources">
	<xsl:apply-templates select="row"/>
</xsl:template>
<xsl:template match="row">
	<div class="tr">
		<div class="th xml-id">ID</div>
		<div class="th xml-date">Date</div>
		<div class="th xml-description">Description</div>
		<div class="th xml-account">Account</div>
		<div class="th xml-debit">Debit</div>
		<div class="th xml-credit">Credit</div>
		<div class="th buttons">&#160;</div>
	</div>
	<div class="tr">
		<div class="td xml-id">
			<xsl:value-of select="id"/>
		</div>
		<div class="td xml-date">
			<xsl:value-of select="date"/>
		</div>
		<div class="td xml-description">
			<xsl:value-of select="description"/>
		</div>
		<div class="td xml-account">
			<xsl:value-of select="account"/>
		</div>
		<div class="td xml-debit">
			<xsl:value-of select="debit"/>
		</div>
		<div class="td xml-credit">
			<xsl:value-of select="credit"/>
		</div>
		<div class="td buttons">&#160;</div>
	</div>
</xsl:template>

</xsl:stylesheet>
