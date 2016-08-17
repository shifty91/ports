#!/bin/sh
#
# Time-stamp: <2016-08-17 18:11:09 kurt>
#
# Shell Script for updating the FreeBSD ports using portmaster.
#
# Copyright (c) 2015, Kurt Kanzenbach <kurt@kmk-computers.de>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

set -e

MAILTO=root
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

PKG=/usr/sbin/pkg
MAKE=/usr/bin/make
PORTMASTER=/usr/local/sbin/portmaster
YES=/usr/bin/yes
MAIL=/usr/bin/mail

usage()
{
  cat <<EOF
$0 [-h|--help] [command(s)]
  - commands
    - update : Update the ports tree
    - list   : Show ports to be updated
    - upgrade: Run portmaster to upgrade ports
    - cron   : Updates ports tree and sends a mail with a list of outdated ports
    - --help : Show this help text
EOF
}

test_tools()
{
  [ -x "$PKG" ]        || ( echo "pkg not found"        ; exit 1 )
  [ -x "$MAKE" ]       || ( echo "make not found"       ; exit 1 )
  [ -x "$PORTMASTER" ] || ( echo "portmaster not found" ; exit 1 )
  [ -x "$YES" ]        || ( echo "yes not found"        ; exit 1 )
  [ -x "$MAIL" ]       || ( echo "mail not found"       ; exit 1 )
}

update_tree()
{
  echo -n "Updating ports tree..."
  cd /usr/ports
  "$MAKE" update >/dev/null
  echo "Done"
}

list_updates()
{
  echo "Ports to be updated:"
  "$PKG" version -vl\<
}

update_ports()
{
  local PORTS=`$PKG version -vl\<`
  if [ "$PORTS" == "" ] ; then
    echo "Nothing to update"
    exit 1
  fi

  while read -p "Run portmaster (y/n)? " ANSWER ; do
    case "$ANSWER" in
      y*) "$YES" | "$PORTMASTER" -adB ; break ;;
      n*) break ;;
    esac
  done
}

cron()
{
  cd /usr/ports
  # update ports depending on method
  local PORTSNAP=`which portsnap`
  local SVN=`which svn`
  local GIT=`which git`
  if [ -f ".portsnap.INDEX" ] ; then
    [ -x "$PORTSNAP" ] && "$PORTSNAP" cron update >/dev/null
  elif [ -d ".svn" ] ; then
    [ -x "$SVN" ] && "$SVN" update >/dev/null
  elif [ -d ".git" ] ; then
    [ -x "$GIT" ] && "$GIT" pull >/dev/null 2>&1
  else
    echo "Could not update ports tree. Exiting now."
    exit 1
  fi
  local PORTS=`"$PKG" version -vl\<`
  [ "$PORTS" == "" ] && return
  (
    echo "Hello,"
    echo ""
    echo "List of ports to be updated:"
    echo "$PORTS"
    echo ""
    echo "Cheers, $0"
  ) | "$MAIL" -s "Updateable Ports on Host `hostname`" "$MAILTO"
}

test_tools

if [ $# -eq 0 ] ; then
  # nothing given -> do complete update
  update_tree
  list_updates
  update_ports
else
  # arguments given
  while [ $# -gt 0 ] ; do
    case "$1" in
      update   ) update_tree  ; shift ;;
      list     ) list_updates ; shift ;;
      upgrade  ) update_ports ; shift ;;
      cron     ) cron ; break ;;
      -h|--help) usage ; shift ;;
      *        ) echo "Unknown option '$1'" ; exit 1 ;;
    esac
  done
fi

exit 0
