<xsl:stylesheet
   version="2.0"
   xmlns:d="data:,dpc"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   exclude-result-prefixes="d xs">

<!-- 
 HTML Parser in XSLT2 Copyright 2004 David Carlisle 
 Distribution, use and modification of this code permited so long as original is cited.
-->

<!-- $Id: htmlparse.xsl,v 1.9 2004-08-06 20:35:55 David Exp $-->

<xsl:variable name="d:attr"
   select="'([a-zA-Z:\-]+)\s*(=\s*(&quot;[^&quot;]*&quot;|''[^'']*''|[a-zA-Z0-9]+))?\s*'"/>

<xsl:variable name="d:elem"
   select="'([a-zA-Z][A-Za-z0-9:\-]*)'"/>

<xsl:variable name="d:comment"
   select="'&lt;!\-\-[^\-]*(\-[^\-]+)*\-\->'"/>

<xsl:variable name="d:pi"
   select="'&lt;\?[a-zA-Z0-9]+[^>]*>'"/>

<xsl:variable name="d:doctype"
   select="'&lt;!D[^\[&lt;>]*(\[[^\]]*\])?>'"/>

<xsl:variable name="d:cdata"
   select="'&lt;!\[CDATA(.|\s)*\]\]>'"/>


<xsl:function name="d:htmlparse">
 <xsl:param name="s"/>
 <xsl:variable name="x">
  <xsl:analyze-string select="replace($s,'&#13;&#10;','&#10;')"
     regex="&lt;(/?){$d:elem}\s*(({$d:attr})*)(/?)>|{$d:comment}|{$d:pi}|{$d:doctype}|{$d:cdata}">
    <xsl:matching-substring>
      <xsl:choose>
      <xsl:when test="starts-with(.,'&lt;![CDATA')">
        <xsl:value-of select="substring(.,10,string-length(.)-13)"/>
      </xsl:when>
      <xsl:when test="starts-with(.,'&lt;!D')"></xsl:when>
      <xsl:when test="starts-with(.,'&lt;!-')">
        <comment>
          <xsl:value-of select="substring(.,5,string-length(.)-7)"/>
        </comment>
      </xsl:when>
      <xsl:when test="starts-with(.,'&lt;?')">
        <pi>
          <xsl:value-of select="normalize-space((substring(.,3,string-length(.)-4)))"/>
        </pi>
      </xsl:when>
      <xsl:when test="(regex-group(1)='/')">
        <end name="{lower-case(regex-group(2))}"/>
      </xsl:when>
      <xsl:otherwise>
        <start name="{lower-case(regex-group(2))}">
          <attrib>
            <xsl:analyze-string regex="{$d:attr}" select="regex-group(3)">
            <xsl:matching-substring>
              <xsl:choose>
              <xsl:when test="starts-with(regex-group(1),'xmlns')">
                <!-- prototype support for embedded (MS-style) namespaced XML inside html -->
                 <d:ns>
                   <xsl:namespace name="{substring-after(regex-group(1),'xmlns:')}"
                                  select="d:chars(substring(regex-group(3),2,string-length(regex-group(3))-2))"/>
                 </d:ns>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute name="{lower-case(regex-group(1))}">
                  <xsl:choose>
                  <xsl:when test="starts-with(regex-group(3),'&quot;')">
                    <xsl:value-of select="d:chars(substring(regex-group(3),2,string-length(regex-group(3))-2))"/>
                  </xsl:when>
                  <xsl:when test="starts-with(regex-group(3),'''')">
                    <xsl:value-of select="d:chars(substring(regex-group(3),2,string-length(regex-group(3))-2))"/>
                  </xsl:when>
                  <xsl:when test="string(regex-group(2))">
                    <xsl:value-of select="regex-group(3)"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="regex-group(1)"/>
                  </xsl:otherwise>
                  </xsl:choose>
                </xsl:attribute>
              </xsl:otherwise>
              </xsl:choose>
            </xsl:matching-substring>
            </xsl:analyze-string>
          </attrib>
        </start>
        <xsl:if test="regex-group(8)='/'">
        <end name="{lower-case(regex-group(2))}"/>
        </xsl:if>
      </xsl:otherwise>
      </xsl:choose>
    </xsl:matching-substring>
    <xsl:non-matching-substring>
      <xsl:value-of select="."/>
    </xsl:non-matching-substring>
  </xsl:analyze-string>
  </xsl:variable>
  
  
  <xsl:variable name="y">
  <xsl:apply-templates mode="d:html" select="$x/node()[1]"/>
  </xsl:variable>
  
  <xsl:variable name="j">
    <x xmlns="http://www.w3.org/1999/xhtml"/> 
  </xsl:variable>

  <xsl:variable name="z">
  <xsl:apply-templates mode="d:tree" select="$y/node()[1]">
    <xsl:with-param name="ns" select="$j/*/namespace::*[name()='']"/>
   </xsl:apply-templates>
  </xsl:variable>
  
  <!--
   <xsl:copy-of select="$x"/>
  ===
  <xsl:copy-of select="$y"/>
  ===
 -->

  <xsl:copy-of select="$z"/>
  
