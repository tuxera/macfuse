#!/bin/bash
#
# Copyright (C) 2008 Google. All Rights Reserved.
#
# Creates the "MacFUSE.pkg".

# TODO: 
#  - Fill in the pkg size with the size from one our our .pkgs  

MACFUSE_VERSION=$1
MACFUSE_UPDATER=$2
MACFUSE_PLATFORMS=$3

BUILD_DIR="/tmp/macfuse-$MACFUSE_VERSION"

PATH=/Developer/usr/bin:/Developer/Tools:$PATH
PACKAGEMAKER=packagemaker

OUTPUT_PACKAGE_NAME="MacFUSE.pkg"
OUTPUT_PACKAGE="${BUILD_DIR}/${OUTPUT_PACKAGE_NAME}"

DISTRIBUTION_FOLDER="$BUILD_DIR/Distribution_folder"
INSTALL_RESOURCES_NAME="Install_resources"
INSTALL_RESOURCES_SRC="./$INSTALL_RESOURCES_NAME"
INSTALL_RESOURCES="$BUILD_DIR/$INSTALL_RESOURCES_NAME"
INFO_PLIST_IN="Info.plist.in"
INFO_PLIST_OUT="${BUILD_DIR}/Info.plist"
DESCRIPTION_PLIST="./Description.plist"

# Make sure they gave proper args.
if [ x"$MACFUSE_VERSION" = x"" -o x"MACFUSE_UPDATER" = x"" -o x"$MACFUSE_PLATFORMS" = x"" ]
then
  echo -n "Usage: make-pkg.sh <version> <updater_bundle_path>"
  echo "<osver=pkgpath,osver=pkgpath,..>"
  exit 1
fi

# Check input sources
if [ ! -d "$BUILD_DIR" ]
then
  echo "Warning: Build dir '$BUILD_DIR' does not exist; creating."
  mkdir -p "$BUILD_DIR"
fi
if [ ! -d "$INSTALL_RESOURCES_SRC" ]
then
  echo "Unable to find install resources dir: '$INSTALL_RESOURCES_SRC'"
  exit 1
fi
if [ ! -f "$INFO_PLIST_IN" ]
then
  echo "Unable to find Info.plist: '$INFO_PLIST_IN'"
  exit 1
fi
if [ ! -f "$DESCRIPTION_PLIST" ]
then
  echo "Unable to find Description.plist: '$DESCRIPTION_PLIST'"
  exit 1
fi

SCRATCH_DMG="$BUILD_DIR/macfuse-scratch.dmg"
FINAL_DMG="$BUILD_DIR/MacFUSE-$MACFUSE_VERSION.dmg"
VOLUME_NAME="MacFUSE $MACFUSE_VERSION"

# Remove any previous runs
sudo rm -rf "$DISTRIBUTION_FOLDER"
sudo rm -rf "$INSTALL_RESOURCES"
sudo rm -rf "$OUTPUT_PACKAGE"
sudo rm -f "$INFO_PLIST_OUT"
sudo rm -f "$SCRATCH_DMG"
sudo rm -f "$FINAL_DMG"

# Create the distribution folder (empty for this package)
mkdir $DISTRIBUTION_FOLDER

# Copy package resources to build directory while stripping out .svn etc.
sudo tar --exclude '.svn' -cpvf - "$INSTALL_RESOURCES_SRC" | sudo tar -C "$BUILD_DIR" -xpvf -

