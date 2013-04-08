<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:template name="salesorderitem">
		<xsl:call-template name="setSearchPath"/>

                <xsl:if test="not(@id)">
                        <xsl:text>INSERT INTO salesorderitem (authuser, clientip) VALUES ('</xsl:text>
                        <xsl:copy-of select="$authuser"/>
                        <xsl:text>','</xsl:text>
                        <xsl:copy-of select="$clientip"/>
                        <xsl:text>');</xsl:text>
                </xsl:if>

		<xsl:text>INSERT INTO salesorderitemdetail (salesorderitem,</xsl:text>
		<xsl:if test="salesorder">
			<xsl:text>salesorder,</xsl:text>
		</xsl:if>
		<xsl:if test="product">
			<xsl:text>product,</xsl:text>
		</xsl:if>
		<xsl:if test="linetext">
			<xsl:text>linetext,</xsl:text>
		</xsl:if>
		<xsl:if test="discount">
			<xsl:text>discount,</xsl:text>
		</xsl:if>
		<xsl:if test="price">
			<xsl:text>price,</xsl:text>
		</xsl:if>
		<xsl:if test="@is_deleted">
			<xsl:text>is_deleted,</xsl:text>
		</xsl:if>

		<xsl:text>authuser,clientip) VALUES (</xsl:text>

                <xsl:choose>
                        <xsl:when test="@id">
                                <xsl:text>'</xsl:text>
                                <xsl:value-of select="@id"/>
                                <xsl:text>','</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:text>currval(pg_get_serial_sequence('salesorderitem','id')),'</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>

		<xsl:if test="salesorder">
			<xsl:value-of select="salesorder"/>
			<xsl:text>','</xsl:text>
		</xsl:if>

		<xsl:if test="product">
			<xsl:value-of select="product"/>
			<xsl:text>','</xsl:text>
		</xsl:if>

		<xsl:if test="linetext">
			<xsl:call-template name="cleanQuote">
				<xsl:with-param name="string">
					<xsl:value-of select="linetext"/>
				</xsl:with-param>
			</xsl:call-template>
			<xsl:text>','</xsl:text>
		</xsl:if>

		<xsl:if test="discount">
			<xsl:value-of select="discount"/>
			<xsl:text>','</xsl:text>
		</xsl:if>

		<xsl:if test="price">
			<xsl:value-of select="price"/>
			<xsl:text>','</xsl:text>
		</xsl:if>

		<xsl:if test="@is_deleted">
			<xsl:value-of select="@is_deleted"/>
			<xsl:text>','</xsl:text>
		</xsl:if>

		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>

	</xsl:template>

</xsl:stylesheet>
