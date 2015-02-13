<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" indent="yes" />

<xsl:template match="resources">
	<div class="tr">
		<!--div class="th selector">
			<input type="checkbox"/>
		</div-->
		<div class="th xml-ref">Ref</div>
		<div class="th xml-salesorder">SO</div>
		<div class="th xml-ponumber">PO</div>
		<div class="th xml-taxpoint">Taxpoint</div>
		<div class="th xml-issued">Issued</div>
		<div class="th xml-due">Due</div>
		<div class="th xml-subtotal">Subtotal</div>
		<div class="th xml-tax">Tax</div>
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
		<div class="td xml-salesorder">
			<xsl:value-of select="salesorder"/>
		</div>
		<div class="td xml-ponumber">
			<xsl:value-of select="ponumber"/>
		</div>
		<div class="td xml-taxpoint">
			<xsl:value-of select="taxpoint"/>
		</div>
		<div class="td xml-issued">
			<xsl:value-of select="issued"/>
		</div>
		<div class="td xml-due">
			<xsl:value-of select="due"/>
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
	</div>
</xsl:template>

</xsl:stylesheet>