# Copy all of the MacFUSE Core.pkg's in their platform directories under Resources
PKG_SIZE=0
SAVED_IFS="$IFS"
IFS=","
for i in $MACFUSE_PLATFORMS
do
  if [ x"$i" = x"" ]
  then
    continue;  # Skip empty/bogus comma-item
  fi

  OS_VERSION=${i%%=*}
  CORE_PKG=${i##*=}
  CORE_PKG_DIR=$(dirname "$CORE_PKG")
  CORE_PKG_NAME=$(basename "$CORE_PKG")
  PKG_DST="${INSTALL_RESOURCES}/${OS_VERSION}"

  NEW_SIZE=$(defaults read "$CORE_PKG/Contents/Info" IFPkgFlagInstalledSize)
  if [ -z "$NEW_SIZE" ]
  then
    echo "Unable to read pkg size from: ${CORE_PKG}"
  fi
  if [ $NEW_SIZE -gt $PKG_SIZE ]
  then
    PKG_SIZE=$NEW_SIZE
  fi

  echo "Adding package for OS X Version=$OS_VERSION, Pkg=$CORE_PKG"
  mkdir "$PKG_DST"
  sudo tar -C "$CORE_PKG_DIR" -cpvf - "$CORE_PKG_NAME" | \
    sudo tar -C "$PKG_DST" -xpvf -
  if [ $? -ne 0 ]
    then
    echo "Failed to add package."
    exit 1
  fi
done
IFS="$SAVED_IFS"

# If we included 10.5, then we can symlink and get 10.6 for free.
if [ -d "${INSTALL_RESOURCES}/10.5" ]
then
  ln -s "10.5" "${INSTALL_RESOURCES}/10.6"
fi

# Copy the MacFUSE Updater under Resources.
echo "Adding MacFUSEUpdater: ${MACFUSE_UPDATER}"
sudo cp "$MACFUSE_UPDATER" "$INSTALL_RESOURCES"
if [ $? -ne 0 ]
then
  echo "Failed to copy MacFUSE Updater."
  exit 1
fi

# Fix up the Info.plist
sed -e "s/MACFUSE_PKG_VERSION_LITERAL/$MACFUSE_VERSION/g" \
    -e "s/MACFUSE_PKG_INSTALLED_SIZE/$PKG_SIZE/g" \
  < "$INFO_PLIST_IN" > "$INFO_PLIST_OUT"

# Build the package
sudo $PACKAGEMAKER -build -p "$OUTPUT_PACKAGE" -f "$DISTRIBUTION_FOLDER" -b /tmp -ds -v \
                   -r "$INSTALL_RESOURCES" -i "$INFO_PLIST_OUT" -d "$DESCRIPTION_PLIST"
if [ $? -eq 0 ]
then
  sudo chown -R root:admin "$OUTPUT_PACKAGE"
fi

if [ $? -ne 0 ]
then
  echo "Failed to change ownership of $OUTPUT_PACKAGE"
  exit 1
fi

# Create the volume.
sudo hdiutil create -layout NONE -megabytes 10 -fs HFS+ -volname "$VOLUME_NAME" "$SCRATCH_DMG"
if [ $? -ne 0 ]
then
    echo "Failed to create scratch disk image: $SCRATCH_DMG"
    exit 1
fi

# Attach/mount the volume.
sudo hdiutil attach -private -nobrowse "$SCRATCH_DMG"
if [ $? -ne 0 ]
then
    echo "Failed to attach scratch disk image: $SCRATCH_DMG"
    exit 1
fi

VOLUME_PATH="/Volumes/$VOLUME_NAME"

# Create the .engine_install file.
ENGINE_INSTALL_DST="${VOLUME_PATH}/.engine_install"
cat >  "$ENGINE_INSTALL_DST" <<EOF
#!/bin/sh
/usr/sbin/installer -pkg "\$1/${OUTPUT_PACKAGE_NAME}" -target /
EOF
chmod +x "$ENGINE_INSTALL_DST"

# For backward compatibility, we need a .keystone_install
ln -s ".engine_install" "${VOLUME_PATH}/.keystone_install"

# Copy over the package.
sudo cp -pRX "$OUTPUT_PACKAGE" "$VOLUME_PATH"
if [ $? -ne 0 ]
then
    hdiutil detach "$VOLUME_PATH"
    exit 1
fi

# Set the custom icon.
sudo cp -pRX "$INSTALL_RESOURCES/.VolumeIcon.icns" "$VOLUME_PATH"/.VolumeIcon.icns
sudo /Developer/Tools/SetFile -a C "$VOLUME_PATH"

# Copy over the license file.
sudo cp "$INSTALL_RESOURCES/License.rtf" "$VOLUME_PATH"/License.rtf

# Copy over the CHANGELOG.txt.
sudo cp "../../../CHANGELOG.txt" "$VOLUME_PATH"/CHANGELOG.txt

# Detach the volume.
hdiutil detach "$VOLUME_PATH"
if [ $? -ne 0 ]
then
    echo "Failed to detach volume: $VOLUME_PATH"
    exit 1
fi

# Convert to a read-only compressed dmg.
hdiutil convert -imagekey zlib-level=9 -format UDZO "$SCRATCH_DMG" -o "$FINAL_DMG"
if [ $? -ne 0 ]
then
    echo "Failed to convert disk image."
    exit 1
fi

sudo rm "$SCRATCH_DMG"

echo "SUCCESS: All Done."
exit 0
