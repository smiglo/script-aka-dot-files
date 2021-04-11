#!/usr/bin/env bash

colorConv() { # {{{
  local ret=${colors[${1,,}]}
  [[ -z $ret ]] && ret=$1
  echo $ret
} # }}}

declare -A colors
colors[red]="    255 0   0"
colors[green]="  0   255 0"
colors[blue]="   0   0   255"
colors[cyan]="   0   255 255"
colors[yellow]=" 255 255 0"

if [[ $1 == '@@' ]]; then # {{{
  case $3 in
  --delay) echo "1 3 5 10 30 60";;
  *)
    echo "-v --no-delay --delay --reset --blink --blink= -h --help"
    echo "--breath-random --breath-single --breath-dual --reactive --spectrum --starlight-single --static --wave --ripple-single --ripple-random --brightness"
    for i in ${!colors[*]}; do
      echo "--blink=$i"
    done
    ;;
  esac
  exit 0
fi # }}}

chroma="$SCRIPT_PATH/bin/oth/chroma-effects.py"
verbose=false

defSleep=3
defBrightness=10
defEffect="static"
defColor="cyan"
defBlinkColor="red"
defCmd="$chroma --brightness $defBrightness; $chroma --$defEffect $(colorConv $defColor)"

$chroma --test || exit 0

while [[ ! -z $1 ]]; do
  cmd=$1
  fullCmd=
  case $cmd in
  --help | -h) # {{{
    echo "$(basename $0) [-v] [--delay N|--no-delay] [--reset] [--blink|--blink=DELAY [COLOR]] [--test]"
    exit 0 ;; # }}}
  -v) verbose=true;;
  --no-delay);;
  --delay) [[ $2 != 0 ]] && fullCmd="sleep $2"; shift;;
  --reset) fullCmd="$defCmd";;
  --test)  $chroma --test; exit $?;;
  --*) # {{{
    args= first=true
    while [[ ! -z $2 && $2 != '--'* ]]; do # {{{
      if $first; then
        args+=" $(colorConv $2)"
        first=false
      else
        args+=" $2"
      fi
      shift
    done # }}}
    case $cmd in
    --blink)   sleepTime=$defSleep;;&
    --blink=*) sleepTime=${cmd#--blink=};;&
    --blink | --blink=*) # {{{
      fullCmd="$chroma --starlight ${args:-$(colorConv $defBlinkColor)}; $chroma --brightness 100; sleep $sleepTime; "
      [[ -z $2 ]] && fullCmd+="$defCmd"
      ;; # }}}
    --*) fullCmd="$chroma $cmd $args";;
    esac;; # }}}
  esac
  shift
  [[ -z $fullCmd ]] && continue
  $verbose && echo $fullCmd
  eval $fullCmd
  if [[ ! -z $1 && $1 != '--delay' && $1 != '--no-delay' ]]; then
    case $cmd in
    --delay | --brightness | --blink);;
    *) sleep $defSleep;;
    esac
  fi
done

