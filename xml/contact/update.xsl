<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

        <xsl:variable name="authuser" select="request/authuser" />
        <xsl:variable name="clientip" select="request/clientip" />

        <xsl:template match="request">
                <xsl:apply-templates select="data/contact"/>
        </xsl:template>

	<xsl:template match="contact">
		<xsl:text>BEGIN;</xsl:text>
		<xsl:text>LOCK TABLE contactdetail IN SHARE MODE;</xsl:text>
		<xsl:text>INSERT INTO contactdetail (contact,</xsl:text>
		<xsl:choose>
			<xsl:when test="@name">
				<xsl:text>name,</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="@terms">
				<xsl:text>terms,</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="@billcontact">
				<xsl:text>billcontact,</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="@is_active">
				<xsl:text>is_active,</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="@is_suspended">
				<xsl:text>is_suspended,</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="@is_vatreg">
				<xsl:text>is_vatreg,</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="@vatnumber">
				<xsl:text>vatnumber,</xsl:text>
			</xsl:when>
		</xsl:choose>

		<xsl:text>authuser,clientip) VALUES ('</xsl:text>
		<xsl:value-of select="@id"/>
		<xsl:text>','</xsl:text>

		<xsl:choose>
			<xsl:when test="@name">
				<xsl:value-of select="@name"/>
				<xsl:text>','</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="@terms">
				<xsl:value-of select="@terms"/>
				<xsl:text>','</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="@billcontact">
				<xsl:value-of select="@billcontact"/>
				<xsl:text>','</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="@is_active">
				<xsl:value-of select="@is_active"/>
				<xsl:text>','</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="@is_suspended">
				<xsl:value-of select="@is_suspended"/>
				<xsl:text>','</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="@is_vatreg">
				<xsl:value-of select="@is_vatreg"/>
				<xsl:text>','</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="@vatnumber">
				<xsl:value-of select="@vatnumber"/>
				<xsl:text>','</xsl:text>
			</xsl:when>
		</xsl:choose>

		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>
		<xsl:text>COMMIT;</xsl:text>
	</xsl:template>

</xsl:stylesheet>
