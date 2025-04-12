#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: execute_chroot_script
#
# Execute chroot script

execute_chroot_script () {
  case "${iso['osname']}" in
    "ubuntu")
      execute_ubuntu_chroot_script
      ;;
  esac
}

# Function: execute_ubuntu_chroot_script
#
#  Chroot into environment and run script on chrooted environmnet
#
# Examples:
# sudo chroot ./isonew/custom

execute_ubuntu_chroot_script () {
  if [ "${options['chroot']}" = "true" ]; then
    handle_output "# Executing chroot script" "TEXT"
    handle_output "chroot ${iso['newdir']}/custom /tmp/modify_chroot.sh" "TEXT"
    if [ "${options['testmode']}" = "false" ]; then
      execute_command "sudo mount --bind /dev ${iso['newdir']}/custom/dev"
      execute_command "sudo mount --bind /dev/pts ${iso['newdir']}/custom/dev/pts"
      execute_command "sudo mount --bind /proc ${iso['newdir']}/custom/proc"
      execute_command "sudo mount --bind /sys ${iso['newdir']}/custom/sys"
      sudo chroot "${iso['newdir']}/custom" "/tmp/modify_chroot.sh"
      execute_command "sudo umount ${iso['newdir']}/custom/dev/pts"
      execute_command "sudo umount ${iso['newdir']}/custom/dev"
      execute_command "sudo umount ${iso['newdir']}/custom/proc"
      execute_command "sudo umount ${iso['newdir']}/custom/sys"
    fi
  fi
}

# Function: create_chroot_script
#
# Create chroot script

create_chroot_script () {
  if [ "${options['chroot']}" = "true" ]; then
    case "${iso['osname']}" in
      "ubuntu")
        create_ubuntu_chroot_script
        ;;
    esac
  fi
}

# Function: create_ubuntu_chroot_script
#
# Create script to drop into chrooted environment for Ubuntu
# Inside chrooted environment, mount filesystems and packages
#
# Examples:
# mount -t proc none /proc/
# mount -t sysfs none /sys/
# mount -t devpts none /dev/pts
# export HOME=/root
# sudo apt update
# sudo apt install -y --download-only zfsutils-linux grub-efi zfs-initramfs net-tools curl wget lftp
# sudo apt install -y zfsutils-linux grub-efi zfs-initramfs net-tools curl wget lftp
# umount /proc/
# umount /sys/
# umount /dev/pts/
# exit

create_ubuntu_chroot_script () {
  orig_script="${iso['workdir']}/files/modify_chroot.sh"
  chroot_script="${iso['newdir']}/custom/tmp/modify_chroot.sh"
  check_file_perms "${orig_chroot}"
  handle_output "# Creating chroot script ${chroot_script}" "TEXT"
  if [ "${options['testmode']}" = "false" ]; then
    echo "#!/usr/bin/bash" > "${orig_script}"
    echo "export HOME=/root" >> "${orig_script}"
    echo "export DEBIAN_FRONTEND=noninteractive" >> "${orig_script}"
    if [ ! "${iso['country']}" = "us" ]; then
      echo "sed -i \"s/\\/archive/\\/${iso['country']}.archive/g\" /etc/apt/sources.list" >> "${orig_script}"
    fi
    echo "if [ -d \"/var/cache/apt/archives\" ]; then" >> "${orig_script}"
    echo "  rm -rf /var/cache/apt/archives" >> "${orig_script}"
    echo "  mkdir -p /var/cache/apt/archives" >> "${orig_script}"
    echo "fi" >> "${orig_script}"
    echo "if [ -f \"/etc/apt/apt.conf.d/20apt-esm-hook.conf\" ]; then" >> "${orig_script}"
    echo "  rm /etc/apt/apt.conf.d/20apt-esm-hook.conf" >> "${orig_script}"
    echo "fi" >> "${orig_script}"
    echo "if [ -f \"/etc/update-motd.d/91-contract-ua-esm-status\" ]; then" >> "${orig_script}"
    echo "  rm /etc/update-motd.d/91-contract-ua-esm-status" >> "${orig_script}"
    echo "fi" >> "${orig_script}"
    echo "apt update" >> "${orig_script}"
    echo "export LC_ALL=C ; apt install -y --download-only ${iso['chrootpackages']}" >> "${orig_script}"
    echo "export LC_ALL=C ; apt install -y ${iso['chrootpackages']} --option=Dpkg::Options::=${iso['dpkgconf']}" >> "${orig_script}"
    echo "exit" >> "${orig_script}"
    if [ -f "/.dockerenv" ]; then
      if [ ! -d "${iso['newdir']}/custom/tmp" ]; then
        sudo_create_dir "${iso['newdir']}/custom/tmp"
      fi
    else
      if ! [[ "${iso['options']}" =~ "docker" ]]; then
        if [ ! -d "${iso['newdir']}/custom/tmp" ]; then
          sudo_create_dir "${iso['newdir']}/custom/tmp"
        fi
      fi
    fi
    execute_command "cp ${orig_script} ${chroot_script}"
    execute_command "sudo chmod +x ${chroot_script}"
    print_file "${orig_script}"
  fi
}
