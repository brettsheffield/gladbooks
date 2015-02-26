<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" indent="yes" />

<xsl:template match="resources">
	<div class="tr">
		<div class="th xml-taxpoint">Taxpoint</div>
		<div class="th xml-issued smallscreen-hidden">Issued</div>
		<div class="th xml-due smallscreen-hidden">Due</div>
		<div class="th xml-ref">Ref</div>
		<div class="th xml-debit">Debit</div>
		<div class="th xml-credit">Credit</div>
		<div class="th xml-total">Total</div>
	</div>
        <xsl:apply-templates select="row"/>
</xsl:template>
<xsl:template match="row">
        <xsl:if test="taxpoint != '0001-01-01'">
	<div class="tr">
                <input name="id" type="hidden" value="{lineid}"/>
                <input name="type" type="hidden" value="{type}"/>
                <input name="ref" type="hidden" value="{ref}"/>
		<div class="td xml-taxpoint">
			<xsl:value-of select="taxpoint"/>
		</div>
		<div class="td xml-issued smallscreen-hidden">
			<xsl:value-of select="issued"/>
		</div>
		<div class="td xml-due smallscreen-hidden">
			<xsl:value-of select="due"/>
		</div>
		<div class="td xml-ref">
			<xsl:value-of select="description"/>
		</div>
		<div class="td xml-debit">
                <xsl:if test="type = 'SI'">
			<xsl:value-of select="total"/>
                </xsl:if>
		</div>
		<div class="td xml-credit">
                <xsl:if test="type = 'SP'">
			<xsl:value-of select="total"/>
                </xsl:if>
		</div>
		<div class="td xml-total">
                <xsl:if test="type = 'TOTAL'">
			<xsl:value-of select="total"/>
                </xsl:if>
		</div>
	</div>
        </xsl:if>
</xsl:template>

</xsl:stylesheet>
