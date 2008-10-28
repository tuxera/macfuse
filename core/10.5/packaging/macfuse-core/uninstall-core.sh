#!/bin/sh
#
# Copyright (C) 2006 Google. All Rights Reserved.
#
# Uninstalls the "MacFUSE Core.pkg".

# Make sure this script runs as root
if [ "$EUID" -ne 0 ]
then
  echo $0: Sudoing...
  sudo $0 "$@"
  exit $?
fi

INSTALL_VOLUME="/"

OS_RELEASE=`/usr/bin/uname -r`

case "$OS_RELEASE" in 
  8*)
    echo "Incorrect uninstall. Use the Tiger version please."
    exit 1
    ;;
  9*)
    PACKAGE_RECEIPT="$INSTALL_VOLUME/Library/Receipts/MacFUSE Core.pkg"
    BOMFILE="$PACKAGE_RECEIPT/Contents/Archive.bom"
    ;;
  10*)
     PACKAGE_RECEIPT=""
     BOMFILE="$INSTALL_VOLUME/var/db/receipts/com.google.macfuse.core.bom"
     ;;
esac

# Set to 1 if at any point it looks like the uninstall did not proceed
# smoothly. If IS_BOTCHED_UNINSTALL then we don't remove the Receipt. 
IS_BOTCHED_UNINSTALL=0

