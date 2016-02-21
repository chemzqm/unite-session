"=============================================================================
" FILE: session.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 05 Oct 2010
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

if exists('g:loaded_unite_source_session')
  finish
endif

let s:restart_cmd = expand('<sfile>:h:h:h').'/bin/nvimstart'
let s:save_cpo = &cpo
set cpo&vim

function! s:RestartVim()
  if has('gui_running') && has('gui_macvim')
    let cmd = 'mvim'
  elseif has('gui_running')
    let cmd = 'gvim'
  else
    let cmd = 'vim'
  endif
  let name = empty(v:this_session) ? 'default' : v:this_session
  call unite#sources#session#_save(name)
  if exists(':ItermStart') && has('gui_running')
    let succeed = Iterm#Run(cmd . ' -c "SessionLoad ' . name . '"')
    if !succeed | return | endif
  elseif has('nvim')
    call jobstart(s:restart_cmd . ' ' . v:this_session , {
      \ 'detach': 1,
      \})
  else
    silent execute '!' . cmd . ' -c "SessionLoad ' . v:this_session . '"'
    if v:shell_error| return | endif
  endif
  silent! wa
  silent quitall!
endfunction

command! -nargs=? -complete=customlist,unite#sources#session#_complete
      \ SessionSave call unite#sources#session#_save(<q-args>)

command! -nargs=? -complete=customlist,unite#sources#session#_complete
      \ SessionLoad call unite#sources#session#_load(<q-args>)

command! -nargs=0 RestartVim call s:RestartVim()

let g:loaded_unite_source_session = 1

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
