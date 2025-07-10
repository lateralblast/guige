#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2153
# shellcheck disable=SC2154

# Function: update_iso_build
#
# Update ISO build

update_iso_build () {
  if [[ "${iso['build']}" =~ server ]]; then
    if [[ "${iso['build']}" =~ daily ]]; then
      iso['build']="daily/server"
    else
      iso['build']="live/server"
    fi
  else
    if [[ "${iso['build']}" =~ desktop ]]; then
      if [[ "${iso['build']}" =~ daily ]]; then
        iso['build']="daily/desktop"
      else
        iso['build']="live/desktop"
      fi
    else
      iso['build']="live/server"
    fi
  fi
}

# Funtion update_iso_url
#
# Update ISO URL

update_iso_url () {
  iso['inputfilebase']=$( basename "${iso['inputfile']}" )
  if [ "${iso['osname']}" = "ubuntu" ]; then
    case "${iso['build']}" in
      daily-live|daily-live-server|daily-server|daily/server)
        if [ "${iso['release']}" = "${current['devrelease']}" ] || [ "${iso['osname']}" = "${current['codename']}" ]; then
          iso['url']="https://cdimage.ubuntu.com/ubuntu-server/daily-live/current/${iso['osname']}-live-server-${iso['arch']}.iso"
        else
          iso['url']="https://cdimage.ubuntu.com/ubuntu-server/${iso['codename']}/daily-live/current/${iso['inputfilebase']}"
        fi
        iso['inputfile']="${iso['workdir']}/files/${iso['codename']}-live-server-${iso['arch']}.iso"
        ;;
      daily-desktop|daily/desktop)
        if [ "${iso['release']}" = "${current['devrelease']}" ] || [ "${iso['codename']}" = "${current['codename']}" ]; then
          iso['url']="https://cdimage.ubuntu.com/daily-live/current/${iso['inputfilebase']}"
        else
          iso['url']="https://cdimage.ubuntu.com/${iso['codename']}/daily-live/current/${iso['inputfilebase']}"
        fi
        iso['inputfile']="${iso['workdir']}/files/${iso['codename']}-desktop-${iso['arch']}.iso"
        ;;
      desktop|server|live-server|live/server)
        if [ "${iso['release']}" = "${current['betarelease']}" ]; then
          iso['url']="https://releases.ubuntu.com/${iso['codename']}/${iso['inputfilebase']}"
          iso['inputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-beta-desktop-${iso['arch']}.iso"
        else
          if [ "${iso['release']}" = "${current['devrelease']}" ]; then
            if [[ "${iso['build']}" =~ server ]]; then
              iso['url']="https://cdimage.ubuntu.com/ubuntu-server/daily-live/current/${iso['codename']}-live-server-${iso['arch']}.iso"
              iso['inputfile']="${iso['workdir']}/files/${iso['codename']}-live-server-${iso['arch']}.iso"
            else
              iso['url']="https://cdimage.ubuntu.com/daily-live/current/${iso['codename']}-desktop-${iso['arch']}.iso"
              iso['inputfile']="${iso['workdir']}/files/${iso['codename']}-desktop-${iso['arch']}.iso"
            fi
          else
            if [[ "${iso['arch']}" =~ arm ]]; then
              iso['url']="https://cdimage.ubuntu.com/daily-live/current/${iso['majorrelease']}.${iso['minorrelease']}/release/${iso['inputfilebase']}"
            else
              iso['url']="https://releases.ubuntu.com/${iso['release']}/${iso['inputfilebase']}"
            fi
          fi
        fi
        ;;
      *)
        if [ "${iso['release']}" = "${current['devrelease']}" ]; then
          if [[ "${iso['build']}" =~ server ]]; then
            iso['url']="https://cdimage.ubuntu.com/ubuntu-server/daily-live/current/${iso['codename']}-live-server-${iso['arch']}.iso"
            iso['inputfile']="${iso['workdir']}/files/${iso['codename']}-live-server-${iso['arch']}.iso"
          else
            iso['url']="https://cdimage.ubuntu.com/daily-live/current/${iso['codename']}-desktop-${iso['arch']}.iso"
            iso['inputfile']="${iso['workdir']}/files/${iso['codename']}-desktop-${iso['arch']}.iso"
          fi
        else
          iso['url']="https://cdimage.ubuntu.com/releases/${iso['release']}/release/${iso['inputfilebase']}"
        fi
        ;;
    esac
    if [ "${old['url']}" = "" ]; then
      old['url']="${defaults['oldworkdir']}"
    fi
  else
    if [ "${iso['osname']}" = "rocky" ]; then
      if [ "${iso['url']}" = "" ]; then
        iso['url']="https://download.rockylinux.org/pub/rocky/${iso['majorrelease']}/isos/${iso['arch']}/${iso['inputfilebase']}"
      fi
    fi
  fi
}

