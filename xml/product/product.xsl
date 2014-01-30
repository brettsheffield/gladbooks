<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:include href="../product_tax/product_tax.xsl"/>

	<xsl:template match="product">
		<xsl:call-template name="setSearchPath"/>

                <xsl:if test="not($id)">
                        <xsl:text>INSERT INTO product (</xsl:text>
			<xsl:if test="@import_id">
				<xsl:text>import_id,</xsl:text>
			</xsl:if>
			<xsl:text>authuser, clientip) VALUES (</xsl:text>
			<xsl:if test="@import_id">
				<xsl:text>'</xsl:text>
                        	<xsl:value-of select="@import_id"/>
				<xsl:text>',</xsl:text>
			</xsl:if>
                        <xsl:text>'</xsl:text>
                        <xsl:copy-of select="$authuser"/>
                        <xsl:text>','</xsl:text>
                        <xsl:copy-of select="$clientip"/>
                        <xsl:text>');</xsl:text>
                </xsl:if>

		<xsl:text>INSERT INTO productdetail (product,</xsl:text>
		<xsl:if test="account">
			<xsl:text>account,</xsl:text>
		</xsl:if>
		<xsl:if test="shortname">
			<xsl:text>shortname,</xsl:text>
		</xsl:if>
		<xsl:if test="description">
			<xsl:text>description,</xsl:text>
		</xsl:if>
		<xsl:if test="price_buy">
			<xsl:text>price_buy,</xsl:text>
		</xsl:if>
		<xsl:if test="price_sell">
			<xsl:text>price_sell,</xsl:text>
		</xsl:if>

		<xsl:text>authuser,clientip) VALUES (</xsl:text>

                <xsl:choose>
                        <xsl:when test="$id">
                                <xsl:text>'</xsl:text>
                                <xsl:value-of select="$id"/>
                                <xsl:text>',</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:text>currval(pg_get_serial_sequence('product','id')),</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>

		<xsl:if test="account">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="account"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="shortname">
			<xsl:text>'</xsl:text>
			<xsl:call-template name="cleanQuote">
				<xsl:with-param name="string">
					<xsl:value-of select="shortname"/>
				</xsl:with-param>
			</xsl:call-template>
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
		<xsl:if test="price_buy">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="price_buy"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="price_sell">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="price_sell"/>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:text>'</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>

		<!-- product taxes -->
		<xsl:apply-templates select="tax"/>
	</xsl:template>

</xsl:stylesheet>
