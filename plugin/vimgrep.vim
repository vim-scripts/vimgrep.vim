" Vim plugin script grep utility
" Language:    vim script
" Maintainer:  Dave Silvia <dsilvia@mchsi.com>
" Date:        8/4/2004
"
" Version 2.1
"   Fixed:
"    -  echo-ed results scrolling off
"       command line by adding Pause()
"    -  problem with file argument
"       being '/' would append '/*' to
"       search which always failed.
"       Now only appends extra '/' if
"       file argument does not end in
"       '/' or '\'.
"   Enhanced:
"    -  Stopped search after first match
"       if FNonly.  Do no search at all
"       if srchpat == '\%$'
"   New:
"    -  Added Vimfind
"       (inspired by email from
"         Hari Krishna Dara)
"
" Version 2.0
"   Changed script name to vimgrep.vim
"   Introduced naming convention for
"   commands and functions.  Commands
"   begin Vimgrep[\w*], functions and
"   variables begin [\w*]Vimgrep
"
"   Function MiniVimGrep() obsoleted.
"   Replaced with Vimgrep().
"   Wrapper exists to maintain
"   backward compatibility.
"
"   New:
"    -  Added opening of edit buffers
"       for successfully grep-ed files.
"    -  Added help files grep-ing.
"    -  Added delete of edit/help
"       buffers.
"    -  Added gvim menu/toolbar items
"       and key mappings for deleting.
"    -  Included documentation files.
"    -  rewrote, beefed up, made more
"       robust, and otherwise enhanced.
"
" Version 1.1
"   For grep-ing in open buffers:
"    -  Added BufVimgrep for grep-ing all open buffers
"    -  Added code to set cursor to line 1, col 1 in the file in case it is
"       being done with open buffers.  Then the cursor is set back to its
"       original position.
"    -  Added code to allow passing '%' or '' for file, meaning current buffer
"    -  Added augroup and autocmd to save the buffer number so it can be used
"       to return to the original buffer if grep-ing in open buffers
"
"   For multiple files
"    -  Added code to check for comma and newline file name separators.
"       Comma allows the user to specify 'file' argument as
"       "file1,file2,...", while newline allows 'file' argument to be
"       something like glob(expand("%:p:h")."/*") or
"       glob("<some-path>/*")
"    -  Added code to check if file is the same as the original open
"       buffer, if so, don't do bwipeout.
"    -  Added second optional argument for returning file names only.
"       If non-zero, just return file names, not the matching lines.
"
"   Misc
"    -  Added code to test for empty files
"    -  Added code to test for directories
"
" Version 1.0
"
" Original Release
"
" This script is a grep utility without an outside grep program.  It uses
" vim's native search capabilities on a single file.  It has 2 required
" arguments, the pattern and the file name, and one optional argument for
" matching case.  If the file argument does not include a full path
" specification, it is searched for in the current buffer's directory.


" set the buffer number so it can be readily gotten if needed
augroup vimgrepgrp
	autocmd!
	autocmd BufEnter,BufNew,BufAdd,BufRead * let b:bufNo=expand("<abuf>")
augroup END

let s:thisScript=expand("<sfile>:t")

function! s:getHelpIsKeyWord()
	let HelpKeyWordCmd='silent! h | let g:VGHlpISK=&iskeyword | silent! bwipeout'
	execute HelpKeyWordCmd
	let g:VGHlpISK=substitute(g:VGHlpISK,'|',"\\\\|","g")
	let g:VGHlpISK=substitute(g:VGHlpISK,'"','\\\\"',"g")
endfunction

command! SUVIMGREP unlet! g:VimgrepSetUp | call s:setUpVimgrep()

function! s:setUpVimgrep()
	if exists("g:VimgrepSetUp")
		return
	endif
	let g:VimgrepSetUp=1
" directory in which to create dummy file and grep program result file
if !exists("g:VGCreatDir")
	let g:VGCreatDir="~"
endif

" directories to search when file arguments are not fully qualified paths
if !exists("g:VGDirs")
	let g:VGDirs=expand("~").",".&runtimepath.",".getcwd()
endif

" directories to search for 'doc/*.txt' help files
if !exists("g:VGHlpDirs")
	let g:VGHlpDirs=expand("~").",".&runtimepath
endif

" defaults for optional arguments
if !exists("g:VGMCDflt")
	let g:VGMCDflt=0
endif

if !exists("g:VGFNonlyDflt")
	let g:VGFNonlyDflt=0
endif

if !exists("g:VGterseDflt")
	let g:VGterseDflt=0
endif

if !exists("g:VGdoSubsDflt")
	let g:VGdoSubsDflt=0
endif

if !exists("g:VGfpatDflt")
	let g:VGfpatDflt=''
endif

if !exists("g:VGmpatDflt")
	let g:VGmpatDflt=''
endif

"
" key mappings & GUI menu/toolbar for delete of Help/Edit buffers
"
if !exists("delVimgrepHelp")
	let g:VGdelHlpmap='<F6>'
endif
if !exists("g:VGdelEdtmap")
	let g:VGdelEdtmap='<F7>'
endif
let s:mapIt='map! '.g:VGdelHlpmap.' :call <SID>DeleteVimgrepHelp()<CR>'
execute s:mapIt
let s:mapIt='map! '.g:VGdelEdtmap.' :call <SID>DeleteVimgrepEdit()<CR>'
execute s:mapIt

" if gui, add to menus
if has("gui_running")
	" add 'Delete Vimgrep Help Buffers' to User Specific menu
	let s:menuIt='amenu &User\ Specific.&Vimgrep\ Buffers.Delete\ &Help\ Buffers<TAB>'.g:VGdelHlpmap.' :call <SID>DeleteVimgrepHelp()<CR>'
	execute s:menuIt
	" add 'Delete Vimgrep Edit Buffers' to User Specific menu
	let s:menuIt='amenu &User\ Specific.&Vimgrep\ Buffers.Delete\ &Edit\ Buffers<TAB>'.g:VGdelEdtmap.' :call <SID>DeleteVimgrepEdit()<CR>'
	execute s:menuIt
	if !exists("g:VGdelHlpIco")
		let g:VGdelHlpIco='tb_close'
	endif
	if !exists("g:VGdelEdtIco")
		let g:VGdelEdtIco='tb_close'
	endif
	" ditto ToolBar... if you don't want the default icons, change to your
	" preference with 'let delVG[Help|Edit]Ico=' before you source this script
	amenu 1.399 ToolBar.-399- <Nop>
	let s:menuIt='amenu icon='.g:VGdelHlpIco.' 1.400 ToolBar.Delete\ Vimgrep\ Help\ Buffers :call <SID>DeleteVimgrepHelp()<CR>'
	execute s:menuIt
	let s:menuIt='amenu icon='.g:VGdelEdtIco.' 1.401 ToolBar.Delete\ Vimgrep\ Edit\ Buffers :call <SID>DeleteVimgrepEdit()<CR>'
	execute s:menuIt
	amenu 1.405 ToolBar.-405- <Nop>
	" 'roll over' help...
	tmenu ToolBar.Delete\ Vimgrep\ Help\ Buffers Delete Vimgrep Help Buffers
	tmenu ToolBar.Delete\ Vimgrep\ Edit\ Buffers Delete Vimgrep Edit Buffers
	endif
" END if gui, add to menus
"
" END key mappings & GUI menu/toolbar for delete of Help/Edit buffers
"
call s:getHelpIsKeyWord()
endfunction

SUVIMGREP

" g:VGMSGLEVEL=2  error messages only
" g:VGMSGLEVEL=1  error & warning messages only
" g:VGMSGLEVEL=0  all messages
" set in your vimrc to change default or use VMSGLVL command to set on the fly
if !exists("g:VGMSGLEVEL")
	" show warnings & errors
	let g:VGMSGLEVEL=1
endif
if !exists("g:VGMSGPAUSE")
	let g:VGMSGPAUSE=1
endif

command! -nargs=1 VGMSGLVL let g:VGMSGLEVEL=<args> | if g:VGMSGLEVEL < 0 | let g:VGMSGLEVEL=0 | elseif g:VGMSGLEVEL > 2 | let g:VGMSGLEVEL=2 | endif

command! -nargs=1 VGMSG call s:vimgrepMsg(expand("<sfile>"),<args>)

function! s:vimgrepMsg(func,msg,...)
	if a:0 | let lvl=a:1 | else | let lvl=0 | endif
	if lvl < g:VGMSGLEVEL
		return
	endif
	if lvl == 1
		echohl Warningmsg
	elseif lvl > 1
		echohl Errormsg
	endif
	let theMsg=a:msg
	let msgline=StrListTok(a:msg,'b:VGMSGLINES',"\<NL>\\+")
	echomsg s:thisScript."::".a:func.": ".msgline
	let msgline=StrListTok('','b:VGMSGLINES')
	while msgline != ''
		echomsg msgline
		let msgline=StrListTok('','b:VGMSGLINES')
	endwhile
	if lvl > 1 && g:VGMSGPAUSE
		echohl Question
		echo "          Press a key to continue"
		call getchar()
		call setcmdpos(1)
		echo ' '
	endif
	echohl None
endfunction

function! s:doDummyView()
	let dummyDir=g:VGCreatDir
	let theDir=glob(dummyDir)
	execute "silent view ".theDir."/.dummyViewVimgrep"
endfunction

function! s:validSrchPat(srchpat)
	if a:srchpat == ''
		VGMSG "empty srchpat",2
		return 0
	endif
	call s:doDummyView()
	try
		execute "silent /".a:srchpat
	catch
		let emsg=strpart(v:exception,match(v:exception,':E\d\+:')+2)
		let eNum=strpart(emsg,0,match(emsg,':'))
		silent! bwipeout
		if eNum != 385 && eNum != 486
			VGMSG "invalid srchpat\<NL>".emsg,2
			return 0
		else
			return 1
		endif
	endtry
	silent! bwipeout
	return 1
endfunction

function! s:isNonTextFile(file)
	let thisBuf=b:bufNo
	let holdHidden=&hidden
	set hidden
	if !buflisted(a:file)
		execute 'silent view '.a:file.' | let L2Bsize=line2byte(line("$")+1) | let GetFsize=getfsize(expand("%:p")) |	silent bwipeout'
		silent "b".thisBuf
		let &hidden=holdHidden
		if L2Bsize-GetFsize == 1
			return 0
		endif
		return 1
	endif
	return 0
endfunction

command! -nargs=0 VimgrepEditDel call s:DeleteVimgrepEdit()

function! s:DeleteVimgrepEdit()
	if !exists("g:VGEdtBufs")
		return
	endif
	let thisBufNo=StrListTok(g:VGEdtBufs,'g:VGEdtBufs',':')
	while thisBufNo != ''
		let delB='silent! b'.thisBufNo
		execute delB
		silent! bwipeout
		let thisBufNo=StrListTok('','g:VGEdtBufs')
	endwhile
	unlet! g:VGEdtBufs
endfunction

command! -nargs=0 VimgrepHelpDel call s:DeleteVimgrepHelp()

function! s:DeleteVimgrepHelp()
	if !exists("g:VGHlpBufs")
		return
	endif
	let thisBufNo=StrListTok(g:VGHlpBufs,'g:VGHlpBufs',':')
	while thisBufNo != ''
		let delB='silent! b'.thisBufNo
		execute delB
		silent! bwipeout
		let thisBufNo=StrListTok('','g:VGHlpBufs')
	endwhile
	unlet! g:VGHlpBufs
endfunction

let s:depth=0

function! s:getDirFiles(thisFile,doSubs,fpat,mpat,fileRef)
	let thisFile=glob(a:thisFile)
	let fpat=a:fpat
	let mpat=a:mpat
	let Ret=0
	if mpat != '' && match(thisFile,mpat) != -1
		return
	endif
	let theFiles=a:fileRef
	if isdirectory(thisFile)
		let trailChar=thisFile[strlen(thisFile)-1]
		if trailChar != '/' && trailChar != '\'
			let tmpFiles=glob(thisFile.'/*')
		else
			let tmpFiles=glob(thisFile.'*')
		endif
		if tmpFiles != ''
			let b:subFiles{s:depth}=tmpFiles
			let tmpFname{s:depth}="b:subFiles".s:depth
			let tmpFile{s:depth}=StrListTok(tmpFiles,tmpFname{s:depth})
			while tmpFile{s:depth} != ''
				let argFile=tmpFile{s:depth}
				if isdirectory(argFile) && a:doSubs
					let s:depth=s:depth+1
					call s:getDirFiles(argFile,a:doSubs,fpat,mpat,a:fileRef)
					let s:depth=s:depth-1
				else
					if mpat != '' && match(argFile,mpat) != -1
						let tmpFile{s:depth}=StrListTok('',tmpFname{s:depth})
						continue
					endif
					if (fpat != '' && match(argFile,fpat) != -1) || fpat == ''
						let {theFiles}={theFiles}.argFile."\<NL>"
					endif
				endif
				let tmpFile{s:depth}=StrListTok('',tmpFname{s:depth})
			endwhile
			unlet b:subFiles{s:depth}
		endif
		return
	else
		let tmpFiles=glob(thisFile)
		if tmpFiles == ''
			return
		endif
		let b:subFiles{s:depth}=tmpFiles
		let tmpFname{s:depth}="b:subFiles".s:depth
		let tmpFile{s:depth}=StrListTok(tmpFiles,tmpFname{s:depth})
		while tmpFile{s:depth} != ''
			let argFile=tmpFile{s:depth}
			if isdirectory(argFile) && a:doSubs
				let s:depth=s:depth+1
				call s:getDirFiles(argFile,a:doSubs,fpat,mpat,a:fileRef)
				let s:depth=s:depth-1
			else
				if mpat != '' && match(argFile,mpat) != -1
					let tmpFile{s:depth}=StrListTok('',tmpFname{s:depth})
					continue
				endif
				if (fpat != '' && match(argFile,fpat) != -1) || fpat == ''
					let {theFiles}={theFiles}.argFile."\<NL>"
				endif
			endif
			let tmpFile{s:depth}=StrListTok('',tmpFname{s:depth})
		endwhile
		unlet b:subFiles{s:depth}
		return
	endif
	VGMSG "Should not have gotten here!!!",2
	return
endfunction

let s:dirDepth=0

function! s:recurseForDirs(dir,refDirList,MC,mpat)
	let theContents{s:dirDepth}=glob(a:dir.'/*')
	let bContents{s:dirDepth}='b:contents'.s:dirDepth
	let thisEntry{s:dirDepth}=StrListTok(theContents{s:dirDepth},bContents{s:dirDepth})
	while thisEntry{s:dirDepth} != ''
		let matchesMpat=0
		if a:mpat != ''
			if a:MC
				let matchesMpat=thisEntry{s:dirDepth} =~# a:mpat
			else
				let matchesMpat= thisEntry{s:dirDepth} =~? a:mpat
			endif
		endif
		if !matchesMpat
			if isdirectory(thisEntry{s:dirDepth})
				let {a:refDirList}={a:refDirList}.thisEntry{s:dirDepth}."\<NL>"
				let s:dirDepth=s:dirDepth+1
				call s:recurseForDirs(thisEntry{s:dirDepth-1},a:refDirList,a:MC,a:mpat)
				let s:dirDepth=s:dirDepth-1
			endif
		endif
		let thisEntry{s:dirDepth}=StrListTok('',bContents{s:dirDepth})
	endwhile
	unlet! {bContents{s:dirDepth}}
endfunction

function! s:getVRBfname()
	if has("browse")
		let VRBfile=browse(1,'Vimgrep Result Buffer File',expand("%:p:h"),'VimgrepResultBuf.txt')
	else
		let thisDir=expand("%:p:h")
		let VRBfile=input("File Name to save results? ",thisDir.'/VimgrepResultBuf.txt')
		if !QualifiedPath(VRBfile)
			let VRBfile=thisDir.'/'.VRBfile
		endif
	endif
	return VRBfile
endfunction

" strings to identify 'Pattern not found' return
" that won't be confused with normal return (hopefully!)
let s:PatNotFound=nr2char(16).nr2char(14).nr2char(6)."\<NL>"

command! -nargs=+ VimgrepBufsToBuf call BufsToBufVimgrep(<f-args>)

function! BufsToBufVimgrep(srchpat,...)
	if &modified
		VGMSG "current file has been modified - write before continuing",2
		return
	endif
	if bufname('') == ''
		call s:doDummyView()
	endif
	let VRBfile=s:getVRBfname()
	if VRBfile == ''
		VGMSG "Need file name for result buffer",2
		return
	endif
	let s:OrigBuf=b:bufNo
	let OrigLin=line('.')
	let OrigCol=col('.')
	if a:0  && a:1 | let MC=a:1 | else | let MC=g:VGMCDflt | endif
	let Ret=''
	bufdo let Ret=Ret.Vimgrep(a:srchpat,expand("%:p"),MC)
	execute "b".s:OrigBuf
	while Ret[0] == "\<NL>"
		let Ret=strpart(Ret,1)
	endwhile
	if Ret == ''
		VGMSG "No results for : ".a:srchpat,2
		execute 'b'.s:OrigBuf
		call cursor(OrigLin,OrigCol)
		return
	endif
	execute 'edit '.VRBfile
	let holdz=@z
	let @z=Ret
	normal "zP
	let holdWS=&wrapscan
	set wrapscan
	let @/=a:srchpat
	execute "normal \<C-End>"
	silent! normal n
	let &wrapscan=holdWS
	file
	let @z=holdz
endfunction

command! -nargs=+ VimgrepBufs call Pause(BufsVimgrep(<f-args>))

function! BufsVimgrep(srchpat,...)
	if a:0  && a:1 | let MC=a:1 | else | let MC=g:VGMCDflt | endif
	let s:OrigBuf=b:bufNo
	let OrigLin=line('.')
	let OrigCol=col('.')
	let Ret=''
	bufdo let Ret=Ret.Vimgrep(a:srchpat,expand("%:p"),MC)
	execute 'b'.s:OrigBuf
	call cursor(OrigLin,OrigCol)
	return Ret
endfunction

command! -nargs=+ VimgrepHelp call HelpVimgrep(<f-args>)

function! HelpVimgrep(srchpat,...)
	if &modified
		VGMSG "current file has been modified - write before continuing",2
		return
	endif
	if a:0  && a:1 | let MC=a:1 | else | let MC=g:VGMCDflt | endif
	if !exists("g:VGHlpBufs")
		let g:VGHlpBufs=':'
	endif
	let helpFiles=''
	let thePaths=g:VGHlpDirs
	let thisPath=StrListTok(thePaths,'b:runtimepathsVimgrep')
	while thisPath != ''
		let tmpFiles=glob(thisPath.'/doc/*.txt')
		if tmpFiles != ''
			let helpFiles=helpFiles.tmpFiles."\<NL>"
		endif
		let thisPath=StrListTok('','b:runtimepathsVimgrep')
	endwhile
	unlet b:runtimepathsVimgrep
	let helpFiles=Vimgrep(a:srchpat,helpFiles,MC,1,1)
	let thisFile=StrListTok(helpFiles,'b:helpListVimgrep')
	if thisFile == ''
		unlet! b:helpListVimgrep
		return
	endif
	if !MC | let mc='ignorecase' | else | let mc='noignorecase' | endif
	let saveWS=&wrapscan
	set wrapscan
	let @/=a:srchpat
	let tailCmd='setlocal iskeyword+='.g:VGHlpISK.' | '.
		\'setlocal '.mc.' | '.
		\"setlocal filetype=help | ".
		\"setlocal buftype=help | ".
		\"setlocal nomodifiable | ".
		\"let g:VGHlpBufs=g:VGHlpBufs.b:bufNo.':'"
	let startName=thisFile
	while thisFile != ''
		let editCmd="silent! view ".thisFile." | ".tailCmd
		execute editCmd
		execute "normal \<C-End>"
		silent! normal n
		b#
		let thisFile=StrListTok('','b:helpListVimgrep')
	endwhile
	let startBuf=bufnr(startName)
	execute ":b".startBuf
	execute "normal \<C-End>"
	silent! normal n
	let &wrapscan=saveWS
	file
	unlet! b:helpListVimgrep
endfunction

command! -nargs=* VimgrepEdit call EditVimgrep(<f-args>)

function! EditVimgrep(srchpat,file,...)
	if &modified
		VGMSG "current file has been modified - write before continuing",2
		return
	endif
	if a:0  && a:1 | let MC =a:1 | else | let MC      =g:VGMCDflt | endif
	let FNonly=1
	let terse=1
	if a:0 > 3 | let doSubs =a:4 | else | let doSubs =g:VGdoSubsDflt  | endif
	if a:0 > 4 | let fpat   =a:5 | else | let fpat   =g:VGfpatDflt | endif
	if a:0 > 5 | let mpat   =a:6 | else | let mpat   =g:VGmpatDflt | endif
	if fpat == "''" || fpat == '""'
		let fpat=g:VGfpatDflt
	endif
	if mpat == "''" || mpat == '""'
		let mpat=g:VGmpatDflt
	endif
	if !exists("g:VGEdtBufs")
		let g:VGEdtBufs=':'
	endif
	let b:editListVimgrep=''
	let editFiles=Vimgrep(a:srchpat,a:file,MC,FNonly,terse,doSubs,fpat,mpat)
	let thisFile=StrListTok(editFiles,'b:editListVimgrep')
	if thisFile == ''
		unlet! b:editListVimgrep
		return
	endif
	if !MC | let mc='ignorecase' | else | let mc='noignorecase' | endif
	let saveWS=&wrapscan
	set wrapscan
	let @/=a:srchpat
	let tailCmd=
		\'setlocal '.mc.' | '.
		\"let g:VGEdtBufs=g:VGEdtBufs.b:bufNo.':'"
	let startName=thisFile
	while thisFile != ''
		if !buflisted(thisFile)
			let itsPath=fnamemodify(thisFile,":p:h")
			let itsName=fnamemodify(thisFile,":t")
			let itsSwap=itsPath.'/.'.itsName.'.swp'
			let itsSwap=glob(itsSwap)
			if itsSwap == ''
				let editCmd="silent! edit ".thisFile." | ".tailCmd
			else
				let editCmd="silent! view ".thisFile." | setlocal nomodifiable | ".tailCmd
			endif
			execute editCmd
			execute "normal \<C-End>"
			silent! normal n
			silent b#
		endif
		let thisFile=StrListTok('','b:editListVimgrep')
	endwhile
	let startBuf=bufnr(startName)
	let goHome='silent b'.startBuf
	execute goHome
	execute "normal \<C-End>"
	silent! normal n
	let &wrapscan=saveWS
	file
	unlet! b:editListVimgrep
endfunction

command! -nargs=* VimgrepToBuf call ToBufVimgrep(<f-args>)

function! ToBufVimgrep(srchpat,file,...)
	if &modified
		VGMSG "current file has been modified - write before continuing",2
		return
	endif
	if a:0  && a:1 | let MC =a:1 | else | let MC     =g:VGMCDflt  | endif
	if a:0 > 1 | let FNonly =a:2 | else | let FNonly =g:VGFNonlyDflt  | endif
	if a:0 > 2 | let terse  =a:3 | else | let terse  =g:VGterseDflt  | endif
	if a:0 > 3 | let doSubs =a:4 | else | let doSubs =g:VGdoSubsDflt  | endif
	if a:0 > 4 | let fpat   =a:5 | else | let fpat   =g:VGfpatDflt | endif
	if a:0 > 5 | let mpat   =a:6 | else | let mpat   =g:VGmpatDflt | endif
	if fpat == "''" || fpat == '""'
		let fpat=g:VGfpatDflt
	endif
	if mpat == "''" || mpat == '""'
		let mpat=g:VGmpatDflt
	endif
	if bufname('') == ''
		call s:doDummyView()
	endif
	let VRBfile=s:getVRBfname()
	if VRBfile == ''
		VGMSG "Need file name for result buffer",2
		return
	endif
	let holdz=@z
	let @z=Vimgrep(a:srchpat,a:file,MC,FNonly,terse,doSubs,fpat,mpat)
	while @z[0] == "\<NL>"
		let @z=strpart(@z,1)
	endwhile
	if @z == ''
		VGMSG "No results for : ".a:srchpat,2
		let @z=holdz
		return
	endif
	let holdWS=&wrapscan
	let @/=a:srchpat
	set wrapscan
	execute 'edit '.VRBfile
	normal "zP
	execute "normal \<C-End>"
	silent! normal n
	let &wrapscan=holdWS
	file
	let @z=holdz
endfunction

" For backward compatibility.  Previous versions 1.0 and 1.1 use this name
" Only address first 2 optional args as only they existed in 1.0/1.1
function! MiniVimGrep(srchpat,file,...)
	let callMG="let Ret=Vimgrep('".a:srchpat."','".a:file."'"
	if a:0
		let callMG=callMG.','.a:1
		if a:0 > 1
			let callMG=callMG.','.a:2
		endif
	endif
	let callMG=callMG.')'
	execute callMG
	return Ret
endfunction

" Thanks to Hari Krishna Dara for the idea for this one
command! -nargs=* Vimfind call Pause(Vimfind(<f-args>))

" opt args MC doSubs mpat
function! Vimfind(file,fpat,...)
	if !s:validSrchPat(a:fpat)
		return ''
	endif
	if a:0  && a:1 | let MC =a:1 | else | let MC     =g:VGMCDflt  | endif
	if a:0 > 1 | let doSubs =a:2 | else | let doSubs =g:VGdoSubsDflt  | endif
	if a:0 > 2 | let mpat   =a:3 | else | let mpat   =g:VGmpatDflt | endif
	if a:fpat[0] == '\'
		if a:fpat[1] != 'C' && a:fpat[1] != 'c'
			if MC | let fpat='\C'.a:fpat | else | let fpat='\c'.a:fpat | endif
		endif
	else
		if MC | let fpat='\C'.a:fpat | else | let fpat='\c'.a:fpat | endif
	endif
	return Vimgrep('\%$',a:file,0,1,0,doSubs,fpat,mpat)
endfunction

command! -nargs=* Vimgrep call Pause(Vimgrep(<f-args>))

let s:VGdepth=0

function! Vimgrep(srchpat,file,...)
	if !s:validSrchPat(a:srchpat)
		return ''
	endif
	if a:0  && a:1 | let MC =a:1 | else | let MC     =g:VGMCDflt  | endif
	if a:0 > 1 | let FNonly =a:2 | else | let FNonly =g:VGFNonlyDflt  | endif
	if a:0 > 2 | let terse  =a:3 | else | let terse  =g:VGterseDflt  | endif
	if a:0 > 3 | let doSubs =a:4 | else | let doSubs =g:VGdoSubsDflt  | endif
	if a:0 > 4 | let fpat   =a:5 | else | let fpat   =g:VGfpatDflt | endif
	if a:0 > 5 | let mpat   =a:6 | else | let mpat   =g:VGmpatDflt | endif
	if fpat == "''" || fpat == '""'
		let fpat=g:VGfpatDflt
	endif
	if mpat == "''" || mpat == '""'
		let mpat=g:VGmpatDflt
	endif
	if bufname('') == ''
		call s:doDummyView()
	endif
	let aFile=a:file
	if aFile == '%' || aFile == '' || aFile == "''" || aFile == '""' || aFile == '.'
		if doSubs || fpat != '' || mpat != ''
			let aFile=expand("%:p:h")
		else
			let aFile=expand("%:p")
		endif
	endif
	if aFile == '*'
		let aFile=g:VGDirs
	endif
	VGMSG " ".
			\"\<NL>  Search Pattern: ".a:srchpat.
			\"\<NL>  File(s): ".aFile.
			\"\<NL>  MC=".MC." FNonly=".FNonly." terse=".terse." doSubs=".doSubs.
			\"\<NL>  fpat: ".fpat.
			\"\<NL>  mpat: ".mpat
	let b:theArgList=''
	let theArg=StrListTok(aFile,'b:theArgs')
	while theArg != ''
		VGMSG "(1) theArg=".theArg
		let tmpArg=theArg
		let theArg=glob(tmpArg)
		VGMSG "(2) theArg=".theArg
		if theArg == ''
			try
				execute 'let theArg=expand('.tmpArg.')'
			catch
				let theArg=''
			endtry
		VGMSG "(3) theArg=".theArg
			if theArg == ''
				try
					execute 'let theArg=expand("'.{tmpArg}.'")'
				catch
					let theArg=''
				endtry
			endif
		endif
		VGMSG "(4) theArg=".theArg
		if !QualifiedPath(theArg)
			let theArg=''
			let b:dfltDirs=g:VGDirs
			if doSubs
				let b:allSubs=''
				let dfltDir=StrListTok(b:dfltDirs,'b:dfltDirs')
				while dfltDir != ''
					call s:recurseForDirs(dfltDir,'b:allSubs',MC,mpat)
					let dfltDir=StrListTok('','b:dfltDirs')
				endwhile
				let b:dfltDirs=g:VGDirs
				if b:allSubs != ''
					let b:dfltDirs=b:dfltDirs.','.b:allSubs
				endif
				unlet b:allSubs
			endif
			let dfltDir=StrListTok(b:dfltDirs,'b:dfltDirs')
			while dfltDir != ''
				let thisResult=glob(dfltDir.'/'.tmpArg)
				if thisResult != ''
					let theArg=theArg.thisResult."\<NL>"
				endif
				let dfltDir=StrListTok('','b:dfltDirs')
			endwhile
			unlet b:dfltDirs
		endif
		if theArg == ''
			VGMSG "Could not resolve file argument: ".tmpArg,1
		else
			let b:theArgList=b:theArgList.theArg."\<NL>"
		endif
		let theArg=StrListTok('','b:theArgs')
	endwhile
	VGMSG "b:theArgList:\<NL>".b:theArgList
	if b:theArgList == ''
		VGMSG "No arguments to process from file argument: ".aFile,2
		return ''
	endif
	let Ret="\<NL>"
	let b:fileListVimgrep=''
	let thisFile=StrListTok(b:theArgList,'b:theArgList')
	while thisFile != ''
		VGMSG " ".
		\"\<NL>  Getting Files from:".
		\"\<NL>    ".thisFile.
		\"\<NL>  That match the pattern: ".fpat.
		\"\<NL>  And don't match the pattern:".mpat.
		\"\<NL>  Doing subdirectories=".doSubs
		call s:getDirFiles(thisFile,doSubs,fpat,mpat,'b:fileListVimgrep')
		let thisFile=StrListTok('','b:theArgList')
	endwhile
	VGMSG "b:fileListVimgrep:\<NL>".b:fileListVimgrep
	if b:fileListVimgrep == ''
		let thisFile=StrListTok(theArg,'b:fileListVimgrep')
	else
		let thisFile=StrListTok(b:fileListVimgrep,'b:fileListVimgrep')
	endif
	while thisFile != ''
"		let thisFile=fnamemodify(thisFile,":p")
"		if glob(thisFile) == ''
"			let thisFile=StrListTok('','b:fileListVimgrep')
"			continue
"		endif
"		if fpat != '' && match(thisFile,fpat) == -1
"			let thisFile=StrListTok('','b:fileListVimgrep')
"			continue
"		endif
		if isdirectory(thisFile)
			if !terse
				let Ret=Ret."Vimgrep: ".thisFile.": Directory\<NL>"
			endif
			let thisFile=StrListTok('','b:fileListVimgrep')
			continue
		endif
		if a:srchpat == '\%$' && FNonly
			let Ret=Ret.thisFile."\<NL>"
			let thisFile=StrListTok('','b:fileListVimgrep')
			continue
		endif
		if s:isNonTextFile(thisFile)
			if !terse
				let Ret=Ret."Vimgrep: ".thisFile.": Non Text\<NL>"
			endif
			let thisFile=StrListTok('','b:fileListVimgrep')
			continue
		endif
		if !buflisted(thisFile)
			let isEmptyCmd='silent! view '.thisFile.' | '.
				\'let zBytes=line2byte(line("$")) | let lBytes=strlen(getline(1)) | silent! bwipeout'
			execute isEmptyCmd
			let emptyFile=zBytes == -1 || (zBytes == 1 && lBytes == 0)
			if emptyFile
				if !terse
					let Ret=Ret."Vimgrep: ".thisFile.": Empty File\<NL>"
				endif
				let thisFile=StrListTok('','b:fileListVimgrep')
				continue
			endif
		endif
		let theResult=s:vimGrep(a:srchpat,thisFile,MC,FNonly)
		if (FNonly && theResult == "\<NL>") || !FNonly
			if !terse
				if theResult == s:PatNotFound
					let Ret=Ret."Vimgrep: ".thisFile.": Pattern not found : ".a:srchpat."\<NL>"
				else
					if FNonly
						let Ret=Ret.thisFile.theResult
					else
						let Ret=Ret.thisFile.": ".theResult
					endif
				endif
			elseif theResult != s:PatNotFound
				if FNonly
					let Ret=Ret.thisFile.theResult
				else
					let Ret=Ret.thisFile.": ".theResult
				endif
			endif
		endif
		let thisFile=StrListTok('','b:fileListVimgrep')
	endwhile
	unlet! b:fileListVimgrep
	return Ret
endfunction

function! s:vimGrep(srchpat,file,mc,fnonly)
	if a:mc == 1 | let IC='noignorecase' | else | let IC='ignorecase' | endif
	let FNonly=a:fnonly
	" Note: first line has to be checked independently as the search pattern may
	"       match line 1, col 1 and normal matches start with the first
	"       character _after_ the cursor.
	let origlin=line('.')
	let origcol=col('.')
	let NL="\<NL>"
	let Ret=NL
	let bufIsListed=buflisted(a:file)
	let openCmd=
		\'silent! view '.a:file
	if !bufIsListed
		try
			execute openCmd
		catch
			let Ret=Ret.s:thisScript."::".expand("<sfile>").": Could not open ".a:file." for searching".NL
			let Ret=Ret.v:errmsg.NL
			return Ret
		endtry
	else
		execute "b".bufnr(a:file)
	endif
	let setupCmd=
		\"let saveIC=&ignorecase | set ".IC." | ".
		\"let saveWS=&wrapscan | set nowrapscan | ".
		\"let lastLine=0 | ".
		\"let thePat='".a:srchpat."'"
	try
		execute setupCmd
	catch
		let Ret=Ret.s:thisScript."::".expand("<sfile>").": Set up ".a:file." for searching failed".NL
		if !bufIsListed
			silent! bwipeout
		endif
		let &wrapscan=saveWS
		let &ignorecase=saveIC
		return Ret
	endtry
	let thePat=a:srchpat
	let lastLine=0
	let cline=getline(1)
	if match(cline,thePat) != -1
		let Ret=Ret.'1:'.cline.NL
	endif
	call cursor(1,col($))
	let matchedIt=0
	let srchCmd=
		\"silent! /".a:srchpat."\\|\\%$/"
	try
		execute srchCmd
	catch
		let Ret=Ret.s:thisScript."::".expand("<sfile>").": Search of ".a:file." for ".a:srchpat." failed".NL
		let Ret=Ret.v:errmsg.NL
		if !bufIsListed
			silent! bwipeout
		endif
		let &wrapscan=saveWS
		let &ignorecase=saveIC
		call cursor(origlin,origcol)
		return Ret
	endtry
	let cline=getline('.')
	if match(cline,thePat) != -1 && FNonly
		if !bufIsListed
			silent! bwipeout
		endif
		let &wrapscan=saveWS
		let &ignorecase=saveIC
		call cursor(origlin,origcol)
		return NL
	endif
	let lNum=line('.')
	let lastLine=lNum
	while match(cline,thePat) != -1 && lastLine != line('$')
		let Ret=Ret.lNum.':'.cline.NL
		try
			execute srchCmd
		catch
			let Ret=Ret.s:thisScript."::".expand("<sfile>").": Search of ".a:file." for ".a:srchpat." failed".NL
			let Ret=Ret.v:errmsg.NL
			if !bufIsListed
				silent! bwipeout
			endif
			let &wrapscan=saveWS
			let &ignorecase=saveIC
			call cursor(origlin,origcol)
			return Ret
		endtry
		let cline=getline('.')
		let lNum=line('.')
		let lastLine=lNum
	endwhile
	if !bufIsListed
		silent! bwipeout
	endif
	let &wrapscan=saveWS
	let &ignorecase=saveIC
	let emptyResult=Ret == NL || match(Ret,'^\s*$') != -1
	if emptyResult
		call cursor(origlin,origcol)
		return s:PatNotFound
	endif
	call cursor(origlin,origcol)
	return Ret
endfunction
