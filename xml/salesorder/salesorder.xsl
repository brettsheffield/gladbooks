<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:include href="../salesorderitem/salesorderitem.xsl"/>
	<xsl:include href="../salesinvoice/salesinvoice.xsl"/>

	<xsl:template match="salesorder">
		<xsl:call-template name="setSearchPath"/>

                <xsl:if test="not($id)">
                        <xsl:text>INSERT INTO salesorder (organisation, authuser, clientip) VALUES (</xsl:text>
			<xsl:choose>
				<xsl:when test="organisation">
					<xsl:text>'</xsl:text>
					<xsl:value-of select="organisation"/>
					<xsl:text>',</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>currval(pg_get_serial_sequence('organisation','id')),</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
                        <xsl:text>'</xsl:text>
                        <xsl:copy-of select="$authuser"/>
                        <xsl:text>','</xsl:text>
                        <xsl:copy-of select="$clientip"/>
                        <xsl:text>');</xsl:text>
                </xsl:if>

		<xsl:text>INSERT INTO salesorderdetail (salesorder,</xsl:text>
		<xsl:if test="quotenumber">
			<xsl:text>quotenumber,</xsl:text>
		</xsl:if>
		<xsl:if test="ponumber">
			<xsl:text>ponumber,</xsl:text>
		</xsl:if>
		<xsl:if test="description">
			<xsl:text>description,</xsl:text>
		</xsl:if>
		<xsl:if test="cycle">
			<xsl:text>cycle,</xsl:text>
		</xsl:if>
		<xsl:if test="start_date">
			<xsl:text>start_date,</xsl:text>
		</xsl:if>
                <xsl:if test="start_date = ''">
                        <xsl:text>start_date_null,</xsl:text>
                </xsl:if>
		<xsl:if test="end_date">
			<xsl:text>end_date,</xsl:text>
		</xsl:if>
                <xsl:if test="end_date = ''">
                        <xsl:text>end_date_null,</xsl:text>
                </xsl:if>
		<xsl:if test="@is_open">
			<xsl:text>is_open,</xsl:text>
		</xsl:if>
		<xsl:if test="@is_deleted">
			<xsl:text>is_deleted,</xsl:text>
		</xsl:if>

		<xsl:text>authuser,clientip) VALUES (</xsl:text>

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

		<xsl:if test="quotenumber">
			<xsl:text>'</xsl:text>
			<xsl:call-template name="cleanQuote">
				<xsl:with-param name="string">
					<xsl:value-of select="quotenumber"/>
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

		<xsl:if test="cycle">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="cycle"/>
			<xsl:text>',</xsl:text>
		</xsl:if>
                <xsl:if test="start_date">
                        <xsl:choose>
                                <xsl:when test="start_date != ''">
                                        <xsl:text>'</xsl:text>
                                        <xsl:value-of select="start_date"/>
                                        <xsl:text>',</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                        <xsl:text>NULL,true,</xsl:text>
                                </xsl:otherwise>
                        </xsl:choose>
                </xsl:if>
                <xsl:if test="end_date">
                        <xsl:choose>
                                <xsl:when test="end_date != ''">
                                        <xsl:text>'</xsl:text>
                                        <xsl:value-of select="end_date"/>
                                        <xsl:text>',</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                        <xsl:text>NULL,true,</xsl:text>
                                </xsl:otherwise>
                        </xsl:choose>
                </xsl:if>
		<xsl:if test="@is_open">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="@is_open"/>
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

		<!-- add any salesorderitems -->
		<xsl:apply-templates select="salesorderitem"/>

		<!-- add any salesinvoices -->
		<xsl:apply-templates select="salesinvoice"/>
	</xsl:template>

</xsl:stylesheet>
