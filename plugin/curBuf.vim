" Vim plugin for source/execute of the current buffer
" Language:    * (various)
" Maintainer:  Dave Silvia <dsilvia@mchsi.com>
" Date:        8/8/2004
"
" Version 1.1
"   Fixed:
"     -  problem with spaces in path name
"        when exec-ing a file.

" SUMMARY:
"
" Non GUI:
"
"  in your plugin directory
"
"      let curBufRunKey=<your choice>
"      let curBufExeKey=<your choice>
"
"  or source it in vimrc
"
"      let curBufRunKey=<your choice>
"      let curBufExeKey=<your choice>
"      runtime plugin/curBuf.vim
"
" Include GUI:
"
"  in your plugin directory
"
"      let curBufRunKey=<your choice>
"      let curBufExeKey=<your choice>
"      let curBufRunIco=<your choice>
"      let curBufExeIco=<your choice>
"
"  or source it in vimrc
"
"      let curBufRunKey=<your choice>
"      let curBufExeKey=<your choice>
"      let curBufRunIco=<your choice>
"      let curBufExeIco=<your choice>
"      runtime plugin/curBuf.vim
"
" END SUMMARY:
"
" Where:
"
"      curBuf[Run|Exe]Key are the {lhs} of the key mappings.  If these are not
"      specified, they default to '<F8>' and '<F9>', respectively.
"
"      curBuf[Run|Exe]Ico are the icons to use in the Tool Bar.  If these are
"      not specified, they default to 'speed' and 'lightning', respectively.
"
" See:
"      :h map.txt
"      :h map
"      :h {lhs}
"
"      to see how to set curBuf[Run|Exe]Key.
"
"      :h icon=
"
"      to see how curBuf[Run|Exe]Ico are used.
"
" Note:
"      Use the first SUMMARY: example if you are loading many plugins, the
"      second example to only load 'curBuf.vim'
"
"      Non GUI methodology is for environments compiled without GUI support.
"      Include GUI methodology is for environments that include GUI support.
"
"      **** 'let' statements are optional.  If not specified, defaults apply.
"
" See:
"      :h filetype
"      :h filetype-plugin
"      :h runtime
"      :h runtimepath


" functions to source/execute the current buffer
function s:SrcIt()
	update
	source %
endfunction
function s:ExeIt()
	update
	let execScriptPath=expand("%:p")
	if match(execScriptPath,'\s')
		let execScriptPath='"'.execScriptPath.'"'
	endif
	execute '!'.execScriptPath
endfunction
" add mappings for same... if you don't want f8/f9, change to your
" preference with 'let curBuf[Run|Exe]Key=' before you source this script
" SEE: SUMMARY: above
if !exists("curBufRunKey")
	let curBufRunKey='<F8>'
endif
if !exists("curBufExeKey")
	let curBufExeKey='<F9>'
endif
let s:mapIt='map '.curBufRunKey.' :call <SID>SrcIt()<CR>'
execute s:mapIt
let s:mapIt='map '.curBufExeKey.' :call <SID>ExeIt()<CR>'
execute s:mapIt

" if gui, add to menus
if !has("gui") || !has("gui_running")
	finish
endif
" add 'Current Buffer' menu
let s:menuIt='amenu &User\ Specific.&Current\ Buffer.&Source<TAB>'.curBufRunKey.' :call <SID>SrcIt()<CR>' 
execute s:menuIt
let s:menuIt='amenu &User\ Specific.&Current\ Buffer.&Execute<TAB>'.curBufExeKey.' :call <SID>ExeIt()<CR>' 
execute s:menuIt
if !exists("curBufRunIco")
	let curBufRunIco='speed'
endif
if !exists("curBufExeIco")
	let curBufExeIco='lightning'
endif
" ditto ToolBar... if you don't want the default icons, change to your
" preference with 'let curBuf[Run|Exe]Ico=' before you source this script
" SEE: SUMMARY: above
amenu 1.242 ToolBar.-242- <Nop>
let s:menuIt='amenu icon='.curBufRunIco.' 1.243 ToolBar.Source\ Current\ Buffer :call <SID>SrcIt()<CR>'
execute s:menuIt
let s:menuIt='amenu icon='.curBufExeIco.' 1.244 ToolBar.Execute\ Current\ Buffer :call <SID>ExeIt()<CR>'
execute s:menuIt
" 'roll over' help...
tmenu ToolBar.Source\ Current\ Buffer Source Current Buffer
tmenu ToolBar.Execute\ Current\ Buffer Execute Current Buffer
