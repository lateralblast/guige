#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034
# shellcheck disable=SC2153

# Funtion update_iso_url
#
# Update ISO URL

update_iso_url () {
  BASE_INPUT_FILE=$( basename "$INPUT_FILE" )
  if [ "$ISO_OS_NAME" = "ubuntu" ]; then
    case $ISO_BUILD_TYPE in
      "daily-live"|"daily-live-server")
        if [ "$ISO_RELEASE" = "$CURRENT_ISO_DEV_RELEASE" ] || [ "$ISO_CODENAME" = "$CURRENT_ISO_CODENAME" ]; then
          ISO_URL="https://cdimage.ubuntu.com/ubuntu-server/daily-live/current/$ISO_CODENAME-live-server-$ISO_ARCH.iso"
        else
          ISO_URL="https://cdimage.ubuntu.com/ubuntu-server/$ISO_CODENAME/daily-live/current/$BASE_INPUT_FILE"
        fi
        NEW_DIR="$ISO_OS_NAME/$ISO_CODENAME"
       ;;
      "daily-desktop")
        if [ "$ISO_RELEASE" = "$CURRENT_ISO_DEV_RELEASE" ] || [ "$ISO_CODENAME" = "$CURRENT_ISO_CODENAME" ]; then
          ISO_URL="https://cdimage.ubuntu.com/daily-live/current/$BASE_INPUT_FILE"
        else
          ISO_URL="https://cdimage.ubuntu.com/$ISO_CODENAME/daily-live/current/$BASE_INPUT_FILE"
        fi
        NEW_DIR="$ISO_OS_NAME/$ISO_CODENAME"
        ;;
      "desktop")
        ISO_URL="https://releases.ubuntu.com/$ISO_RELEASE/$BASE_INPUT_FILE"
        NEW_DIR="$ISO_OS_NAME/$ISO_RELEASE"
        ;;
      *)
        if [ "$ISO_ARCH" = "amd64" ]; then
          URL_RELEASE=$( echo "$ISO_RELEASE" |awk -F. '{print $1"."$2}' )
          if [ "$URL_RELEASE" = "22.04" ]; then
            if [ "$ISO_RELEASE" = "22.04.4" ]; then
              ISO_URL="https://releases.ubuntu.com/$URL_RELEASE/$BASE_INPUT_FILE"
            else
              ISO_URL="https://old-releases.ubuntu.com/releases/$URL_RELEASE/$BASE_INPUT_FILE"
            fi
          else
            ISO_URL="https://releases.ubuntu.com/$URL_RELEASE/$BASE_INPUT_FILE"
          fi
        else
          ISO_URL="https://cdimage.ubuntu.com/releases/$ISO_RELEASE/release/$BASE_INPUT_FILE"
        fi
        NEW_DIR="$ISO_OS_NAME/$ISO_RELEASE"
        ;;
    esac
    if [ "$OLD_ISO_URL" = "" ]; then
      OLD_ISO_URL="$DEFAULT_OLD_ISO_URL"
    fi
  else
    if [ "$ISO_OS_NAME" = "rocky" ]; then
      if [ "$ISO_URL" = "" ]; then
        ISO_URL="https://download.rockylinux.org/pub/rocky/$ISO_MAJOR_RELEASE/isos/$ISO_ARCH/$BASE_INPUT_FILE"
      fi
    fi
  fi
}

# Function: update_required_packages
#
# Update required packages

update_required_packages () {
  if [ "$OS_NAME" = "Darwin" ]; then
    if ! [[ "$ACTION" =~ "docker" ]]; then
      REQUIRED_PACKAGES="p7zip lftp wget xorriso ansible squashfs"
    fi
  fi
}

# Function: update_iso_packages
#
# Update packages to include in ISO

update_iso_packages () {
  if [ "$ISO_OS_NAME" = "ubuntu" ]; then
    if [ "$DO_NO_HWE_KERNEL" = "false" ]; then
      ISO_INSTALL_PACKAGES="$ISO_INSTALL_PACKAGES linux-image-generic-hwe-$ISO_MAJOR_RELEASE.$ISO_MINOR_RELEASE"
    fi
  fi
}

# Function: create_iso
# 
# Prepare ISO

create_iso () {
  if [ "$DO_CREATE_ISO" = "true" ]; then
    case "$ISO_OS_NAME" in
      "ubuntu")
        create_autoinstall_iso
        ;;
      "rocky")
        create_kickstart_iso
        ;;
    esac
  fi
}

# Function: copy_iso
#
# Copy contents of ISO to a RW location so we can work with them
#
# Examples:
# rsync --exclude=/casper/ubuntu-server-minimal.squashfs -av ./isomount/ ./isonew/cd
# rsync -av ./isomount/ ./isonew/cd

