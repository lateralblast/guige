#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034
# shellcheck disable=SC2153

# Funtion update_iso_url
#
# Update ISO URL

update_iso_url () {
  BASE_ISO_INPUT_FILE=$( basename "$ISO_INPUT_FILE" )
  if [ "$ISO_OS_NAME" = "ubuntu" ]; then
    case $ISO_BUILD_TYPE in
      "daily-live"|"daily-live-server")
        if [ "$ISO_RELEASE" = "$CURRENT_ISO_DEV_RELEASE" ] || [ "$ISO_CODENAME" = "$CURRENT_ISO_CODENAME" ]; then
          ISO_URL="https://cdimage.ubuntu.com/ubuntu-server/daily-live/current/$ISO_CODENAME-live-server-$ISO_ARCH.iso"
        else
          ISO_URL="https://cdimage.ubuntu.com/ubuntu-server/$ISO_CODENAME/daily-live/current/$BASE_ISO_INPUT_FILE"
        fi
        NEW_DIR="$ISO_OS_NAME/$ISO_CODENAME"
        CI_URL="https://cloud-images.ubuntu.com/daily/server/$ISO_CODENAME/current/$BASE_ISO_INPUT_FILE"
       ;;
      "daily-desktop")
        if [ "$ISO_RELEASE" = "$CURRENT_ISO_DEV_RELEASE" ] || [ "$ISO_CODENAME" = "$CURRENT_ISO_CODENAME" ]; then
          ISO_URL="https://cdimage.ubuntu.com/daily-live/current/$BASE_ISO_INPUT_FILE"
        else
          ISO_URL="https://cdimage.ubuntu.com/$ISO_CODENAME/daily-live/current/$BASE_ISO_INPUT_FILE"
        fi
        NEW_DIR="$ISO_OS_NAME/$ISO_CODENAME"
        ;;
      "desktop")
        ISO_URL="https://releases.ubuntu.com/$ISO_RELEASE/$BASE_ISO_INPUT_FILE"
        NEW_DIR="$ISO_OS_NAME/$ISO_RELEASE"
        ;;
      *)
        if [ "$ISO_ARCH" = "amd64" ]; then
          URL_RELEASE=$( echo "$ISO_RELEASE" |awk -F. '{print $1"."$2}' )
          if [ "$URL_RELEASE" = "22.04" ]; then
            if [ "$ISO_RELEASE" = "22.04.4" ]; then
              ISO_URL="https://releases.ubuntu.com/$URL_RELEASE/$BASE_ISO_INPUT_FILE"
            else
              ISO_URL="https://old-releases.ubuntu.com/releases/$URL_RELEASE/$BASE_ISO_INPUT_FILE"
            fi
          else
            ISO_URL="https://releases.ubuntu.com/$URL_RELEASE/$BASE_ISO_INPUT_FILE"
          fi
        else
          ISO_URL="https://cdimage.ubuntu.com/releases/$ISO_RELEASE/release/$BASE_ISO_INPUT_FILE"
        fi
        CI_URL="https://cloud-images.ubuntu.com/releases/$ISO_RELEASE/release/$BASE_ISO_INPUT_FILE"
        NEW_DIR="$ISO_OS_NAME/$ISO_RELEASE"
        ;;
    esac
    if [ "$OLD_ISO_URL" = "" ]; then
      OLD_ISO_URL="$DEFAULT_OLD_ISO_URL"
    fi
  else
    if [ "$ISO_OS_NAME" = "rocky" ]; then
      if [ "$ISO_URL" = "" ]; then
        ISO_URL="https://download.rockylinux.org/pub/rocky/$ISO_MAJOR_RELEASE/isos/$ISO_ARCH/$BASE_ISO_INPUT_FILE"
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
    if [ "$DO_HWE_KERNEL" = "true" ]; then
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
  handle_output "# Copying ISO files from $ISO_MOUNT_DIR to $ISO_NEW_DIR/cd" "TEXT"
  if [ ! -f "/usr/bin/rsync" ]; then
    install_required_packages "$REQUIRED_PACKAGES"
  fi
  UC_TEST_DIR="$ISO_MOUNT_DIR/EFI"
  LC_TEST_DIR="$ISO_MOUNT_DIR/efi"
  if [ ! -d "$UC_TEST_DIR" ] && [ ! -d "$LC_TEST_DIR" ]; then
    warning_message "ISO $ISO_INPUT_FILE not mounted"
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
  handle_output "sudo umount -l $ISO_MOUNT_DIR" ""
  if [ "$TEST_MODE" = "false" ]; then
    MOUNT_TEST=$( mount | grep "$ISO_MOUNT_DIR" | wc -l )
    if [ ! "$MOUNT_TEST" = "0" ]; then
      sudo umount -l "$ISO_MOUNT_DIR"
    fi
  fi
}

