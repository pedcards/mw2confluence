/*	mw2confluence
	Convert MediaWiki XML into Confluence Markup
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%

fileIn := "allpages.xml"

y := new XML(fileIn)

pagesNS := y.selectNodes("mediawiki/page/ns[text()='" 0 "']")							; pagesNS all pages with <ns>0</ns> (wiki pages)
pages := object()

loop, % pagesNS.length																	; loop through pagesNS
{
	par := pagesNS.item(A_Index-1).parentNode											; parent <page> node of the item
	nm := par.selectSingleNode("title").text											; get <title>
	id := par.selectSingleNode("id").text												; get <id> number
	pages.InsertAt(id,nm)																; insert into pages[] array
}

Loop,
{
	InputBox, findStr, Search string, Enter search term or paste URL:`n(blank to exit)
	
	if !(findStr) {																		; findStr empty
		break																			; break loop to exitapp
	}

	if instr(findStr,"https://confluence") {											; Appears to be a Confluence URL
		findStr := strX(findStr,"title=",1,6,"&",1,1)									; extract title
		findStr := RegExReplace(findStr,"\+"," ")										; convert to a normal string
		findStr := trim(RegExReplace(findStr,"%[0-9A-Fa-f]{2}"," "))					; without URL codes
	}
	found := chkPages(findStr)															; find best match among pages[]
	
	MsgBox, 36,, % "Found page:`n`n" found.best " (" found.id ")`n`n`nUse this page?"
	IfMsgBox, No
	{
		continue																		; repeat loop
	}
	
	txt := fetchPage(found.id)															; get text from page
	
	MsgBox, 36, % found.best, % substr(txt,1,1024) "`n`n. . .`n`nCONVERT THIS BLOCK?"
	IfMsgBox, No
	{
		continue																		; not right, redo loop
	}
	
	newtxt := convert(txt)																; convert txt
	clipboard := newtxt																	; copy to clipboard
	
	MsgBox, 64, Copied to clipboard, % substr(newtxt,1,1024) "`n`n. . ."
}
	
ExitApp

fetchPage(idx) {
	global y
	if (idx~="[[:alpha:]]+") {															; any alpha chars is a string
		tail := "[title='" idx "']"
	} else {																			; no alpha means digits
		tail := "[id='" idx "']"
	}
	page := y.selectSingleNode("mediawiki/page" tail )									; <mediawiki/page[id='20']>
	revs := page.selectNodes("revision")												; all revisions
	rev := revs.item(revs.length-1)														; take the last revision
	txt := rev.selectSingleNode("text").text											; get the <text>
	
	return txt
}

chkPages(txt) {
	global pages
	fuzz := 1
	for idx,val in pages
	{
		res := fuzzysearch(txt,val)
		if (res<fuzz) {
			fuzz := res
			best := val
			bestID := idx
		}
	}
	return {"fuzz":round((1-fuzz)*100,2),"best":best,"id":bestID}
}

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
		
		chk_header(l)																	; do header check
		chk_tags(l)																		; convert tags
		chk_wikiLinks(l)																; convert [[wiki links]]
		chk_Url(l)																		; convert [http(s):]]
		
		newtxt .= l "`n"
	}
	
	clean_br(newtxt)																		; clear instances of <br>
	clean_table(newtxt)																	; fix tables
	
	return newtxt
}

clean_br(byref txt) {
	txt := RegExReplace(txt,"<br>|<br />|</br>")
	return txt
}

chk_header(byref txt) {
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

chk_tags(byref txt) {
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

chk_wikiLinks(byref txt) {
	txt := RegExReplace(txt,"\[\[(.*)?\s*\|\s*(.*)?\]\]","[[$2|$1]]")							; reverse [[aaa|bbb]] to [[bbb|aaa]]
	txt := RegExReplace(txt,"\[\[(.*?)\s*?\]\]","[$1]")											; reduce [[aaa]] to [aaa], and remove any trailing \s
	
	return txt
}

chk_Url(byref txt) {
	txt := RegExReplace(txt,"i)\[(http.?:\/\/.*?)((\s)(.*?))?\]","[$4 $1]")						; reverse [http://google.com The GOOGLE] to [The GOOGLE http://google.com]
	
	return txt
}

clean_table(byref txt) {
	txt := RegExReplace(txt,"im)(*ANYCRLF)^.?\{\| class=.wikitable","{| class=""wikitable")
	while instr(txt,"{| class=""wikitable") {
		RegExMatch(txt,"Oi)\{\| class=.wikitable(.*?)\|\}",ex)
		tbl := ex.value()
		pos := ex.pos()
		len := ex.len()
		
		tbl := RegExReplace(tbl,"i)\{\| class=.wikitable(.*?)[\r\n]+")
		tbl := RegExReplace(tbl,"\|\}(.*?)[\r\n]*")
		tbl := RegExReplace(tbl,"m)(*ANYCRLF)^\|-[\r\n]")
		
		loop, parse, tbl, `n, `r
		{
			row := A_LoopField
			if (row~="^! ") {
				row := RegExReplace(row,"^! ","!! ") " !!"
				row := RegExReplace(row,"!!","||")
			}
			else if (row~="^\| ") {
				row := RegExReplace(row,"^\| ","|| ") " ||"
				row := RegExReplace(row,"\|\|","|")
			}
			newtbl .= row "`n"
		}
		txt := RegExReplace(txt,"(.*?)\|\}",newtbl,,,pos)
	}
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
#include sift3.ahk
