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
" enable (default)
let g:goimports = 1
" disable
let g:goimports = 0
```

## Requirements

* goimports

## License

MIT

## Author

Yasuhiro Matsumoto (a.k.a. mattn)
