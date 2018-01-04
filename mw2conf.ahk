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
	
	MsgBox,
		, % title
		, rev_text
}

ExitApp

#Include strX.ahk
#Include stRegX.ahk
#Include xml.ahk
