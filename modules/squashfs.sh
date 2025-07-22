#!/usr/bin/env bash

# shellcheck disable=SC2046
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: unmount_squashfs
#
# Unmount squashfs filesystem

unmount_squashfs () {
  case "${iso['osname']}" in
    "ubuntu")
      unmount_ubuntu_squashfs
      ;;
  esac
}


# Function: unmount_ubuntu_squashfs
#
# Unmount ubuntu squashfs filesystem

unmount_ubuntu_squashfs () {
  if [ "${options['updatesquashfs']}" = "true" ]; then
    handle_output "# Unmounting squashfs ${iso['newdir']}/squashfs" "TEXT"
    if [ "${options['testmode']}" = "false" ]; then
      mount_test=$( mount | grep -c "${iso['newdir']}/squashfs" )
      if [ ! "${mount_test}" = "0" ]; then
        sudo umount "${iso['newdir']}/squashfs"
      fi
    fi
  fi
}

# Function: copy_squashfs
#
# Copy ISO squashfs

copy_squashfs () {
  case "${iso['osname']}" in
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
    install_required_packages
  fi
  if [ "${options['updatesquashfs']}" = "true" ] || [ "${options['unpacksquashfs']}" = "true" ]; then
    if [ ! -f "${iso['squashfsfile']}" ]; then
      warning_message "Squash file system file \"${iso['squashfsfile']}\" does not exist"
      exit
    fi
    handle_output "# Copying squashfs files" "TEXT"
    current['kernel']=$( uname -r )
    if [ -f "${current['kernel']}" ]; then
      if [ "${options['testmode']}" = "false" ]; then
        sudo mount -t squashfs -o loop "${iso['squashfsfile']}" "${iso['newdir']}/squashfs"
      fi
      if [ "${options['verbose']}" = "true" ]; then
        if [ "${options['testmode']}" = "false" ]; then
          sudo rsync -av "${iso['newdir']}/squashfs/" "${iso['newdir']}/custom"
        fi
      else
        if [ "${options['testmode']}" = "false" ]; then
          sudo rsync -a "${iso['newdir']}/squashfs/" "${iso['newdir']}/custom"
        fi
      fi
    else
      if [ "${options['testmode']}" = "false" ]; then
        sudo unsquashfs -f -d "${iso['newdir']}/custom" "${iso['squashfsfile']}"
      fi
    fi
    if [ "${options['testmode']}" = "false" ]; then
      sudo cp /etc/resolv.conf /etc/hosts "${iso['newdir']}/custom/etc"
    fi
  fi
}

# Function: update_iso_squashfs
#
# Update ISO squashfs

update_iso_squashfs () {
  case "${iso['osname']}" in
    "ubuntu")
      update_ubuntu_iso_squashfs
      ;;
  esac
}

# Function: update_ubuntu_iso_squashfs
#
# Update Ubuntu ISO squashfs

update_ubuntu_iso_squashfs () {
  if [ "${options['updatesquashfs']}" = "true" ]; then
    handle_output "# Making squashfs (this will take a while)" "TEXT"
    if [ "${options['testmode']}" = "false" ]; then
      sudo mksquashfs "${iso['newdir']}/custom" "${iso['newdir']}/mksquash/filesystem.squashfs" -noappend
      sudo cp "${iso['newdir']}/mksquash/filesystem.squashfs" "${iso['newsquashfsfile']}"
      sudo chmod 0444 i"${iso['newsquashfsfile']}"
      sudo echo -n $( sudo du -s --block-size=1 "${iso['newdir']}/custom" | tail -1 | awk '{print $1}') | sudo tee "${iso['newdir']}/mksquash/filesystem.size"
      sudo cp "${iso['newdir']}/mksquash/filesystem.size" "${iso['sourcedir']}/casper/filesystem.size"
      sudo chmod 0444 "${iso['sourcedir']}/casper/filesystem.size"
      sudo find "${iso['sourcedir']}" -type f -print0 | xargs -0 md5sum | sed "s@${iso['newdir']}}@.@" | grep -v md5sum.txt | sudo tee "${iso['sourcedir']}/md5sum.txt"
    fi
  fi
}
