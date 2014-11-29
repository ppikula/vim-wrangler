# vim-wrangler

The wrangler plugin for Vim.
Based on  Pawel 'kTT' Salata <rockplayer.pl@gmail.com> vimerl wrangler branch 
(https://github.com/jimenezrick/vimerl/tree/wrangler-support).

## Configuration

Add the following lines to your vimrc file:

    "enable wrangler
    let g:erlangRefactoring = 1

    "set path to wrangler directory
    let g:erlangWranglerPath = '/Users/pawel.pikula/dev/other/wrangler'

    "sample wrangler bindings
    nnoremap <leader>e :call ErlangExtractFunction("n")<ENTER>
    vnoremap <leader>e :call ErlangExtractFunction("v")<ENTER>
    noremap  <leader>m :call ErlangRenameModule()<ENTER>
    noremap  <leader>f :call ErlangRenameFunction()<ENTER>
    noremap  <leader>v :call ErlangRenameVariable()<ENTER>
    noremap  <leader>p :call ErlangRenameProcess()<ENTER>
    noremap  <leader>u :call ErlangUndo()<ENTER>

## ToDo

- [x] automatically find erl_call
- [ ] documentation
- [ ] create more generic function that will allow to easily bind every wrangler command

