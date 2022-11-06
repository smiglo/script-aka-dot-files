#!/usr/bin/env bash
# vim: fdl=0

if [[ $1 == '@@' ]]; then # {{{
  ret="-l --log-path --file"
  if [[ -z $DEV_USB_SERIAL ]]; then
    if $IS_MAC; then
      ret+=" $(getFileList '/dev/tty.usbserial*') $(getFileList '/dev/tty.PL2303*')"
    else
      ret+=" $(getFileList '/dev/ttyUSB*')"
    fi
  else
      ret+=" $(getFileList "$DEV_USB_SERIAL")"
  fi
  echo "$ret"
  exit 0
fi # }}}
getLogPath() { # {{{
  local path="${LOG_PATH:-$TMP_PATH/logs}"
  [[ ! -e $path ]] && command mkdir -p $path
  if [[ $1 != '--full' && $path = $PWD* ]]; then
    path=".${path#$PWD}"
  fi
  path="${path%/}"
  [[ -z $path ]] && path='.'
  echo $path
} # }}}
genLogFilename() { #{{{
  local DATE=$($ALIASES date)
  local suffix=
  [[ ! -z $1 ]] && suffix="-$1"
  echo "log-${DATE}${suffix}.log"
} #}}}
in_loop=false port= log_filename= log_path="$(getLogPath)" minirc=~/.minirc.dfl auto_filename=true
[[ ! -z $DEV_USB_SERIAL ]] && port="$(getFileList -1 "$DEV_USB_SERIAL")"
while [[ ! -z "$1" ]]; do # {{{
  case "$1" in
  -l)         in_loop=true;;
  --log-path) shift; log_path="$1";;
  --file)     shift; log_filename="$1";;
  *)          if [[ $1 == /dev/* ]]; then
                port="$1"
              elif [[ -d $1 ]]; then
                log_path="$1"
              else
                log_filename="$1"
              fi;;
  esac
  shift
done # }}}
if [[ -z $port ]]; then # {{{
  if $IS_MAC; then
    port="$($ALIASES getFileList -1 '/dev/tty.usbserial*')"
    [[ -z $port ]] && port="$($ALIASES getFileList -1 '/dev/tty.PL2303*')"
  else
    port=$($ALIASES getFileList -1 '/dev/ttyUSB*')
  fi
fi # }}}
[[ -z $port ]] && echo "Serial adapter not found" >/dev/stderr  && exit 1
[[ ! -e $port ]] && echo "Serial adapter [$port] not connected" >/dev/stderr  && exit 1
sed -i -re "2s#.*#pu port $port#" $minirc
[[ ! -z $log_filename ]] && auto_filename=false
while true; do # {{{
  if $auto_filename; then # {{{
    log_filename="$(genLogFilename)"
    log_filename="$log_path/$log_filename"
  fi # }}}
  $ALIASES set_title "L: ${log_filename##*/}"
  minicom -c on -C $log_filename
  $in_loop && continue || break
done # }}}

