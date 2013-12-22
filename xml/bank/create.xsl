<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

        <xsl:variable name="authuser" select="request/authuser" />
        <xsl:variable name="clientip" select="request/clientip" />
        <xsl:variable name="instance" select="request/instance" />
        <xsl:variable name="business" select="request/business" />
        <xsl:variable name="account" select="request/data/account" />

	<xsl:include href="../cleanQuote.xsl"/>
	<xsl:include href="../setSearchPath.xsl"/>

        <xsl:template match="request">
                <xsl:apply-templates select="data/bank"/>
        </xsl:template>

	<xsl:template match="bank">
		<xsl:call-template name="setSearchPath"/>

		<xsl:text>BEGIN;</xsl:text>

                <xsl:if test="not(@id)">
                        <xsl:text>INSERT INTO bank (</xsl:text>
			<xsl:text>authuser, clientip) VALUES ('</xsl:text>
                        <xsl:copy-of select="$authuser"/>
                        <xsl:text>','</xsl:text>
                        <xsl:copy-of select="$clientip"/>
                        <xsl:text>');</xsl:text>
                </xsl:if>

		<xsl:text>INSERT INTO bankdetail (</xsl:text>
		<xsl:text>bank,</xsl:text>
		<xsl:if test="transactdate">
			<xsl:text>transactdate,</xsl:text>
		</xsl:if>
		<xsl:if test="description">
			<xsl:text>description,</xsl:text>
		</xsl:if>
		<xsl:text>account,</xsl:text>
		<xsl:if test="paymenttype">
			<xsl:text>paymenttype,</xsl:text>
		</xsl:if>
		<xsl:if test="ledger">
			<xsl:text>ledger,</xsl:text>
		</xsl:if>
		<xsl:if test="debit">
			<xsl:text>debit,</xsl:text>
		</xsl:if>
		<xsl:if test="credit">
			<xsl:text>credit,</xsl:text>
		</xsl:if>

		<xsl:text>authuser,clientip) VALUES (</xsl:text>

                <xsl:choose>
                        <xsl:when test="@id">
                                <xsl:text>'</xsl:text>
                                <xsl:value-of select="@id"/>
                                <xsl:text>',</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:text>currval(pg_get_serial_sequence('bank','id')),</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>

		<xsl:if test="transactdate">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="transactdate"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="description">
			<xsl:text>'</xsl:text>
			<xsl:call-template name="cleanQuote">
				<xsl:with-param name="string">
					<xsl:value-of select="description"/>
				</xsl:with-param>
			</xsl:call-template>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:text>'</xsl:text>
		<xsl:copy-of select="$account"/>
		<xsl:text>',</xsl:text>
		<xsl:if test="paymenttype">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="paymenttype"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="ledger">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="ledger"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="debit">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="debit"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="credit">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="credit"/>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:text>'</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
		<xsl:text>COMMIT;</xsl:text>
	</xsl:template>

</xsl:stylesheet>
