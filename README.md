# Dcoverage: Gradle & Clover test coverage parser
Dcoverage generates Clover reports for Gradle projects, provides coverage
highlighting, and a coverage summary. Built as a companion to Prof. Drew
Hilton's ECE651 Software Engineering course.

## Installation
```vim
Plug 'rwl93/dcoverage'
```

## Usage
When a Gradle project is entered, Dcoverage automatically detects the
`build.gradle` file and provides commands and mappings to generate the Clover
reports with `gradle clean cloverGenerateReport`, summarize the report, and
provide coverage highlighting.
### Commands
#### `DcovGenAndSave {fname}`
Generates Clover report, parses it, sets coverage signs, and shows summary in a
new buffer. Also, writes the coverage summary to `fname` [default=coverage.txt]
in the Gradle root folder.

#### `DcovGenAndShow`
Like `DcovGenAndSave`, but does not save the coverage summary to a file.

#### `DcovGenCloverReport`
Generates the Clover report, but does not parse it.

#### `DcovToggleOutputWin`
Toggle the Gradle output window.

#### `DcovToggleCoverageWin`
Toggle the coverage summary window.

#### `DcovToggleSigns`
Toggle the code highlighting.

### Mappings (Normal mode)
- `<Leader>dg`: Generate and save coverage

Remap by adding the following line to your vimrc:
```vim
nnoremap <Leader>dg <Plug>DcovGenAndSaveCoverage
```
- `<Leader>do`: Toggle Gradle output
```vim
nnoremap <Leader>do <Plug>DcovToggleOutputWin`
```
- `<Leader>dc`: Toggle Coverage summary
```vim
nnoremap <Leader>dc <Plug>DcovToggleCoverageWin
```
- `<Leader>ds`: Toggle code coverage highlighting
```vim
nnoremap <Leader>ds <Plug>DcovToggleSigns
```

### Options
The following maps are also provided:
- `<Plug>DcovGenAndShowCoverage`
- `<Plug>DcovGenCloverReport`

## Acknowledgments
1. Prof. Hilton's Elisp Dcoverage code
2. The Gradle wrapper is largely based off of [vim-gradle](https://github.com/hdiniz/vim-gradle)

## License
Copyright 2022 Randolph Linderman

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
