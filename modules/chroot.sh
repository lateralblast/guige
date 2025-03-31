#!/usr/bin/env bash

# shellcheck disable=SC2129

# Function: execute_chroot_script
#
# Execute chroot script

execute_chroot_script () {
  case "$ISO_CODENAME" in
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
  if [ "$DO_CHROOT" = "true" ]; then
    handle_output "# Executing chroot script" "TEXT"
    handle_output "chroot $ISO_NEW_DIR/custom /tmp/modify_chroot.sh" "TEXT"
    if [ "$TEST_MODE" = "false" ]; then
      sudo chroot "$ISO_NEW_DIR/custom" "/tmp/modify_chroot.sh"
    fi
  fi
}

# Function: create_chroot_script
#
# Create chroot script

create_chroot_script () {
  if [ "$DO_CHROOT" = "true" ]; then
    case "$ISO_CODENAME" in
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
  ORIG_SCRIPT="$ISO_WORKDIR/files/modify_chroot.sh"
  ISO_CHROOT_SCRIPT="$ISO_NEW_DIR/custom/tmp/modify_chroot.sh"
  check_file_perms "$ORIG_SCRIPT"
  handle_output "# Creating chroot script $ISO_CHROOT_SCRIPT" "TEXT"
  if [ "$TEST_MODE" = "false" ]; then
    echo "#!/usr/bin/bash" > "$ORIG_SCRIPT"
    echo "mount -t proc none /proc/" >> "$ORIG_SCRIPT"
    echo "mount -t sysfs none /sys/" >> "$ORIG_SCRIPT"
    echo "mount -t devpts none /dev/pts" >> "$ORIG_SCRIPT"
    echo "export HOME=/root" >> "$ORIG_SCRIPT"
    echo "export DEBIAN_FRONTEND=noninteractive" >> "$ORIG_SCRIPT"
    if [ ! "$ISO_COUNTRY" = "us" ]; then
      echo "sed -i \"s/\\/archive/\\/$ISO_COUNTRY.archive/g\" /etc/apt/sources.list" >> "$ORIG_SCRIPT"
    fi
    echo "if [ -d \"/var/cache/apt/archives\" ]; then" >> "$ORIG_SCRIPT"
    echo "  rm -rf /var/cache/apt/archives" >> "$ORIG_SCRIPT"
    echo "  mkdir -p /var/cache/apt/archives" >> "$ORIG_SCRIPT"
    echo "fi" >> "$ORIG_SCRIPT"
    echo "if [ -f \"/etc/apt/apt.conf.d/20apt-esm-hook.conf\" ]; then" >> "$ORIG_SCRIPT"
    echo "  rm /etc/apt/apt.conf.d/20apt-esm-hook.conf" >> "$ORIG_SCRIPT"
    echo "fi" >> "$ORIG_SCRIPT"
    echo "if [ -f \"/etc/update-motd.d/91-contract-ua-esm-status\" ]; then" >> "$ORIG_SCRIPT"
    echo "  rm /etc/update-motd.d/91-contract-ua-esm-status" >> "$ORIG_SCRIPT"
    echo "fi" >> "$ORIG_SCRIPT"
    echo "apt update" >> "$ORIG_SCRIPT"
    echo "export LC_ALL=C ; apt install -y --download-only $ISO_CHROOTPACKAGES" >> "$ORIG_SCRIPT"
    echo "export LC_ALL=C ; apt install -y $ISO_CHROOTPACKAGES --option=Dpkg::Options::=$ISO_DPKG_CONF" >> "$ORIG_SCRIPT"
    echo "umount /proc/" >> "$ORIG_SCRIPT"
    echo "umount /sys/" >> "$ORIG_SCRIPT"
    echo "umount /dev/pts/" >> "$ORIG_SCRIPT"
    echo "exit" >> "$ORIG_SCRIPT"
    if [ -f "/.dockerenv" ]; then
      if [ ! -d "$ISO_NEW_DIR/custom/tmp" ]; then
        sudo_create_dir "$ISO_NEW_DIR/custom/tmp"
      fi
    else
      if ! [[ "$ISO_OPTIONS" =~ "docker" ]]; then
        if [ ! -d "$ISO_NEW_DIR/custom/tmp" ]; then
          sudo_create_dir "$ISO_NEW_DIR/custom/tmp"
        fi
      fi
    fi
    sudo cp "$ORIG_SCRIPT" "$ISO_CHROOT_SCRIPT"
    sudo chmod +x "$ISO_CHROOT_SCRIPT"
    print_file "$ORIG_SCRIPT"
  fi
}