# Function: unmounat_old_iso
#
# unmount loopback older release ISO filesystem
#
# Examples:
# sudo umount -l /home/user/ubuntu-old-iso/isomount

unmount_old_iso () {
  handle_output "sudo umount -l $OLD_ISO_MOUNT_DIR" ""
  if [ "$TEST_MODE" = "false" ]; then
    MOUNT_TEST=$( mount | grep "$OLD_ISO_MOUNT_DIR" | wc -l )
    if [ ! "$MOUNT_TEST" = "0" ]; then
      sudo umount -l "$OLD_ISO_MOUNT_DIR"
    fi
  fi
}

# Function: mount_iso
#
# Mount base ISO as loopback device so contents can be copied
#
# sudo mount -o loop ./ubuntu-22.04.1-live-server-arm64.iso ./isomount 2> /dev/null

mount_iso () {
  get_base_iso
  check_base_iso_file
  handle_output "# Mounting ISO $WORK_DIR/files/$BASE_ISO_INPUT_FILE at $ISO_MOUNT_DIR" "TEXT"
  handle_output "sudo mount -o loop \"$WORK_DIR/files/$BASE_ISO_INPUT_FILE\" \"$ISO_MOUNT_DIR\" 2> /dev/null" ""
  if [ "$TEST_MODE" = "false" ]; then
    sudo mount -o loop "$WORK_DIR/files/$BASE_ISO_INPUT_FILE" "$ISO_MOUNT_DIR" 2> /dev/null
  fi
}

# Function: unmount_old_iso
#
# Mount older revision base ISO as loopback device so contents can be copied
#
# sudo mount -o loop ./ubuntu-22.04.1-live-server-arm64.iso ./isomount 2> /dev/null

mount_old_iso () {
  get_old_base_iso
  check_old_base_iso_file
  handle_output "# Mounting ISO $OLD_WORK_DIR/files/$OLD_BASE_ISO_INPUT_FILE at $OLD_ISO_MOUNT_DIR" "TEXT"
  handle_output "sudo mount -o loop \"$OLD_WORK_DIR/files/$OLD_BASE_ISO_INPUT_FILE\" \"$OLD_ISO_MOUNT_DIR\" 2> /dev/null" ""
  if [ "$TEST_MODE" = "false" ]; then
    sudo mount -o loop "$OLD_WORK_DIR/files/$OLD_BASE_ISO_INPUT_FILE" "$OLD_ISO_MOUNT_DIR" 2> /dev/null
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
      handle_output "$BMC_USERNAME@$MY_IP:$FILE_NAME" "TEXT"
    else
      handle_output "$FILE_NAME" "TEXT"
    fi
  done
  TEMP_VERBOSE_MODE="false"
}

# Function: check_base_iso_file
#
# Check base ISO file exists

check_base_iso_file () {
  if [ -f "$ISO_INPUT_FILE" ]; then
    BASE_ISO_INPUT_FILE=$( basename "$ISO_INPUT_FILE" )
    FILE_TYPE=$( file "$WORK_DIR/files/$BASE_ISO_INPUT_FILE" |cut -f2 -d: |grep -E "MBR|ISO")
    if [ -z "$FILE_TYPE" ]; then
      warning_message "$WORK_DIR/files/$BASE_ISO_INPUT_FILE is not a valid ISO file"
      exit
    fi
  fi
}

# Function: check_old_base_iso_file
#
# Check previous release base ISO file exists
# Used when copying files from an old release to a new release

