<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:include href="../salesitem/salesitem.xsl"/>

	<xsl:template match="purchaseinvoice">
		<xsl:call-template name="setSearchPath"/>

                <xsl:if test="not($id)">
                        <xsl:text>INSERT INTO purchaseinvoice (organisation, authuser, clientip) VALUES (</xsl:text>
			<xsl:choose>
				<xsl:when test="organisation">
					<xsl:text>'</xsl:text>
					<xsl:value-of select="organisation"/>
					<xsl:text>','</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>currval(pg_get_serial_sequence('organisation','id')),'</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
                        <xsl:copy-of select="$authuser"/>
                        <xsl:text>','</xsl:text>
                        <xsl:copy-of select="$clientip"/>
                        <xsl:text>');</xsl:text>
                </xsl:if>

		<xsl:text>INSERT INTO purchaseinvoicedetail (</xsl:text>
		<xsl:text>purchaseinvoice,purchaseorder,</xsl:text>

		<xsl:if test="period">
			<xsl:text>period,</xsl:text>
		</xsl:if>
		<xsl:if test="ref">
			<xsl:text>ref,</xsl:text>
		</xsl:if>
		<xsl:if test="ponumber">
			<xsl:text>ponumber,</xsl:text>
		</xsl:if>
		<xsl:if test="description">
			<xsl:text>description,</xsl:text>
		</xsl:if>
		<xsl:if test="taxpoint">
			<xsl:text>taxpoint,</xsl:text>
		</xsl:if>
		<xsl:if test="endpoint">
			<xsl:text>endpoint,</xsl:text>
		</xsl:if>
		<xsl:if test="issued">
			<xsl:text>issued,</xsl:text>
		</xsl:if>
		<xsl:if test="due">
			<xsl:text>due,</xsl:text>
		</xsl:if>
		<xsl:if test="subtotal">
			<xsl:text>subtotal,</xsl:text>
		</xsl:if>
		<xsl:if test="tax">
			<xsl:text>tax,</xsl:text>
		</xsl:if>
		<xsl:if test="total">
			<xsl:text>total,</xsl:text>
		</xsl:if>
		<xsl:if test="pdf">
			<xsl:text>pdf,</xsl:text>
		</xsl:if>
		<xsl:if test="emailtext">
			<xsl:text>emailtext,</xsl:text>
		</xsl:if>

		<xsl:text>authuser,clientip) VALUES (</xsl:text>

                <xsl:choose>
                        <xsl:when test="$id">
                                <xsl:text>'</xsl:text>
                                <xsl:value-of select="$id"/>
                                <xsl:text>',</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:text>currval(pg_get_serial_sequence('purchaseinvoice','id')),</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>

		<xsl:choose>
			<xsl:when test="purchaseorder">
                                <xsl:text>'</xsl:text>
                                <xsl:value-of select="@id"/>
                                <xsl:text>','</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
				<xsl:text>NULL,</xsl:text>
                        </xsl:otherwise>
		</xsl:choose>

		<xsl:if test="period">
                        <xsl:text>'</xsl:text>
			<xsl:value-of select="period"/>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:if test="ref">
                        <xsl:text>'</xsl:text>
			<xsl:call-template name="cleanQuote">
				<xsl:with-param name="string">
					<xsl:value-of select="ref"/>
				</xsl:with-param>
			</xsl:call-template>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:if test="ponumber">
                        <xsl:text>'</xsl:text>
			<xsl:call-template name="cleanQuote">
				<xsl:with-param name="string">
					<xsl:value-of select="ponumber"/>
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

		<xsl:if test="taxpoint">
                        <xsl:text>'</xsl:text>
			<xsl:value-of select="taxpoint"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="endpoint">
                        <xsl:text>'</xsl:text>
			<xsl:value-of select="endpoint"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="issued">
                        <xsl:text>'</xsl:text>
			<xsl:value-of select="issued"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="due">
                        <xsl:text>'</xsl:text>
			<xsl:value-of select="due"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="subtotal">
                        <xsl:text>'</xsl:text>
			<xsl:value-of select="subtotal"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="tax">
                        <xsl:text>'</xsl:text>
			<xsl:value-of select="tax"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="total">
                        <xsl:text>'</xsl:text>
			<xsl:value-of select="total"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="pdf">
                        <xsl:text>'</xsl:text>
			<xsl:call-template name="cleanQuote">
				<xsl:with-param name="string">
					<xsl:value-of select="pdf"/>
				</xsl:with-param>
			</xsl:call-template>
			<xsl:text>',</xsl:text>
		</xsl:if>
		<xsl:if test="emailtext">
                        <xsl:text>'</xsl:text>
			<xsl:call-template name="emailtext">
				<xsl:with-param name="string">
					<xsl:value-of select="emailtext"/>
				</xsl:with-param>
			</xsl:call-template>
			<xsl:text>',</xsl:text>
		</xsl:if>

		<xsl:text>'</xsl:text>
		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>

		<!-- add any salesitems -->
		<xsl:apply-templates select="salesitem">
			<xsl:with-param name="parentobject" select="'purchaseinvoice'" />
		</xsl:apply-templates>
                
                <!-- post this now? -->
                <xsl:if test="@post">
                        <xsl:text>SELECT post_purchaseinvoice(</xsl:text>
                        <xsl:choose>
                                <xsl:when test="$id">
                                        <xsl:text>'</xsl:text>
                                        <xsl:value-of select="$id"/>
                                        <xsl:text>'</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                        <xsl:text>currval(pg_get_serial_sequence('purchaseinvoice','id'))</xsl:text>
                                </xsl:otherwise>
                        </xsl:choose>
		        <xsl:text>);</xsl:text>
                </xsl:if>
	</xsl:template>

</xsl:stylesheet>
