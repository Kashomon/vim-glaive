let s:thisplugin = expand('<sfile>:p:h:h')
let s:qargpattern = '\v\s*(\S+)%(\s+(.*))?$'


""
" Installs this plugin. The maktaba library must be available: either make sure
" it's on your runtimepath or put it in the same directory as glaive and source
" the glaive bootstrap file. (If you source the bootstrap file, there is no need
" to call this function.)
function! glaive#Install() abort
  let l:glaive = maktaba#plugin#GetOrInstall(s:thisplugin)
  call l:glaive.Load('commands')
endfunction


""
" Given {qargs} (a quoted string given to the @command(Glaive) command, as
" generated by |<q-args>|), returns the plugin name and the configuration
" string.
" @throws BadValue if {qargs} has no plugin name.
function! glaive#SplitPluginNameFromOperations(qargs) abort
  let l:match = matchlist(a:qargs, s:qargpattern)
  if empty(l:match)
    throw maktaba#error#BadValue('Plugin missing in "%s"', a:qargs)
  endif
  return [l:match[1], l:match[2]]
endfunction


""
" Applies Glaive operations for {plugin} as described in {operations}.
" See @command(Glaive).
" @throws BadValue when the parsing of {operations} goes south.
" @throws WrongType when invalid flag operations are requested.
" @throws NotFound when a {operations} references a non-existent flag.
function! glaive#Configure(plugin, text) abort
  try
    let l:settings = maktaba#setting#ParseAll(maktaba#string#Strip(a:text))
  catch /ERROR(BadValue):/
    let [l:type, l:msg] = maktaba#error#Split(v:exception)
    let l:qualifier = 'Error parsing Glaive settings for %s: %s'
    throw maktaba#error#Message(l:type, l:qualifier, a:plugin.name, l:msg)
  endtry
  for l:setting in l:settings
    call l:setting.Apply(a:plugin)
  endfor
endfunction

""
" Gets {plugin}, which must already be on the runtimepath.
" Calls maktaba#plugin#Install on {plugin} if it has not yet been installed by
" maktaba. This will have no effect on non-maktaba plugins (which were already
" on the runtimepath), but will cause maktaba instant/* files to load (thus
" making their flags available).
"
" {plugin} will be passed through @function(maktaba#plugin#CanonicalName).
" Therefore, you can use anything which evaluates to the same canonical name:
" "my_plugin", "my-plugin", and even "my!plugin" are all equivalent.
"
" @throws NotFound if {plugin} cannot be found.
function! glaive#GetPlugin(plugin) abort
  let l:canonical_name = maktaba#plugin#CanonicalName(a:plugin)

  " First, check whether the plugin was already registered with maktaba.
  let l:registered_plugins = maktaba#plugin#RegisteredPlugins()
  if index(l:registered_plugins, l:canonical_name) >= 0
    return maktaba#plugin#Get(l:canonical_name)
  endif
  
  " Get the maktaba plugin object for a plugin already on the runtimepath.
  " If the plugin was installed with a plugin manager like pathogen or vundle,
  " then it's possible that it's on the runtimepath but hasn't been "Installed"
  " by maktaba. maktaba#plugin#Install is what forces the flags file to load
  " during vimrc time, so we need to make sure that the plugin has been
  " maktaba#plugin#Install'd before we can configure it.
  let l:plugins = maktaba#rtp#LeafDirs()
  for l:key in keys(l:plugins)
    if maktaba#plugin#CanonicalName(l:key) ==# l:canonical_name
      return maktaba#plugin#GetOrInstall(l:plugins[l:key])
    endif
  endfor

  " If we're still here, we can't find the plugin.
  throw maktaba#error#NotFound('Plugin %s', a:plugin)
endfunction
