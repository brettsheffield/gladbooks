<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="xml" encoding="UTF-8" indent="yes" />

<xsl:template match="resources">
<div class="report statement">
	<xsl:apply-templates select="row"/>
	<xsl:text disable-output-escaping="yes"><![CDATA[</div>]]></xsl:text>
	<div class="clearfix"/>
</div>
</xsl:template>

<xsl:template match="row">
	<xsl:if test="type='ORG_NAME'">
		<h2>Statement</h2>
		<h3><xsl:value-of select="ref"/></h3>
		<xsl:text disable-output-escaping="yes">
		<![CDATA[<div class="panel left">]]>
		</xsl:text>
	</xsl:if>
	<xsl:if test="type='TOTAL'">
		<div class="linespace"/>
		<b>
		<div class="bsaccount">
			<xsl:value-of select="ref"/>
		</div>
		<div class="bsamount">
			<xsl:value-of select="total"/>
		</div>
		</b>
	</xsl:if>
	
	<xsl:if test="type='SI' or type='SP'">
		<div class="bsaccount">
			<xsl:value-of select="taxpoint"/>
			&#160;&#160;&#160;&#160;
			<xsl:value-of select="ref"/>
		</div>
		<div class="bsamount">
			<xsl:value-of select="total"/>
		</div>
	</xsl:if>
	<div class="clearfix"/>
</xsl:template>

</xsl:stylesheet>
