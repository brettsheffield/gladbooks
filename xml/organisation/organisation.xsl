<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:include href="../contact/contact.xsl"/>
	<xsl:include href="../salesorder/salesorder.xsl"/>
	<xsl:include href="../salesinvoice/salesinvoice.xsl"/>

	<xsl:template match="organisation">
		<xsl:call-template name="setSearchPath"/>

                <xsl:if test="not(@id)">
                        <xsl:text>INSERT INTO organisation (</xsl:text>
			<xsl:if test="@orgcode">
				<xsl:text>orgcode, </xsl:text>
			</xsl:if>
                        <xsl:text>authuser, clientip) VALUES ('</xsl:text>
			<xsl:if test="@orgcode">
				<xsl:value-of select="@orgcode"/>
				<xsl:text>','</xsl:text>
			</xsl:if>
                        <xsl:copy-of select="$authuser"/>
                        <xsl:text>','</xsl:text>
                        <xsl:copy-of select="$clientip"/>
                        <xsl:text>');</xsl:text>
                </xsl:if>

                <xsl:apply-templates select="contact"/>
                <xsl:apply-templates select="salesinvoice"/>
                <xsl:apply-templates select="salesorder"/>

		<xsl:text>INSERT INTO organisationdetail (organisation,</xsl:text>
		<xsl:if test="name">
			<xsl:text>name,</xsl:text>
		</xsl:if>
		<xsl:if test="terms">
			<xsl:text>terms,</xsl:text>
		</xsl:if>
		<xsl:if test="billcontact">
			<xsl:text>billcontact,</xsl:text>
		</xsl:if>
		<xsl:if test="@is_active">
			<xsl:text>is_active,</xsl:text>
		</xsl:if>
		<xsl:if test="@is_suspended">
			<xsl:text>is_suspended,</xsl:text>
		</xsl:if>
		<xsl:if test="@is_vatreg">
			<xsl:text>is_vatreg,</xsl:text>
		</xsl:if>
		<xsl:if test="vatnumber">
			<xsl:text>vatnumber,</xsl:text>
		</xsl:if>

		<xsl:text>authuser,clientip) VALUES (</xsl:text>

                <xsl:choose>
                        <xsl:when test="@id">
                                <xsl:text>'</xsl:text>
                                <xsl:value-of select="@id"/>
                                <xsl:text>','</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:text>currval(pg_get_serial_sequence('organisation','id')),'</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>

		<xsl:if test="name">
			<xsl:call-template name="cleanQuote">
				<xsl:with-param name="string">
					<xsl:value-of select="name"/>
				</xsl:with-param>
			</xsl:call-template>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="terms">
			<xsl:value-of select="terms"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="billcontact">
			<xsl:value-of select="billcontact"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="@is_active">
			<xsl:value-of select="@is_active"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="@is_suspended">
			<xsl:value-of select="@is_suspended"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="@is_vatreg">
			<xsl:value-of select="@is_vatreg"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="vatnumber">
			<xsl:call-template name="cleanQuote">
				<xsl:with-param name="string">
					<xsl:value-of select="vatnumber"/>
				</xsl:with-param>
			</xsl:call-template>
			<xsl:text>','</xsl:text>
		</xsl:if>

		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
	</xsl:template>

</xsl:stylesheet>