</xsl:function>

<xsl:function name="d:chars">
 <xsl:param name="s"/>
 <xsl:value-of>
  <xsl:analyze-string select="$s" regex="&amp;(#?)(x?)([0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);">
  <xsl:matching-substring>
  <xsl:choose>
  <xsl:when test="regex-group(2)='x'">
   <xsl:value-of select="codepoints-to-string(
         d:hex(
           for $i in string-to-codepoints(upper-case(regex-group(3)))
           return if ($i &gt; 64) then $i - 55 else $i - 48))"/>
  </xsl:when>
  <xsl:when test="regex-group(1)='#'">
    <xsl:value-of select="codepoints-to-string(xs:integer(regex-group(3)))"/>
  </xsl:when>
  <xsl:when test="$d:ents/key('d:ents',regex-group(3))">
    <xsl:value-of select="$d:ents/key('d:ents',regex-group(3))"/>
  </xsl:when>
  <xsl:otherwise>
  <xsl:message>htmlparse: Unknown entity: <xsl:value-of select="regex-group(3)"/></xsl:message>
  <xsl:text>&amp;</xsl:text>
  <xsl:value-of select="regex-group(3)"/>
  <xsl:text>;</xsl:text>
  </xsl:otherwise>
  </xsl:choose>
  </xsl:matching-substring>
  <xsl:non-matching-substring>
   <xsl:value-of select="."/>
  </xsl:non-matching-substring>
  </xsl:analyze-string>
 </xsl:value-of>
</xsl:function>


<xsl:function name="d:hex">
<xsl:param name="x"/>
  <xsl:value-of
    select="if (empty($x)) then 0 else ($x[last()] + 16* d:hex($x[position()!=last()]))"/>
</xsl:function>

<xsl:template mode="d:cdata"  match="text()">
<xsl:param name="s" select="()"/>
  <xsl:value-of select="."/>
  <xsl:apply-templates mode="#current" select="following-sibling::node()[1]">
    <xsl:with-param name="s" select="$s"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template mode="d:html"  match="text()">
<xsl:param name="s" select="()"/>
  <xsl:value-of select="d:chars(.)"/>
  <xsl:apply-templates mode="#current" select="following-sibling::node()[1]">
    <xsl:with-param name="s" select="$s"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template mode="d:html"  match="comment|pi">
<xsl:param name="s" select="()"/>
  <xsl:copy-of select="."/>
  <xsl:apply-templates mode="#current" select="following-sibling::node()[1]">
    <xsl:with-param name="s" select="$s"/>
  </xsl:apply-templates>
</xsl:template>


<xsl:template mode="d:html" match="start[@name=('script','style')]">
<xsl:param name="s" select="()"/>
  <start name="{@name}" s="{$s}">
   <xsl:copy-of select="attrib"/>
  </start>
  <xsl:apply-templates mode="d:cdata" select="following-sibling::node()[1]"/>
  <end name="{@name}" s="{$s}"/>
  <xsl:apply-templates mode="d:html" select="following-sibling::end[@name=current()/@name][1]/following-sibling::node()[1]">
   <xsl:with-param  name="s" select="$s"/>
  </xsl:apply-templates>
</xsl:template>



