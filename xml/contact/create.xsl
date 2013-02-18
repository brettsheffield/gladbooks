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

		<xsl:if test="not(@id)">
			<xsl:text>INSERT INTO contact (authuser, clientip) VALUES ('</xsl:text>
			<xsl:copy-of select="$authuser"/>
			<xsl:text>','</xsl:text>
			<xsl:copy-of select="$clientip"/>
			<xsl:text>');</xsl:text>
		</xsl:if>

		<xsl:text>INSERT INTO contactdetail (contact,name,</xsl:text>

		<xsl:if test="line_1">
			<xsl:text>line_1,</xsl:text>
		</xsl:if>
		<xsl:if test="line_2">
			<xsl:text>line_2,</xsl:text>
		</xsl:if>
		<xsl:if test="line_3">
			<xsl:text>line_3,</xsl:text>
		</xsl:if>
		<xsl:if test="town">
			<xsl:text>town,</xsl:text>
		</xsl:if>
		<xsl:if test="county">
			<xsl:text>county,</xsl:text>
		</xsl:if>
		<xsl:if test="country">
			<xsl:text>country,</xsl:text>
		</xsl:if>
		<xsl:if test="postcode">
			<xsl:text>postcode,</xsl:text>
		</xsl:if>
		<xsl:if test="email">
			<xsl:text>email,</xsl:text>
		</xsl:if>
		<xsl:if test="phone">
			<xsl:text>phone,</xsl:text>
		</xsl:if>
		<xsl:if test="phonealt">
			<xsl:text>phonealt,</xsl:text>
		</xsl:if>
		<xsl:if test="mobile">
			<xsl:text>mobile,</xsl:text>
		</xsl:if>
		<xsl:if test="fax">
			<xsl:text>fax,</xsl:text>
		</xsl:if>
		<xsl:if test="is_active">
			<xsl:text>is_active,</xsl:text>
		</xsl:if>
		<xsl:if test="is_deleted">
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
				<xsl:text>currval(pg_get_serial_sequence('contact','id')),'</xsl:text>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:value-of select="name"/>
		<xsl:text>','</xsl:text>

		<xsl:if test="line_1">
			<xsl:value-of select="line_1"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="line_2">
			<xsl:value-of select="line_2"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="line_3">
			<xsl:value-of select="line_3"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="town">
			<xsl:value-of select="town"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="county">
			<xsl:value-of select="county"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="country">
			<xsl:value-of select="country"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="postcode">
			<xsl:value-of select="postcode"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="email">
			<xsl:value-of select="email"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="phone">
			<xsl:value-of select="phone"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="phonealt">
			<xsl:value-of select="phonealt"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="mobile">
			<xsl:value-of select="mobile"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="fax">
			<xsl:value-of select="fax"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="is_active">
			<xsl:value-of select="is_active"/>
			<xsl:text>','</xsl:text>
		</xsl:if>
		<xsl:if test="is_deleted">
			<xsl:value-of select="is_deleted"/>
			<xsl:text>','</xsl:text>
		</xsl:if>

		<xsl:copy-of select="$authuser"/>
		<xsl:text>','</xsl:text>
		<xsl:copy-of select="$clientip"/>
		<xsl:text>');</xsl:text>

		<xsl:if test="organisation">
			<xsl:text>INSERT INTO organisation_contact </xsl:text>
			<xsl:text>(organisation,contact</xsl:text>
			<xsl:if test="organisation/@is_billing">
				<xsl:text>,is_billing</xsl:text>
			</xsl:if>
			<xsl:if test="organisation/@is_shipping">
				<xsl:text>,is_shipping</xsl:text>
			</xsl:if>
			<xsl:text>) </xsl:text>
			<xsl:text>VALUES ('</xsl:text>
			<xsl:value-of select="organisation/@id"/>
			<xsl:text>',currval(pg_get_serial_sequence('contact','id'))</xsl:text>
			<xsl:if test="organisation/@is_billing">
				<xsl:text>,'</xsl:text>
				<xsl:value-of select="organisation/@is_billing"/>
				<xsl:text>'</xsl:text>
			</xsl:if>
			<xsl:if test="organisation/@is_shipping">
				<xsl:text>,'</xsl:text>
				<xsl:value-of select="organisation/@is_shipping"/>
				<xsl:text>'</xsl:text>
			</xsl:if>
			<xsl:text>);</xsl:text>
		</xsl:if>

		<xsl:text>COMMIT;</xsl:text>
	</xsl:template>

</xsl:stylesheet>
