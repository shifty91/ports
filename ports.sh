#!/bin/sh
#
# Copyright (C) 2015 Kurt Kanzenbach <kurt@kmk-computers.de>
# Time-stamp: <2015-08-31 12:13:04 kurt>
#
# Shell Script for updating the FreeBSD ports tree.
# It uses portmaster for that.
#

set -e

PKG=/usr/sbin/pkg
MAKE=/usr/bin/make
PORTMASTER=/usr/local/sbin/portmaster
YES=/usr/bin/yes

test_tools()
{
  [ -x "$PKG" ]        || (echo "pkg not found"        ; exit -1)
  [ -x "$MAKE" ]       || (echo "make not found"       ; exit -1)
  [ -x "$PORTMASTER" ] || (echo "portmaster not found" ; exit -1)
  [ -x "$YES" ]        || (echo "yes not found"        ; exit -1)
}

update_tree()
{
  cd /usr/ports
  "$MAKE" update
}

list_updates()
{
  "$PKG" version -vl\<
}

update_ports()
{
  "$YES" | "$PORTMASTER" -adB
}

case "$1" in
  update  ) update_tree  ;;
  list    ) list_updates ;;
  upgrade ) update_ports ;;
  *       ) update_tree ; list_updates ; update_ports ;;
esac

exit 0
