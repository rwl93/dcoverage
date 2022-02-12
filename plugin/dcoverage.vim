" Vim filetype plugin for generating and reading clover reports
" Maintainer: Randy Linderman <randolph.linderman@gmail.com>
" License:	This file is placed in the public domain.
if exists("b:loaded_dcoverage")
  finish
endif
let g:loaded_dcoverage = 1
echo "dcoverage loading..."

let s:save_cpo = &cpo
set cpo&vim

function! s:restore_cpo()
  let &cpo = s:save_cpo
  unlet s:save_cpo
endfunction

function! s:buffer_enter()
    if get(g:, "vim_dcoverage_autoload", 1) == 0
        return
    endif

    if get(b:, "dcov_gradle_project_root", '') != ''
        return
    endif

    let l:path = expand('%:p:h')
    if l:path =~ "^fugitive:"
        return
    endif

    call s:load_from(l:path)
endfunction

function! s:load_from(path)
  let l:build_file_name = 'build.gradle'
  let b:dcov_gradle_project_root = s:find_project_root(a:path, l:build_file_name)
  if b:dcov_gradle_project_root != ''
    call dcoverage#load_project(b:dcov_gradle_project_root)
    return 1
  endif
  return 0
endfunction

function! s:find_project_root(path, build_file_name)
  let l:build_file = findfile(a:build_file_name, a:path . ';$HOME')
  if l:build_file == ''
    return ''
  else
    let l:next_path = fnamemodify(l:build_file, ':p:h:h')
    let l:result = s:find_project_root(l:next_path, a:build_file_name)
    if l:result == ''
      return fnamemodify(l:build_file, ':p:h')
    else
      return l:result
    endif
  endif
endfunction

augroup dcoverage
  autocmd!
  autocmd BufEnter * call s:buffer_enter()
augroup END

call s:restore_cpo()
