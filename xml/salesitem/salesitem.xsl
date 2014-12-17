<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:template match="salesitem">
		<xsl:param name="parentobject"/>
		<xsl:call-template name="setSearchPath"/>

                <xsl:if test="not(@id)">
                        <xsl:text>INSERT INTO </xsl:text>
			<xsl:value-of select="$parentobject"/>
			<xsl:text>item (</xsl:text>
                        <xsl:if test="@uuid">
                                <xsl:text>uuid, </xsl:text>
                        </xsl:if>
			<xsl:text>authuser, clientip) </xsl:text>
			<xsl:text>VALUES (</xsl:text>
                        <xsl:if test="@uuid">
			        <xsl:text>'</xsl:text>
                                <xsl:value-of select="@uuid"/>
                                <xsl:text>',</xsl:text>
                        </xsl:if>
			<xsl:text>'</xsl:text>
                        <xsl:copy-of select="$authuser"/>
                        <xsl:text>','</xsl:text>
                        <xsl:copy-of select="$clientip"/>
                        <xsl:text>');</xsl:text>
                </xsl:if>

		<xsl:text>INSERT INTO </xsl:text>
		<xsl:value-of select="$parentobject"/>
		<xsl:text>itemdetail (</xsl:text>
		<xsl:value-of select="$parentobject"/>
		<xsl:text>item,</xsl:text>
		<xsl:value-of select="$parentobject"/>
		<xsl:text>,</xsl:text>

		<xsl:if test="product or product_import">
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
		<xsl:if test="qty">
			<xsl:text>qty,</xsl:text>
		</xsl:if>
		<xsl:if test="is_deleted">
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
                                <xsl:text>currval(pg_get_serial_sequence('</xsl:text>
				<xsl:value-of select="$parentobject"/>
				<xsl:text>item','id')),</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                        <xsl:when test="$id">
                                <xsl:text>'</xsl:text>
                                <xsl:value-of select="$id"/>
                                <xsl:text>',</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
				<xsl:text>currval(pg_get_serial_sequence('</xsl:text>
				<xsl:value-of select="$parentobject"/>
				<xsl:text>','id')),</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>

		<xsl:if test="product">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="product"/>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:if test="product_import">
		        <xsl:text>'</xsl:text>
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
		        <xsl:text>'</xsl:text>
			<xsl:value-of select="discount"/>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:if test="price">
		        <xsl:text>'</xsl:text>
			<xsl:value-of select="price"/>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:if test="qty">
		        <xsl:text>'</xsl:text>
			<xsl:value-of select="qty"/>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:if test="is_deleted">
		        <xsl:text>'</xsl:text>
			<xsl:value-of select="is_deleted"/>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:text>'</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>

	</xsl:template>

</xsl:stylesheet>
