_grunt()
{
  local cur=${COMP_WORDS[COMP_CWORD]}
  local tasks=$( cat Gruntfile.* | sed -n -r -e 's/.+registerTask\W+(\w+)\W.*/\1/p' )
  COMPREPLY=( $( compgen -W "$tasks" -- "$cur") )
}
complete -F _grunt grunt

_gulp()
{
  local cur=${COMP_WORDS[COMP_CWORD]}
  local tasks=$( cat Gulpfile.* | sed -n -r -e 's/gulp\.task\W+(\w+)\W.*/\1/p' )
  COMPREPLY=( $( compgen -W "$tasks" -- "$cur") )
}
complete -F _gulp gulp
