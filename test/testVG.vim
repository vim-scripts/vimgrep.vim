" Test suite for Vim plugin script grep utility
" Language:    vim script
" Maintainer:  Dave Silvia <dsilvia@mchsi.com>
" Date:        8/5/2004
"
" For V3.0 of Vimgrep
"
" execute in any vim session in an empty buffer
command! VGtest1 call VGtest1()

" execute in any vim session
command! VGtest2 VimgrepToBuf fun\p*match\w* &runtimepath 0 0 0 1 \w*\.vim\>

" execute in any vim session
command! VGtest3 VimgrepEdit \<try\>\|catch\|fina\%[lly]\|endtry $VIMRUNTIME 1 0 \w*\.vim\>

" execute in any vim session
command! VGtest4 VimgrepHelp $T\w*mp\w*

" execute in any vim session with open listed buffers
command! VGtest5 VimgrepBufs ^\s*fu\%[nction]\%[!]\s\+\p*

" execute in vim session with open listed buffers
command! VGtest6 VimgrepBufsToBuf ^\s*fu\%[nction]\%[!]\s\+\p*

" execute in vim session
command! VGtest7 Vimgrep ^\s*fu\%[nction]\%[!]\s\+\p* match*.vim,vim.vim 0 0 1 1

" execute in vim session
command! VGtest8 Vimgrep ^\s*fu\%[nction]\%[!]\s\+\p* match*.vim,vim.vim,f*.vim,g*.vim 0 1 0 1

" execute in any vim session in an empty buffer
" <args> can be any file(s)
command! -nargs=1 VGtestArgs call VGtestArgs(<args>)

" execute in vim session
command! VGtodo Vimgrep todo $VIMRUNTIME.'/indent/*.vim' 0 0 1

" execute in any vim session in an empty buffer
command! Gtest1 echo Grep('-R --include="*.vim" "fun\w*[	 ]*\w*indent\w*" '.$VIMRUNTIME)

" execute in any vim session
command! Gtest2 call GrepToBuf('-R --include="*.vim" "fun\w*[	 ]*\w*match\w*" '.$VIMRUNTIME)

" execute in any vim session
command! Gtest3 call GrepEdit('-R --include="*.vim" "\<try\>\|catch\|fina[lly]*\|endtry" '.$VIMRUNTIME)

" execute in any vim session
command! Gtest4 GrepHelp $T\w*mp\w*

" execute in any vim session with open listed buffers
command! Gtest5 GrepBufs "^[	 ]*fu[nction!]*[	 ]*[s:]*\w*"

" execute in vim session with open listed buffers
command! Gtest6 GrepBufsToBuf "^[	 ]*fu[nction!]*[	 ]*[s:]*\w*"
" execute in vim session
command! Gtest7 echo Grep('-R --include="match*.vim" --include="vim.vim" "^[ 	]*fu[nction!]*[ 	]*[s:]*\w*" '.$VIMRUNTIME)
"command! VGtest7 Vimgrep ^\s*fu\%[nction]\%[!]\s\+\p* match*.vim,vim.vim 0 0 1 1

function! VGtest1()
	let @a=Vimgrep('fun\p*indent\w*',&runtimepath,0,0,0,1,'\w*\.vim\>')
	normal gg
	normal "aP
endfunction

function! VGtestArgs(args)
	let @a=Vimgrep('\s*fu\%[nction]\%[!]\s\+\p*',a:args,0,0,0,1)
	normal gg
	normal "aP
endfunction

fu! Fu()
endf

fun! Fun()
endfun

	 func! Func()
	 endfunc
