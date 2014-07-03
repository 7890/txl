<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="text"/>
  <xsl:variable name="nl" select="'&#10;'"/>
  <xsl:strip-space elements="*"/>
  <!-- //tb/140703 -->
  <!-- convert xml to txl -->
  <!-- this stylesheet is not complete -->
  <!-- no mixed content -->
  <!-- no namespaces -->

  <xsl:template match="/">
    <!-- handle nodes before root element -->
    <xsl:call-template name="pre_root_node"/>
    <!-- aplly templates -->

    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
    <!-- handle nodes after root element -->
    <xsl:call-template name="post_root_node"/>
  </xsl:template>

  <xsl:template name="pre_root_node">
    <!-- match nodes before root element -->
    <xsl:for-each select=" /comment()[not(parent::*) and not(preceding-sibling::*)]  | /processing-instruction()[not(parent::*) and not(preceding-sibling::*)] ">
      <!-- apply templates for comments and processing-intructions -->
      <xsl:call-template name="comment">
        <xsl:with-param name="text" select="."/>
      </xsl:call-template>
      <xsl:call-template name="processing-instruction"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="post_root_node">
    <!-- match nodes after root element -->
    <xsl:for-each select=" /comment()[not(parent::*) and not(following-sibling::*)] | /processing-instruction()[not(parent::*) and not(following-sibling::*)]">
      <!-- apply templates for comments and processing-intructions -->
      <xsl:call-template name="comment">
        <xsl:with-param name="text" select="."/>
      </xsl:call-template>
      <xsl:call-template name="processing-instruction"/>
    </xsl:for-each>
  </xsl:template>

  <!-- comments, handle multiline -->
  <xsl:template name="comment">
    <xsl:param name="text"/>
    <!-- be sure it's a comment node -->
    <xsl:if test="self::comment()">
      <xsl:choose>
        <xsl:when test="contains($text,$nl)">
          <!-- output //comment  -->
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
          <!-- output //comment  -->
          <xsl:value-of select="concat('//',$text,$nl)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template name="processing-instruction">
    <!-- be sure it's a comment node -->
    <xsl:if test="self::processing-instruction()">
      <!-- output ?my processing="instr" b="c" -->
      <xsl:value-of select="concat('?',name(.),' ',.,$nl)"/>
    </xsl:if>
  </xsl:template>

  <!-- main rule ============================== -->
  <xsl:template match="@*|node()">
    <xsl:choose>
      <!-- filter out pre/post root comments and processing-instructions -->
      <xsl:when test=" (  (   self::comment() | self::processing-instruction()  )  [   not(parent::*) and not(preceding-sibling::*)  ] )  |  (  (   self::comment() | self::processing-instruction()  )  [   not(parent::*) and not(following-sibling::*)  ] ) ">
      </xsl:when>
      <xsl:otherwise>
        <!-- nested, has children ============= -->
        <xsl:if test="*">

<!--
<xsl:variable name="all_mixed_content_text">
<xsl:for-each select="text()">
<xsl:value-of select="."/>
</xsl:for-each>
</xsl:variable>
    <xsl:call-template name="text">
      <xsl:with-param name="text" select="$all_mixed_content_text"/>
      <xsl:with-param name="line_number" select="1"/>
      <xsl:with-param name="style" select="1"/>
    </xsl:call-template>
-->
          <xsl:choose>
            <!-- handle root node specially -->
            <xsl:when test="not(ancestor::*)">
              <xsl:value-of select="concat(name(.),'::',$nl)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('=',name(.),$nl)"/>
            </xsl:otherwise>
          </xsl:choose>

          <!-- handle all attributes -->
          <xsl:for-each select="./@*">
            <xsl:value-of select="concat(name(.),' ',.,$nl)"/>
          </xsl:for-each>
          <!-- handle sub nodes -->
          <xsl:apply-templates select="@*|node()"/>

          <xsl:value-of select="concat('..//end ',name(.),$nl)"/>
        </xsl:if>

        <!-- leaf ========================== -->
        <xsl:if test="not(*)">
          <!-- no comments in leafs !!-->
          <xsl:choose>
            <xsl:when test="self::comment()">
              <xsl:call-template name="comment">
                <xsl:with-param name="text" select="."/>
              </xsl:call-template>
            </xsl:when>

            <!-- special case empty root node (leaf) -->
	    <xsl:when test="not(ancestor::*)">
              <xsl:value-of select="concat(name(.),'::',$nl)"/>
              <!-- handle all attributes -->
              <xsl:for-each select="./@*">
                <xsl:value-of select="concat(name(.),' ',.,$nl)"/>
              </xsl:for-each>
              <xsl:value-of select="concat(':://end ',name(.),$nl,$nl)"/>
            </xsl:when>

            <xsl:otherwise>
<!--
<xsl:value-of select="concat('TEST ',name(.))"/>
-->
              <!-- handle .leaf and leaf text content -->
              <xsl:call-template name="text">
                <xsl:with-param name="text" select="text()"/>
                <xsl:with-param name="line_number" select="1"/>
                <xsl:with-param name="style" select="2"/>
              </xsl:call-template>
              <!-- handle all attributes -->
              <xsl:for-each select="./@*">
                <xsl:value-of select="concat(name(.),' ',.,$nl)"/>
              </xsl:for-each>

            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ===================================================== -->
  <xsl:template name="text">
    <xsl:param name="text"/>
    <xsl:param name="line_number"/>
    <!--style 1: nested  style 2: leaf -->
    <xsl:param name="style"/>
    <xsl:variable name="cmd">
      <xsl:if test="$style=1">=</xsl:if>
      <xsl:if test="$style=2">.</xsl:if>
    </xsl:variable>
    <xsl:choose>
      <!-- text has at least one newline  -->
      <xsl:when test="contains($text,$nl)">
        <!-- <xsl:value-of select="$line_number"/>-->
        <xsl:choose>
          <xsl:when test="$line_number=1">
            <!-- .leaf first line\\ -->
            <xsl:value-of select="concat($cmd,name(.),' ')"/>
            <xsl:value-of select="substring-before($text,$nl)"/>
            <xsl:value-of select="concat('\\',$nl)"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- | a line or lastline (closing tag not on same line) -->
            <xsl:value-of select="'|'"/>
            <xsl:value-of select="substring-before($text,$nl)"/>
            <xsl:value-of select="$nl"/>
          </xsl:otherwise>
        </xsl:choose>
        <!-- recursive call until no more newlines -->
        <xsl:call-template name="text">
          <xsl:with-param name="text">
            <xsl:value-of select="substring-after($text,$nl)"/>
          </xsl:with-param>
          <xsl:with-param name="line_number" select="$line_number+1"/>
          <xsl:with-param name="style" select="$style"/>
        </xsl:call-template>
      </xsl:when>

      <!-- no more newline, finished splitting up  -->
      <xsl:when test="$text!=''">
          <xsl:choose>
            <xsl:when test="$line_number=1">
              <!-- .leaf single line content -->
              <xsl:value-of select="concat($cmd,name(.),' ')"/>
              <xsl:value-of select="concat($text,$nl)"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- | last line content with closing tag on same line\\. -->
              <xsl:value-of select="concat('|',$text,'\\.',$nl)"/>
            </xsl:otherwise>
          </xsl:choose>
      </xsl:when>

      <xsl:otherwise>
            <xsl:if test="$line_number=1">
               <xsl:value-of select="concat($cmd,name(.),$nl)"/>
            </xsl:if>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <!-- override implicit rule http://lenzconsulting.com/how-xslt-works/ -->
  <xsl:template match="text() | @*"/>

</xsl:stylesheet>