check_old_base_iso_file () {
  if [ -f "$OLD_ISO_INPUT_FILE" ]; then
    OLD_BASE_ISO_INPUT_FILE=$( basename "$OLD_ISO_INPUT_FILE" )
    OLD_FILE_TYPE=$( file "$OLD_WORK_DIR/files/$OLD_BASE_ISO_INPUT_FILE" |cut -f2 -d: |grep -E "MBR|ISO")
    if [ -z "$OLD_FILE_TYPE" ]; then
      warning_message "$OLD_WORK_DIR/files/$OLD_BASE_ISO_INPUT_FILE is not a valid ISO file"
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
  handle_output "# Check source ISO exists and grab it if it doesn't" "TEXT"
  BASE_ISO_INPUT_FILE=$( basename "$ISO_INPUT_FILE" )
  if [ "$FULL_FORCE_MODE" = "true" ]; then
    handle_output "rm $WORK_DIR/files/$BASE_ISO_INPUT_FILE" ""
    if [ "$TEST_MODE" = "false" ]; then
      rm "$WORK_DIR/files/$BASE_ISO_INPUT_FILE"
    fi
  fi
  check_base_iso_file
  if [ "$DO_CHECK_ISO" = "true" ]; then
    cd "$WORK_DIR/files" || exit ; wget -N "$ISO_URL"
  else
    if ! [ -f "$WORK_DIR/files/$BASE_ISO_INPUT_FILE" ]; then
      if [ "$TEST_MODE" = "false" ]; then
        wget "$ISO_URL" -O "$WORK_DIR/files/$BASE_ISO_INPUT_FILE"
      fi
    fi
  fi
}

# Function: get_old_base_iso
#
# Get old base ISO

get_old_base_iso () {
  handle_output "# Check old source ISO exists and grab it if it doesn't" "TEXT"
  OLD_BASE_ISO_INPUT_FILE=$( basename "$OLD_ISO_INPUT_FILE" )
  if [ "$FULL_FORCE_MODE" = "true" ]; then
    handle_output "rm $WORK_DIR/files/$OLD_BASE_ISO_INPUT_FILE" ""
    if [ "$TEST_MODE" = "false" ]; then
      rm "$OLD_WORK_DIR/files/$OLD_BASE_ISO_INPUT_FILE"
    fi
  fi
  check_old_base_iso_file
  if [ "$DO_CHECK_ISO" = "true" ]; then
    cd "$OLD_WORK_DIR/files" || exit ; wget -N "$OLD_ISO_URL"
  else
    if ! [ -f "$OLD_WORK_DIR/files/$OLD_BASE_ISO_INPUT_FILE" ]; then
      if [ "$TEST_MODE" = "false" ]; then
        wget "$OLD_ISO_URL" -O "$OLD_WORK_DIR/files/$OLD_BASE_ISO_INPUT_FILE"
      fi
    fi
  fi
}

# Function: get_iso_type
#
# Get ISO type

get_iso_type () {
  if [[ "$ISO_INPUT_FILE" =~ "dvd" ]]; then
    ISO_TYPE="dvd"
  fi
}

# Function: prepare_iso
#
# Prepare ISO

prepare_iso () {
  case "$ISO_OS_NAME" in
    "ubuntu")
      if [[ "$ISO_BUILD_TYPE" =~ "desktop" ]]; then
        prepare_autoinstall_desktop_iso
      else
        prepare_autoinstall_server_iso
      fi
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
  handle_output "# Analysing $ISO_INPUT_FILE" "TEXT"
  TEST_FILE=$( basename "$ISO_INPUT_FILE" )
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
    "oracular")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2410"
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
  ISO_OUTPUT_FILE="$WORK_DIR/files/$TEST_NAME-$ISO_RELEASE-$TEST_TYPE-$ISO_ARCH.iso"
  handle_output "# Input ISO:     $ISO_INPUT_FILE" "TEXT"
  handle_output "# Distribution:  $ISO_DISTRO"     "TEXT"
  handle_output "# Release:       $ISO_RELEASE"    "TEXT"
  handle_output "# Codename:      $ISO_CODENAME"   "TEXT"
  handle_output "# Architecture:  $ISO_ARCH"       "TEXT"
  handle_output "# Output ISO:    $ISO_OUTPUT_FILE"    "TEXT"
}

