<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" indent="yes" />

<xsl:template match="resources">
	<div class="bank suggestions">
		<xsl:apply-templates select="row"/>
	</div>
</xsl:template>
<xsl:template match="row">
	<div class="tr bank suggestion salesinvoice">
		<div class="td xml-id">
			<xsl:value-of select="id"/>
		</div>
		<div class="td xml-organisation">
			<xsl:value-of select="organisation"/>
		</div>
		<div class="td xml-date">
			<xsl:value-of select="taxpoint"/>
		</div>
		<div class="td xml-description">
			Sales Invoice
			<xsl:value-of select="ref"/>&#160;
		</div>
		<div class="td xml-account">
			<xsl:value-of select="account"/>&#160;
		</div>
		<div class="td xml-subtotal">
			<xsl:value-of select="subtotal"/>
		</div>
		<div class="td xml-tax">
			<xsl:value-of select="tax"/>
		</div>
		<div class="td xml-total">
			<xsl:value-of select="total"/>
		</div>
		<div class="td xml-type">SI</div>
	</div>
</xsl:template>

</xsl:stylesheet>