# Function: update_iso['requiredpackages']}
#
# Update required packages

update_required_packages () {
  if [ "${os['name']}" = "Darwin" ]; then
    if ! [[ "${iso['action']}" =~ "docker" ]]; then
      iso['requiredpackages']="p7zip lftp wget xorriso ansible squashfs"
    fi
  fi
}

# Function: update_iso['packages']}
#
# Update packages to include in ISO

update_iso_packages () {
  if [ "${iso['osname']}" = "ubuntu" ]; then
    if [ "${options['hwekernel']}" = "true" ]; then
      iso['packages']="${iso['packages']} linux-image-generic-hwe-${iso['majorrelease']}.${iso['minorrelease']}"
    fi
  fi
}

# Function: create_iso
#
# Prepare ISO

create_iso () {
  if [ "${options['createiso']}" = "true" ]; then
    case "${iso['osname']}" in
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
  handle_output "# Copying ISO files from ${iso['mountdir']} to ${iso['newdir']}/cd" "TEXT"
  if [ ! -f "/usr/bin/rsync" ]; then
    install_required_packages
  fi
  uc_test_dir="${iso['mountdir']}/EFI"
  lc_test_dir="${iso['mountdir']}/efi"
  if [ ! -d "${uc_test_dir}" ] && [ ! -d "${lc_test_dir}" ]; then
    warning_message "ISO ${iso['inputfile']} not mounted"
    exit
  else
    if [ "${options['verbose']}" = "true" ]; then
      if [ "${options['testmode']}" = "false" ]; then
        execute_command "sudo rsync -av --delete ${iso['mountdir']}/ ${iso['newdir']}/cd"
      fi
    else
      if [ "${options['testmode']}" = "false" ]; then
        execute_command "sudo rsync -a --delete ${iso['mountdir']}/ ${iso['newdir']}/cd"
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
  handle_output "sudo umount -l ${iso['mountdir']}" ""
  if [ "${options['testmode']}" = "false" ]; then
    mount_test=$( mount | grep -c "${iso['mountdir']}" )
    if [ ! "${mount_test}" = "0" ]; then
      sudo umount -l "${iso['mountdir']}"
    fi
  fi
}

# Function: unmounat_old
#
# unmount loopback older release ISO filesystem
#
# Examples:
# sudo umount -l /home/user/ubuntu-old-iso/isomount

unmount_old () {
  if [ "${options['testmode']}" = "false" ]; then
    mount_test=$( mount | grep -c "${old['mountdir']}" )
    if [ ! "${mount_test}" = "0" ]; then
      handle_output "sudo umount -l ${old['mountdir']}" ""
      sudo umount -l "${old['mountdir']}"
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
  handle_output "# Mounting ISO ${iso['workdir']}/files/${iso['inputfilebase']} at ${iso['mountdir']}" "TEXT"
  handle_output "sudo mount -o loop \"${iso['workdir']}/files/${iso['inputfilebase']}\" \"${iso['mountdir']}\" 2> /dev/null" ""
  if [ "${options['testmode']}" = "false" ]; then
    sudo mount -o loop "${iso['workdir']}/files/${iso['inputfilebase']}" "${iso['mountdir']}" 2> /dev/null
  fi
}

# Function: unmount_old
#
# Mount older revision base ISO as loopback device so contents can be copied
#
# sudo mount -o loop ./ubuntu-22.04.1-live-server-arm64.iso ./isomount 2> /dev/null

