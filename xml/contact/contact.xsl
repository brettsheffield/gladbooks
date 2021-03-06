<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:include href="relationship.xsl"/>

	<xsl:template match="contact">
		<xsl:call-template name="setSearchPath"/>

                <xsl:if test="not($id)">
                        <xsl:text>INSERT INTO contact (authuser, clientip) VALUES ('</xsl:text>
                        <xsl:copy-of select="$authuser"/>
                        <xsl:text>','</xsl:text>
                        <xsl:copy-of select="$clientip"/>
                        <xsl:text>');</xsl:text>
                </xsl:if>

                <xsl:text>INSERT INTO contactdetail (contact,</xsl:text>
                <xsl:if test="name">
                        <xsl:text>name,</xsl:text>
                </xsl:if>
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
                        <xsl:when test="$id">
                                <xsl:text>'</xsl:text>
                                <xsl:value-of select="$id"/>
                                <xsl:text>','</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:text>currval(pg_get_serial_sequence('contact','id')),'</xsl:text>
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

                <xsl:if test="line_1">
                        <xsl:call-template name="cleanQuote">
                                <xsl:with-param name="string">
                                        <xsl:value-of select="line_1"/>
                                </xsl:with-param>
                        </xsl:call-template>
                        <xsl:text>','</xsl:text>
                </xsl:if>
                <xsl:if test="line_2">
                        <xsl:call-template name="cleanQuote">
                                <xsl:with-param name="string">
                                        <xsl:value-of select="line_2"/>
                                </xsl:with-param>
                        </xsl:call-template>
                        <xsl:text>','</xsl:text>
                </xsl:if>
                <xsl:if test="line_3">
                        <xsl:call-template name="cleanQuote">
                                <xsl:with-param name="string">
                                        <xsl:value-of select="line_3"/>
                                </xsl:with-param>
                        </xsl:call-template>
                        <xsl:text>','</xsl:text>
                </xsl:if>
                <xsl:if test="town">
                        <xsl:call-template name="cleanQuote">
                                <xsl:with-param name="string">
                                        <xsl:value-of select="town"/>
                                </xsl:with-param>
                        </xsl:call-template>
                        <xsl:text>','</xsl:text>
                </xsl:if>
                <xsl:if test="county">
                        <xsl:call-template name="cleanQuote">
                                <xsl:with-param name="string">
                                        <xsl:value-of select="county"/>
                                </xsl:with-param>
                        </xsl:call-template>
                        <xsl:text>','</xsl:text>
                </xsl:if>
                <xsl:if test="country">
                        <xsl:call-template name="cleanQuote">
                                <xsl:with-param name="string">
                                        <xsl:value-of select="country"/>
                                </xsl:with-param>
                        </xsl:call-template>
                        <xsl:text>','</xsl:text>
                </xsl:if>
                <xsl:if test="postcode">
                        <xsl:call-template name="cleanQuote">
                                <xsl:with-param name="string">
                                        <xsl:value-of select="postcode"/>
                                </xsl:with-param>
                        </xsl:call-template>
                        <xsl:text>','</xsl:text>
                </xsl:if>
                <xsl:if test="email">
                        <xsl:call-template name="cleanQuote">
                                <xsl:with-param name="string">
                                        <xsl:value-of select="email"/>
                                </xsl:with-param>
                        </xsl:call-template>
                        <xsl:text>','</xsl:text>
                </xsl:if>
                <xsl:if test="phone">
                        <xsl:call-template name="cleanQuote">
                                <xsl:with-param name="string">
                                        <xsl:value-of select="phone"/>
                                </xsl:with-param>
                        </xsl:call-template>
                        <xsl:text>','</xsl:text>
                </xsl:if>
                <xsl:if test="phonealt">
                        <xsl:call-template name="cleanQuote">
                                <xsl:with-param name="string">
                                        <xsl:value-of select="phonealt"/>
                                </xsl:with-param>
                        </xsl:call-template>
                        <xsl:text>','</xsl:text>
                </xsl:if>
                <xsl:if test="mobile">
                        <xsl:call-template name="cleanQuote">
                                <xsl:with-param name="string">
                                        <xsl:value-of select="mobile"/>
                                </xsl:with-param>
                        </xsl:call-template>
                        <xsl:text>','</xsl:text>
                </xsl:if>
                <xsl:if test="fax">
                        <xsl:call-template name="cleanQuote">
                                <xsl:with-param name="string">
                                        <xsl:value-of select="fax"/>
                                </xsl:with-param>
                        </xsl:call-template>
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

                <xsl:for-each select="relationship">
                        <xsl:call-template name="relationship"/>
                </xsl:for-each>
	</xsl:template>

</xsl:stylesheet>
