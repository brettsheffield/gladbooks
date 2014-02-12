<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="text" disable-output-escaping="yes" />

	<xsl:template match="paymentallocation">
		<xsl:param name="type"/>
		<xsl:text>INSERT INTO </xsl:text>
		<xsl:value-of select="$type"/>
		<xsl:text>paymentallocation();</xsl:text>
	</xsl:template>

</xsl:stylesheet>
