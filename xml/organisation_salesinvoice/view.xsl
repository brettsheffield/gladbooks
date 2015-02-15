<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" indent="yes" />

<xsl:template match="resources">
	<div class="tr">
		<!--div class="th selector">
			<input type="checkbox"/>
		</div-->
		<div class="th xml-ref">Ref</div>
		<div class="th xml-salesorder smallscreen-hidden">SO</div>
		<div class="th xml-ponumber smallscreen-hidden">PO</div>
		<div class="th xml-taxpoint">Taxpoint</div>
		<div class="th xml-issued smallscreen-hidden">Issued</div>
		<div class="th xml-due smallscreen-hidden">Due</div>
		<div class="th xml-subtotal smallscreen-hidden">Subtotal</div>
		<div class="th xml-tax smallscreen-hidden">Tax</div>
		<div class="th xml-total">Total</div>
	</div>
        <xsl:apply-templates select="row"/>
</xsl:template>
<xsl:template match="row">
	<div class="tr">
                <input name="id" type="hidden" value="{id}"/>
		<!--div class="td selector">
			<input type="checkbox"/>
		</div-->
		<div class="td xml-ref">
			<xsl:value-of select="ref"/>
		</div>
		<div class="td xml-salesorder smallscreen-hidden">
			<xsl:value-of select="salesorder"/>
		</div>
		<div class="td xml-ponumber smallscreen-hidden">
			<xsl:value-of select="ponumber"/>
		</div>
		<div class="td xml-taxpoint">
			<xsl:value-of select="taxpoint"/>
		</div>
		<div class="td xml-issued smallscreen-hidden">
			<xsl:value-of select="issued"/>
		</div>
		<div class="td xml-due smallscreen-hidden">
			<xsl:value-of select="due"/>
		</div>
		<div class="td xml-subtotal smallscreen-hidden">
			<xsl:value-of select="subtotal"/>
		</div>
		<div class="td xml-tax smallscreen-hidden">
			<xsl:value-of select="tax"/>
		</div>
		<div class="td xml-total">
			<xsl:value-of select="total"/>
		</div>
	</div>
</xsl:template>

</xsl:stylesheet>
