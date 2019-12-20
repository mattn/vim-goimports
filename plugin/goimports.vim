function! s:install()
  augroup goimports_autoformat
    au!
    autocmd BufWritePre <buffer> call goimports#Run()
  augroup END
endfunction

augroup goimports_install
  au!
  autocmd FileType go call s:install()
augroup END
