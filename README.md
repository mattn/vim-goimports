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

## Requirements

* goimports
* gofmt (optional: for `g:goimports_simplify = 1`)

## License

MIT

## Author

Yasuhiro Matsumoto (a.k.a. mattn)