mount_old () {
  get_old_base_iso
  check_old_base_iso_file
  handle_output "# Mounting ISO ${old['workdir']}/files/${old['inputfilebase']} at ${old['mountdir']}" "TEXT"
  handle_output "sudo mount -o loop \"${old['workdir']}/files/${old['inputfilebase']}\" \"${old['mountdir']}\" 2> /dev/null" ""
  if [ "${options['testmode']}" = "false" ]; then
    sudo mount -o loop "${old['workdir']}/files/${old['inputfilebase']}" "${old['mountdir']}" 2> /dev/null
  fi
}

# Function: list_isos
#
# List ISOs

list_isos () {
  temp['verbose']="true"
  if [ "${iso['search']}" = "" ]; then
    file_list=$(find "${iso['workdir']}" -name "*.iso" 2> /dev/null)
  else
    file_list=$(find "${iso['workdir']}" -name "*.iso" 2> /dev/null |grep "${iso['search']}" )
  fi
  for file_name in ${file_list}; do
    if [ "${options['scpheader']}" = "true" ]; then
      handle_output "${iso['bmcusername']}@${os['ip']}:${file_name}" "TEXT"
    else
      handle_output "${file_name}" "TEXT"
    fi
  done
  temp['verbose']="false"
}

# Function: check_base_iso_file
#
# Check base ISO file exists

check_base_iso_file () {
  if [ -f "${iso['inputfile']}" ]; then
    iso['inputfilebase']=$( basename "${iso['inputfile']}" )
    check_file="${iso['workdir']}/files/${iso['inputfilebase']}"
    if [ -f "${check_file}" ]; then
      file_type=$( file "${check_file}" |cut -f2 -d: |grep -cE "MBR|ISO" )
      if [ "${file_type}" = "0" ]; then
        warning_message "${check_file} is not a valid ISO file"
        exit
      fi
    fi
  fi
}

# Function: check_old_base_iso_file
#
# Check previous release base ISO file exists
# Used when copying files from an old release to a new release

check_old_base_iso_file () {
  if [ -f "${old['inputfile']}" ]; then
    old['inputfilebase']=$( basename "${old['inputfile']}" )
    file_type=$( file "${old['workdir']}/files/${old['inputfilebase']}" |cut -f2 -d: |grep -E "MBR|ISO")
    if [ -z "${file_type}" ]; then
      warning_message "${old['workdir']}/files/${old['inputfilebase']} is not a valid ISO file"
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
  iso['inputfilebase']=$( basename "${iso['inputfile']}" )
  if [ "${options['forceall']}" = "true" ]; then
    handle_output "rm ${iso['workdir']}/files/${iso['inputfilebase']}" ""
    if [ "${options['testmode']}" = "false" ]; then
      rm "${iso['workdir']}/files/${iso['inputfilebase']}"
    fi
  fi
  check_base_iso_file
  if [ "${options['latest']}" = "true" ]; then
    cd "${iso['workdir']}/files" || exit ; wget -N "${iso['url']}"
  else
    if ! [ -f "${iso['workdir']}/files/${iso['inputfilebase']}" ]; then
      if [ "${options['testmode']}" = "false" ]; then
        wget "${iso['url']}" -O "${iso['workdir']}/files/${iso['inputfilebase']}"
      fi
    fi
  fi
}

# Function: get_old_base_iso
#
# Get old base ISO

get_old_base_iso () {
  handle_output "# Check old source ISO exists and grab it if it doesn't" "TEXT"
  old['inputfilebase']=$( basename "${old['inputfile']}" )
  if [ "${options['forceall']}" = "true" ]; then
    handle_output "rm ${iso['workdir']}/files/${old['inputfilebase']}" ""
    if [ "${options['testmode']}" = "false" ]; then
      rm "${old['workdir']}/files/${old['inputfilebase']}"
    fi
  fi
  check_old_base_iso_file
  if [ "${options['latest']}" = "true" ]; then
    cd "${old['workdir']}/files" || exit ; wget -N "${old['url']}"
  else
    if ! [ -f "${old['workdir']}/files/${old['inputfilebase']}" ]; then
      if [ "${options['testmode']}" = "false" ]; then
        wget "${old['url']}" -O "${old['workdir']}/files/${old['inputfilebase']}"
      fi
    fi
  fi
}

# Function: get_iso_type
#
# Get ISO type

