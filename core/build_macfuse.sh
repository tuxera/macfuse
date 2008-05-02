#! /bin/sh
# Copyright (C) 2006-2007 Amit Singh. All Rights Reserved.
#

CUT=/usr/bin/cut
DIRNAME=/usr/bin/dirname
RM=/bin/rm
UNAME=/usr/bin/uname

os_name=`$UNAME -s`
os_codename="Unknown"

is_absolute_path=`echo "$0" | $CUT -c1`
if [ "$is_absolute_path" = "/" ]
then
    macfuse_dir="`$DIRNAME $0`/.."
else
    macfuse_dir="`pwd`/`$DIRNAME $0`/.."
fi
pushd . > /dev/null
cd "$macfuse_dir" || exit 1
macfuse_dir=`pwd`
popd > /dev/null

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
      sudo true # Need root password to delete previous builds
      if [ $? -ne 0 ]
      then
          echo "Administrator password is required to clean up MacFUSE builds."
          exit 1
      fi
      echo "Cleaning up any previous MacFUSE builds"
      sudo $RM -rf "$macfuse_dir"/core/10.4/fusefs/build/
      sudo $RM -rf "$macfuse_dir"/core/10.5/fusefs/build/
      sudo $RM -rf "$macfuse_dir"/core/sdk-objc/build/
      sudo $RM -rf "/tmp/macfuse-core-10.*-*"
      exit 0
  ;;
  8*)
      src_dir="$macfuse_dir/core/10.4/fusefs/"
      os_codename="Tiger"
  ;;
  9*)
      src_dir="$macfuse_dir/core/10.5/fusefs/"
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
