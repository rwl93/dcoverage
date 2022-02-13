if exists("b:did_ftdetect")
    finish
endif

let b:did_ftdetect = 1

au! BufRead,BufNewFile *coverage.txt   set filetype=dcoverage
au! BufRead,BufNewFile *.dcoverage     set filetype=dcoverage
au! BufRead,BufNewFile *.dcov          set filetype=dcoverage
