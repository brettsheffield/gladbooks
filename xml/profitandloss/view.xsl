<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="xml" encoding="UTF-8" indent="yes" />

<xsl:template match="resources">
<div class="report balancesheet">
	<h2>Profit &amp; Loss</h2>
	<div class="panel left">
	<xsl:apply-templates select="row"/>
	</div>
</div>
</xsl:template>
<xsl:template match="row">
	<xsl:if test="account=''">
		<div class="linespace"/>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="description='Revenue'">
			<h3>Revenue</h3>
		</xsl:when>
		<xsl:when test="description='Expenditure'">
			<h3>Expenditure</h3>
		</xsl:when>
		<xsl:when test="description='Total Profit / (Loss)'">
			<div class="clearfix">
				<b>
				<div class="bsaccount">
					<xsl:value-of select="description"/>
				</div>
				<div class="bsamount">
					<xsl:value-of select="amount"/>
				</div>
				</b>
			</div>
		</xsl:when>
		<xsl:otherwise>
			<div class="clearfix">
				<div class="bsaccount">
					<xsl:value-of select="description"/>
				</div>
				<div class="bsamount">
					<xsl:value-of select="amount"/>
				</div>
			</div>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