<xsl:template mode="d:cdata" match="start">
   <xsl:text>&lt;</xsl:text>
  <xsl:value-of select="(@name,.)"/>
  <xsl:text>&gt;</xsl:text>
  <xsl:apply-templates mode="d:cdata" select="following-sibling::node()[1]"/>
</xsl:template>

<xsl:template mode="d:html" match="start">
<xsl:param name="s" select="()"/>
  <start name="{@name}" s="{$s}">
   <xsl:copy-of select="attrib"/>
  </start>
  <xsl:apply-templates mode="d:html"
  select="following-sibling::node()[1]">
   <xsl:with-param  name="s" select="(string(@name),$s)"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template mode="d:html" match="start[@name=('br','hr','basefont','area','link','img','param','input','col','frame','isindex','base','meta')]">
<xsl:param name="s" select="()"/>
  <start name="{@name}" s="{$s}">
   <xsl:copy-of select="attrib"/>
  </start>
  <end name="{@name}" s="{$s}"/>
  <xsl:apply-templates mode="d:html"
  select="following-sibling::node()[1]">
   <xsl:with-param  name="s" select="$s"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:variable name="d:lists" select="('ul','ol','dl')"/>
<xsl:variable name="d:listitems" select="('li','dt','dd')"/>

<xsl:template mode="d:html" match="start[@name=$d:listitems]">
<xsl:param name="s" select="()"/>
  <xsl:choose>
  <xsl:when test="not($d:lists=$s) or $d:lists=$s[1]">
  <start name="{@name}" s="{$s}">
   <xsl:copy-of select="attrib"/>
  </start>
  <xsl:apply-templates mode="d:html"
  select="following-sibling::node()[1]">
   <xsl:with-param  name="s" select="(string(@name),$s)"/>
  </xsl:apply-templates>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="d:end">
      <xsl:with-param name="s" select="$s"/>
      <xsl:with-param name="n" select="$s[1]"/>
      <xsl:with-param name="next" select="."/>
    </xsl:call-template>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>



<xsl:template mode="d:html" match="start[@name='td']">
<xsl:param name="s" select="()"/>
  <xsl:choose>
  <xsl:when test="not('tr'=$s) or 'tr'=$s[1]">
  <start name="{@name}" s="{$s}">
   <xsl:copy-of select="attrib"/>
  </start>
  <xsl:apply-templates mode="d:html"
  select="following-sibling::node()[1]">
   <xsl:with-param  name="s" select="(string(@name),$s)"/>
  </xsl:apply-templates>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="d:end">
      <xsl:with-param name="s" select="$s"/>
      <xsl:with-param name="n" select="$s[1]"/>
      <xsl:with-param name="next" select="."/>
    </xsl:call-template>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template mode="d:html" match="start[@name='p']">
<xsl:param name="s" select="()"/>
  <xsl:choose>
  <xsl:when test="not('p'=$s)">
  <start name="{@name}" s="{$s}">
   <xsl:copy-of select="attrib"/>
  </start>
  <xsl:apply-templates mode="d:html"
  select="following-sibling::node()[1]">
   <xsl:with-param  name="s" select="(string(@name),$s)"/>
  </xsl:apply-templates>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="d:end">
      <xsl:with-param name="s" select="$s"/>
      <xsl:with-param name="n" select="$s[1]"/>
      <xsl:with-param name="next" select="."/>
    </xsl:call-template>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template mode="d:html" match="end" name="d:end">
<xsl:param name="n" select="@name"/>
<xsl:param name="s" select="()"/>
<xsl:param name="next" select="following-sibling::node()[1]"/>
<xsl:variable name="s2" select="$s[position()!=1]"/>
  <xsl:choose>
  <xsl:when test="empty($s)">
  <!--====/<xsl:value-of select="$n"/>======-->
  <xsl:message>htmlparse: Not well formed (<xsl:value-of select="@name"/>)</xsl:message>
  </xsl:when>
  <xsl:when test="$s[1]=$n">
  <end name="{$n}" s="{$s2}"/>
  <xsl:apply-templates mode="d:html" select="$next">
   <xsl:with-param name="s" select="$s2"/>
  </xsl:apply-templates>
  </xsl:when>
  <xsl:when test="not($n=$s)">
  <!--====/<xsl:value-of select="$n"/>======-->
  <xsl:message>htmlparse: Not well formed (ignoring /<xsl:value-of select="$n"/>)</xsl:message>
  <xsl:apply-templates mode="d:html" select="$next">
   <xsl:with-param name="s" select="$s"/>
  </xsl:apply-templates>
  </xsl:when>
  <xsl:otherwise>
  <end name="{$s[1]}" s="{$s2}"/>
  <xsl:apply-templates mode="d:html" select=".">
   <xsl:with-param name="s" select="$s2"/>
  </xsl:apply-templates>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>



