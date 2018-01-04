/*	mw2confluence
	Convert MediaWiki XML into Confluence Markup
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%

fileIn := "allpages.xml"

y := new XML(fileIn)

Loop, % (pages := y.selectNodes("mediawiki/page")).length
{
	idx := A_Index
	page := pages.item(idx-1)
	title := page.selectSingleNode("title").text
	revs := page.selectNodes("revision")
	rev := revs.item(revs.length-1)
	rev_text := rev.selectSingleNode("text").text
	
	new_text := convert(rev_text)
	
	MsgBox,
		, % title
		, rev_text
}

ExitApp

convert(txt) {
/*	MW markup in, Confluence markup out
	* remove <br> or <br /> or </br>
	* read each line to find header marks (and closing 
		= 		h1.
		==		h2.
		===		h3.
		====	h4.
		----    ----
		
	* convert open and closing marks
		''' (b)
		'' (i)
		<u>
		<b>
		<i>
	* convert links
		[[page | text]]		[text | page]
		[URL text follows]	[text precedes URL]
	* convert tables
		{| class="wikitable" ... |}
*/
}

#Include strX.ahk
#Include stRegX.ahk
#Include xml.ahk
