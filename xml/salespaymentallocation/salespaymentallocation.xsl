<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:template match="salespaymentallocation">
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
		<xsl:text>payment,</xsl:text>
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
                                <xsl:text>',</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:text>currval(pg_get_serial_sequence('salespaymentallocation','id')),</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>

		<xsl:choose>
			<xsl:when test="salespayment">
				<xsl:text>'</xsl:text>
				<xsl:value-of select="salespayment"/>
				<xsl:text>',</xsl:text>
			</xsl:when>
			<xsl:otherwise>
                                <xsl:text>currval(pg_get_serial_sequence('salespayment','id')),</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="salesinvoice">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="salesinvoice"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="amount">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="amount"/>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:text>'</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
	</xsl:template>

</xsl:stylesheet>