<xsl:template mode="d:tree" match="text()">
  <xsl:param name="ns"/>
  <xsl:copy-of select="."/>
  <xsl:apply-templates select="following-sibling::node()[1]" mode="d:tree">
    <xsl:with-param name="ns" select="$ns"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template mode="d:tree" match="comment">
  <xsl:param name="ns"/>
  <xsl:comment>
    <xsl:value-of select="."/>
  </xsl:comment>
  <xsl:apply-templates select="following-sibling::node()[1]" mode="d:tree">
    <xsl:with-param name="ns" select="$ns"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template mode="d:tree" match="pi">
  <xsl:param name="ns"/>
  <xsl:processing-instruction name="{substring-before(.,' ')}">
    <xsl:value-of select="substring-after(.,' ')"/>
  </xsl:processing-instruction>
  <xsl:apply-templates select="following-sibling::node()[1]" mode="d:tree">
    <xsl:with-param name="ns" select="$ns"/>
  </xsl:apply-templates>
</xsl:template>



<xsl:template mode="d:tree" match="start">
  <xsl:param name="ns"/>
  <xsl:variable name="n" select="following-sibling::end[@s=current()/@s][1]"/>
  <xsl:variable name="xns" select="attrib/d:ns/namespace::*[not(.='data:,dpc')]"/>
  <xsl:variable name="nns" select="($ns,$xns)"/>
  <xsl:element name="{@name}" namespace="{$nns[name()=substring-before(current()/@name,':')][last()]}">
  <xsl:copy-of select="attrib/(@*|$nns[not(name()='')])"/>
  <xsl:apply-templates select="following-sibling::node()[1][not(. is $n)]" mode="d:tree">
    <xsl:with-param name="ns" select="$nns"/>
  </xsl:apply-templates>
  </xsl:element>
  <xsl:apply-templates select="$n/following-sibling::node()[1]" mode="d:tree">
    <xsl:with-param name="ns" select="$ns"/>
  </xsl:apply-templates>
</xsl:template>

<!--
Old version without NS support
<xsl:template mode="d:tree" match="start">
  <xsl:variable name="n" select="following-sibling::end[@s=current()/@s][1]"/>
  <xsl:element name="{@name}" namespace="http://www.w3.org/1999/xhtml">
  <xsl:copy-of select="attrib/@*"/>
  <xsl:apply-templates select="following-sibling::node()[1][not(. is $n)]" mode="d:tree"/>
  </xsl:element>
  <xsl:apply-templates select="$n/following-sibling::node()[1]" mode="d:tree"/>
</xsl:template>
-->


