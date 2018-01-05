/*	mw2confluence
	Convert MediaWiki XML into Confluence Markup
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%

fileIn := "allpages.xml"

y := new XML(fileIn)

Loop, % (pages := y.selectNodes("mediawiki/page")).length()
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
		l := chk_tags(l)																; convert tags
		l := chk_wikiLinks(l)															; convert [[wiki links]]
		
		newtxt .= l "`n"
	}
	
	return newtxt
}

clean_br(txt) {
	txt := RegExReplace(txt,"<br>|<br />|</br>")
	return txt
}

chk_header(txt) {
	tagHdr := ["^= ", "^== ", "^=== ", "^==== "]
	tagEnd := [" =", " ==", " ===", " ===="]
	tagSub := ["h1. ", "h2. ", "h3. ", "h4. "]
	
	if (idx:=objHasValue(tagHdr,txt,1)) {
		txt := RegExReplace(txt,tagHdr[idx])
		txt := RegExReplace(txt,tagEnd[idx])
		txt := tagSub[idx] txt
	}
	
	return txt
}

chk_tags(txt) {
	tag := ["<b>","</b>"
			,"<u>","</u>"
			,"<i>","</i>"
			,"<ins>","</ins>"
			,"<del>","</del>"
			,"'''''"
			,"'''"
			,"''"
			,"{{","}}"
			,"<sup>","</sup>"
			,"<sub>","</sub>"
			,"<big>","</big>"
			,"<small>","</small>"
			,"<code>","</code>"]
	sub := ["*","*"
			,"+","+"
			,"_","_"
			,"+","+"
			,"-","-"
			,"*_"
			,"*"
			,"_"
			,"((","))"
			,"^","^"
			,"~","~"
			,"",""
			,"",""
			,"{{","}}"]
	
	loop, % tag.length()
	{
		txt := RegExReplace(txt,"(?<!<nowiki>)" tag[A_Index] "(?!</nowiki>)", sub[A_Index])
	}
	
	return txt
}

chk_wikiLinks(txt) {
	txt := RegExReplace(txt,"\[\[(.*)?\s*\|\s*(.*)?\]\]","[[$2|$1]]")							; reverse [[aaa|bbb]] to [[bbb|aaa]]
	txt := RegExReplace(txt,"\[\[(.*?)\s*?\]\]","[$1]")											; reduce [[aaa]] to [aaa], and remove any trailing \s
	
	return txt
}

chk_Url(txt) {
	txt := RegExReplace(txt,"i)\[(http.?:\/\/.*?)((\s)(.*))?\]","[$4 $1]")						; reverse [http://google.com The GOOGLE] to [The GOOGLE http://google.com]
	
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