copy_iso () {
  handle_output "# Copying ISO files from $ISO_MOUNT_DIR to $ISO_NEW_DIR/cd" TEXT
  if [ ! -f "/usr/bin/rsync" ]; then
    install_required_packages
  fi
  TEST_DIR="$ISO_MOUNT_DIR/EFI"
  if [ ! -d "$TEST_DIR" ]; then
    warning_message "ISO $INPUT_FILE not mounted"
    exit
  else
    if [ "$VERBOSE_MODE" = "true" ]; then
      if [ "$TEST_MODE" = "false" ]; then
        sudo rsync -av --delete "$ISO_MOUNT_DIR/" "$ISO_NEW_DIR/cd"
      fi
    else
      if [ "$TEST_MODE" = "false" ]; then
        sudo rsync -a --delete "$ISO_MOUNT_DIR/" "$ISO_NEW_DIR/cd"
      fi
    fi
  fi
}

# Function: unmount_iso
#
# unmount loopback ISO filesystem
#
# Examples:
# sudo umount -l /home/user/ubuntu-iso/isomount

unmount_iso () {
  handle_output "sudo umount -l $ISO_MOUNT_DIR"
  if [ "$TEST_MODE" = "false" ]; then
    sudo umount -l "$ISO_MOUNT_DIR"
  fi
}

# Function: unmounat_old_iso
#
# unmount loopback older release ISO filesystem
#
# Examples:
# sudo umount -l /home/user/ubuntu-old-iso/isomount

unmount_old_iso () {
  handle_output "sudo umount -l $OLD_ISO_MOUNT_DIR"
  if [ "$TEST_MODE" = "false" ]; then
    sudo umount -l "$OLD_ISO_MOUNT_DIR"
  fi
}

# Function: mount_iso
#
# Mount base ISO as loopback device so contents can be copied
#
# sudo mount -o loop ./ubuntu-22.04.1-live-server-arm64.iso ./isomount
# sudo mount -o loop ./ubuntu-22.04.1-live-server-amd64.iso ./isomount

mount_iso () {
  get_base_iso
  check_base_iso_file
  handle_output "sudo mount -o loop \"$WORK_DIR/files/$BASE_INPUT_FILE\" \"$ISO_MOUNT_DIR\""
  if [ "$TEST_MODE" = "false" ]; then
    sudo mount -o loop "$WORK_DIR/files/$BASE_INPUT_FILE" "$ISO_MOUNT_DIR"
  fi
}

# Function: unmount_old_iso
#
# Mount older revision base ISO as loopback device so contents can be copied
#
# sudo mount -o loop ./ubuntu-22.04.1-live-server-arm64.iso ./isomount
# sudo mount -o loop ./ubuntu-22.04.1-live-server-amd64.iso ./isomount

mount_old_iso () {
  get_old_base_iso
  check_old_base_iso_file
  handle_output "$ Mounting ISO $OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE at $OLD_ISO_MOUNT_DIR" TEXT
  if [ "$TEST_MODE" = "false" ]; then
    sudo mount -o loop "$OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE" "$OLD_ISO_MOUNT_DIR"
  fi
}

# Function: list_isos
#
# List ISOs

list_isos () {
  TEMP_VERBOSE_MODE="true"
  if [ "$ISO_SEARCH" = "" ]; then
    FILE_LIST=$(find "$WORK_DIR" -name "*.iso" 2> /dev/null)
  else
    FILE_LIST=$(find "$WORK_DIR" -name "*.iso" 2> /dev/null |grep "$ISO_SEARCH" )
  fi
  for FILE_NAME in $FILE_LIST; do
    if [ "$DO_SCP_HEADER" = "true" ]; then
      handle_output "$MY_USERNAME@$MY_IP:$FILE_NAME" TEXT
    else
      handle_output "$FILE_NAME" TEXT
    fi
  done
  TEMP_VERBOSE_MODE="false"
}

# Function: check_base_iso_file
#
# Check base ISO file exists

check_base_iso_file () {
  if [ -f "$INPUT_FILE" ]; then
    BASE_INPUT_FILE=$( basename "$INPUT_FILE" )
    FILE_TYPE=$( file "$WORK_DIR/files/$BASE_INPUT_FILE" |cut -f2 -d: |grep -E "MBR|ISO")
    if [ -z "$FILE_TYPE" ]; then
      warning_message "$WORK_DIR/files/$BASE_INPUT_FILE is not a valid ISO file"
      exit
    fi
  fi
}

# Function: check_old_base_iso_file
#
# Check previous release base ISO file exists
# Used when copying files from an old release to a new release

check_old_base_iso_file () {
  if [ -f "$OLD_INPUT_FILE" ]; then
    OLD_BASE_INPUT_FILE=$( basename "$OLD_INPUT_FILE" )
    OLD_FILE_TYPE=$( file "$OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE" |cut -f2 -d: |grep -E "MBR|ISO")
    if [ -z "$OLD_FILE_TYPE" ]; then
      warning_message "$OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE is not a valid ISO file"
      exit
    fi
  fi
}

