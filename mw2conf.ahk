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
		, % rev_text "`n----`n" new_text
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
	Loop, parse, txt, `n, `r
	{
		l := A_LoopField																; read next line
		
		l := clean_br(l)																; clear instances of <br>
		l := chk_header(l)																; do header check
		
		newtxt .= l "`n"
	}
	
	return newtxt
}

clean_br(txt) {
	txt := RegExReplace(txt,"<br>|<br />|</br>")
	return txt
}

chk_header(txt) {
	tag := object()
	tag["hdr"] := ["^= ", "^== ", "^=== ", "^==== "]
	tag["end"] := [" =", " ==", " ===", " ===="]
	tag["sub"] := ["h1. ", "h2. ", "h3. ", "h4. "]
	
	if (idx:=objHasValue(tag["hdr"],txt,1)) {
		txt := RegExReplace(txt,tag["hdr",idx])
		txt := RegExReplace(txt,tag["end",idx])
		txt := tag["sub",idx] txt
	}
	
	return txt
}

ObjHasValue(aObj, aValue, rx:="") {
; modified from http://www.autohotkey.com/board/topic/84006-ahk-l-containshasvalue-method/	
   for key, val in aObj
		if (rx) {
			if (rx=="i") {													; make case insensitive search
				val := "i)" val
			}
			if (aValue ~= val) {
				return, key, Errorlevel := 0
			}
		} else {
			if (val = aValue) {
				return, key, ErrorLevel := 0
			}
		}
    return, false, errorlevel := 1
}

#Include strX.ahk
#Include stRegX.ahk
#Include xml.ahk
