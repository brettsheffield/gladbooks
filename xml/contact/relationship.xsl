<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

        <xsl:template name="relationship">
                <xsl:text>INSERT INTO gladbooks_</xsl:text>
                <xsl:copy-of select="$instance"/>
                <xsl:text>.organisation_contact (organisation, contact, relationship, authuser, clientip) VALUES (</xsl:text>

		<xsl:choose>
			<xsl:when test="@organisation">
				<xsl:text>'</xsl:text>
                		<xsl:value-of select="@organisation"/>
				<xsl:text>'</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>currval(pg_get_serial_sequence('organisation','id'))</xsl:text>
			</xsl:otherwise>
		</xsl:choose>

                <xsl:text>,currval(pg_get_serial_sequence('contact','id')),'</xsl:text>
                <xsl:value-of select="@type"/>
                <xsl:text>','</xsl:text>
                <xsl:copy-of select="$authuser"/>
                <xsl:text>','</xsl:text>
                <xsl:copy-of select="$clientip"/>
                <xsl:text>');</xsl:text>
        </xsl:template>

</xsl:stylesheet>

