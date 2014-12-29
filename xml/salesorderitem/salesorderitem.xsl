<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:template match="salesorderitem">
                <xsl:if test="not(@id)">
                        <xsl:text>INSERT INTO salesorderitem (</xsl:text>
                        <xsl:if test="@uuid">
                                <xsl:text>uuid, </xsl:text>
                        </xsl:if>
                        <xsl:text>authuser, clientip) VALUES ('</xsl:text>
                        <xsl:if test="@uuid">
                                <xsl:value-of select="@uuid"/>
                                <xsl:text>','</xsl:text>
                        </xsl:if>
                        <xsl:copy-of select="$authuser"/>
                        <xsl:text>','</xsl:text>
                        <xsl:copy-of select="$clientip"/>
                        <xsl:text>');</xsl:text>
                </xsl:if>

		<xsl:text>INSERT INTO salesorderitemdetail (salesorderitem,salesorder,</xsl:text>

		<xsl:if test="product or product_import">
			<xsl:text>product,</xsl:text>
		</xsl:if>

		<xsl:if test="linetext">
			<xsl:text>linetext,</xsl:text>
		</xsl:if>
		<xsl:if test="discount">
			<xsl:text>discount,</xsl:text>
		</xsl:if>
		<xsl:if test="discount = ''">
			<xsl:text>discount_null,</xsl:text>
		</xsl:if>
		<xsl:if test="price">
			<xsl:text>price,</xsl:text>
		</xsl:if>
		<xsl:if test="price = ''">
			<xsl:text>price_null,</xsl:text>
		</xsl:if>
		<xsl:if test="qty">
			<xsl:text>qty,</xsl:text>
		</xsl:if>
		<xsl:if test="@is_deleted">
			<xsl:text>is_deleted,</xsl:text>
		</xsl:if>

		<xsl:text>authuser,clientip) VALUES (</xsl:text>

                <xsl:choose>
                        <xsl:when test="@id">
                                <xsl:text>'</xsl:text>
                                <xsl:value-of select="@id"/>
                                <xsl:text>',</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:text>currval(pg_get_serial_sequence('salesorderitem','id')),</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                        <xsl:when test="$id">
                                <xsl:text>'</xsl:text>
                                <xsl:value-of select="$id"/>
                                <xsl:text>',</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
				<xsl:text>currval(pg_get_serial_sequence('salesorder','id')),</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>

		<xsl:if test="product">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="product"/>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:if test="product_import">
			<xsl:text>(SELECT id FROM product </xsl:text>
			<xsl:text>WHERE import_id='</xsl:text>
			<xsl:value-of select="product_import"/>
			<xsl:text>'),</xsl:text>
		</xsl:if>

		<xsl:if test="linetext">
			<xsl:text>'</xsl:text>
			<xsl:call-template name="cleanQuote">
				<xsl:with-param name="string">
					<xsl:value-of select="linetext"/>
				</xsl:with-param>
			</xsl:call-template>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:if test="discount">
                        <xsl:choose>
                                <xsl:when test="discount = ''">
                                        <xsl:text>NULL,true,</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                        <xsl:text>'</xsl:text>
                                        <xsl:value-of select="discount"/>
                                        <xsl:text>',</xsl:text>
                                </xsl:otherwise>
                        </xsl:choose>
		</xsl:if>

		<xsl:if test="price">
                        <xsl:choose>
                                <xsl:when test="price = ''">
                                        <xsl:text>NULL,true,</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                        <xsl:text>'</xsl:text>
                                        <xsl:value-of select="price"/>
                                        <xsl:text>',</xsl:text>
                                </xsl:otherwise>
                        </xsl:choose>
		</xsl:if>

		<xsl:if test="qty">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="qty"/>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:if test="@is_deleted">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="@is_deleted"/>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:text>'</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>

	</xsl:template>

</xsl:stylesheet>
