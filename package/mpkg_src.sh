#!/bin/sh

# This script requires 'GNU tar' tool for compression.

if [ "$1" = 'zip' ] || [ "$1" = 'ZIP' ]; then
   hb_archbin='zip'
   hb_ext='.zip'
elif tar --version >/dev/null 2>&1; then
   hb_archbin='tar'
elif gtar --version >/dev/null 2>&1; then
   hb_archbin='gtar'
else
   hb_archbin='tar'
   echo "Warning!!! Cannot find 'GNU tar'"
fi

hb_currdir="$(pwd)"

hb_archopt='-czf'
[ -n "${hb_ext}" ] || hb_ext='.tar.gz'

if [ -f mpkg_ver.sh ]; then
   hb_rootdir='..'
else
   hb_rootdir=$(dirname "$0")
   hb_rootdir=$(dirname "${hb_rootdir}")
fi
# shellcheck source=./mpkg_ver.sh
. "${hb_rootdir}/package/mpkg_ver.sh"

hb_ver=$(get_hbver "${hb_rootdir}")
hb_filename="${hb_currdir}/harbour-${hb_ver}.src${hb_ext}"
rm -f "$hb_filename"

#[ -z "$TZ" ] && export TZ=PST8PDT

hb_collect_all_git()
{
   for f in $(git ls-tree HEAD -r --name-only)
   do
      [ -f "$f" ] && echo "$f"
   done
}

hb_collect_all_tree()
{
   _exclude='/obj/|/lib/|/bin/.*/|\.tar|\.zip|\.exe|\.log|/linux/|/win|/config/'
   for f in $(find -type f | grep -vE "${_exclude}")
   do
      echo "$f" | awk '{ string=substr($0, 2); print string; }'
   done
   find config -type f -exec echo '{}' \;
}

hb_rmflst='yes'
hb_flst='bin/hb_flst.tmp'
if [ -d "$hb_rootdir/.git" ] ; then
   hb_rmflst='yes'
   (cd "$hb_rootdir" || exit; hb_collect_all_git) > "$hb_rootdir/$hb_flst"
   echo "$hb_flst" >> "$hb_rootdir/$hb_flst"
else
   hb_rmflst='yes'
   (cd "$hb_rootdir" || exit; hb_collect_all_tree) > "$hb_rootdir/$hb_flst"
fi

if [ "$hb_archbin" = 'zip' ]; then
   (cd "$hb_rootdir" || exit; $hb_archbin -r -q "$hb_filename" . "-i@$hb_flst")
else
   (cd "$hb_rootdir" || exit; $hb_archbin $hb_archopt "$hb_filename" --files-from "$hb_flst")
fi
[ "$hb_rmflst" != 'yes' ] || rm -fR "${hb_rootdir:?}/$hb_flst"

cd "$hb_currdir" || exit
