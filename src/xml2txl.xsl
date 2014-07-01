<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output method="text"/>
  <xsl:variable name="nl" select="'&#10;'"/>
  <xsl:strip-space elements="*"/>

  <!-- //tb/140701 -->
  <!-- convert xml to txl -->
  <!-- this stylesheet is not complete -->
  <!--  -->
  <!-- comment order / place not kept atm!! -->

  <!-- main rule -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!--  root  -->
  <xsl:template match="/*[1]">
    <xsl:for-each select="comment()">
      <xsl:call-template name="comment">
        <xsl:with-param name="text" select="."/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:value-of select="concat(name(.),'::',$nl)"/>
    <xsl:for-each select="./@*">
      <xsl:value-of select="concat(name(.),' ',.,$nl)"/>
    </xsl:for-each>
    <xsl:apply-templates select="@*|node()"/>
    <xsl:value-of select="concat('..//end ',name(.),$nl,$nl)"/>
  </xsl:template>

  <!-- leaf -->
  <xsl:template match="*[not(*)]">
    <xsl:for-each select="preceding-sibling::comment()">
      <xsl:call-template name="comment">
        <xsl:with-param name="text" select="."/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:value-of select="concat('.',name(.),' ',.,$nl)"/>
    <xsl:for-each select="./@*">
      <xsl:value-of select="concat(name(.),' ',.,$nl)"/>
    </xsl:for-each>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:template>

  <!-- nested -->
  <xsl:template match="/*//*[*]">
    <xsl:value-of select="concat('=',name(.),$nl)"/>
    <xsl:for-each select="./@*">
      <xsl:value-of select="concat(name(.),' ',.,$nl)"/>
    </xsl:for-each>
    <xsl:apply-templates select="@*|node()"/>
    <xsl:value-of select="concat('..//end ',name(.),$nl)"/>
  </xsl:template>

  <!-- pre multiline text -->
  <xsl:template match="//pre">
    <xsl:call-template name="pre">
      <xsl:with-param name="text" select="."/>
      <xsl:with-param name="line_number" select="1"/>
    </xsl:call-template>
  </xsl:template>

  <!-- pre test -->
  <xsl:template name="pre">
    <xsl:param name="text"/>
    <xsl:param name="line_number"/>
    <xsl:choose>
      <!-- text has at least one newline  -->
      <xsl:when test="contains($text,$nl)">
        <!-- <xsl:value-of select="$line_number"/>-->
        <xsl:choose>
          <xsl:when test="$line_number=1">
            <xsl:value-of select="'.pre '"/>
            <xsl:value-of select="substring-before($text,$nl)"/>
            <xsl:value-of select="concat('\\',$nl)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="'|'"/>
            <xsl:value-of select="substring-before($text,$nl)"/>
            <xsl:value-of select="$nl"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="pre">
          <xsl:with-param name="text">
            <xsl:value-of select="substring-after($text,$nl)"/>
          </xsl:with-param>
          <xsl:with-param name="line_number" select="$line_number+1"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <!-- no more newline, finished splitting up  -->
        <xsl:if test="$text!=''">
          <xsl:value-of select="concat('|',$text,'\\.',$nl)"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- comments -->
  <xsl:template name="comment">
    <xsl:param name="text"/>
    <xsl:choose>
      <xsl:when test="contains($text,$nl)">
        <xsl:value-of select="'//'"/>
        <xsl:value-of select="substring-before($text,$nl)"/>
        <xsl:value-of select="$nl"/>
        <xsl:call-template name="comment">
          <xsl:with-param name="text">
            <xsl:value-of select="substring-after($text,$nl)"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('//',$text,$nl)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- override implicit rule http://lenzconsulting.com/how-xslt-works/ -->
  <xsl:template match="text() | @*"/>

</xsl:stylesheet>
