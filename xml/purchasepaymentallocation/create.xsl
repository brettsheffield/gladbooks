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
                <xsl:apply-templates select="data/purchasepaymentallocation"/>
        </xsl:template>

	<xsl:template match="purchasepaymentallocation">
		<xsl:call-template name="setSearchPath"/>

		<xsl:text>BEGIN;</xsl:text>

                <xsl:if test="not(@id)">
                        <xsl:text>INSERT INTO purchasepaymentallocation (</xsl:text>
			<xsl:text>authuser, clientip) VALUES ('</xsl:text>
                        <xsl:copy-of select="$authuser"/>
                        <xsl:text>','</xsl:text>
                        <xsl:copy-of select="$clientip"/>
                        <xsl:text>');</xsl:text>
                </xsl:if>

		<xsl:text>INSERT INTO purchasepaymentallocationdetail (</xsl:text>
		<xsl:text>purchasepaymentallocation,</xsl:text>
		<xsl:if test="purchasepayment">
			<xsl:text>payment,</xsl:text>
		</xsl:if>
		<xsl:if test="purchaseinvoice">
			<xsl:text>purchaseinvoice,</xsl:text>
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
                                <xsl:text>currval(pg_get_serial_sequence('purchasepaymentallocation','id')),'</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>

		<xsl:if test="purchasepayment">
			<xsl:value-of select="purchasepayment"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="purchaseinvoice">
			<xsl:value-of select="purchaseinvoice"/>
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
