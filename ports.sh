#!/bin/sh
#
# Copyright (C) 2015 Kurt Kanzenbach <kurt@kmk-computers.de>
# Time-stamp: <2015-09-03 09:07:19 kurt>
#
# Shell Script for updating the FreeBSD ports using portmaster.
#

set -e

PKG=/usr/sbin/pkg
MAKE=/usr/bin/make
PORTMASTER=/usr/local/sbin/portmaster
YES=/usr/bin/yes

usage()
{
  cat <<EOF
ports.sh [-h|--help] [command(s)]
  - commands
    - update : Update the ports tree
    - list   : Show ports to be updated
    - upgrade: Run portmaster to upgrade ports
    - --help : Show this help text
EOF
}

test_tools()
{
  [ -x "$PKG" ]        || (echo "pkg not found"        ; exit -1)
  [ -x "$MAKE" ]       || (echo "make not found"       ; exit -1)
  [ -x "$PORTMASTER" ] || (echo "portmaster not found" ; exit -1)
  [ -x "$YES" ]        || (echo "yes not found"        ; exit -1)
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
  while read -p "Run portmaster (y/n)? " ANSWER ; do
    case "$ANSWER" in
      y*) "$YES" | "$PORTMASTER" -adB ; break ;;
      n*) break ;;
    esac
  done
}

while [ $# -gt 0 ] ; do
  case "$1" in
    update   ) update_tree  ; shift ;;
    list     ) list_updates ; shift ;;
    upgrade  ) update_ports ; shift ;;
    -h|--help) usage ; shift ;;
    *        ) update_tree ; list_updates ; update_ports ; break ;;
  esac
done

exit 0