# Function: create_autoinstall_iso
#
# get ISO formatting information
#
# xorriso -indev ubuntu-22.04.1-live-server-amd64.iso -report_el_torito as_mkisofs
# xorriso 1.5.4 : RockRidge filesystem manipulator, libburnia project.
#
# xorriso : NOTE : Loading ISO image tree from LBA 0
# xorriso : UPDATE :     803 nodes read in 1 seconds
# libisofs: NOTE : Found hidden El-Torito image for EFI.
# libisofs: NOTE : EFI image start and size: 717863 * 2048 , 8496 * 512
# xorriso : NOTE : Detected El-Torito boot information which currently is set to be discarded
# Drive current: -indev 'ubuntu-22.04.1-live-server-amd64.iso'
# Media current: stdio file, overwriteable
# Media status : is written , is appendable
# Boot record  : El Torito , MBR protective-msdos-label grub2-mbr cyl-align-off GPT
# Media summary: 1 session, 720153 data blocks, 1407m data,  401g free
# Volume id    : 'Ubuntu-Server 22.04.1 LTS amd64'
# -V 'Ubuntu-Server 22.04.1 LTS amd64'
# --modification-date='2022080916483300'
# --grub2-mbr --interval:local_fs:0s-15s:zero_mbrpt,zero_gpt:'ubuntu-22.04.1-live-server-amd64.iso'
# --protective-msdos-label
# -partition_cyl_align off
# -partition_offset 16
# --mbr-force-bootable
# -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b --interval:local_fs:2871452d-2879947d::'ubuntu-22.04.1-live-server-amd64.iso'
# -appended_part_as_gpt
# -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7
# -c '/boot.catalog'
# -b '/boot/grub/i386-pc/eltorito.img'
# -no-emul-boot
# -boot-load-size 4
# -boot-info-table
# --grub2-boot-info
# -eltorito-alt-boot
# -e '--interval:appended_partition_2_start_717863s_size_8496d:all::'
# -no-emul-boot
# -boot-load-size 8496
#
# export APPEND_PARTITION=$(xorriso -indev ubuntu-22.04.1-live-server-amd64.iso -report_el_torito as_mkisofs |grep append_partition |tail -1 |awk '{print $3}' 2>&1)
# export ISO_MBR_PART_TYPE=$(xorriso -indev ubuntu-22.04.1-live-server-amd64.iso -report_el_torito as_mkisofs |grep iso_mbr_part_type |tail -1 |awk '{print $2}' 2>&1)
# xorriso -as mkisofs -r -V 'Ubuntu-Server 22.04.1 LTS arm64' -o ../ubuntu-22.04-autoinstall-arm64.iso --grub2-mbr \
# ../BOOT/Boot-NoEmul.img -partition_offset 16 --mbr-force-bootable -append_partition 2 $APPEND_PARTITION ../BOOT/Boot-NoEmul.img \
# -appended_part_as_gpt -iso_mbr_part_type $ISO_MBR_PART_TYPE -c '/boot/boot.cat' -e '--interval:appended_partition_2:::' -no-emul-boot

