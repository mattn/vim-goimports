" vint: -ProhibitUnusedVariable

function! goimports#Run() abort
  if !executable('goimports')
    call s:error('goimports executable not found')
    return
  endif
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
    call s:handle_errors(expand('%'), l:out)
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
  for l:line in l:lines
    let l:tokens = matchlist(l:line, '^\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)')
    if empty(l:tokens)
      continue
    endif
    call add(l:errors,{
          \'filename': a:filename,
          \'lnum':     l:tokens[2],
          \'col':      l:tokens[3],
          \'text':     l:tokens[4],
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

let s:dirs = split(system('go env GOROOT GOPATH'), "\n")
let [s:goos, s:goarch] = split(system('go env GOOS GOARCH'), "\n")

function! goimports#Complete(lead, cmdline, pos) abort
  let l:ret = {}
  for l:dir in s:dirs
    let l:root = split(expand(l:dir . '/pkg/' . s:goos . '_' . s:goarch), "\n")
    call add(l:root, expand(l:dir . '/src'))
    for l:r in l:root
      for l:e in split(globpath(l:r, a:lead.'*'), "\n")
        if isdirectory(l:e)
          let l:e .= '/'
        elseif l:e !~# '\.a$'
          continue
        endif
        let l:e = substitute(substitute(l:e[len(l:r)+1:], '[\\]', '/', 'g'), '\.a$', '', 'g')
        let l:ret[l:e] = 1
      endfor
    endfor
  endfor
  return sort(keys(l:ret))
endfunction

function! goimports#SwitchImport(enabled, localname, path, bang) abort
  let l:view = winsaveview()
  let l:path = substitute(a:path, '^\s*\(.\{-}\)\s*$', '\1', '')

  " Quotes are not necessary, so remove them if provided.
  if l:path[0] == '"'
    let l:path = strpart(l:path, 1)
  endif
  if l:path[len(l:path)-1] == '"'
    let l:path = strpart(l:path, 0, len(l:path) - 1)
  endif

  " if given a trailing slash, eg. `github.com/user/pkg/`, remove it
  if l:path[len(l:path)-1] == '/'
    let l:path = strpart(l:path, 0, len(l:path) - 1)
  endif

  if l:path == ''
    call s:error('Import path not provided')
    return
  endif

  if a:bang == '!'
    let [l:out, l:err] = system(printf('go get -u -v %s', shellescape(l:path)))
    if l:err != 0
      call s:error('Can''t find import: ' . l:path . ':' . l:out)
    endif
  endif

  " Extract any site prefix (e.g. github.com/).
  " If other imports with the same prefix are grouped separately,
  " we will add this new import with them.
  " Only up to and including the first slash is used.
  let l:siteprefix = matchstr(l:path, '^[^/]*/')

  let l:qpath = '"' . l:path . '"'
  if a:localname != ''
    let l:qlocalpath = a:localname . ' ' . l:qpath
  else
    let l:qlocalpath = l:qpath
  endif
  let l:indentstr = 0
  let l:packageline = -1 " Position of package name statement
  let l:appendline = -1  " Position to introduce new import
  let l:deleteline = -1  " Position of line with existing import
  let l:linesdelta = 0   " Lines added/removed

  " Find proper place to add/remove import.
  let l:line = 0
  while l:line <= line('$')
    let l:linestr = getline(l:line)

    if l:linestr =~# '^package\s'
      let l:packageline = l:line
      let l:appendline = l:line

    elseif l:linestr =~# '^import\s\+(\+)'
      let l:appendline = l:line
      let l:appendstr = l:qlocalpath
    elseif l:linestr =~# '^import\s\+('
      let l:appendstr = l:qlocalpath
      let l:indentstr = 1
      let l:appendline = l:line
      let l:firstblank = -1
      while l:line <= line('$')
        let l:line = l:line + 1
        let l:linestr = getline(l:line)
        let l:m = matchlist(getline(l:line), '^\()\|\(\s\+\)\(\S*\s*\)"\(.\+\)"\)')
        if empty(l:m)
          if l:siteprefix == '' && a:enabled
            " must be in the first group
            break
          endif
          " record this position, but keep looking
          if l:firstblank < 0
            let l:firstblank = l:line
          endif
          continue
        endif
        if l:m[1] == ')'
          " if there's no match, add it to the first group
          if l:appendline < 0 && l:firstblank >= 0
            let l:appendline = l:firstblank
          endif
          break
        endif
        if a:localname != '' && l:m[3] != ''
          let l:qlocalpath = printf('%-' . (len(l:m[3])-1) . 's %s', a:localname, l:qpath)
        endif
        let l:appendstr = l:m[2] . l:qlocalpath
        let l:indentstr = 0
        if l:m[4] == l:path
          let l:appendline = -1
          let l:deleteline = l:line
          break
        elseif l:m[4] < l:path
          " don't set candidate position if we have a site prefix,
          " we've passed a blank line, and this doesn't share the same
          " site prefix.
          if l:siteprefix == '' || l:firstblank < 0 || match(l:m[4], '^' . l:siteprefix) >= 0
            let l:appendline = l:line
          endif
        elseif l:siteprefix != '' && match(l:m[4], '^' . l:siteprefix) >= 0
          " first entry of site group
          let l:appendline = l:line - 1
          break
        endif
      endwhile
      break

    elseif l:linestr =~# '^import '
      if l:appendline == l:packageline
        let l:appendstr = 'import ' . l:qlocalpath
        let l:appendline = l:line - 1
      endif
      let l:m = matchlist(l:linestr, '^import\(\s\+\)\(\S*\s*\)"\(.\+\)"')
      if !empty(l:m)
        if l:m[3] == l:path
          let l:appendline = -1
          let l:deleteline = l:line
          break
        endif
        if l:m[3] < l:path
          let l:appendline = l:line
        endif
        if a:localname != '' && l:m[2] != ''
          let l:qlocalpath = printf('%s %' . len(l:m[2])-1 . 's', a:localname, l:qpath)
        endif
        let l:appendstr = 'import' . l:m[1] . l:qlocalpath
      endif

    elseif l:linestr =~# '^\(var\|const\|type\|func\)\>'
      break

    endif
    let l:line = l:line + 1
  endwhile

  " Append or remove the package import, as requested.
  if a:enabled
    if l:deleteline != -1
      call s:error(l:qpath . ' already being imported')
    elseif l:appendline == -1
      call s:error('No package line found')
    else
      if l:appendline == l:packageline
        call append(l:appendline + 0, '')
        call append(l:appendline + 1, 'import (')
        call append(l:appendline + 2, ')')
        let l:appendline += 2
        let l:linesdelta += 3
        let l:appendstr = l:qlocalpath
        let l:indentstr = 1
        call append(l:appendline, l:appendstr)
      elseif getline(l:appendline) =~# '^import\s\+(\+)'
        call setline(l:appendline, 'import (')
        call append(l:appendline + 0, l:appendstr)
        call append(l:appendline + 1, ')')
        let l:linesdelta -= 1
        let l:indentstr = 1
      else
        call append(l:appendline, l:appendstr)
      endif
      execute l:appendline + 1
      if l:indentstr
        execute 'normal! >>'
      endif
      let l:linesdelta += 1
    endif
  else
    if l:deleteline == -1
      call s:error(l:qpath . ' not being imported')
    else
      execute l:deleteline . 'd'
      let l:linesdelta -= 1

      if getline(l:deleteline-1) =~# '^import\s\+(' && getline(l:deleteline) =~# '^)'
        " Delete empty import block
        let l:deleteline -= 1
        execute l:deleteline . 'd'
        execute l:deleteline . 'd'
        let l:linesdelta -= 2
      endif

      if getline(l:deleteline) == '' && getline(l:deleteline - 1) == ''
        " Delete spacing for removed line too.
        execute l:deleteline . 'd'
        let l:linesdelta -= 1
      endif
    endif
  endif

  " Adjust l:view for any changes.
  let l:view.lnum += l:linesdelta
  let l:view.topline += l:linesdelta
  if l:view.topline < 0
    let l:view.topline = 0
  endif

  " Put buffer back where it was.
  call winrestview(l:view)
endfunction


function! s:error(s) abort
  echohl Error | echo a:s | echohl None
endfunction
