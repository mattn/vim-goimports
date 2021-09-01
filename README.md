# vim-goimports

Vim plugin for Minimalist Gopher

## Features

* Auto-formatting with `:w`
* GoImport/GoImportAs

This plugin is mostly based on vim-go.

## Will not do

* Add new commands
* Modify syntax

## Usage

```
:w
```

## Installation

For [vim-plug](https://github.com/junegunn/vim-plug) plugin manager:

```viml
Plug 'mattn/vim-goimports'
```

## Configuration

```viml
" enable auto format when write (default)
let g:goimports = 1
" disable auto format. but :GoImportRun will work.
let g:goimports = 0
```

* `g:goimports_simplify` - make simplify (a.k.a. `gofmt -s`) in formatting,
  when make value of this `1` (default disabled).

    ```viml
    " enable simplify filter
    let g:goimports_simplify = 1
    " disable simplify filter
    unlet! g:goimports_simplify
    ```

* `g:goimports_local` - use `-local` option when running `goimports`.
  This is useful to import closed-source packages. (comma separated list)

    ```viml
    " run goimports with `-local "github.com/myrepo"` option
    let g:goimports_local = 'github.com/myrepo'
    ```

* To replace goimports command with the drop in replacement tool (e.g. [gofumpt](https://github.com/mvdan/gofumpt)).

  ```viml
  " goimport (default)
  let g:goimports_cmd = 'goimports'
  let g:goimports_simplify_cmd = 'gofmt'
  
  " gofumpt
  let g:goimports_cmd = 'gofumports'
  let g:goimports_simplify_cmd = 'gofumpt'
  ```

* To not trigger the location list if errors are present, you can use this option :
  ```viml
  " default is 1
  let g:goimports_show_loclist = 0
  ```

## Requirements

* goimports
* gofmt (optional: for `g:goimports_simplify = 1`)

## License

MIT

## Author

Yasuhiro Matsumoto (a.k.a. mattn)
