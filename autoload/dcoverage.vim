" Autoload functions for dcoverage
" Gradle Api (adapted from hdiniz/vim-gradle) {{{1
" Setup {{{2
let s:script_path = tolower(resolve(expand('<sfile>:p:h')))
let s:gradle_folder_path = escape( expand( '<sfile>:p:h:h' ), '\' ) . '/gradle'

let s:default_vim_gradle_properties = {
    \ 'vim.gradle.enable.rtp': '1',
    \ 'vim.gradle.build.welcome': 'Built with vim-gradle plugin'
    \ }

let s:default_vim_gradle_extensions = [
    \ '"'.s:gradle_folder_path.'/java.gradle"',
    \ '"'.s:gradle_folder_path.'/kotlin.gradle"',
    \ '"'.s:gradle_folder_path.'/test.gradle"',
    \ ]

" https://github.com/vim-airline/vim-airline/blob/master/autoload/airline/extensions.vim
function! s:extension_scripts()
    let l:scripts =  copy(s:default_vim_gradle_extensions)
    for l:file in split(globpath(&rtp, 'autoload/gradle/extensions/*.vim'), '\n')
        if stridx(tolower(resolve(fnamemodify(file, ':p'))), s:script_path) < 0
            \ && stridx(tolower(fnamemodify(file, ':p')), s:script_path) < 0
        let l:name = fnamemodify(l:file, ':t:r')
        try
            for l:script in gradle#extensions#{l:name}#build_scripts()
               let l:scripts += ['"'.l:script.'"']
            endfor
        catch
        endtry
      endif
    endfor
    return "[".join(l:scripts, ',')."]"
endfunction
" 2}}}
" Project setup (Private helpers) {{{2
let s:projects = {}

function! s:NopFunc() abort
endfunction

let s:project = {
    \ 'last_sync': localtime(),
    \ 'open_buffers': 0,
    \ 'build_job': 0,
    \ 'build_buffer': 0,
    \ 'coverage_buffer': 0,
    \ 'quickfix_file': '',
    \ 'gradle_log_file': '',
    \ 'coverage_file': '',
    \ 'last_compile_args': [],
    \ 'post_compilation_function' : function("s:NopFunc"),
    \ 'signs_visible': v:false,
    \ }

function! s:project.is_building() dict
    if has('nvim')
        return self.build_job != 0
    else
        return type(self.build_job) == 8
    endif
endfunction

function! s:build_file(root_folder) abort
  let l:file = '/build.gradle'
  if filereadable(a:.root_folder . l:file)
    return a:root_folder . l:file
  endif
  throw 'Build file for project ' . a:root_folder  . ' not found'
endfunction

function! s:wrapper(root_folder)
  let l:ext = ''
  if has('win32') || has('win64')
    let l:ext = '.bat'
  endif
  let l:wrapper = a:root_folder . '/gradlew' . l:ext
  if filereadable(l:wrapper)
    return l:wrapper
  endif
  return ''
endfunction

function! s:create_project(root_folder) abort
  let l:project = copy(s:project)
  call extend(l:project, {
        \ 'root_folder': a:root_folder,
        \ 'wrapper': s:wrapper(a:root_folder),
        \ 'last_sync': localtime(),
        \ 'build_file': s:build_file(a:root_folder)
        \ })

  let s:projects[a:root_folder] = l:project
  return l:project
endfunction

function! s:get_proj(root_folder) abort
  if has_key(s:projects, a:root_folder)
    return get(s:projects, a:root_folder)
  else
    return s:create_project(a:root_folder)
  endif
endfunction
" 2}}}
" Project loading (Public API) {{{2
function! dcoverage#load_project(root_project_folder) abort
  let l:project = s:get_proj(a:root_project_folder)
  if type(l:project) == type({})
    call dcoverage#define_buffer_cmds()
  endif
endfunction

function! dcoverage#get_proj(root_folder) abort
    if has_key(s:projects, a:root_folder)
        return get(s:projects, a:root_folder)
    else
        return s:create_project(a:root_folder)
    endif
endfunction

function! dcoverage#current_proj()
    if exists('b:dcov_gradle_project_root')
        return dcoverage#get_proj(b:dcov_gradle_project_root)
    else
        return v:null
    endif
endfunction
" 2}}}
" Get Gradle executable (Private) {{{2
function! s:gradle_home()
    if exists('g:vim_gradle_home')
        return g:vim_gradle_home
    endif

    if exists('$GRADLE_HOME')
        return $GRADLE_HOME
    endif
endfunction

function! s:gradlecmd()
    if exists('g:vim_gradle_bin')
        return g:vim_gradle_bin
    endif

    if executable(s:gradle_home() . '/bin/gradle')
        return s:gradle_home() . '/bin/gradle'
    endif

    if executable('gradle')
        return 'gradle'
    endif

    return ''
endfunction

function! s:project.cmd() dict
    return self.wrapper != '' ? self.wrapper : s:gradlecmd()
endfunction
" 2}}}
" Utils for building windows (Public) {{{2
function! dcoverage#refresh_airline()
  if exists(':AirlineRefresh')
    exec 'AirlineRefresh'
    exec 'redrawstatus'
  endif
endfunction

"
" position
" size
" buffer_nr
" relative_to
" relative_position
" filename
" alternative_name
" filetype
" modifiers
function! dcoverage#create_win_for(opt)
  let l:position = get(a:opt, 'position', 'below')
  let l:size = get(a:opt, 'size', '')
  let l:buffer_nr = get(a:opt, 'buffer_nr', 0)
  let l:relative_to = get(a:opt, 'relative_to', 0)
  let l:relative_position = get(a:opt, 'relative_position', 'vertical')
  let l:relative_size = get(a:opt, 'relative_size', '')
  let l:filename = get(a:opt, 'filename', '')
  let l:alternative_name = get(a:opt, 'alternative_name', '')
  let l:filetype = get(a:opt, 'filetype', '')
  let l:modifiers = get(a:opt, 'modifiers', '')

  let l:has_relative = l:relative_to != 0 && bufwinnr(l:relative_to) != -1
  let l:cur_win = winnr()

  let l:open_cmd = 'new'
  if l:filename != ''
    let l:open_cmd = 'sp '.l:filename
  endif

  let l:position_and_size = l:position.' '.l:size.' '
  if l:has_relative
    let l:position_and_size = l:relative_position.' '.l:position.' '.l:relative_size
  endif

  if l:has_relative
    exec bufwinnr(l:relative_to).'wincmd w'
  endif

  if l:buffer_nr == 0
    exec l:position_and_size.' '.l:open_cmd
    silent! setlocal buftype=nofile nobuflisted noswapfile nonumber nowrap
    exec 'silent! setlocal '.l:modifiers
    exec 'silent! setlocal filetype='.l:filetype
    if l:alternative_name != ''
      execute 'silent! file '.l:alternative_name
    endif
    let l:buffer_nr = bufnr('%')
  else
    let l:winnr = bufwinnr(l:buffer_nr)
    if l:winnr != -1
      exec l:winnr.'wincmd w'
    else
      exec l:position_and_size.'sp'
      exec 'b'. l:buffer_nr
    endif
  endif

  if l:has_relative
    exec l:cur_win.'wincmd w'
    exec bufwinnr(l:buffer_nr).'wincmd w'
  endif

  return l:buffer_nr
endfunction
" 2}}}
" Create output window for gradle job {{{2
function! s:project.toggle_output_win() dict
  if bufwinnr(self.build_buffer) != -1
    call self.close_output_win()
  else
    call self.open_output_win(0)
  endif
endfunction

function! s:project.close_output_win() dict
  let l:winnr = bufwinnr(self.build_buffer)
  if l:winnr != -1
    exec l:winnr.'wincmd c'
  endif
endfunction

function! s:project.open_output_win(clean) dict
  let l:opts = {
        \ 'buffer_nr': self.build_buffer,
        \ 'filetype': 'gradle-build',
        \ 'position': 'belowright',
        \ 'size': '15',
        \ 'relative_to': self.coverage_buffer,
        \ 'alternative_name': self.root_folder .':\ gradle\ '. join(self.last_compile_args, '\ '),
        \ }

  let self.build_buffer = dcoverage#create_win_for(l:opts)
  let b:dcov_gradle_project_root = self.root_folder
  let b:dcov_output_win = 1
  call gradle#define_buffer_cmds()
  call gradle#utils#refresh_airline()

  if a:clean
    exec ':%d'
  endif
endfunction
" 2}}}
" Create window for coverage summary {{{2
function! s:project.toggle_coverage_win() dict
    if bufwinnr(self.coverage_buffer) != -1
        call self.close_coverage_win()
    else
        call self.open_coverage_win(0)
    endif
endfunction

function! s:project.close_coverage_win() dict
    let l:winnr = bufwinnr(self.coverage_buffer)
    if l:winnr != -1
        exec l:winnr.'wincmd c'
    endif
endfunction

function! s:project.open_coverage_win(clean) dict
  let l:opts = {
        \ 'buffer_nr': self.coverage_buffer,
        \ 'filetype': 'dcoverage',
        \ 'position': 'belowright',
        \ 'size': '30',
        \ 'relative_to': self.build_buffer,
        \ 'alternative_name': 'Coverage Results',
        \ 'modifiers': 'signcolumn=no colorcolumn=""'
        \ }

  let self.coverage_buffer = dcoverage#create_win_for(l:opts)
  let b:dcov_gradle_project_root = self.root_folder
  let b:dcov_coverage_win = 1
  call gradle#define_buffer_cmds()
  call gradle#utils#refresh_airline()

  if a:clean
    exec ':%d'
  endif
endfunction
" 2}}}
" Vim job_start args {{{2
function! s:project.compiler_out(ch, msg) dict
endfunction

function! s:project.compiler_callback(ch, msg) dict
endfunction

function! s:project.compiler_exited(job, status) dict
  call self.compilation_done()
endfunction

function! s:project.compilation_done() dict
  let l:errorformat = &errorformat
  let &errorformat = "%t:\ %f:%l:%c\ %m,%t:\ %f:%l\ %m,%t:\ %f\ %m"
  exec 'cgetfile ' . self.quickfix_file
  let &errorformat = l:errorformat
  let self.build_job = 0
  call self.post_compilation_function()
  let self.post_compilation_function = function("s:NopFunc")
  call dcoverage#refresh_airline()
endfunction
" 2}}}
" NeoVim Job callback {{{2
" NeoVim uses jobstart {opts} as `self` dict in callback
function! s:nvim_job_out(ch, msg, event) dict
  call nvim_buf_set_lines(self.out_buf, -1, -1, v:true, a:msg)
endfunction

function! s:nvim_job_exit(job, data, event) dict
  let l:project = dcoverage#get_proj(self.root_folder)
  call l:project.compilation_done()
endfunction
" 2}}}
" Gradle generate clover report job handling (Private) {{{2
function! s:vim_gradle_properties()
  let l:args = []
  for l:key in keys(s:default_vim_gradle_properties)
    let l:global_key = substitute(l:key, "\\.", "_", "g")
    let l:value = get(g:, l:global_key, get(s:default_vim_gradle_properties, l:key))
    let l:arg = '-P'.l:key.'='.l:value
    let l:args += [l:arg]
  endfor

  return l:args
endfunction

function! s:make_cmd()
  let l:project = dcoverage#current_proj()

  return [
        \ l:project.cmd(),
        \ '--console',
        \ 'plain',
        \ '-I',
        \ s:gradle_folder_path . '/init.gradle',
        \ '-b',
        \ l:project.build_file
        \ ] + s:vim_gradle_properties()
endfunction

function! s:project.compile(cmd, args) dict
  if self.is_building()
    echom "Please wait until current build is finished"
    return
  endif

  if has('nvim')
    let l:compile_options = {
          \ 'on_stdout': function('s:nvim_job_out'),
          \ 'on_stderr': function('s:nvim_job_out'),
          \ 'on_exit': function('s:nvim_job_exit'),
          \ 'root_folder': self.root_folder,
          \ }
  else
    let l:compile_options = {
          \ 'in_mode': 'raw',
          \ 'out_mode': 'nl',
          \ 'err_mode': 'nl',
          \ 'in_io': 'null',
          \ 'out_io': 'buffer',
          \ 'err_io': 'out',
          \ 'stoponexit': 'term',
          \ 'out_cb': self.compiler_out,
          \ 'exit_cb': self.compiler_exited,
          \ 'callback': self.compiler_callback,
          \ }
  endif

  let self.last_compile_args = a:args
  let self.quickfix_file = tempname()
  let self.gradle_log_file = tempname()
  let self.tests_file = tempname()
  let l:additional_args = [
        \ '-Pvim.gradle.tests.file='.self.tests_file,
        \ '-Pvim.gradle.quickfix.file='.self.quickfix_file,
        \ '-Pvim.gradle.log.file='.self.gradle_log_file
        \ ]
  cclose
  call self.open_output_win(1)
  let l:compile_options['out_buf'] = self.build_buffer
  if has('nvim')
    let self.build_job = jobstart(a:cmd + a:args + l:additional_args, l:compile_options)
  else
    let self.build_job = job_start(a:cmd + a:args + l:additional_args, l:compile_options)
  endif
  wincmd p
endfunction

function! s:gen_clover_report() abort
  let l:project = dcoverage#current_proj()
  let l:cmd = s:make_cmd()
  call l:project.compile(l:cmd, ["clean", "cloverGenerateReport"])
endfunction
" 2}}}
" }}}
" Parse clover report {{{
let s:coverage_template = {
  \ 'coveredstatements': 0,
  \ 'coveredconditionals': 0,
  \ 'statements': 0,
  \ 'conditionals': 0,
  \ 'coverage_percent': 0.0,
  \ 'coveredstmt_lns': [],
  \ 'uncoveredstmt_lns': [],
  \ 'coveredcond_lns': [],
  \ 'partialcoveredcond_lns': [],
  \ 'uncoveredcond_lns': [],
  \ 'fullyqualifiedname': '',
  \ 'adjname': '',
  \ 'path': '',
  \ 'package': '',
  \ }

function! s:coverage_template.extract_file_info(currline) dict
  let self.path = matchstr(a:currline, 'path="\zs.\{-}\ze"')
  let l:filenameext = fnamemodify(self.path, ":t")
  let l:filename = fnamemodify(self.path, ":t:r")
  let self.fullyqualifiedname = self.package . "." . l:filenameext
  let self.adjname = self.package . "." . l:filename
endfunction

function! s:coverage_template.extract_file_metrics(currline) dict
  let self.coveredstatements = matchstr(a:currline, 'coveredstatements="\zs.\{-}\ze"')
  let self.coveredconditionals = matchstr(a:currline, 'coveredconditionals="\zs.\{-}\ze"')
  let self.statements = matchstr(a:currline, ' statements="\zs.\{-}\ze"')
  let self.conditionals = matchstr(a:currline, ' conditionals="\zs.\{-}\ze"')
  let l:coveredtot = 1.0 * (self.coveredstatements + self.coveredconditionals)
  let l:alltot = 1.0 * (self.statements + self.conditionals)
  if l:alltot > 0
    let self.coverage_percent = 100.0 * (l:coveredtot / l:alltot)
  else
    let self.coverage_percent = 100.0
  endif
endfunction

function! s:coverage_template.extract_stmt_data(currline) dict
  if matchstr(a:currline, 'count="\zs.\{-}\ze"') > 0
    call add(self.coveredstmt_lns, matchstr(a:currline, 'num="\zs.\{-}\ze"'))
  else
    call add(self.uncoveredstmt_lns, matchstr(a:currline, 'num="\zs.\{-}\ze"'))
  endif
endfunction

function! s:coverage_template.extract_cond_data(currline) dict
  let l:condtruecount = matchstr(a:currline, 'truecount="\zs.\{-}\ze"')
  let l:condfalsecount = matchstr(a:currline, 'falsecount="\zs.\{-}\ze"')
  let l:condlinenum = matchstr(a:currline, 'num="\zs.\{-}\ze"')
  " If tests true and false branches then covered
  " Else If tests the true or false branch then partial
  " Else uncovered
  if l:condtruecount > 0 && l:condfalsecount > 0
    call add(self.coveredcond_lns, l:condlinenum)
  elseif l:condtruecount > 0 || l:condfalsecount > 0
    call add(self.partialcoveredcond_lns, l:condlinenum)
  else
    call add(self.uncoveredcond_lns, l:condlinenum)
  endif
endfunction

function! s:coverage_template.extract_line_data(currline) dict
  if !empty(matchstr(a:currline, 'type="stmt"'))
    call self.extract_stmt_data(a:currline)
  endif
  if !empty(matchstr(a:currline, 'type="cond"'))
    call self.extract_cond_data(a:currline)
  endif
endfunction

function! s:project.parse_clover() dict
  " Load clover file
  let l:cloverfile = self.root_folder . '/app/build/reports/clover/clover.xml'
  echom "Looking for clover file in " . l:cloverfile
  if !filereadable(l:cloverfile)
    let l:cloverfile = self.root_folder . '/build/reports/clover/clover.xml'
    echom "Looking for clover file in " . l:cloverfile
    if !filereadable(l:cloverfile)
      throw 'Clover report for project not found'
    endif
  endif
  let l:cloverlines = readfile(l:cloverfile,)
  " loop over lines in file and extract coverage info
  let self.coverage_data = {
        \ 'covered_stmt': 0,
        \ 'covered_branch': 0,
        \ 'covered_total': 0.0,
        \ 'covered_percent': 0.0,
        \ 'all_stmt': 0,
        \ 'all_branch': 0,
        \ 'all_total': 0.0,
        \ }
  let l:currlineidx = 0
  let l:currpackage = ''
  while l:currlineidx < len(l:cloverlines)
    let l:currline = get(l:cloverlines, l:currlineidx)
    " read package name from package open tag
    if !empty(matchstr(l:currline, "<package"))
      let l:currpackage = matchstr(l:currline, 'name="\zs.\{-}\ze"')
    endif
    " package close tag
    if !empty(matchstr(l:currline, "</package"))
      let l:currpackage = ''
    endif
    " start loop to gather file data
    if !empty(matchstr(l:currline, "<file"))
      let l:currfilecov = deepcopy(s:coverage_template)
      let l:currfilecov.package = l:currpackage
      call l:currfilecov.extract_file_info(l:currline)
      let l:metrics_set = v:false
      " loop until the file close tag
      while empty(matchstr(l:currline, "</file>"))
        let l:currlineidx += 1
        let l:currline = get(l:cloverlines, l:currlineidx)
        " get file metrics info
        if !empty(matchstr(l:currline, "<metrics")) && !l:metrics_set
          call l:currfilecov.extract_file_metrics(l:currline)
          " update totals
          let self.coverage_data.covered_stmt += l:currfilecov.coveredstatements
          let self.coverage_data.covered_branch += l:currfilecov.coveredconditionals
          let self.coverage_data.all_stmt += l:currfilecov.statements
          let self.coverage_data.all_branch += l:currfilecov.conditionals
          let l:metrics_set = v:true
        endif
        " get line info
        if !empty(matchstr(l:currline, "<line"))
          call l:currfilecov.extract_line_data(l:currline)
        endif
      endwhile
      let self.coverage_data[l:currfilecov.fullyqualifiedname] = l:currfilecov
    endif

    let l:currlineidx += 1
  endwhile
  let self.coverage_data.covered_total = self.coverage_data.covered_stmt +
        \ self.coverage_data.covered_branch
  echom self.coverage_data.covered_total
  let self.coverage_data.all_total = self.coverage_data.all_stmt +
        \ self.coverage_data.all_branch
  echom self.coverage_data.all_total
  if self.coverage_data.all_total > 0.0
    let self.coverage_data.covered_percent =
      \ (100.0 * self.coverage_data.covered_total) / self.coverage_data.all_total
  else
    let self.coverage_data.covered_percent = 100.0
  endif
  echom self.coverage_data.covered_percent
endfunction
" }}}
" Code signs {{{
hi! def dcoverageCoveredStmtColor       ctermbg=White ctermbg=Green  guifg=#FFFFFF guibg=#008700
hi! def dcoverageUncoveredStmtColor     ctermbg=White ctermbg=Red    guifg=#FFFFFF guibg=#870000
hi! def dcoveragePartCoveredBranchColor ctermbg=White ctermbg=Yellow guifg=#FFFFFF guibg=#878700

function! s:define_signs(signs_visible) abort
  if a:signs_visible
    call sign_define([
          \ { "name":   "DcoverageCoveredStmt",
            \ "linehl": "dcoverageCoveredStmtColor",
            \ "texthl": "dcoverageCoveredStmtColor",
            \ "text":   "WC",
            \ },
          \ { "name":   "DcoverageUncoveredStmt",
            \ "linehl": "dcoverageUncoveredStmtColor",
            \ "texthl": "dcoverageUncoveredStmtColor",
            \ "text":   "UC",
            \ },
          \ { "name":   "DcoveragePartCoveredBranch",
            \ "linehl": "dcoveragePartCoveredBranchColor",
            \ "texthl": "dcoveragePartCoveredBranchColor",
            \ "text":   "PC",
            \ },
          \])
  else
    call sign_define([
          \ { "name":   "DcoverageCoveredStmt",
            \ "linehl": "",
            \ "texthl": "",
            \ "text":   "",
            \ },
          \ { "name":   "DcoverageUncoveredStmt",
            \ "linehl": "",
            \ "texthl": "",
            \ "text":   "",
            \ },
          \ { "name":   "DcoveragePartCoveredBranch",
            \ "linehl": "",
            \ "texthl": "",
            \ "text":   "",
            \ },
          \])
  endif
endfunction

function! s:place_signlist(lns, sign, filepath, group) abort
  let l:slist = map(copy(a:lns),
        \{_, val -> {
          \ 'id': 0,
          \ 'name': a:sign,
          \ 'buffer': a:filepath,
          \ 'group': a:group,
          \ 'lnum': val,
          \}
        \})
  call sign_placelist(l:slist)
endfunction

let s:sign_group_name = 'DcoverageSignGroup'

function! s:project.placeSigns() dict
  if exists("self.coverage_data")
    if !exists("DcoverageCoveredStmt")
      call s:define_signs(self.signs_visible)
    endif
    for [l:key, l:value] in items(self.coverage_data)
      " Remove the values not associated with a file
      if type(l:value) != type({}) | continue | endif
      let l:covstmtlns = l:value['coveredstmt_lns']
      let l:uncovstmtlns = l:value['uncoveredstmt_lns']
      let l:covcondlns = l:value['coveredcond_lns']
      let l:parcovcondlns = l:value['partialcoveredcond_lns']
      let l:uncovcondlns = l:value['uncoveredcond_lns']
      let l:fpath = l:value['path']
      if bufnr(l:fpath) != -1
        call s:place_signlist(l:covstmtlns, 'DcoverageCoveredStmt',
              \ l:fpath, s:sign_group_name)
        call s:place_signlist(l:uncovstmtlns, 'DcoverageUncoveredStmt',
              \ l:fpath, s:sign_group_name)
        call s:place_signlist(l:covcondlns, 'DcoverageCoveredStmt',
              \ l:fpath, s:sign_group_name)
        call s:place_signlist(l:parcovcondlns, 'DcoveragePartCoveredBranch',
              \ l:fpath, s:sign_group_name)
        call s:place_signlist(l:uncovcondlns, 'DcoverageUncoveredStmt',
              \ l:fpath, s:sign_group_name)
      endif
    endfor
  endif
endfunction

function! dcoverage#remove_signs() abort
  call sign_unplace(s:sign_group_name)
endfunction

function! s:project.show_signs() dict
  let self.signs_visible = v:true
  call s:define_signs(self.signs_visible)
endfunction

function! s:project.hide_signs() dict
  let self.signs_visible = v:false
  call s:define_signs(self.signs_visible)
endfunction

function! s:project.toggle_signs() dict
  if self.signs_visible
    call self.hide_signs()
  else
    call self.show_signs()
  endif
endfunction
" }}}
" Write coverage summary {{{
function! s:Float2Str(val)
  return printf('%.0f', floor(a:val))
endfunction
function! s:project.calc_columnwidth(valuekey, initval=0) dict
  let l:max_len = a:initval
  for [l:key, l:value] in items(self.coverage_data)
    if type(l:value) != type({}) | continue | endif
    let l:val = l:value[a:valuekey]
    if type(l:val) == type(0.0)
      let l:val = s:Float2Str(l:val)
    endif
    if len(l:val) > l:max_len
      let l:max_len = len(l:val)
    endif
  endfor
  return l:max_len + 2 " 2 additional spaces
endfunction

function! s:gen_inner_line(value, column_widths, valuekeys) abort
  let l:values = []
  for l:key in a:valuekeys
    call add(l:values, a:value[l:key])
  endfor
  return s:gen_line(l:values, a:column_widths)
endfunction

function! s:gen_line(values, column_widths) abort
  let l:idx = 0
  let l:output = '|'
  while l:idx < len(a:column_widths)
    let l:val = get(a:values, l:idx)
    if type(l:val) == type(0.0)
      let l:val = s:Float2Str(l:val)
    endif
    let l:vlen = len(l:val)
    let l:cw = get(a:column_widths, l:idx)
    let l:prespaces = (l:cw - l:vlen) / 2
    let l:postspaces = l:cw - (l:prespaces + l:vlen)
    let l:output .= repeat(" ", l:prespaces)
    let l:output .= l:val
    let l:output .= repeat(" ", l:postspaces) . '|'
    let l:idx += 1
  endwhile
  return l:output
endfunction

function! s:gen_sepline(column_widths) abort
  let l:idx = 0
  let l:output = '+'
  for l:colw in a:column_widths
    let l:output .= repeat("-", l:colw) . '+'
  endfor
  return l:output
endfunction

function! s:project.gen_coverage_report() dict
  let l:header = [
        \ "Class Name",
        \ "Total Coverage%",
        \ "Cvrd Stmts",
        \ "Ttl Stmts",
        \ "Cvrd Brs",
        \ "Ttl Brs"]
  let l:valuekeys = ['adjname', 'coverage_percent', 'coveredstatements',
        \ 'statements', 'coveredconditionals', 'conditionals']

  let l:column_widths = [
        \ self.calc_columnwidth(get(l:valuekeys, 0), len(get(l:header, 0))),
        \ self.calc_columnwidth(get(l:valuekeys, 1), len(get(l:header, 1))),
        \ self.calc_columnwidth(get(l:valuekeys, 2), len(get(l:header, 2))),
        \ self.calc_columnwidth(get(l:valuekeys, 3), len(get(l:header, 3))),
        \ self.calc_columnwidth(get(l:valuekeys, 4), len(get(l:header, 4))),
        \ self.calc_columnwidth(get(l:valuekeys, 5), len(get(l:header, 5)))]
  " create header and separator lines
  let l:headerline = s:gen_line(l:header, l:column_widths)
  let l:sepline = s:gen_sepline(l:column_widths)
  " Create list of coverage [percentage, summary string] so that it can be
  " sorted
  let l:file_info = []
  for [l:key, l:value] in items(self.coverage_data)
    if type(l:value) != type({}) | continue | endif
    call add(l:file_info, [
          \ l:value.coverage_percent,
          \ s:gen_inner_line(l:value, l:column_widths, l:valuekeys)])
  endfor
  " sort files by coverage_percent
  call sort(l:file_info, {l,r -> l[0]==r[0] ? 0 : l[0]>r[0] ? 1 : -1})
  " Get totals line
  let l:totals = ['Totals', self.coverage_data.covered_percent,
        \ self.coverage_data.covered_stmt,
        \ self.coverage_data.all_stmt,
        \ self.coverage_data.covered_branch,
        \ self.coverage_data.all_branch]
  let l:totalsline = s:gen_line(l:totals, l:column_widths)
  let l:timeline =  "Text finished at " . strftime("%a %b %d %X")
  let self.coverage_report_lines = [l:sepline, l:headerline, l:sepline,]
        \ + map(copy(l:file_info), {_, v -> v[1]})
        \ + [l:sepline, l:totalsline, l:sepline, '', l:timeline]
endfunction

function! s:project.write_coverage_report(fname) dict
  echom "Saving coverage summary to " . self.root_folder . "/" . a:fname
  call writefile(self.coverage_report_lines, self.root_folder . "/" . a:fname)
endfunction
" }}}
" Generate and show helpers {{{
function! s:PostfunGenAndShow() dict
  call self.close_output_win()
  call self.parse_clover()
  call self.gen_coverage_report()
  call self.open_coverage_win(1)
  " Print coverage report to buffer
  call appendbufline(self.coverage_buffer, 0, self.coverage_report_lines)
  call dcoverage#remove_signs()
  call self.show_signs()
  call self.placeSigns()
endfunction

function! s:PostfunGenAndSave(fname) dict
  call self.close_output_win()
  call self.parse_clover()
  call self.gen_coverage_report()
  call self.write_coverage_report(a:fname)
  call self.open_coverage_win(1)
  " Print coverage report to buffer
  call appendbufline(self.coverage_buffer, 0, self.coverage_report_lines)
  call dcoverage#remove_signs()
  call self.show_signs()
  call self.placeSigns()
endfunction

function! s:generate_and_show_dcoverage() abort
  let l:project = dcoverage#current_proj()
  let l:project.post_compilation_function = s:PostfunGenAndShow
  let l:cmd = s:make_cmd()
  call l:project.compile(l:cmd, ["clean", "cloverGenerateReport"])
endfunction

function! s:generate_and_save_dcoverage(fname='coverage.txt') abort
  let l:project = dcoverage#current_proj()
  let l:project.post_compilation_function = function('s:PostfunGenAndSave', [a:fname,])
  let l:cmd = s:make_cmd()
  call l:project.compile(l:cmd, ["clean", "cloverGenerateReport"])
endfunction
" }}}
" Define Commands and Mappings {{{
function! dcoverage#define_buffer_cmds()
  command! -buffer DcovGenAndShow call s:generate_and_show_dcoverage()
  command! -buffer -nargs=? DcovGenAndSave call s:generate_and_save_dcoverage(<args>)
  command! -buffer DcovGenCloverReport call s:gen_clover_report()
  command! -buffer DcovToggleOutputWin call dcoverage#current_proj().toggle_output_win()
  command! -buffer DcovToggleCoverageWin call dcoverage#current_proj().toggle_coverage_win()
  command! -buffer DcovToggleSigns call dcoverage#current_proj().toggle_signs()
endfunction

nnoremap <unique> <script> <silent> <Plug>DcovGenAndShowCoverage  :call <SID>generate_and_show_dcoverage()<CR>
nnoremap <unique> <script> <silent> <Plug>DcovGenAndSaveCoverage  :call <SID>generate_and_save_dcoverage()<CR>
nnoremap <unique> <script> <silent> <Plug>DcovGenCloverReport     :call <SID>gen_clover_report()<CR>
nnoremap <unique> <script> <silent> <Plug>DcovToggleOutputWin     :call dcoverage#current_proj().toggle_output_win()<CR>
nnoremap <unique> <script> <silent> <Plug>DcovToggleCoverageWin   :call dcoverage#current_proj().toggle_coverage_win()<CR>
nnoremap <unique> <script> <silent> <Plug>DcovToggleSigns         :call dcoverage#current_proj().toggle_signs()<CR>

if !hasmapto('<Plug>DcovGenAndSaveCoverage')
  nmap <unique> <Leader>dg  <Plug>DcovGenAndSaveCoverage
endif
if !hasmapto('<Plug>DcovToggleOutputWin')
  nmap <unique> <Leader>do  <Plug>DcovToggleOutputWin
endif
if !hasmapto('<Plug>DcovToggleCoverageWin')
  nmap <unique> <Leader>dc  <Plug>DcovToggleCoverageWin
endif
if !hasmapto('<Plug>DcovToggleSigns')
  nmap <unique> <Leader>ds  <Plug>DcovToggleSigns
endif
" }}}
" vim: foldmethod=marker : foldlevel=0 :
