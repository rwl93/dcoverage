" Vim syntax file
" Language:	    dcoverage
" Maintainer:   Randy Linderman <randolph.linderman@gmail.com>
" Last Change:	2022 Feb 12
" Remark:
if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "dcoverage"

syntax region dcoverageComment oneline start="\"" end="$"
syntax match dcoverageHeaderLine "^|\s*Class Name.*$"
" syntax match dcoverageTotalsLine "^|\s*Totals.*$"
syntax match dcoverageSepLine "^+.*$"

syntax match dcoverageWellCoveredReport "^|[^|]*|\s*100.*$"
syntax match dcoverageModerateCoveredReport "^|[^|]*|\s*[56789][0-9]\s.*$"
syntax match dcoveragePoorlyCoveredReport "^|[^|]*|\s*\([0-9]\s\|[1-4][0-9]\s\).*$"

hi! def link dcoverageComment Comment
hi! def link dcoverageHeaderLine Title
" hi! def link dcoverageTotalsLine
hi! def link dcoverageSepLine Character

" Define sign colors
hi! def link dcoverageWellCoveredReport       Search
hi! def link dcoverageModerateCoveredReport   WarningMsg
hi! def link dcoveragePoorlyCoveredReport     ErrorMsg

" NB: These are the color's Drew used
" let s:dcoverage_covered_stm_color = "#008700"
" let s:dcoverage_uncovered_stm_color = "#870000"
" let s:dcoverage_part_covered_branch_color = "#878700"
" let s:dcoverage_well_covered_report_color = "green"
" let s:dcoverage_moderate_covered_report_color = "dark orange"
" let s:dcoverage_poorly_covered_report_color = "red"
