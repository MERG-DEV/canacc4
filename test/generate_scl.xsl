<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">

  <xsl:strip-space elements="*"/>
  <xsl:output method="text"
              omit-xml-declaration="yes"
              indent="no"
              encoding="utf-8"
              media-type="text/plain"/>

  <xsl:variable name="test_name">
    <xsl:value-of select="test/@name"/>
  </xsl:variable>
  <xsl:variable name="processor">
    <xsl:value-of select="test/@processor"/>
  </xsl:variable>
  <xsl:variable name="test_timeout">
    <xsl:value-of select="test/@timeout"/>
  </xsl:variable>

  <!-- Called Templates -->
  <xsl:template name="report">
    <xsl:param name="indentation"/>
    <xsl:param name="report_text"/>
    <xsl:value-of select="$indentation"/>
    <xsl:text>report(&quot;</xsl:text>
    <xsl:value-of select="$test_name"/>
    <xsl:text>: </xsl:text>
    <xsl:value-of select="$report_text"/><xsl:text>&quot;);&#xA;</xsl:text>
  </xsl:template>

  <!-- Matched Templates -->
  <xsl:template match="test">
    <xsl:text>configuration for &quot;</xsl:text><xsl:value-of select="$processor"/><xsl:text>&quot; is&#xA;</xsl:text>
    <xsl:text>end configuration;&#xA;</xsl:text>
    <xsl:text>--&#xA;</xsl:text>
    <xsl:text>testbench for &quot;</xsl:text><xsl:value-of select="$processor"/><xsl:text>&quot; is&#xA;</xsl:text>
    <xsl:text>begin&#xA;</xsl:text>
    <xsl:text>  test_timeout: process is&#xA;</xsl:text>
    <xsl:text>    begin&#xA;</xsl:text>
    <xsl:text>      wait for </xsl:text><xsl:value-of select="$test_timeout"/><xsl:text>ms;&#xA;</xsl:text>
    <xsl:call-template name="report">
      <xsl:with-param name="indentation">&#xA0;     </xsl:with-param>
      <xsl:with-param name="report_text">TIMEOUT</xsl:with-param>
    </xsl:call-template>
    <xsl:text>      report(PC); -- Crashes simulator, MDB will report current source line&#xA;</xsl:text>
    <xsl:text>      PC &lt;= 0;&#xA;</xsl:text>
    <xsl:text>      wait;&#xA;</xsl:text>
    <xsl:text>    end process test_timeout;&#xA;</xsl:text>
    <xsl:text>  --&#xA;</xsl:text>
    <xsl:apply-templates select="procedure"/>
    <xsl:text>end testbench;&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="procedure">
    <xsl:text>  </xsl:text><xsl:value-of select="$test_name"/><xsl:text>: process is&#xA;</xsl:text>
    <xsl:text>    begin&#xA;</xsl:text>
    <xsl:call-template name="report">
      <xsl:with-param name="indentation">&#xA0;     </xsl:with-param>
      <xsl:with-param name="report_text">START</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates/>
    <xsl:text>    end process </xsl:text><xsl:value-of select="$test_name"/><xsl:text>;&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="set_register">
    <xsl:text>      </xsl:text>
    <xsl:value-of select="@register"/>
    <xsl:text> &lt;= 16#</xsl:text>
    <xsl:value-of select="@value"/>
    <xsl:text>#;&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="test_register">
    <xsl:text>      if </xsl:text>
    <xsl:value-of select="@register"/>
    <xsl:text> != 16#</xsl:text>
    <xsl:value-of select="@expected"/>
    <xsl:text># then&#xA;</xsl:text>
    <xsl:call-template name="report">
      <xsl:with-param name="indentation">&#xA0;       </xsl:with-param>
      <xsl:with-param name="report_text">Incorrect <xsl:value-of select="@register"/></xsl:with-param>
    </xsl:call-template>
    <xsl:text>        test_state := fail;&#xA;</xsl:text>
    <xsl:text>      end if;&#xA;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
