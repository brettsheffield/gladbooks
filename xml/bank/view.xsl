<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" indent="yes" />

<xsl:template match="resources">
	<div class="bank statement">
		<div class="tr">
			<div class="th xml-id">id</div>
			<div class="th xml-date">date</div>
			<div class="th xml-description">description</div>
			<div class="th xml-account">account</div>
			<div class="th xml-type">type</div>
			<div class="th xml-ledger">ledger</div>
			<div class="th xml-debit">debit</div>
			<div class="th xml-credit">credit</div>
			<div class="th buttons">&#160;</div>
		</div>
		<xsl:apply-templates select="row"/>
	</div>
</xsl:template>
<xsl:template match="row">
	<div>
		<xsl:attribute name="class">
			<xsl:text>tr</xsl:text>
			<xsl:if test="string-length(ledger)!=0">
				<xsl:text> reconciled</xsl:text>
			</xsl:if>
		</xsl:attribute>
		<div class="td xml-id">
			<xsl:value-of select="id"/>
		</div>
		<div class="td xml-date">
			<xsl:value-of select="date"/>
		</div>
		<div class="td xml-description">
			<xsl:value-of select="description"/>&#160;
		</div>
		<div class="td xml-account">
			<xsl:value-of select="account"/>
		</div>
		<div class="td xml-type">
			<xsl:value-of select="type"/>
		</div>
		<div class="td xml-ledger">
			<xsl:value-of select="ledger"/>
		</div>
		<div class="td xml-debit">
			<xsl:value-of select="debit"/>
		</div>
		<div class="td xml-credit">
			<xsl:value-of select="credit"/>
		</div>
	</div>
</xsl:template>

</xsl:stylesheet>
