if !has('nvim-0.6')
    echoerr 'repossession requires at least Neovim 0.6.0'
    finish
endif

if exists('g:loaded_repossession')
    finish
endif
let g:loaded_repossession = v:true

let s:cpo_save = &cpo
set cpo&vim

" command! -bang -nargs=1 -complete=file SessionRestoreFromFile lua require'repossession'.load_sesion({f-args})
" command!       -nargs=1 -complete=file SessionSaveToFile lua require'repossession'.save_session({f-args})
command! -bang -nargs=? -complete=custom,s:StoredSessionsComplete SessionRestore lua require'repossession'.load_session({<f-args>}, <q-bang>)
command!       -nargs=+ -complete=custom,s:StoredSessionsComplete SessionDelete lua require'repossession'.delete_sessions({<f-args>})
command!       -nargs=? -complete=custom,s:StoredSessionsComplete SessionSave lua require'repossession'.save_session({<f-args>})

function! s:StoredSessionsComplete(arg,line,pos)
    return luaeval("require'repossession.session'.complete_sessions()")
endfunction

augroup repossession
    autocmd VimEnter * ++nested lua require'repossession'.auto_load_session()
    autocmd VimLeavePre * lua require'repossession'.auto_save_session()
    autocmd BufEnter * lua require'repossession'.auto_save_session()
    autocmd StdinReadPre * let g:read_from_stdin = v:true
augroup END

let &cpo = s:cpo_save
unlet s:cpo_save
