<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="xml" encoding="UTF-8" indent="yes" />

<xsl:template match="resources">
<div class="report balancesheet">
	<h2>Balance Sheet</h2>
	<div class="panel left">
	<h3>Assets</h3>
	<xsl:apply-templates select="row"/>
	</div>
</div>
</xsl:template>
<xsl:template match="row">
	<xsl:if test="sort=1999 or sort=2999 or sort=3999 or sort=99999">
		<div class="linespace"/>
	</xsl:if>
	<div class="clearfix">
		<div class="bsaccount">
			<xsl:value-of select="description"/>
		</div>
		<div class="bsamount">
			<xsl:value-of select="total"/>
		</div>
	</div>
	<xsl:if test="sort = 1999">
		<xsl:text disable-output-escaping="yes">
			<![CDATA[
			</div>
			<div class="panel right">
			<h3>Liabilities</h3>
			]]>
		</xsl:text>
	</xsl:if>
	<xsl:if test="sort = 2999">
		<xsl:text disable-output-escaping="yes">
			<![CDATA[
			<h3>Capital</h3>
			]]>
		</xsl:text>
	</xsl:if>
</xsl:template>

</xsl:stylesheet>