get_iso_type () {
  if [[ "${iso['inputfile']}" =~ "dvd" ]]; then
    iso['type']="dvd"
  fi
}

# Function: prepare_iso
#
# Prepare ISO

prepare_iso () {
  case "${iso['osname']}" in
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
  if [ "${iso['osname']}" = "ubuntu" ]; then
    handle_output "# Analysing ${iso['inputfile']}" "TEXT"
    test_file=$( basename "${iso['inputfile']}" )
    test_name=$( echo "${test_file}" | cut -f1 -d- )
    test_type=$( echo "${test_file}" | cut -f2 -d- )
    case "${test_name}" in
      "bionic")
        iso['release']="${current['release1804']}"
        ;;
      "focal")
        iso['release']="${current['release2004']}"
        ;;
      "jammy")
        iso['release']="${current['release2204']}"
        ;;
      "kinetic")
        iso['release']="${current['release2210']}"
        ;;
      "lunar")
        iso['release']="${current['release2304']}"
        ;;
      "mantic")
        iso['release']="${current['release2310']}"
        ;;
      "noble")
        iso['release']="${current['release2404']}"
        ;;
      "oracular")
        iso['release']="${current['release2410']}"
        ;;
      "plucky")
        iso['release']="${current['release2504']}"
        ;;
      "questing")
        iso['release']="${current['release2510']}"
        ;;
      "ubuntu")
        iso['release']=$(echo "${test_file}" |cut -f2 -d- )
        ;;
      *)
        iso['release']="${defaults['release']}"
        ;;
    esac
    if [ "${test_name}" = "ubuntu" ]; then
      if [ "${test_type}" = "desktop" ]; then
        iso['arch']=$( echo "${test_file}" |cut -f4 -d- |cut -f1 -d. )
      else
        iso['arch']=$( echo "${test_file}" |cut -f5 -d- |cut -f1 -d. )
        test_type="live-server"
      fi
    else
      if [ "${test_type}" = "desktop" ]; then
        iso['arch']=$( echo "${test_file}" |cut -f3 -d- |cut -f1 -d. )
      else
        iso['arch']=$( echo "${test_file}" |cut -f4 -d- |cut -f1 -d. )
        test_type="live-server"
      fi
    fi
    iso['outputfile']="${iso['workdir']}/files/${test_name}-${iso['release']}-${test_type}-${iso['arch']}.iso"
    handle_output "# Input ISO:     ${iso['inputfile']}"  "TEXT"
    handle_output "# Distribution:  ${iso['distro']}"     "TEXT"
    handle_output "# Release:       ${iso['release']}"    "TEXT"
    handle_output "# Codename:      ${iso['codename']}"   "TEXT"
    handle_output "# Architecture:  ${iso['arch']}"       "TEXT"
    handle_output "# Output ISO:    ${iso['outputfile']}" "TEXT"
  fi
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
    install_required_packages
  fi
  check_file_perms "${iso['outputfile']}"
  handle_output "# Creating ISO" "TEXT"
  ISO_MBR_PART_TYPE=$( xorriso -indev "${iso['inputfile']}" -report_el_torito as_mkisofs |grep iso_mbr_part_type |tail -1 |awk '{print $2}' 2>&1 )
  BOOT_CATALOG=$( xorriso -indev "${iso['inputfile']}" -report_el_torito as_mkisofs |grep "^-c " |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  BOOT_IMAGE=$( xorriso -indev "${iso['inputfile']}" -report_el_torito as_mkisofs |grep "^-b " |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  UEFI_BOOT_SIZE=$( xorriso -indev "${iso['inputfile']}" -report_el_torito as_mkisofs |grep "^-boot-load-size" |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  DOS_BOOT_SIZE=$( xorriso -indev "${iso['inputfile']}" -report_el_torito as_mkisofs |grep "^-boot-load-size" |head -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  if [ "${iso['majorrelease']}" -gt 22 ]; then
    APPEND_PART=$( xorriso -indev "${iso['inputfile']}" -report_el_torito as_mkisofs |grep append_partition |tail -1 |awk '{print $3}' 2>&1 )
    UEFI_IMAGE="--interval:appended_partition_2:::"
  else
    APPEND_PART="0xef"
    UEFI_IMAGE=$( xorriso -indev "${iso['inputfile']}" -report_el_torito as_mkisofs |grep "^-e " |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  fi
  if [ "${options['testmode']}" = "false" ]; then
    if [ "${iso['arch']}" = "amd64" ]; then
      verbose_message "# Executing:"
      verbose_message "xorriso -as mkisofs -r -V \"${iso['volid']}\" -o \"${iso['outputfile']}\" \\"
      verbose_message "--grub2-mbr \"${iso['workdir']}/BOOT/1-Boot-NoEmul.img\" --protective-msdos-label -partition_cyl_align off \\"
      verbose_message "-partition_offset 16 --mbr-force-bootable -append_partition 2 \"$APPEND_PART\" \"${iso['workdir']}/BOOT/2-Boot-NoEmul.img\" \\"
      verbose_message "-appended_part_as_gpt -iso_mbr_part_type \"$ISO_MBR_PART_TYPE\" -c \"$BOOT_CATALOG\" -b \"$BOOT_IMAGE\" \\"
      verbose_message "-no-emul-boot -boot-load-size \"$DOS_BOOT_SIZE\" -boot-info-table --grub2-boot-info -eltorito-alt-boot \\"
      verbose_message "-e \"$UEFI_IMAGE\" -no-emul-boot -boot-load-size \"$UEFI_BOOT_SIZE\" \"${iso['sourcedir']}\""
      xorriso -as mkisofs -r -V "${iso['volid']}" -o "${iso['outputfile']}" \
      --grub2-mbr "${iso['workdir']}/BOOT/1-Boot-NoEmul.img" --protective-msdos-label -partition_cyl_align off \
      -partition_offset 16 --mbr-force-bootable -append_partition 2 "$APPEND_PART" "${iso['workdir']}/BOOT/2-Boot-NoEmul.img" \
      -appended_part_as_gpt -iso_mbr_part_type "$ISO_MBR_PART_TYPE" -c "$BOOT_CATALOG" -b "$BOOT_IMAGE" \
      -no-emul-boot -boot-load-size "$DOS_BOOT_SIZE" -boot-info-table --grub2-boot-info -eltorito-alt-boot \
      -e "$UEFI_IMAGE" -no-emul-boot -boot-load-size "$UEFI_BOOT_SIZE" "${iso['sourcedir']}"
    else
      verbose_message "# Executing:"
      verbose_message "xorriso -as mkisofs -r -V \"${iso['volid']}\" -o \"${iso['outputfile']}\" \\"
      verbose_message "-partition_cyl_align all -partition_offset 16 -partition_hd_cyl 86 -partition_sec_hd 32 \\"
      verbose_message "-append_partition 2 \"$APPEND_PART\" \"${iso['workdir']}/BOOT/Boot-NoEmul.img\" -G \"${iso['workdir']}/BOOT/Boot-NoEmul.img\" \\"
      verbose_message "-iso_mbr_part_type \"$ISO_MBR_PART_TYPE\" -c \"$BOOT_CATALOG\" \\"
      verbose_message "-e \"$UEFI_IMAGE\" -no-emul-boot -boot-load-size \"$UEFI_BOOT_SIZE\" \"${iso['sourcedir']}\""
      xorriso -as mkisofs -r -V "${iso['volid']}" -o "${iso['outputfile']}" \
      -partition_cyl_align all -partition_offset 16 -partition_hd_cyl 86 -partition_sec_hd 32 \
      -append_partition 2 "$APPEND_PART" "${iso['workdir']}/BOOT/Boot-NoEmul.img" -G "${iso['workdir']}/BOOT/Boot-NoEmul.img" \
      -iso_mbr_part_type "$ISO_MBR_PART_TYPE" -c "$BOOT_CATALOG" \
      -e "$UEFI_IMAGE" -no-emul-boot -boot-load-size "$UEFI_BOOT_SIZE" "${iso['sourcedir']}"
    fi
    if [ "${options['docker']}" = "true" ]; then
      docker['outputfilebase']=$( basename "${iso['outputfile']}" )
      echo "# Output file will be at \"${iso['preworkdir']}/files/${docker['outputfilebase']}\""
    fi
  fi
  check_file_perms "${iso['outputfile']}"
}
