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
       		<xsl:apply-templates select="data/journal"/>
	</xsl:template>

	<xsl:template match="journal">
		<xsl:call-template name="setSearchPath"/>

		<xsl:text>BEGIN;</xsl:text>
		<xsl:text>INSERT INTO journal (transactdate, description, authuser, clientip) VALUES ('</xsl:text>
		<xsl:value-of select="@transactdate"/>
		<xsl:text>','</xsl:text>

		<xsl:call-template name="cleanQuote">
			<xsl:with-param name="string">
				<xsl:value-of select="@description"/>
			</xsl:with-param>
		</xsl:call-template>

		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
		<fo:inline-sequence>
			<xsl:apply-templates select="debit"/>
			<xsl:apply-templates select="credit"/>
		</fo:inline-sequence>
		<xsl:if test="@bankid">
			<xsl:text>INSERT INTO bankdetail (bank, journal) VALUES ('</xsl:text>
			<xsl:value-of select="@bankid"/>
			<xsl:text>',journal_id_last());</xsl:text>
		</xsl:if>
		<xsl:text>COMMIT;</xsl:text>
	</xsl:template>
	<xsl:template match="debit">
		<xsl:text>INSERT INTO ledger (journal, account, </xsl:text>
		<xsl:if test="@division">
			<xsl:text>division, </xsl:text>
		</xsl:if>
		<xsl:if test="@department">
			<xsl:text>department, </xsl:text>
		</xsl:if>
		<xsl:text>debit, authuser, clientip) VALUES (journal_id_last(),'</xsl:text>
		<xsl:value-of select="@account"/>
		<xsl:text>&apos;,&apos;</xsl:text>
		<xsl:if test="@division">
			<xsl:value-of select="@division"/>
			<xsl:text>&apos;,&apos;</xsl:text>
		</xsl:if>
		<xsl:if test="@department">
			<xsl:value-of select="@department"/>
			<xsl:text>&apos;,&apos;</xsl:text>
		</xsl:if>
		<xsl:value-of select="@amount"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>&apos;);</xsl:text><br/>       
	</xsl:template>
	<xsl:template match="credit">
		<xsl:text>INSERT INTO ledger (journal, account, </xsl:text>
		<xsl:if test="@division">
			<xsl:text>division, </xsl:text>
		</xsl:if>
		<xsl:if test="@department">
			<xsl:text>department, </xsl:text>
		</xsl:if>
		<xsl:text>credit, authuser, clientip) VALUES (journal_id_last(),'</xsl:text>
		<xsl:value-of select="@account"/>
		<xsl:text>','</xsl:text>
		<xsl:if test="@division">
			<xsl:value-of select="@division"/>
			<xsl:text>&apos;,&apos;</xsl:text>
		</xsl:if>
		<xsl:if test="@department">
			<xsl:value-of select="@department"/>
			<xsl:text>&apos;,&apos;</xsl:text>
		</xsl:if>
		<xsl:value-of select="@amount"/>
		<xsl:text>&apos;,&apos;</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>&apos;);</xsl:text><br/>       
	</xsl:template>
</xsl:stylesheet>
