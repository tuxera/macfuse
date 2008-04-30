#! /bin/sh
# Copyright (C) 2006-2007 Amit Singh. All Rights Reserved.
#

DIRNAME=/usr/bin/dirname
RM=/bin/rm
UNAME=/usr/bin/uname

os_name=`$UNAME -s`
os_codename="Unknown"
this_dir=`$DIRNAME $0`

os_release=`$UNAME -r`
if [ "$1" != "" ]
then
    os_release="$1"
fi

src_dir="/dev/null"

if [ "$os_name" != "Darwin" ]
then
    echo "This script can only be run on Darwin"
    exit 1
fi

case "$os_release" in
  0)
      pushd . > /dev/null
      if [ $? -ne 0 ]
      then
          echo "$this_dir" is not a valid MacFUSE source directory
          exit 1
      fi
      echo "Cleaning up any previous MacFUSE builds"
      sudo $RM -rf "$this_dir"/10.4/fusefs/build/
      sudo $RM -rf "$this_dir"/10.5/fusefs/build/
      sudo $RM -rf "$this_dir"/sdk-objc/build/
      sudo $RM -rf "/tmp/macfuse-core-10.*-*"
      popd > /dev/null
      exit 0
  ;;
  8*)
      src_dir="$this_dir/10.4/fusefs/"
      os_codename="Tiger"
  ;;
  9*)
      src_dir="$this_dir/10.5/fusefs/"
      os_codename="Leopard"
  ;;
  *)
      echo "Unsupported Mac OS X release $os_release"
      exit 1
  ;;
esac

sudo true # Need root password to set permissions for output files.
if [ $? -ne 0 ]
then
    echo "Administrator password is required to build MacFUSE."
    exit 1
fi

echo "Initiating Universal build of MacFUSE for Mac OS X \"$os_codename\""

pushd . > /dev/null

cd "$src_dir"
if [ $? -ne 0 ]
then
    echo "*** failed to access MacFUSE source"
    exit 1
fi

sudo xcodebuild -target All -configuration Release

ret=$?

popd > /dev/null

exit $ret
