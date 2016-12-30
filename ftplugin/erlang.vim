" Erlang refactor file
" Based on  Pawel 'kTT' Salata <rockplayer.pl@gmail.com> plugin
" Language:   Erlang
" Maintainer: Pawel Pikula <ppikula@gmail.com>

if !exists('g:erlangWranglerPath')
    finish
endif

if exists('b:did_ftplugin_wrangler')
	finish
else
	let b:did_ftplugin_wrangler = 1
endif

if exists('*s:call_rename_module')
    finish
endif

if( !exists('g:askForWranglersSearchPath') )
    let g:askForWranglersSearchPath = 0
endif

if glob(g:erlangWranglerPath) == ""
    call confirm("Wrong path to wrangler dir")
    finish
endif

function! s:get_search_path()
    let path=expand('%:p:h')
    if !empty(matchstr(path,".*/apps/.*/src$"))
        let app_path = matchstr(path, ".*/apps/")
        if empty(app_path)
            return path
        else
            return app_path
        endif
    endif
    return path
endfunction

let s:fake_input = []
function! AddInput(text)
    call add(s:fake_input, a:text)
endfunction

" mock input for test purposes
function! s:get_input(text, initial)
    if(exists('g:wranglerTestMode'))
        let val = s:fake_input[0]
        let s:fake_input = s:fake_input[1:]
        return val
    else
        return inputdialog(a:text, a:initial)
    endif
endfunction

autocmd VimLeavePre * call StopWranglerServer()

let s:erlangServerName = "wrangler_vim"
let s:erl_call_finder = expand('<sfile>:p:h') . '/find_erl_call.escript'
let s:erl_call_cmd = substitute(system(s:erl_call_finder), "\n", '','')
let s:wrangler_node_started = 0

" COMMANDS
command! -n=0 -range WranglerExtractFunction <line1>,<line2>call ErlangExtractFunction("v")
command! -n=0 -bar WranglerRenameFunction call ErlangRenameFunction()
command! -n=0 -bar WranglerRenameModule call ErlangRenameModule()
command! -n=0 -bar WranglerRenameVariable call ErlangRenameVariable()
command! -n=0 -bar WranglerRenameProcess call ErlangRenameProcess()
command! -n=0 -bar WranglerMoveFunction call ErlangMoveFunction()
command! -n=0 -bar WranglerUndo call ErlangUndo()

" Starting background erlang session with wrangler on
function! StartWranglerServer()
    let wranglerEbinDir = g:erlangWranglerPath . "/ebin"
    let command = s:erl_call_cmd." -s -sname " . s:erlangServerName . " -x 'erl -pa " . wranglerEbinDir . "'"
    call system(command)
    call s:send_rpc('application', 'start', '[wrangler]')
    " in thest mode it starts without cwd, thath causes wrnageler crashed
    call s:send_rpc('file', 'set_cwd', '["/tmp"]')
    let s:wrangler_node_started = 1
endfunction

" Stopping erlang session
function! StopWranglerServer()
    if (s:wrangler_node_started == 1)
        let command = s:erl_call_cmd." -sname " . s:erlangServerName . " -a 'erlang halt'"
        system(command)
    endif
endfunction

"undo last operation
function! ErlangUndo()
    echo s:send_rpc("api_wrangler", "undo", "[]")
    :e!
endfunction

" Sending rpc call to erlang session
function! s:send_rpc(module, fun, args)
    let command = s:erl_call_cmd." -sname " . s:erlangServerName . " -a '" . a:module . " " . a:fun . " " . a:args . "'"
    let result = system(command)
    if match(result, 'erl_call: failed to connect to node .*') != -1
        call StartWranglerServer()
        return system(command)
    endif
    return result
endfunction

function! s:trim(text)
    return substitute(a:text, "^\\s\\+\\|\\s\\+$", "", "g")
endfunction

function! s:get_msg(result, tuple_start)
    let msg_begin = '{' . a:tuple_start . ','
    let matching_start =  match(a:result, msg_begin)
    if matching_start != -1
        return s:trim(matchstr(a:result, '[^}]*', matching_start + strlen(msg_begin)))
    endif
    return ""
endfunction

" Check if there is an error in result
function! s:check_for_error(result)
    let msg = s:get_msg(a:result, 'ok')
    if msg != ""
        return [0, msg]
    endif
    let msg = s:get_msg(a:result, 'warning')
    if msg != ""
        return [1, msg]
    endif
    let msg = s:get_msg(a:result, 'error')
    if msg != ""
        return [2, msg]
    endif
    return [-1, ""]
endfunction

" Format and send function extracton call
function! s:call_extract(start_line, start_col, end_line, end_col, name)
    let file = expand("%:p")
    let module = 'refac_new_fun'
    let fun = 'fun_extraction'
    let args = '["' . file . '", {' . a:start_line . ', ' . a:start_col . '}, {' . a:end_line . ', ' . a:end_col . '}, "' . a:name . '", emacs, ' . &sw . ']'
    let result = s:send_rpc(module, fun, args)
    let [error_code, msg] = s:check_for_error(result)
    if error_code != 0
        echom "error: ". msg
        return 0
    endif

    return 1
endfunction



function! ErlangExtractFunction(mode) range
    silent w!
    let name = s:get_input("New function name: ", "")
    if name != ""
        if a:mode == "v"
            let start_pos = getpos("'<")
            let start_line = start_pos[1]
            let start_col = start_pos[2]

            let end_pos = getpos("'>")
            let end_line = end_pos[1]
            let end_col = end_pos[2]
        elseif a:mode == "n"
            let pos = getpos(".")
            let start_line = pos[1]
            let start_col = pos[2]
            let end_line = pos[1]
            let end_col = pos[2]
        else
            echo "Mode not supported."
            return
        endif
        if s:call_extract(start_line, start_col, end_line, end_col, name)
            let temp = &autoread
            set autoread
            let file = expand("%")
            execute "silent :!mv ".file.".swp ".file
            :e
            :redraw!
            if temp == 0
                set noautoread
            endif
        endif
    else
        echo "Empty function name. Ignoring."
    endif
