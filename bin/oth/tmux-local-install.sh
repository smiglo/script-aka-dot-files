#!/bin/bash -e
# Source: https://gist.github.com/ryin/3106801
# Script for installing tmux on systems where you don't have root access.
# tmux will be installed in $ROOT/local/bin.
# It's assumed that wget and a C/C++ compiler are installed.

# Initialize # {{{
TMUX_INSTALL_VERSION=${TMUX_INSTALL_VERSION:-'local:2.5'}
if [[ $TMUX_INSTALL_VERSION == local:* ]]; then
  TMUX_INSTALL_VERSION=${TMUX_INSTALL_VERSION/'local:'}
  LOCAL_TARBALL=$MY_PROJ_PATH/scripts/bash/inits/tmux/src/tmux-src-${TMUX_INSTALL_VERSION}.tar.gz
fi
LIBEVENT_VERSION=${LIBEVENT_VERSION:-'2.0.22-stable'}
NCURSES_VERSION=${NCURSES_VERSION:-'6.0'}
ROOT=$HOME/.config/tmux-local
CLEAN_AFTER=false
# Handle arguments # {{{
while [[ ! -z $1 ]]; do
  case $1 in
  --ver)        shift; TMUX_INSTALL_VERSION=$1; LOCAL_TARBALL=;;
  --local | \
  --local-repo) shift; LOCAL_TARBALL=$1;;&
  --local)      [[ $LOCAL_TARBALL != /* ]] && LOCAL_TARBALL="$PWD/$LOCAL_TARBALL"; TMUX_INSTALL_VERSION=$(echo "$LOCAL_TARBALL" | sed -e 's/.*tmux-//' -e 's/\.tar\.gz//');;
  --local-repo) TMUX_INSTALL_VERSION='repo';;
  --root)       shift; ROOT=$1;;
  --clean)      CLEAN_AFTER=true;;
  esac
  shift
done # }}}
# Prepare #{{{
ROOT=$(cd $ROOT; pwd)
if [[ -e $ROOT/local ]]; then
  suffix=
  type tmux && suffix="$(tmux -V | cut -d\  -f2)-"
  suffix+="$(date +$DATE_FMT)"
  mv $ROOT/local $ROOT/local-${suffix}
fi
command mkdir -p $ROOT/local $ROOT/tmux_tmp
cd $ROOT/tmux_tmp
# Download source files for tmux, libevent, and ncurses # {{{
if [[ -z $LOCAL_TARBALL ]]; then
  [[ ! -e tmux-${TMUX_INSTALL_VERSION}.tar.gz ]] && wget  https://github.com/tmux/tmux/releases/download/${TMUX_INSTALL_VERSION}/tmux-${TMUX_INSTALL_VERSION}.tar.gz
else
  cp -a ${LOCAL_TARBALL%/} ./
  [[ $TMUX_INSTALL_VERSION == 'repo' ]] && mv ${LOCAL_TARBALL%/} tmux-${TMUX_INSTALL_VERSION}
fi
[[ ! -e release-${LIBEVENT_VERSION}.tar.gz ]] && wget https://github.com/libevent/libevent/archive/release-${LIBEVENT_VERSION}.tar.gz
[[ ! -e ncurses-${NCURSES_VERSION}.tar.gz  ]] && wget ftp://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz
# }}}
# }}}
# }}}
# Extract files, configure, and compile # {{{
# LibEvent # {{{
[[ ! -e libevent-release-${LIBEVENT_VERSION} ]] && tar xvzf release-${LIBEVENT_VERSION}.tar.gz
cd libevent-release-${LIBEVENT_VERSION}
./autogen.sh
./configure --prefix=$ROOT/local --disable-shared
make
make install
cd ..
# }}}
# NCureses # {{{
[[ ! -e ncurses-${NCURSES_VERSION} ]] && tar xvzf ncurses-${NCURSES_VERSION}.tar.gz
cd ncurses-${NCURSES_VERSION}
export CPPFLAGS="-P"
./configure --prefix=$ROOT/local
make
make install
export CPPFLAGS=
cd ..
# }}}
# TMUX # {{{
[[ ! -e tmux-${TMUX_INSTALL_VERSION} ]] && tar xvzf tmux-${TMUX_INSTALL_VERSION}.tar.gz
cd tmux-${TMUX_INSTALL_VERSION}
[[ -e autogen.sh ]] && sh autogen.sh
./configure CFLAGS="-I$ROOT/local/include -I$ROOT/local/include/ncurses" LDFLAGS="-L$ROOT/local/lib -L$ROOT/local/include/ncurses -L$ROOT/local/include"
CPPFLAGS="-I$ROOT/local/include -I$ROOT/local/include/ncurses" LDFLAGS="-static -L$ROOT/local/include -L$ROOT/local/include/ncurses -L$ROOT/local/lib" make
cp tmux $ROOT/local/bin
if [[ -e 'tmux.1' ]]; then
  [[ ! -e "$ROOT/local/share/man/man1" ]] && command mkdir -p "$ROOT/local/share/man/man1"
  cp 'tmux.1' "$ROOT/local/share/man/man1/"
  (
    echo ".Sh VERSION"
    echo ".An $(./tmux -V)"
  ) >>$ROOT/local/share/man/man1/tmux.1
fi
cd ..
# }}}
# }}}
# Clean up # {{{
$CLEAN_AFTER && rm -rf $ROOT/tmux_tmp
# ln -s $ROOT/local/bin $HOME/.bin/tmux-local-bin
echo
echo '--------------------------------------------------------------------------------'
echo 'DONE'
echo "$ROOT/local/bin/tmux is now available. You can optionally add $ROOT/local/bin to your PATH."
# }}}