create_autoinstall_iso () {
  if [ ! -f "/usr/bin/xorriso" ]; then
    install_required_packages "$REQUIRED_PACKAGES"
  fi
  check_file_perms "$ISO_OUTPUT_FILE"
  handle_output "# Creating ISO" "TEXT"
  ISO_MBR_PART_TYPE=$( xorriso -indev "$ISO_INPUT_FILE" -report_el_torito as_mkisofs |grep iso_mbr_part_type |tail -1 |awk '{print $2}' 2>&1 )
  BOOT_CATALOG=$( xorriso -indev "$ISO_INPUT_FILE" -report_el_torito as_mkisofs |grep "^-c " |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  BOOT_IMAGE=$( xorriso -indev "$ISO_INPUT_FILE" -report_el_torito as_mkisofs |grep "^-b " |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  UEFI_BOOT_SIZE=$( xorriso -indev "$ISO_INPUT_FILE" -report_el_torito as_mkisofs |grep "^-boot-load-size" |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  DOS_BOOT_SIZE=$( xorriso -indev "$ISO_INPUT_FILE" -report_el_torito as_mkisofs |grep "^-boot-load-size" |head -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  if [ "$ISO_MAJOR_RELEASE" -gt 22 ]; then
    APPEND_PART=$( xorriso -indev "$ISO_INPUT_FILE" -report_el_torito as_mkisofs |grep append_partition |tail -1 |awk '{print $3}' 2>&1 )
    UEFI_IMAGE="--interval:appended_partition_2:::"
  else
    APPEND_PART="0xef"
    UEFI_IMAGE=$( xorriso -indev "$ISO_INPUT_FILE" -report_el_torito as_mkisofs |grep "^-e " |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  fi
  if [ "$TEST_MODE" = "false" ]; then
    if [ "$ISO_ARCH" = "amd64" ]; then
      verbose_message "# Executing:"
      verbose_message "xorriso -as mkisofs -r -V \"$ISO_VOLID\" -o \"$ISO_OUTPUT_FILE\" \\"
      verbose_message "--grub2-mbr \"$WORK_DIR/BOOT/1-Boot-NoEmul.img\" --protective-msdos-label -partition_cyl_align off \\"
      verbose_message "-partition_offset 16 --mbr-force-bootable -append_partition 2 \"$APPEND_PART\" \"$WORK_DIR/BOOT/2-Boot-NoEmul.img\" \\"
      verbose_message "-appended_part_as_gpt -iso_mbr_part_type \"$ISO_MBR_PART_TYPE\" -c \"$BOOT_CATALOG\" -b \"$BOOT_IMAGE\" \\"
      verbose_message "-no-emul-boot -boot-load-size \"$DOS_BOOT_SIZE\" -boot-info-table --grub2-boot-info -eltorito-alt-boot \\"
      verbose_message "-e \"$UEFI_IMAGE\" -no-emul-boot -boot-load-size \"$UEFI_BOOT_SIZE\" \"$ISO_SOURCE_DIR\""
      xorriso -as mkisofs -r -V "$ISO_VOLID" -o "$ISO_OUTPUT_FILE" \
      --grub2-mbr "$WORK_DIR/BOOT/1-Boot-NoEmul.img" --protective-msdos-label -partition_cyl_align off \
      -partition_offset 16 --mbr-force-bootable -append_partition 2 "$APPEND_PART" "$WORK_DIR/BOOT/2-Boot-NoEmul.img" \
      -appended_part_as_gpt -iso_mbr_part_type "$ISO_MBR_PART_TYPE" -c "$BOOT_CATALOG" -b "$BOOT_IMAGE" \
      -no-emul-boot -boot-load-size "$DOS_BOOT_SIZE" -boot-info-table --grub2-boot-info -eltorito-alt-boot \
      -e "$UEFI_IMAGE" -no-emul-boot -boot-load-size "$UEFI_BOOT_SIZE" "$ISO_SOURCE_DIR"
    else
      verbose_message "# Executing:"
      verbose_message "xorriso -as mkisofs -r -V \"$ISO_VOLID\" -o \"$ISO_OUTPUT_FILE\" \\"
      verbose_message "-partition_cyl_align all -partition_offset 16 -partition_hd_cyl 86 -partition_sec_hd 32 \\"
      verbose_message "-append_partition 2 \"$APPEND_PART\" \"$WORK_DIR/BOOT/Boot-NoEmul.img\" -G \"$WORK_DIR/BOOT/Boot-NoEmul.img\" \\"
      verbose_message "-iso_mbr_part_type \"$ISO_MBR_PART_TYPE\" -c \"$BOOT_CATALOG\" \\"
      verbose_message "-e \"$UEFI_IMAGE\" -no-emul-boot -boot-load-size \"$UEFI_BOOT_SIZE\" \"$ISO_SOURCE_DIR\""
      xorriso -as mkisofs -r -V "$ISO_VOLID" -o "$ISO_OUTPUT_FILE" \
      -partition_cyl_align all -partition_offset 16 -partition_hd_cyl 86 -partition_sec_hd 32 \
      -append_partition 2 "$APPEND_PART" "$WORK_DIR/BOOT/Boot-NoEmul.img" -G "$WORK_DIR/BOOT/Boot-NoEmul.img" \
      -iso_mbr_part_type "$ISO_MBR_PART_TYPE" -c "$BOOT_CATALOG" \
      -e "$UEFI_IMAGE" -no-emul-boot -boot-load-size "$UEFI_BOOT_SIZE" "$ISO_SOURCE_DIR"
    fi
    if [ "$DO_DOCKER" = "true" ]; then
      BASE_DOCKER_ISO_OUTPUT_FILE=$( basename "$ISO_OUTPUT_FILE" )
      echo "# Output file will be at \"$PRE_WORK_DIR/files/$BASE_DOCKER_ISO_OUTPUT_FILE\""
    fi
  fi
  check_file_perms "$ISO_OUTPUT_FILE"
}
