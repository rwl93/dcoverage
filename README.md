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
