<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:template match="ledger">
		<xsl:param name="type"/>
		<xsl:text>INSERT INTO ledger (journal, account, </xsl:text>
                <xsl:if test="division">
                        <xsl:text>division, </xsl:text>
                </xsl:if>
                <xsl:if test="department">
                        <xsl:text>department, </xsl:text>
                </xsl:if>
		<xsl:if test="debit">
	                <xsl:text>debit, </xsl:text>
		</xsl:if>
		<xsl:if test="credit">
	                <xsl:text>credit, </xsl:text>
		</xsl:if>
		<xsl:text>authuser, clientip) VALUES (journal_id_last(),'</xsl:text>
                <xsl:value-of select="account"/>
                <xsl:text>',</xsl:text>
                <xsl:if test="division">
                        <xsl:text>'</xsl:text>
                        <xsl:value-of select="division"/>
                        <xsl:text>',</xsl:text>
                </xsl:if>
                <xsl:if test="department">
                        <xsl:text>'</xsl:text>
                        <xsl:value-of select="department"/>
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
                <xsl:text>&apos;);</xsl:text><br/>
	</xsl:template>

</xsl:stylesheet>
