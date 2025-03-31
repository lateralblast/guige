#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2046

# Function: unmount_squashfs
#
# Unmount squashfs filesystem

unmount_squashfs () {
  case "$ISO_CODENAME" in
    "ubuntu")
      unmount_ubuntu_squashfs
      ;;
  esac
}


# Function: unmount_ubuntu_squashfs
#
# Unmount ubuntu squashfs filesystem

unmount_ubuntu_squashfs () {
  if [ "$DO_ISO_SQUASHFS_UPDATE" = "true" ]; then
    handle_output "# Unmounting squashfs $ISO_NEW_DIR/squashfs" "TEXT"
    if [ "$DO_ISO_TESTMODE" = "false" ]; then
      MOUNT_TEST=$( mount | grep "$ISO_NEW_DIR/squashfs" | wc -l )
      if [ ! "$MOUNT_TEST" = "0" ]; then
        sudo umount "$ISO_NEW_DIR/squashfs"
      fi
    fi
  fi
}

# Function: copy_squashfs
#
# Copy ISO squashfs

copy_squashfs () {
  case "$ISO_CODENAME" in
    "ubuntu")
      copy_ubuntu_squashfs
      ;;
  esac
}

# Function: copy_ubuntu_squashfs
#
# Mount squashfs and copy files into it
#
# Examples:
# sudo mount -t squashfs -o loop ./isomount/casper/ubuntu-server-minimal.squashfs ./isonew/squashfs/
# sudo rsync -av ./isonew/squashfs/ ./isonew/custom
# sudo cp /etc/resolv.conf /etc/hosts ./isonew/custom/etc/

copy_ubuntu_squashfs () {
  if [ ! -f "/usr/bin/rsync" ]; then
    install_required_packages "$REQUIRED_PACKAGES"
  fi
  if [ "$DO_ISO_SQUASHFS_UPDATE" = "true" ] || [ "$DO_ISO_SQUASHFS_UNPACK" = "true" ]; then
    handle_output "# Copying squashfs files" "TEXT"
    CURRENT_KERNEL=$( uname -r )
    if [ -f "$CURRENT_KERNEL" ]; then
      if [ "$DO_ISO_TESTMODE" = "false" ]; then
        sudo mount -t squashfs -o loop "$ISO_SQUASHFSFILE" "$ISO_NEW_DIR/squashfs"
      fi
      if [ "$DO_ISO_VERBOSEMODE" = "true" ]; then
        if [ "$DO_ISO_TESTMODE" = "false" ]; then
          sudo rsync -av "$ISO_NEW_DIR/squashfs/" "$ISO_NEW_DIR/custom"
        fi
      else
        if [ "$DO_ISO_TESTMODE" = "false" ]; then
          sudo rsync -a "$ISO_NEW_DIR/squashfs/" "$ISO_NEW_DIR/custom"
        fi
      fi
    else
      if [ "$DO_ISO_TESTMODE" = "false" ]; then
        sudo unsquashfs -f -d "$ISO_NEW_DIR/custom" "$ISO_SQUASHFSFILE"
      fi
    fi
    if [ "$DO_ISO_TESTMODE" = "false" ]; then
      sudo cp /etc/resolv.conf /etc/hosts "$ISO_NEW_DIR/custom/etc"
    fi
  fi
}

# Function: update_iso_squashfs
#
# Update ISO squashfs

update_iso_squashfs () {
  case "$ISO_CODENAME" in
    "ubuntu")
      update_ubuntu_iso_squashfs
      ;;
  esac
}

# Function: update_ubuntu_iso_squashfs
#
# Update Ubuntu ISO squashfs

update_ubuntu_iso_squashfs () {
  if [ "$DO_ISO_SQUASHFS_UPDATE" = "true" ]; then
    handle_output "# Making squashfs (this will take a while)" "TEXT"
    if [ "$DO_ISO_TESTMODE" = "false" ]; then
      sudo mksquashfs "$ISO_NEW_DIR/custom" "$ISO_NEW_DIR/mksquash/filesystem.squashfs" -noappend
      sudo cp "$ISO_NEW_DIR/mksquash/filesystem.squashfs" "$NEW_SQUASHFS_FILE"
      sudo chmod 0444 i"$NEW_SQUASHFS_FILE"
      sudo echo -n $( sudo du -s --block-size=1 "$ISO_NEW_DIR/custom" | tail -1 | awk '{print $1}') | sudo tee "$ISO_NEW_DIR/mksquash/filesystem.size"
      sudo cp "$ISO_NEW_DIR/mksquash/filesystem.size" "$ISO_SOURCE_DIR/casper/filesystem.size"
      sudo chmod 0444 "$ISO_SOURCE_DIR/casper/filesystem.size"
      sudo find "$ISO_SOURCE_DIR" -type f -print0 | xargs -0 md5sum | sed "s@${ISO_NEW_DIR}@.@" | grep -v md5sum.txt | sudo tee "$ISO_SOURCE_DIR/md5sum.txt"
    fi
  fi
}
