<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:include href="paymentallocation.xsl"/>

	<xsl:template match="payment">
		<xsl:param name="type"/>

		<xsl:text>INSERT INTO </xsl:text>
		<xsl:value-of select="$type"/>
		<xsl:text>payment(authuser,clientip) VALUES (</xsl:text>
		<xsl:text>'</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>

		<xsl:text>INSERT INTO </xsl:text>
		<xsl:value-of select="$type"/>
		<xsl:text>paymentdetail(</xsl:text>
		<xsl:value-of select="$type"/>
		<xsl:text>payment,</xsl:text>
		<xsl:text>paymenttype,</xsl:text>
		<xsl:text>organisation,</xsl:text>
		<xsl:text>bank,</xsl:text>
		<xsl:text>bankaccount,</xsl:text>
		<xsl:text>transactdate,</xsl:text>
		<xsl:text>amount,</xsl:text>
		<xsl:text>description,</xsl:text>
		<xsl:text>journal,</xsl:text>
		<xsl:text>authuser,</xsl:text>
		<xsl:text>clientip</xsl:text>
		<xsl:text>) VALUES (</xsl:text>
		<xsl:text>currval(pg_get_serial_sequence('</xsl:text>
		<xsl:value-of select="$type"/>
		<xsl:text>payment','id')),'</xsl:text>
		<xsl:value-of select="../paymenttype"/>
		<xsl:text>','</xsl:text>
		<xsl:value-of select="organisation"/>
		<xsl:text>',</xsl:text>
		<xsl:choose>
			<xsl:when test="../@id">
				<xsl:text>'</xsl:text>
				<xsl:value-of select="../@id"/>
				<xsl:text>','</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>currval(pg_get_serial_sequence('bank','id')),'</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="/request/data/account"/>
		<xsl:text>','</xsl:text>
		<xsl:value-of select="../transactdate"/>
		<xsl:text>','</xsl:text>
		<xsl:value-of select="amount"/>
		<xsl:text>','</xsl:text>
		<xsl:call-template name="cleanQuote">
			<xsl:with-param name="string">
				<xsl:value-of select="description"/>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:text>',journal_id_last(),'</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>

		<xsl:text>INSERT INTO ledger (</xsl:text>
		<xsl:text>journal,account,</xsl:text>
		<xsl:if test="$type = 'purchase'">
			<xsl:text>debit</xsl:text>
		</xsl:if>
		<xsl:if test="$type = 'sales'">
			<xsl:text>credit</xsl:text>
		</xsl:if>
		<xsl:text>) VALUES (journal_id_last(),</xsl:text>
		<!-- 1100 - Debtors Control Account -->
		<xsl:if test="$type = 'sales'">
			<xsl:text>'1100','</xsl:text>
			<xsl:value-of select="amount"/>
		</xsl:if>
		<!-- 2100 - Creditors Control Account -->
		<xsl:if test="$type = 'purchase'">
			<xsl:text>'2100','</xsl:text>
			<xsl:value-of select="amount"/>
		</xsl:if>
		<xsl:text>');</xsl:text>

		<xsl:apply-templates select="paymentallocation">
			<xsl:with-param name="type" select="$type"/>
		</xsl:apply-templates>
	</xsl:template>

</xsl:stylesheet>