endfunction

function! s:call_rename(mode, line, col, search_path)
    if a:mode == "mod"
        let name = s:get_input('Rename module to: ', '')
        if name == ""
            echo "empty name provided"
            return 0
        endif
        call s:call_rename_module(name, a:search_path)
    elseif a:mode == "var"
        let curr_name = expand("<cword>")
        let name = s:get_input('Rename '.curr_name.' variable to: ',curr_name)
        if name == ""
            echo "empty name provided"
            return 0
        endif
        call s:call_rename_variable(name, a:line, a:col, a:search_path)
    else
        let file = expand("%:p")
        let mod = "api_interface"
        let fun = "pos_to_fun_name"
        let args = '["'.file.'",{'.a:line.','.a:col.'}]'
        let result = s:send_rpc(mod,fun,args)
        let [error_code, msg] = s:check_for_error(result)
        if  error_code == 0
            let [module, oldname, arity] = split(msg[1:],",")[0:2]
            let txt ='Rename "' . expand("<cword>") . '" to: '
            let name = s:get_input(txt, s:trim(oldname))
            if name == ""
                echo "empty function name"
                return 0
            else
                call s:call_rename_function(s:trim(oldname), s:trim(arity), name, a:search_path)
            endif
        else
            return 0
        endif
    endif
endfunction

function! s:call_rename_module(newname, search_path)
    let file = expand("%:p")
    let filepath = expand("%:h")
    let module = "api_wrangler"
    let fun = "rename_mod"
    let args = '["'. file .'",'.a:newname.', ["'. a:search_path .'"] ]'
    let result = s:send_rpc(module, fun, args)
    let [error_code, msg] = s:check_for_error(result)
    if error_code != 0
        echo msg
        return 0
    endif
    execute ':bd ' . file
    execute ':e '.filepath."/". a:newname . ".erl"
    redraw!
    return 1
endfunction

function! s:call_rename_function(old_name, arity, new_name, search_path)
    let file = expand("%:p")
    let module = "api_wrangler"
    let fun = "rename_fun"
    let args = '["'. file .'",'.a:old_name.','.a:arity.',"'.a:new_name.'", ["'. a:search_path .'"] ]'
    let result = s:send_rpc(module, fun, args)
    let [error_code, msg] = s:check_for_error(result)
    if error_code != 0
        echo msg
        return 0
    endif
    execute ':e %'
    redraw!

    return 1
endfunction

function! s:call_rename_variable(new_name, line, col, search_path)
    let file = expand("%:p")
    let module = "refac_rename_var"
    let fun = "rename_var"
    let args = '["'. file .'",'.a:line.','.a:col.',"'.a:new_name.'", ["'. a:search_path .'"], command, 8 ]'
    let result = s:send_rpc(module, fun, args)

    let [error_code, msg] = s:check_for_error(result)
    if error_code != 0
        echo msg
        return 0
    endif
    execute ':e %'
    redraw!

    return 1
endfunction

function! s:call_move_function(line, col, search_path)
    let file = expand("%:p")
    let mod = "api_interface"
    let fun = "pos_to_fun_name"
    let args = '["'.file.'",{'.a:line.','.a:col.'}]'
    let result = s:send_rpc(mod,fun,args)
    let [error_code, msg] = s:check_for_error(result)
    if  error_code == 0
        let [module, oldname, arity] = split(msg[1:],",")[0:2]
        let txt ='Move "' . expand("<cword>") . '" to: '
        let name = s:get_input(txt,"")
        if name == ""
            echo "empty function name"
            return 0
        else
            call s:do_call_move_function(s:trim(oldname), s:trim(arity), name, a:search_path)
        endif
    else
        return 0
    endif
    endfunction

function! s:do_call_move_function(old_name, arity, new_name, search_path)
    let file = expand("%:p")
    let module = "api_wrangler"
    let fun = "move_fun"
    let args = '["'. file .'",'.a:old_name.','.a:arity.','.a:new_name.', ["'. a:search_path .'"] ]'
    let result = s:send_rpc(module, fun, args)
    echo result
    let [error_code, msg] = s:check_for_error(result)
    if error_code != 0
        echo msg
        return 0
    endif
    execute 'e %'
    redraw!

    return 1
endfunction

function! ErlangRename(mode)
    silent w!
    if g:askForWranglersSearchPath
        let search_path = get_input('Search path: ', expand("%:p:h"))
    else
        let search_path = s:get_search_path()
    endif
    let pos = getpos(".")
    let line = pos[1]
    let col = pos[2]
    call s:call_rename(a:mode, line, col, search_path)
endfunction

function! ErlangRenameFunction()
    call ErlangRename("fun")
endfunction

function! ErlangRenameVariable()
    call ErlangRename("var")
endfunction

function! ErlangRenameModule()
    call ErlangRename("mod")
endfunction

function! ErlangRenameProcess()
    call ErlangRename("process")
endfunction

function! ErlangMoveFunction()
    silent w!
    if g:askForWranglersSearchPath
        let search_path = get_input('Search path: ', expand("%:p:h"))
    else
        let search_path = s:get_search_path()
    endif
    let pos = getpos(".")
    let line = pos[1]
    let col = pos[2]
    call s:call_move_function(line, col, search_path)
endfunction

" vim: set foldmethod=marker:
