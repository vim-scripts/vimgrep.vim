" Vim plugin of vim script utilities
" Language:    vim script
" Maintainer:  Dave Silvia <dsilvia@mchsi.com>
" Date:        7/31/2004
"
"

function! IsVimNmr(var)
	let l:omega=matchend(a:var,'^\%[0x]\d*')
	return ((match(a:var,'\%[0x]\d*$') <= l:omega) && (l:omega == strlen(a:var)))
endfunction

function! IsVimIdent(var)
	if match(a:var,'^\h\w*') != -1
		return 1
	endif
	return 0
endfunction

" returns 1 if valid and exists, -1 if valid and doesn't exist, 0 if not valid
function! IsVimVar(var)
	if IsVimIdent(a:var)
		if exists(a:var)
			return 1
		else
			return -1
		endif
	endif
	return 0
endfunction

function! IsStrLit(var)
	let sglQuote=match(a:var,"^'") != -1 && match(a:var,"'$") != -1
	let dblQuote=match(a:var,'^"') != -1 && match(a:var,'"$') != -1
	return (sglQuote || dblQuote)
endfunction

" returns 1 if valid and exists, -1 if valid and doesn't exist, 0 if not valid
function! IsArrayDecl(decl)
	if match(a:decl,'^\(b\|w\|g\):\h\w*:\(\d*:\)*$') == 0
		if exists(a:decl)
			return 1
		else
			return -1
		endif
	endif
	return 0
endfunction

function! RGB2Hex(RGBNum)
	let hexdigitstr='0123456789abcdef'
	let hexStr=''
	let decNum=a:RGBNum
	while decNum > 15
		let divNum=decNum/16
		let hexStr=hexStr.strpart(hexdigitstr,divNum,1)
		let subNum=divNum*16
		let decNum=decNum-subNum
	endwhile
	let hexStr=hexStr.strpart(hexdigitstr,decNum,1)
	if strlen(hexStr) < 2
		let hexStr=hexStr.'0'
	endif
	return hexStr
endfunction

function! IsStrListTok(list,...)
	if a:0
		let s:isStrListTokDelim=a:1
	elseif exists("b:strListTokDelim")
		let s:isStrListTokDelim=b:strListTokDelim
	elseif exists("s:strListTokDelim")
		let s:isStrListTokDelim=s:strListTokDelim
	elseif exists("g:strListTokDelim")
		let s:isStrListTokDelim=g:strListTokDelim
	else
		let s:isStrListTokDelim="\<NL>\\+".'\|,\+'
	endif
	return match(a:list,s:isStrListTokDelim) != -1
endfunction

function! StrListTok(list,retList,...)
	let thisList=a:retList.'StrListTokCurList'
	let thisDelim=a:retList.'StrListTokCurDelim'
	if a:list != ''
		if a:0
			let {thisDelim}=a:1
		elseif exists("b:strListTokDelim")
			let {thisDelim}=b:strListTokDelim
		elseif exists("s:strListTokDelim")
			let {thisDelim}=s:strListTokDelim
		elseif exists("g:strListTokDelim")
			let {thisDelim}=g:strListTokDelim
		else
			let {thisDelim}="\<NL>\\+".'\|,\+'
		endif
		let tmp=a:list
		let tmp=substitute(tmp,'^\('.{thisDelim}.'\)','','')
		let tmp=substitute(tmp,'\('.{thisDelim}.'\)$','','')
		let {thisList}=tmp
	else
		if !exists(thisList)
			if exists(thisDelim)
				unlet {thisDelim}
			endif
			return ''
		endif
	endif
	let theMatch=match({thisList},{thisDelim})
	let theMatchEnd=matchend({thisList},{thisDelim})
	if theMatch != -1
		let tok=strpart({thisList},0,theMatch)
		let {thisList}=strpart({thisList},theMatchEnd)
		let {a:retList}={thisList}
	else
		let tok={thisList}
		let {a:retList}=''
		unlet {thisList} {thisDelim}
	endif
	return tok
endfunction

function! QualifiedPath(fileName)
	if !exists("b:QPATH")
		let b:QPATH='^\(\~\|\h:\|\\\|/\)'
	endif
	return !match(a:fileName,b:QPATH)
endfunction

function! FileParts(passedFile,full,path,file,name,ext)
	if a:file != '' | let {a:file}='' | endif
	if a:name != '' | let {a:name}='' | endif
	if a:ext != '' | let {a:ext}='' | endif
	if a:passedFile == '%' || a:passedFile == ''
		if a:full != '' | let {a:full}=expand("%:p") | endif
		if a:path != '' | let {a:path}=expand("%:p:h") | endif
		if a:file != '' | let {a:file}=expand("%:t") | endif
		if a:name != '' | let {a:name}=expand("%:t:r") | endif
		if a:ext != '' | let {a:ext}=".".expand("%:e") | endif
		return
	endif
	let fullname=expand(a:passedFile)
	if fullname == a:passedFile && !QualifiedPath(a:passedFile)
		if glob(expand("%:p:h").'/'.fullname) != ''
			if a:path != '' | let {a:path}=expand("%:p:h") | endif
			if a:full != '' | let {a:full}=expand({a:path}.'/'.fullname) | endif
		endif
	else
		if a:path != '' | let {a:path}=fnamemodify(fullname,":p:h") | endif
		if a:full != '' | let {a:full}=fullname | endif
	endif
	if glob(fullname) == ''
		if a:full != '' | let {a:full}='' | endif
		if a:path != '' | let {a:path}='' | endif
		return
	endif
	if a:file != '' | let {a:file}=fnamemodify(fullname,":t") | endif
	if a:name != '' | let {a:name}=fnamemodify(fullname,":t:r") | endif
	if a:ext != '' | let {a:ext}=fnamemodify(fullname,":e") | endif
	if a:ext != '' && {a:ext} != ''
		let {a:ext}=".".{a:ext}
	endif
endfunction


" Creates name variable for parent script
" execute outside of any functions in the parent script at load time
command! -nargs=0 SUDEBUGMSG let b:thisScript=expand("<sfile>:p:t")

" Toggles DEBUGMSG on and off
command! -nargs=0 TGLDEBUGMSG
	\ if !exists("b:DODEBUGMSG") | let b:DODEBUGMSG=1 | else | unlet b:DODEBUGMSG | endif

" Syntax: DEBUGMSG msg[,lvl]
"  where: msg is a single string
"         lvl is 0 for normal
"                1 for warning
"                > 1 for error
"                not specified is 0
" echomsg
" format: <script>::<function(s)>: <message>
"           in black for normal
"           red for warning
"           reverse red for error
command! -nargs=1 DEBUGMSG
\	if exists("b:DODEBUGMSG") |
\		call s:DebugMsg(b:thisScript,expand("<sfile>"),<args>) |
\	endif

function! s:DebugMsg(script,func,msg,...)
	if a:0
		if a:1 == 1
			echohl Warningmsg
		elseif a:1 > 1
			echohl Errormsg
		endif
	endif
	echomsg a:script."::".a:func.": ".a:msg
	echohl None
endfunction

function! Pause(args)
	echohl Identifier 
	echo a:args
	echohl Cursor
	echo "          Press a key to continue"
	echohl None
	call getchar()
endfunction
