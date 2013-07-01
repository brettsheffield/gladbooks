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
                <xsl:apply-templates select="data/purchasepayment"/>
        </xsl:template>

	<xsl:template match="purchasepayment">
		<xsl:call-template name="setSearchPath"/>

		<xsl:text>BEGIN;</xsl:text>

                <xsl:if test="not(@id)">
                        <xsl:text>INSERT INTO purchasepayment (</xsl:text>
			<xsl:text>authuser, clientip) VALUES ('</xsl:text>
                        <xsl:copy-of select="$authuser"/>
                        <xsl:text>','</xsl:text>
                        <xsl:copy-of select="$clientip"/>
                        <xsl:text>');</xsl:text>
                </xsl:if>

		<xsl:text>INSERT INTO purchasepaymentdetail (</xsl:text>
		<xsl:text>purchasepayment,</xsl:text>
		<xsl:if test="transactdate">
			<xsl:text>transactdate,</xsl:text>
		</xsl:if>
		<xsl:if test="paymenttype">
			<xsl:text>paymenttype,</xsl:text>
		</xsl:if>
		<xsl:if test="organisation">
			<xsl:text>organisation,</xsl:text>
		</xsl:if>
		<xsl:if test="amount">
			<xsl:text>amount,</xsl:text>
		</xsl:if>
		<xsl:if test="description">
			<xsl:text>description,</xsl:text>
		</xsl:if>

		<xsl:text>authuser,clientip) VALUES (</xsl:text>

                <xsl:choose>
                        <xsl:when test="@id">
                                <xsl:text>'</xsl:text>
                                <xsl:value-of select="@id"/>
                                <xsl:text>','</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:text>currval(pg_get_serial_sequence('purchasepayment','id')),'</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>

		<xsl:if test="transactdate">
			<xsl:value-of select="transactdate"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="paymenttype">
			<xsl:value-of select="paymenttype"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="organisation">
			<xsl:value-of select="organisation"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="amount">
			<xsl:value-of select="amount"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="description">
			<xsl:call-template name="cleanQuote">
				<xsl:with-param name="string">
					<xsl:value-of select="description"/>
				</xsl:with-param>
			</xsl:call-template>
			<xsl:text>','</xsl:text>
		</xsl:if>

		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
		<xsl:text>COMMIT;</xsl:text>
	</xsl:template>

</xsl:stylesheet>