# Check to make sure that operations (such as rm, rmdir) are relatively
# safe. This should only allow operations throught that would operate on
# stuff installed by MacFUSE.
#
# Ret: 1 (true) if the prefix is ok to use, otherwise 0 (false).
function is_safe_prefix() {
  local path="$1"
  case "$path" in
    "$INSTALL_VOLUME"/./usr/local/lib/pkgconfig)
      # We don't try to remove the pkgconfig directory.
      return 0;
      ;; 
    "$INSTALL_VOLUME"/./usr/local/bin/*                        |  \
    "$INSTALL_VOLUME"/./usr/local/lib/*                        |  \
    "$INSTALL_VOLUME"/./usr/local/include/*                    |  \
    "$INSTALL_VOLUME"/./Library/Extensions/fusefs.kext         |  \
    "$INSTALL_VOLUME"/./Library/Extensions/fusefs.kext/*       |  \
    "$INSTALL_VOLUME"/./Library/Filesystems/fusefs.fs          |  \
    "$INSTALL_VOLUME"/./Library/Filesystems/fusefs.fs/*        |  \
    "$INSTALL_VOLUME"/./Library/Frameworks/MacFUSE.framework   |  \
    "$INSTALL_VOLUME"/./Library/Frameworks/MacFUSE.framework/* |  \
    "$INSTALL_VOLUME"/Library/Receipts/MacFUSE\ Core.pkg       |  \
    "$INSTALL_VOLUME"/Library/Receipts/MacFUSE\ Core.pkg/*)
      # These are all ok to process.
      return 1;
      ;;  
  esac

  return 0;  # Not allowed!
}

# Remove the given file if it seems "safe" to do so.
function remove_file() {
  local path="$1"
  is_safe_prefix "$path"
  local allow=$?
  if [ $allow -ne 1 ]
  then
    # We ignore this file, which is fine.
    echo "Ignoring file '$path'"
    return 0;
  fi

  if [ \( ! -e "$path" \) -a \( ! -L "$path" \) ]
  then
    # No longer exists
    echo "Skipping file: '$path' since it no longer exists."
    return 0;
  fi

  if [ \( ! -f "$path" \) -a \( ! -L "$path" \) ]
  then
    # This is no longer a file?
    echo "Skipping file: '$path' since it is no longer a file or symlink?"
    return 1;
  fi

  echo "Removing file: '$path'"
  rm -f "$path"
}

# Remove the given directory if it seems "safe" to do so. This will only remove
# empty directories.
function remove_dir() {
  local path="$1"
  is_safe_prefix "$path"
  local allow=$?
  if [ $allow -ne 1 ]
  then
    # We ignore this directory.
    echo "Ignoring dir: '$path'"
    return 0;
  fi

  if [ ! -e "$path" ]
  then
    # No longer exists
    echo "Skipping dir: '$path' since it no longer exists."
    return 0;
  fi

  if [ ! -d "$path" ]
  then
    # Not a directory?
    echo "Skipping dir: '$path' since it is either gone or no longer a dir."
    return 1;
  fi

  echo "Removing dir: '$path'"
  rmdir "$path"
}

# Forcefully remove the given directory tree. This is "rm -rf", so use this routine with caution!
function remove_tree() {
  local path="$1"
  is_safe_prefix "$path"
  local allow=$?
  if [ $allow -ne 1 ]
  then
    # We ignore this tree.
    echo "Ignoring tree: '$path'"
    return 0;
  fi

  if [ ! -e "$path" ]
  then
    # No longer exists
    echo "Skipping tree: '$path' since it no longer exists."
    return 0;
  fi

  if [ ! -d "$path" ]
  then
    # Not a directory?
    echo "Skipping tree: '$path' since it is not a directory."
    return 1;
  fi

  echo "Removing tree: '$path'"
  rm -rf "$path"
}


# Make sure the INSTALL_VOLUME is ok.
if [ ! -d "$INSTALL_VOLUME" ]; then
  echo "Foo"
  echo "Install volume '$INSTALL_VOLUME' is not a directory."
  exit 2
fi

# Make sure that MacFUSE Core is installed and the Archive.bom is present.
if [ ! -z "$PACKAGE_RECEIPT" ]
then 
  if [ ! -d "$PACKAGE_RECEIPT" ]
  then
    echo "It appears that MacFUSE Core is not installed."
    exit 3
  fi
else
  /usr/sbin/pkgutil --pkg-info com.google.macfuse.core > /dev/null 2>&1
  if [ $? -ne 0 ]
  then
    echo "It appears that MacFUSE Core is not installed."
    exit 3    
  fi
fi
if [ ! -f "$BOMFILE" ]
then
  echo "Can not find the Archive.bom for MacFUSE Core package."
  exit 4
fi

# 1. Try to unload the kext if possible. Best effort, so ignore errors.
kextunload -b com.google.filesystems.fusefs > /dev/null 2>&1

# 2. Remove files and symlinks
for x in `/usr/bin/lsbom -slf "$BOMFILE"` 
do
  remove_file "$INSTALL_VOLUME/$x"
  if [ $? -ne 0 ]
  then
    IS_BOTCHED_UNINSTALL=1
  fi
done

# 3. Remove autoinstaller
remove_file "$INSTALL_VOLUME/./Library/Filesystems/fusefs.fs/Support/autoinstall-macfuse-core"

# 4. Remove the directories
for x in `/usr/bin/lsbom -sd "$BOMFILE" | /usr/bin/sort -r`
do
  remove_dir "$INSTALL_VOLUME/$x"
  if [ $? -ne 0 ]
  then
    IS_BOTCHED_UNINSTALL=1
  fi
done

# 5. Remove the Receipt.
if [ $IS_BOTCHED_UNINSTALL -eq 0 ]
then
  if [ ! -z "$PACKAGE_RECEIPT" ]
  then
    remove_tree "$PACKAGE_RECEIPT"
    if [ $? -ne 0 ]
    then
      IS_BOTCHED_UNINSTALL=1
    fi
  else 
    /usr/sbin/pkgutil --forget com.google.macfuse.core
    if [ $? -ne 0 ]
    then
      IS_BOTCHED_UNINSTALL=1
    fi
    /usr/sbin/pkgutil --forget com.google.macfuse
    if [ $? -ne 0 ]
    then
      IS_BOTCHED_UNINSTALL=1
    fi
  fi
fi

exit $IS_BOTCHED_UNINSTALL
