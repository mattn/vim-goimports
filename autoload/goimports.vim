function! goimports#Run() abort
  let l:view = winsaveview()
  let l:tmpname = tempname() . '.go'
  call writefile(s:getlines(), l:tmpname)
  if has('win32')
    let l:tmpname = tr(l:tmpname, '\', '/')
  endif
  let l:col = col('.')
  let [l:out, l:err] = s:goimports(l:tmpname, expand('%'))
  let l:linecount = len(readfile(l:tmpname)) - line('$')
  if l:err == 0
    call s:rename_file(l:tmpname, expand('%'))
  else
    call s:handle_errors(expand('%'), out)
  endif
  call delete(l:tmpname)
  call winrestview(l:view)
  call cursor(line('.') + l:linecount, l:col)
  syntax sync fromstart
endfunction

function! s:rename_file(src, dst)
  try | silent undojoin | catch | endtry

  let l:old_fileformat = &fileformat
  let l:old_fperm = getfperm(a:dst)

  call rename(a:src, a:dst)

  if l:old_fperm != ''
    call setfperm(a:dst , l:old_fperm)
  endif

  silent edit!

  let &fileformat = l:old_fileformat
  let &syntax = &syntax

  let l:title = getloclist(0, {'title': 1})
  if has_key(l:title, 'title') && l:title['title'] ==# 'Format'
    lex []
    lclose
  endif
endfunction

function! s:goimports(src, dst)
  let l:cmd = printf('goimports -w -srcdir %s %s', shellescape(a:dst), shellescape(a:src))
  let l:out = system(l:cmd)
  let l:err = v:shell_error
  return [l:out, l:err]
endfunction

function! s:handle_errors(filename, content) abort
  let l:lines = split(a:content, '\n')
  let l:errors = []
  for line in l:lines
    let tokens = matchlist(line, '^\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)')
    if empty(tokens)
      continue
    endif
    call add(l:errors,{
          \'filename': a:filename,
          \'lnum':     tokens[2],
          \'col':      tokens[3],
          \'text':     tokens[4],
          \ })
  endfor

  if len(l:errors)
    call setloclist(0, l:errors, 'r')
    call setloclist(0, [], 'a', {'title': 'Format'})
    lopen
  else
    lclose
  endif
endfunction

function! s:getlines()
  let l:buf = getline(1, '$')
  if &encoding !=# 'utf-8'
    let l:buf = map(l:buf, 'iconv(v:val, &encoding, "utf-8")')
  endif
  if &l:fileformat ==# 'dos'
    let l:buf = map(l:buf, 'v:val."\r"')
  endif
  return l:buf
endfunction
