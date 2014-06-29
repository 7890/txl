<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
	xmlns:svg="http://www.w3.org/2000/svg" 
	version="1.0">

  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <!--
//tb/140629
after compacting attributes, all attributes__ elements can be removed
xmlstarlet tr compact_attributes.xsl a.xml | xmlstarlet ed -d "//attributes__"
  -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy>

<!--
<x>
	<attributes__>
		<a name="p1">val1</a>
		<b name="p2">val2</a>
	</attributes__>
	<y/>
</x>

<x p1="val1" pw="val2">
	<y/>
</x>
-->

      <xsl:for-each select="./*[position()=1 and name(.)='attributes__']/a">
        <xsl:variable name="n" select="@name"/>
        <xsl:variable name="v" select="."/>
        <xsl:attribute name="{$n}">
          <xsl:value-of select="$v"/>
        </xsl:attribute>
      </xsl:for-each>

<!--
<x>leaf element</x>
<attributes__>
	<a name="p1">val1</a>
	<b name="p2">val2</a>
</attributes__>
<y/>

<x p1="val1" pw="val2"/>
y/>
-->

      <xsl:for-each select="following-sibling::*[position()=1 and name(.)='attributes__']/a">
        <xsl:variable name="n" select="@name"/>
        <xsl:variable name="v" select="."/>
        <xsl:attribute name="{$n}">
          <xsl:value-of select="$v"/>
        </xsl:attribute>
      </xsl:for-each>

      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
