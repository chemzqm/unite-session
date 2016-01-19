"=============================================================================
" FILE: session.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
"          Jason Housley <HousleyJK@gmail.com>
" Last Modified: 06 Jun 2014.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Variables  "{{{
call unite#util#set_default('g:unite_source_session_default_session_name',
      \ 'default')
call unite#util#set_default('g:unite_source_session_path',
      \ unite#get_data_directory() . '/session')
"}}}

function! unite#sources#session#define()"{{{
  return [s:source, s:source_new]
endfunction"}}}

function! unite#sources#session#_save(filename, ...) "{{{
  if unite#util#is_cmdwin()
    return
  endif

  if !isdirectory(g:unite_source_session_path)
    call mkdir(g:unite_source_session_path, 'p')
  endif

  let filename = s:get_session_path(a:filename)

  " Check if this overrides an existing session
  if filereadable(filename) && a:0 && a:1
    call unite#print_error('Session already exists.')
    return
  endif

  execute 'silent mksession!' filename

  echohl MoreMsg
  echo 'Saved session: ' . fnamemodify(v:this_session, ':t:r')
  echohl None
endfunction"}}}

function! unite#sources#session#_load(filename) "{{{
  if unite#util#is_cmdwin()
    return
  endif

  if has('cscope')
    silent! cscope kill -1
  endif

  let filename = s:get_session_path(a:filename)
  if !filereadable(filename)
    call unite#sources#session#_save(filename)
    return
  endif

  noautocmd silent! %bwipeout!
  execute 'silent! source' filename

  for bufnr in range(1, bufnr('$'))
    call setbufvar(bufnr, '&modified', 0)
  endfor
  let g:session_name = filename

  if has('cscope')
    silent! cscope add .
  endif
endfunction"}}}

function! unite#sources#session#_complete(arglead, cmdline, cursorpos)"{{{
  let output = system('ls -F ' . g:unite_source_session_path . '|grep "^' . a:arglead . '"')
  return split(output, "\n")
endfunction"}}}

let s:source = {
      \ 'name' : 'session',
      \ 'description' : 'candidates from session list',
      \ 'default_action' : 'load',
      \ 'alias_table' : { 'edit' : 'open' },
      \ 'action_table' : {},
      \}

function! s:source.gather_candidates(args, context)"{{{
  let sessions = split(glob(g:unite_source_session_path.'/*'), '\n')

  let candidates = map(copy(sessions), "{
        \ 'word' : fnamemodify(v:val, ':t:r'),
        \ 'kind' : 'file',
        \ 'action__path' : v:val,
        \ 'action__directory' : unite#util#path2directory(v:val),
        \}")

  return candidates
endfunction"}}}


" New session only source

let s:source_new = {
      \ 'name' : 'session/new',
      \ 'description' : 'session candidates from input',
      \ 'default_action' : 'save',
      \ 'action_table' : {},
      \}

function! s:source_new.change_candidates(args, context) "{{{
  let input = substitute(substitute(
        \ a:context.input, '\\ ', ' ', 'g'), '^\a\+:\zs\*/', '/', '')
  if input == ''
    return []
  endif

  " Return new session candidate
  return [{ 'word': input, 'abbr': '[new session] ' . input, 'action__path': input }] + 
         \ s:source.gather_candidates(a:args, a:context)
endfunction"}}}

" Actions"{{{
let s:source.action_table.load = {
      \ 'description' : 'load this session',
      \ }

function! s:source.action_table.load.func(candidate)
  if !empty(v:this_session)
    call unite#sources#session#_save(v:this_session)
  endif
  call unite#sources#session#_load(a:candidate.action__path)
endfunction

let s:source.action_table.delete = {
      \ 'description' : 'delete from session list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.delete.func(candidates)"{{{
  for candidate in a:candidates
    if input('Really delete session file: '
          \ . candidate.action__path . '? ') =~? 'y\%[es]'
      call delete(candidate.action__path)
    endif
  endfor
endfunction"}}}
let s:source.action_table.rename = {
      \ 'description' : 'rename session name',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.rename.func(candidates) "{{{
  for candidate in a:candidates
    let session_name = input(printf(
          \ 'New session name: %s -> ', candidate.word), candidate.word)
    if session_name != '' && session_name !=# candidate.word
      call rename(candidate.action__path,
            \ s:get_session_path(session_name))
    endif
  endfor
endfunction"}}}
let s:source.action_table.save = {
      \ 'description' : 'save current session as candidate',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.save.func(candidates) "{{{
  for candidate in a:candidates
    if input('Really save the current session as: '
          \ . candidate.word . '? ') =~? 'y\%[es]'
      call unite#sources#session#_save(candidate.word)
    endif
  endfor
endfunction"}}}
let s:source_new.action_table.save = s:source.action_table.save
function! s:source_new.action_table.save.func(candidates) "{{{
  for candidate in a:candidates
      " Second argument means check if exists
      call unite#sources#session#_save(candidate.word, 1) 
      close
  endfor
endfunction"}}}
"}}}

" Misc.
function! s:get_session_path(filename)
  let filename = a:filename
  if filename == ''
    let filename = v:this_session
  endif
  if filename == ''
    let filename = g:unite_source_session_default_session_name
  endif

  let filename = unite#util#substitute_path_separator(filename)

  if filename !~ '.vim$'
    let filename .= '.vim'
  endif

  if filename !~ '^\%(/\|\a\+:/\)'
    " Relative path.
    let filename = g:unite_source_session_path . '/' . filename
  endif

  return filename
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