<xsl:variable name="d:ents">
  
  <entity name="Aacute">&#xC1;</entity>
  <entity name="aacute">&#xE1;</entity>
  <entity name="Acirc">&#xC2;</entity>
  <entity name="acirc">&#xE2;</entity>
  <entity name="acute">&#xB4;</entity>
  <entity name="AElig">&#xC6;</entity>
  <entity name="aelig">&#xE6;</entity>
  <entity name="Agrave">&#xC0;</entity>
  <entity name="agrave">&#xE0;</entity>
  <entity name="Aring">&#xC5;</entity>
  <entity name="aring">&#xE5;</entity>
  <entity name="Atilde">&#xC3;</entity>
  <entity name="atilde">&#xE3;</entity>
  <entity name="Auml">&#xC4;</entity>
  <entity name="auml">&#xE4;</entity>
  <entity name="brvbar">&#xA6;</entity>
  <entity name="Ccedil">&#xC7;</entity>
  <entity name="ccedil">&#xE7;</entity>
  <entity name="cedil">&#xB8;</entity>
  <entity name="cent">&#xA2;</entity>
  <entity name="copy">&#xA9;</entity>
  <entity name="curren">&#xA4;</entity>
  <entity name="deg">&#xB0;</entity>
  <entity name="divide">&#xF7;</entity>
  <entity name="Eacute">&#xC9;</entity>
  <entity name="eacute">&#xE9;</entity>
  <entity name="Ecirc">&#xCA;</entity>
  <entity name="ecirc">&#xEA;</entity>
  <entity name="Egrave">&#xC8;</entity>
  <entity name="egrave">&#xE8;</entity>
  <entity name="ETH">&#xD0;</entity>
  <entity name="eth">&#xF0;</entity>
  <entity name="Euml">&#xCB;</entity>
  <entity name="euml">&#xEB;</entity>
  <entity name="frac12">&#xBD;</entity>
  <entity name="frac14">&#xBC;</entity>
  <entity name="frac34">&#xBE;</entity>
  <entity name="Iacute">&#xCD;</entity>
  <entity name="iacute">&#xED;</entity>
  <entity name="Icirc">&#xCE;</entity>
  <entity name="icirc">&#xEE;</entity>
  <entity name="iexcl">&#xA1;</entity>
  <entity name="Igrave">&#xCC;</entity>
  <entity name="igrave">&#xEC;</entity>
  <entity name="iquest">&#xBF;</entity>
  <entity name="Iuml">&#xCF;</entity>
  <entity name="iuml">&#xEF;</entity>
  <entity name="laquo">&#xAB;</entity>
  <entity name="macr">&#xAF;</entity>
  <entity name="micro">&#xB5;</entity>
  <entity name="middot">&#xB7;</entity>
  <entity name="nbsp">&#xA0;</entity>
  <entity name="not">&#xAC;</entity>
  <entity name="Ntilde">&#xD1;</entity>
  <entity name="ntilde">&#xF1;</entity>
  <entity name="Oacute">&#xD3;</entity>
  <entity name="oacute">&#xF3;</entity>
  <entity name="Ocirc">&#xD4;</entity>
  <entity name="ocirc">&#xF4;</entity>
  <entity name="Ograve">&#xD2;</entity>
  <entity name="ograve">&#xF2;</entity>
  <entity name="ordf">&#xAA;</entity>
  <entity name="ordm">&#xBA;</entity>
  <entity name="Oslash">&#xD8;</entity>
  <entity name="oslash">&#xF8;</entity>
  <entity name="Otilde">&#xD5;</entity>
  <entity name="otilde">&#xF5;</entity>
  <entity name="Ouml">&#xD6;</entity>
  <entity name="ouml">&#xF6;</entity>
  <entity name="para">&#xB6;</entity>
  <entity name="plusmn">&#xB1;</entity>
  <entity name="pound">&#xA3;</entity>
  <entity name="raquo">&#xBB;</entity>
  <entity name="reg">&#xAE;</entity>
  <entity name="sect">&#xA7;</entity>
  <entity name="shy">&#xAD;</entity>
  <entity name="sup1">&#xB9;</entity>
  <entity name="sup2">&#xB2;</entity>
  <entity name="sup3">&#xB3;</entity>
  <entity name="szlig">&#xDF;</entity>
  <entity name="THORN">&#xDE;</entity>
  <entity name="thorn">&#xFE;</entity>
  <entity name="times">&#xD7;</entity>
  <entity name="Uacute">&#xDA;</entity>
  <entity name="uacute">&#xFA;</entity>
  <entity name="Ucirc">&#xDB;</entity>
  <entity name="ucirc">&#xFB;</entity>
  <entity name="Ugrave">&#xD9;</entity>
  <entity name="ugrave">&#xF9;</entity>
  <entity name="uml">&#xA8;</entity>
  <entity name="Uuml">&#xDC;</entity>
  <entity name="uuml">&#xFC;</entity>
  <entity name="Yacute">&#xDD;</entity>
  <entity name="yacute">&#xFD;</entity>
  <entity name="yen">&#xA5;</entity>
  <entity name="yuml">&#xFF;</entity>
  
  
  <entity name="bdquo">&#x201E;</entity>
  <entity name="circ">&#x2C6;</entity>
  <entity name="Dagger">&#x2021;</entity>
  <entity name="dagger">&#x2020;</entity>
  <entity name="emsp">&#x2003;</entity>
  <entity name="ensp">&#x2002;</entity>
  <entity name="euro">&#x20AC;</entity>
  <entity name="gt">&#x3E;</entity>
  <entity name="ldquo">&#x201C;</entity>
  <entity name="lrm">&#x200E;</entity>
  <entity name="lsaquo">&#x2039;</entity>
  <entity name="lsquo">&#x2018;</entity>
  <entity name="lt">&#38;#60;</entity>
  <entity name="mdash">&#x2014;</entity>
  <entity name="ndash">&#x2013;</entity>
  <entity name="OElig">&#x152;</entity>
  <entity name="oelig">&#x153;</entity>
  <entity name="permil">&#x2030;</entity>
  <entity name="quot">&#x22;</entity>
  <entity name="rdquo">&#x201D;</entity>
  <entity name="rlm">&#x200F;</entity>
  <entity name="rsaquo">&#x203A;</entity>
  <entity name="rsquo">&#x2019;</entity>
  <entity name="sbquo">&#x201A;</entity>
  <entity name="Scaron">&#x160;</entity>
  <entity name="scaron">&#x161;</entity>
  <entity name="thinsp">&#x2009;</entity>
  <entity name="tilde">&#x2DC;</entity>
  <entity name="Yuml">&#x178;</entity>
  <entity name="zwj">&#x200D;</entity>
  <entity name="zwnj">&#x200C;</entity>
  
  
  <entity name="alefsym">&#x2135;</entity>
  <entity name="Alpha">&#x391;</entity>
  <entity name="alpha">&#x3B1;</entity>
  <entity name="and">&#x2227;</entity>
  <entity name="ang">&#x2220;</entity>
  <entity name="asymp">&#x2248;</entity>
  <entity name="Beta">&#x392;</entity>
  <entity name="beta">&#x3B2;</entity>
  <entity name="bull">&#x2022;</entity>
  <entity name="cap">&#x2229;</entity>
  <entity name="Chi">&#x3A7;</entity>
  <entity name="chi">&#x3C7;</entity>
  <entity name="clubs">&#x2663;</entity>
  <entity name="cong">&#x2245;</entity>
  <entity name="crarr">&#x21B5;</entity>
  <entity name="cup">&#x222A;</entity>
  <entity name="dArr">&#x21D3;</entity>
  <entity name="darr">&#x2193;</entity>
  <entity name="Delta">&#x394;</entity>
  <entity name="delta">&#x3B4;</entity>
  <entity name="diams">&#x2666;</entity>
  <entity name="empty">&#x2205;</entity>
  <entity name="Epsilon">&#x395;</entity>
  <entity name="epsilon">&#x3B5;</entity>
  <entity name="equiv">&#x2261;</entity>
  <entity name="Eta">&#x397;</entity>
  <entity name="eta">&#x3B7;</entity>
  <entity name="exist">&#x2203;</entity>
  <entity name="fnof">&#x192;</entity>
  <entity name="forall">&#x2200;</entity>
  <entity name="frasl">&#x2044;</entity>
  <entity name="Gamma">&#x393;</entity>
  <entity name="gamma">&#x3B3;</entity>
  <entity name="ge">&#x2265;</entity>
  <entity name="hArr">&#x21D4;</entity>
  <entity name="harr">&#x2194;</entity>
  <entity name="hearts">&#x2665;</entity>
  <entity name="hellip">&#x2026;</entity>
  <entity name="image">&#x2111;</entity>
  <entity name="infin">&#x221E;</entity>
  <entity name="int">&#x222B;</entity>
  <entity name="Iota">&#x399;</entity>
  <entity name="iota">&#x3B9;</entity>
  <entity name="isin">&#x2208;</entity>
  <entity name="Kappa">&#x39A;</entity>
  <entity name="kappa">&#x3BA;</entity>
  <entity name="Lambda">&#x39B;</entity>
  <entity name="lambda">&#x3BB;</entity>
  <entity name="lang">&#x2329;</entity>
  <entity name="lArr">&#x21D0;</entity>
  <entity name="larr">&#x2190;</entity>
  <entity name="lceil">&#x2308;</entity>
  <entity name="le">&#x2264;</entity>
  <entity name="lfloor">&#x230A;</entity>
  <entity name="lowast">&#x2217;</entity>
  <entity name="loz">&#x25CA;</entity>
  <entity name="minus">&#x2212;</entity>
  <entity name="Mu">&#x39C;</entity>
  <entity name="mu">&#x3BC;</entity>
  <entity name="nabla">&#x2207;</entity>
  <entity name="ne">&#x2260;</entity>
  <entity name="ni">&#x220B;</entity>
  <entity name="notin">&#x2209;</entity>
  <entity name="nsub">&#x2284;</entity>
  <entity name="Nu">&#x39D;</entity>
  <entity name="nu">&#x3BD;</entity>
  <entity name="oline">&#x203E;</entity>
  <entity name="Omega">&#x3A9;</entity>
  <entity name="omega">&#x3C9;</entity>
  <entity name="Omicron">&#x39F;</entity>
  <entity name="omicron">&#x3BF;</entity>
  <entity name="oplus">&#x2295;</entity>
  <entity name="or">&#x2228;</entity>
  <entity name="otimes">&#x2297;</entity>
  <entity name="part">&#x2202;</entity>
  <entity name="perp">&#x22A5;</entity>
  <entity name="Phi">&#x3A6;</entity>
  <entity name="phi">&#x3D5;</entity>
  <entity name="Pi">&#x3A0;</entity>
  <entity name="pi">&#x3C0;</entity>
  <entity name="piv">&#x3D6;</entity>
  <entity name="Prime">&#x2033;</entity>
  <entity name="prime">&#x2032;</entity>
  <entity name="prod">&#x220F;</entity>
  <entity name="prop">&#x221D;</entity>
  <entity name="Psi">&#x3A8;</entity>
  <entity name="psi">&#x3C8;</entity>
  <entity name="radic">&#x221A;</entity>
  <entity name="rang">&#x232A;</entity>
  <entity name="rArr">&#x21D2;</entity>
  <entity name="rarr">&#x2192;</entity>
  <entity name="rceil">&#x2309;</entity>
  <entity name="real">&#x211C;</entity>
  <entity name="rfloor">&#x230B;</entity>
  <entity name="Rho">&#x3A1;</entity>
  <entity name="rho">&#x3C1;</entity>
  <entity name="sdot">&#x22C5;</entity>
  <entity name="Sigma">&#x3A3;</entity>
  <entity name="sigma">&#x3C3;</entity>
  <entity name="sigmaf">&#x3C2;</entity>
  <entity name="sim">&#x223C;</entity>
  <entity name="spades">&#x2660;</entity>
  <entity name="sub">&#x2282;</entity>
  <entity name="sube">&#x2286;</entity>
  <entity name="sum">&#x2211;</entity>
  <entity name="sup">&#x2283;</entity>
  <entity name="supe">&#x2287;</entity>
  <entity name="Tau">&#x3A4;</entity>
  <entity name="tau">&#x3C4;</entity>
  <entity name="there4">&#x2234;</entity>
  <entity name="Theta">&#x398;</entity>
  <entity name="theta">&#x3B8;</entity>
  <entity name="thetasym">&#x3D1;</entity>
  <entity name="trade">&#x2122;</entity>
  <entity name="uArr">&#x21D1;</entity>
  <entity name="uarr">&#x2191;</entity>
  <entity name="upsih">&#x3D2;</entity>
  <entity name="Upsilon">&#x3A5;</entity>
  <entity name="upsilon">&#x3C5;</entity>
  <entity name="weierp">&#x2118;</entity>
  <entity name="Xi">&#x39E;</entity>
  <entity name="xi">&#x3BE;</entity>
  <entity name="Zeta">&#x396;</entity>
  <entity name="zeta">&#x3B6;</entity>

</xsl:variable>

<xsl:key name="d:ents" match="entity" use="@name"/>

</xsl:stylesheet>