# Function: get_base_iso
#
# Grab ISO 
#
# Examples:
#
# Live Server
#
# https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/jammy-live-server-amd64.iso
# wget https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.1-live-server-amd64.iso
#
# Daily Live Server
#
# https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/
#
# Desktop
#
# https://releases.ubuntu.com/22.04/
#
# Daily desktop
#
# https://cdimage.ubuntu.com/jammy/daily-live/current/
#

get_base_iso () {
  handle_output "# Check source ISO exists and grab it if it doesn't" TEXT
  BASE_INPUT_FILE=$( basename "$INPUT_FILE" )
  if [ "$FULL_FORCE_MODE" = "true" ]; then
    handle_output "rm $WORK_DIR/files/$BASE_INPUT_FILE"
    if [ "$TEST_MODE" = "false" ]; then
      rm "$WORK_DIR/files/$BASE_INPUT_FILE"
    fi
  fi
  check_base_iso_file
  if [ "$DO_CHECK_ISO" = "true" ]; then
    cd "$WORK_DIR/files" || exit ; wget -N "$ISO_URL"
  else
    if ! [ -f "$WORK_DIR/files/$BASE_INPUT_FILE" ]; then
      if [ "$TEST_MODE" = "false" ]; then
        wget "$ISO_URL" -O "$WORK_DIR/files/$BASE_INPUT_FILE"
      fi
    fi
  fi
}

# Function: get_old_base_iso
#
# Get old base ISO

get_old_base_iso () {
  handle_output "# Check old source ISO exists and grab it if it doesn't" TEXT
  OLD_BASE_INPUT_FILE=$( basename "$OLD_INPUT_FILE" )
  if [ "$FULL_FORCE_MODE" = "true" ]; then
    handle_output "rm $WORK_DIR/files/$OLD_BASE_INPUT_FILE"
    if [ "$TEST_MODE" = "false" ]; then
      rm "$OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE"
    fi
  fi
  check_old_base_iso_file
  if [ "$DO_CHECK_ISO" = "true" ]; then
    cd "$OLD_WORK_DIR/files" || exit ; wget -N "$OLD_ISO_URL"
  else
    if ! [ -f "$OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE" ]; then
      if [ "$TEST_MODE" = "false" ]; then
        wget "$OLD_ISO_URL" -O "$OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE"
      fi
    fi
  fi
}

# Function: get_iso_type
#
# Get ISO type

get_iso_type () {
  if [[ "$INPUT_FILE" =~ "dvd" ]]; then
    ISO_TYPE="dvd"
  fi
}

# Function: prepare_iso
# 
# Prepare ISO

prepare_iso () {
  case "$ISO_OS_NAME" in
    "ubuntu")
      prepare_autoinstall_iso
      ;;
    "rocky")
      prepare_kickstart_iso
      ;;
  esac
}

# Function: get_info_from_iso
#
# Get info from iso

get_info_from_iso () {
  handle_output "# Analysing $INPUT_FILE" TEXT
  TEST_FILE=$( basename "$INPUT_FILE" )
  TEST_NAME=$( echo "$TEST_FILE" | cut -f1 -d- )
  TEST_TYPE=$( echo "$TEST_FILE" | cut -f2 -d- )
  ISO_DISTRO="Ubuntu"
  case $TEST_NAME in
    "bionic")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_1804"
      ;;
    "focal")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2004"
      ;;
    "jammy")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2204"
      ;;
    "kinetic")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2210"
      ;;
    "lunar")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2304"
      ;;
    "mantic")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2310"
      ;;
    "nobile")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2404"
      ;;
    "ubuntu")
      ISO_RELEASE=$(echo "$TEST_FILE" |cut -f2 -d- )
      ;;
    *)
      ISO_RELEASE="$DEFAULT_ISO_RELEASE"
      ;;
  esac
  if [ "$TEST_NAME" = "ubuntu" ]; then
    if [ "$TEST_TYPE" = "desktop" ]; then
      ISO_ARCH=$( echo "$TEST_FILE" |cut -f4 -d- |cut -f1 -d. )
    else
      ISO_ARCH=$( echo "$TEST_FILE" |cut -f5 -d- |cut -f1 -d. )
      TEST_TYPE="live-server"
    fi
  else
    if [ "$TEST_TYPE" = "desktop" ]; then
      ISO_ARCH=$( echo "$TEST_FILE" |cut -f3 -d- |cut -f1 -d. )
    else
      ISO_ARCH=$( echo "$TEST_FILE" |cut -f4 -d- |cut -f1 -d. )
      TEST_TYPE="live-server"
    fi
  fi
  OUTPUT_FILE="$WORK_DIR/files/$TEST_NAME-$ISO_RELEASE-$TEST_TYPE-$ISO_ARCH.iso"
  handle_output "# Input ISO:     $INPUT_FILE" TEXT
  handle_output "# Distribution:  $ISO_DISTRO" TEXT
  handle_output "# Release:       $ISO_RELEASE" TEXT
  handle_output "# Codename:      $ISO_CODENAME" TEXT
  handle_output "# Architecture:  $ISO_ARCH" TEXT
  handle_output "# Output ISO:    $OUTPUT_FILE" TEXT
}
