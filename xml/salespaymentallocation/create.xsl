<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

        <xsl:variable name="authuser" select="request/authuser" />
        <xsl:variable name="clientip" select="request/clientip" />
        <xsl:variable name="instance" select="request/instance" />
        <xsl:variable name="business" select="request/business" />

	<xsl:include href="../cleanQuote.xsl"/>
	<xsl:include href="../setSearchPath.xsl"/>

        <xsl:template match="request">
                <xsl:apply-templates select="data/salespaymentallocation"/>
        </xsl:template>

	<xsl:template match="salespaymentallocation">
		<xsl:call-template name="setSearchPath"/>

		<xsl:text>BEGIN;</xsl:text>

                <xsl:if test="not(@id)">
                        <xsl:text>INSERT INTO salespaymentallocation (</xsl:text>
			<xsl:text>authuser, clientip) VALUES ('</xsl:text>
                        <xsl:copy-of select="$authuser"/>
                        <xsl:text>','</xsl:text>
                        <xsl:copy-of select="$clientip"/>
                        <xsl:text>');</xsl:text>
                </xsl:if>

		<xsl:text>INSERT INTO salespaymentallocationdetail (</xsl:text>
		<xsl:text>salespaymentallocation,</xsl:text>
		<xsl:if test="salespayment">
			<xsl:text>salespayment,</xsl:text>
		</xsl:if>
		<xsl:if test="salesinvoice">
			<xsl:text>salesinvoice,</xsl:text>
		</xsl:if>
		<xsl:if test="amount">
			<xsl:text>amount,</xsl:text>
		</xsl:if>

		<xsl:text>authuser,clientip) VALUES (</xsl:text>

                <xsl:choose>
                        <xsl:when test="@id">
                                <xsl:text>'</xsl:text>
                                <xsl:value-of select="@id"/>
                                <xsl:text>','</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:text>currval(pg_get_serial_sequence('salespaymentallocation','id')),'</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>

		<xsl:if test="salespayment">
			<xsl:value-of select="salespayment"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="salesinvoice">
			<xsl:value-of select="salesinvoice"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="amount">
			<xsl:value-of select="amount"/>
			<xsl:text>','</xsl:text>
		</xsl:if>

		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
		<xsl:text>COMMIT;</xsl:text>
	</xsl:template>

</xsl:stylesheet>
