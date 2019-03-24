<?xml version="1.0"?>
<!--
  dirlist.xslt - transform nginx's into lighttpd look-alike dirlistings

  I'm currently switching over completely from lighttpd to nginx. If you come
  up with a prettier stylesheet or other improvements, please tell me :)

-->
<!--
   Copyright (c) 2016 by Moritz Wilhelmy <mw@barfooze.de>
   All rights reserved

   Redistribution and use in source and binary forms, with or without
   modification, are permitted providing that the following conditions
   are met:
   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

   THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
   DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
   OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
   IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.
-->
<!DOCTYPE fnord [<!ENTITY nbsp "&#160;">]>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns="http://www.w3.org/1999/xhtml" xmlns:func="http://exslt.org/functions" version="1.0" exclude-result-prefixes="xhtml" extension-element-prefixes="func">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" doctype-public="-//W3C//DTD XHTML 1.1//EN" doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" indent="yes" media-type="application/xhtml+xml"/>
  <xsl:strip-space elements="*" />

  <xsl:template name="size">
    <!-- transform a size in bytes into a human readable representation -->
    <xsl:param name="bytes"/>
    <xsl:choose>
      <xsl:when test="$bytes &lt; 1000"><xsl:value-of select="$bytes" />B</xsl:when>
      <xsl:when test="$bytes &lt; 1048576"><xsl:value-of select="format-number($bytes div 1024, '0.0')" />K</xsl:when>
      <xsl:when test="$bytes &lt; 1073741824"><xsl:value-of select="format-number($bytes div 1048576, '0.0')" />M</xsl:when>
      <xsl:otherwise><xsl:value-of select="format-number(($bytes div 1073741824), '0.00')" />G</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="timestamp">
    <!-- transform an ISO 8601 timestamp into a human readable representation -->
    <xsl:param name="iso-timestamp" />
 <!--
    <xsl:value-of select="concat(substring($iso-timestamp, 0, 11), ' ', substring($iso-timestamp, 12, 5))" />
-->
 <xsl:value-of select="(substring($iso-timestamp, 0, 11))" />
  </xsl:template>

  <xsl:template name="breadcrumb">
    <xsl:param name="list" />
    <xsl:param name="delimiter" select="'/'"  />
    <xsl:param name="reminder" select="$list" />
    <xsl:variable name="newlist">
      <xsl:choose>
        <xsl:when test="contains($list, $delimiter)">
          <xsl:value-of select="normalize-space($list)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat(normalize-space($list), $delimiter)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="first" select="substring-before($newlist, $delimiter)" />
    <xsl:variable name="remaining" select="substring-after($newlist, $delimiter)" />
    <xsl:variable name="current" select="substring-before($reminder, $remaining)" />

    <xsl:choose>
      <xsl:when test="$remaining">
        <xsl:choose>
          <xsl:when test="$first = ''">
            <li class="breadcrumb-item">
              <i class="fa fas fa-home"></i><a href="/">Home</a>
            </li>
          </xsl:when>
          <xsl:otherwise>
            <li class="breadcrumb-item">
              <a href="{$current}"><xsl:value-of select="$first" /></a>
            </li>
          </xsl:otherwise>
        </xsl:choose>

        <xsl:call-template name="breadcrumb">
          <xsl:with-param name="list" select="$remaining" />
          <xsl:with-param name="delimiter" select="$delimiter" />
          <xsl:with-param name="reminder" select="$reminder" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$first = ''">
            <li class="breadcrumb-item">
              <i class="fa fas fa-home"></i><a href="/">Home</a>
            </li>
          </xsl:when>
          <xsl:otherwise>
            <li class="breadcrumb-item active">
              <a href="{$current}"><xsl:value-of select="$first" /></a>
            </li>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="directory">
    <tr>
      <td class="n"><a href="{current()}/"><i class="fa fas fa-folder" style="padding-right: 5px;"></i><xsl:value-of select="."/></a>/</td>
      <td class="m"><xsl:call-template name="timestamp"><xsl:with-param name="iso-timestamp" select="@mtime" /></xsl:call-template></td>
      <td class="s">- &nbsp;</td>
    </tr>
  </xsl:template>

  <xsl:template name="icon">
    <xsl:param name="path"/>
    <xsl:variable name="extension">
      <xsl:call-template name="get-file-extension">
        <xsl:with-param name="path" select="$path" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$extension = 'zip'">
        <i class="fa fas fa-file-archive" style="padding-right: 5px;"></i>
      </xsl:when>
      <xsl:otherwise>
        <i class="fa fas fa-file" style="padding-right: 5px;"></i>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="get-file-extension">
    <xsl:param name="path"/>
    <xsl:choose>
      <xsl:when test="contains($path, '/')">
        <xsl:call-template name="get-file-extension">
          <xsl:with-param name="path" select="substring-after($path, '/')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($path, '.')">
        <xsl:call-template name="get-file-extension">
          <xsl:with-param name="path" select="substring-after($path, '.')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$path"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="file">
    <tr>
      <td class="n">
        <a href="{current()}">
          <xsl:call-template name="icon"><xsl:with-param name="path" select="." /></xsl:call-template>
          <xsl:value-of select="." />
        </a>
      </td>
      <td class="m"><xsl:call-template name="timestamp"><xsl:with-param name="iso-timestamp" select="@mtime" /></xsl:call-template></td>
      <td class="s"><xsl:call-template name="size"><xsl:with-param name="bytes" select="@size" /></xsl:call-template></td>
    </tr>
  </xsl:template>

  <xsl:template match="/">
    <html>
      <head>
        <title>Repositories by Julien</title>
        <meta charset="utf-8" />
        <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css" type="text/css" />
        <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.6.1/css/all.css" type="text/css" integrity="sha384-gfdkjb5BdAXd+lj+gudLWI+BXq4IuLW5IT+brZEZsLFm++aCMlF1V92rMkPaX4PP" crossorigin="anonymous" />
        <style type="text/css">
          /* Sticky footer styles
          -------------------------------------------------- */
          html {
            position: relative;
            min-height: 100%;
          }
          body {
            margin-bottom: 60px; /* Margin bottom by footer height */
          }
          .footer {
            position: absolute;
            bottom: 0;
            width: 100%;
            height: 60px; /* Set the fixed height of the footer here */
            line-height: 60px; /* Vertically center the text there */
            background-color: #f5f5f5;
          }

          /* Custom page CSS
          -------------------------------------------------- */
          .container {
            width: auto;
            max-width: 1280px;
            padding: 0 15px;
          }
        </style>
      </head>
      <body>
        <!-- Begin page content -->
        <main role="main" class="container">
          <h1 class="mt-5">Repositories by Julien</h1>
          <ol class="breadcrumb"><xsl:call-template name="breadcrumb"><xsl:with-param name="list" select="$path" /></xsl:call-template></ol>
          <div class="list">
            <table class="table" summary="Directory Listing" cellpadding="0" cellspacing="0">
              <thead>
                <tr>
                  <th class="n">Name</th>
                  <th class="m">Last Modified</th>
                  <th class="s">Size</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td class="n"><a href="../"><i class="fa fas fa-level-up-alt" style="padding-right: 5px;"></i>Parent Directory/</a></td>
                  <td class="m">&nbsp;</td>
                  <td class="s">- &nbsp;</td>
                </tr>
                <xsl:apply-templates />
              </tbody>
            </table>
          </div>
        </main>

        <footer class="footer">
          <div class="container">
            <span class="text-muted">(c) Julien</span>
          </div>
        </footer>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
