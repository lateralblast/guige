#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2153
# shellcheck disable=SC2028

# Function: prepare_autoinstall_server_iso
#
# Uncompress ISO and copy autoinstall files into it
#
# 7z -y x ubuntu-22.04.1-live-server-arm64.iso -osource-files
# 7z -y x ubuntu-22.04.1-live-server-amd64.iso -osource-files
# mv source-files/\[BOOT\] ./BOOT
# mkdir -p source-files/autoinstall/configs/sda
# mkdir -p source-files/autoinstall/configs/vda
# mkdir -p source-files/autoinstall/packages
# touch source-files/autoinstall/configs/sda/meta-data
# touch source-files/autoinstall/configs/vda/meta-data
# cp isonew/custom/var/cache/apt/archives/*.deb source-files/autoinstall/packages/
#
# Example grub file creation
#
# cat <<EOF > source-files/boot/grub/grub.cfg
# set timeout=10
# loadfont unicode
# set menu_color_normal=white/black
# set menu_color_highlight=black/light-gray
# menuentry "Autoinstall Ubuntu Server - Physical" {
#     set gfxpayload=keep
#     linux   /casper/vmlinuz quiet autoinstall ds=nocloud\;s=/cdrom/autoinstall/configs/sda/  ---
#     initrd  /casper/initrd
# }
# menuentry "Autoinstall Ubuntu Server - KVM" {
#     set gfxpayload=keep
#     linux   /casper/vmlinuz quiet autoinstall ds=nocloud\;s=/cdrom/autoinstall/configd/vda/  ---
#     initrd  /casper/initrd
# }
# menuentry "Try or Install Ubuntu Server" {
#   set gfxpayload=keep
#   linux /casper/vmlinuz quiet ---
#   initrd  /casper/initrd
# }
# menuentry 'Boot from next volume' {
#   exit 1
# }
# menuentry 'UEFI Firmware Settings' {
#   fwsetup
# }
# EOF
#
# Example user-data file creation
#
# cat <<EOF > source-files/autoinstall/configs/sda/user-data
# #cloud-config
# autoinstall:
#   apt:
#     preferences:
#       - package: "*"
#         pin: "release a=jammy-security"
#         pin-priority: 200
#     disable_components: []
#     geoip: true
#     preserve_sources_list: false
#     primary:
#     - arches:
#       - amd64
#       - i386
#       uri: http://archive.ubuntu.com/ubuntu
#     - arches:
#       - default
#       uri: http://ports.ubuntu.com/ubuntu-ports
#   package_update: false
#   package_upgrade: false
#   drivers:
#     install: false
#   user-data:
#     timezone: Australia/Melbourne
#   identity:
#     hostname: ubuntu
#     password: PASSWORD-CRYPT
#     realname: Ubuntu
#     username: ubuntu
#   kernel:
#     package: linux-generic
#   keyboard:
#     layout: us
#   locale: en_US.UTF-8
#   network:
#     ethernets:
#       ens33:
#         critical: true
#         dhcp-identifier: mac
#         dhcp4: true
#     version: 2
#   ssh:
#     allow-pw: true
#     authorized-keys: []
#     install-server: true
#   storage:
#     config:
#     - ptable: gpt
#       path: /dev/sda
#       wipe: superblock-recursive
#       preserve: false
#       name: ''
#       grub_device: true
#       type: disk
#       id: disk1
#     - device: disk1
#       size: 1127219200
#       wipe: superblock-recursive
#       flag: boot
#       number: 1
#       preserve: false
#       grub_device: true
#       type: partition
#       ptable: gpt
#       id: disk1p1
#     - fstype: fat32
#       volume: disk1p1
#       preserve: false
#       type: format
#       id: disk1p1fs1
#     - path: /boot/efi
#       device: disk1p1fs1
#       type: mount
#       id: mount-2
#     - device: disk1
#       size: -1
#       wipe: superblock-recursive
#       flag: root
#       number: 2
#       preserve: false
#       grub_device: false
#       type: partition
#       id: disk1p2
#     - id: disk1p2fs1
#       type: format
#       fstype: zfsroot
#       volume: disk1p2
#       preserve: false
#     - id: disk1p2f1_rootpool
#       mountpoint: /
#       pool: rpool
#       type: zpool
#       device: disk1p2fs1
#       preserve: false
#       vdevs:
#         - disk1p2fs1
#     - id: disk1_rootpool_container
#       pool: disk1p2f1_rootpool
#       preserve: false
#       properties:
#         canmount: "off"
#         mountpoint: "none"
#       type: zfs
#       volume: /ROOT
#     - id: disk1_rootpool_rootfs
#       pool: disk1p2f1_rootpool
#       preserve: false
#       properties:
#         canmount: noauto
#         mountpoint: /
#       type: zfs
#       volume: /ROOT/zfsroot
#     - path: /
#       device: disk1p2fs1
#       type: mount
#       id: mount-disk1p2
#     swap:
#       swap: 0
#   early-commands:
#     - "sudo dpkg --auto-deconfigure --force-depends -i /cdrom/autoinstall/packages/*.deb"
#   version: 1
# EOF
#
# Prepare Ubuntu autoinstall ISO

prepare_autoinstall_iso () {
  if [ -z "$(command -v 7z)" ]; then
    install_required_packages "$REQUIRED_PACKAGES"
  fi
  handle_output "# Preparing autoinstall server ISO" "TEXT"
  PACKAGE_DIR="$ISO_SOURCE_DIR/$ISO_AUTOINSTALLDIR/packages"
  CASPER_DIR="$ISO_SOURCE_DIR/casper"
  SCRIPT_DIR="$ISO_SOURCE_DIR/$ISO_AUTOINSTALLDIR/scripts"
  CONFIG_DIR="$ISO_SOURCE_DIR/$ISO_AUTOINSTALLDIR/configs"
  FILES_DIR="$ISO_SOURCE_DIR/$ISO_AUTOINSTALLDIR/files"
  BASE_ISO_INPUTFILE=$( basename "$ISO_INPUTFILE" )
  if [ "$TEST_MODE" = "false" ]; then
    7z -y x "$ISO_WORKDIR/files/$BASE_ISO_INPUTFILE" -o"$ISO_SOURCE_DIR"
    create_dir "$PACKAGE_DIR"
    create_dir "$SCRIPT_DIR"
    create_dir "$FILES_DIR"
    for ISO_DISK in $ISO_DISK; do
      for ISO_VOLMGR in $ISO_VOLMGRS; do
        handle_output "# Creating directory $CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK" "TEXT"
        create_dir "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK"
        handle_output "# Creating $CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/meta-data" "TEXT"
        touch "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/meta-data"
      done
    done
    if [ -f "$PACKAGE_DIR" ]; then
      if [ ! "$PACKAGE_DIR" = "" ]; then
        sudo rm -rf "$PACKAGE_DIR"
        sudo mkdir -p "$PACKAGE_DIR"
      fi
    fi
    if [ "$DO_ISO_EARLY_PACKAGES" = "true" ] || [ "$DO_ISO_LATE_PACKAGES" = "true" ]; then
      handle_output "# Copying packages to $PACKAGE_DIR" "TEXT"
      if [ "$VERBOSE_MODE" = "true" ]; then
        sudo cp -v "$ISO_NEW_DIR"/custom/var/cache/apt/archives/*.deb "$PACKAGE_DIR"
      else
        sudo cp "$ISO_NEW_DIR"/custom/var/cache/apt/archives/*.deb "$PACKAGE_DIR"
      fi
      if [ "$DO_ISO_OLDINSTALLER" = "true" ]; then
        handle_output "# Copying old installer files from $OLD_ISO_MOUNT_DIR/casper/ to $CASPER_DIR" "TEXT"
        mount_old_iso
        sudo cp "$OLD_ISO_MOUNT_DIR"/casper/*installer* "$CASPER_DIR/"
        umount_old_iso
      fi
    fi
  fi
  if [ -d "$ISO_SOURCE_DIR/[BOOT]" ]; then
    handle_output "# Moving $ISO_SOURCE_DIR/[BOOT] to $ISO_WORKDIR/BOOT" "TEXT"
    if [ ! -d "$ISO_WORKDIR/BOOT" ]; then
      create_dir "/$ISO_WORKDIR/BOOT"
    fi
    if [ "$TEST_MODE" = "false" ]; then
      cp -r "$ISO_SOURCE_DIR/[BOOT]"/* "$ISO_WORKDIR/BOOT/"
      rm -rf "$ISO_SOURCE_DIR/[BOOT]"
    fi
  fi
  if [ -f "$ISO_WORKDIR/grub.cfg" ]; then
    handle_output "cp \"$ISO_WORKDIR/grub.cfg\" \"$ISO_SOURCE_DIR/boot/grub/grub.cfg\"" "TEXT"
    if [ "$TEST_MODE" = "false" ]; then
      cp "$ISO_WORKDIR/grub.cfg" "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
    fi
  else
    if [ "$TEST_MODE" = "false" ]; then
      sudo_create_dir "$ISO_SOURCE_DIR/isolinux"
      sudo_chown "$ISO_SOURCE_DIR/isolinux" "$OS_USER" "$OS_GROUP"
      echo "default $ISO_GRUBMENU" > "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      COUNTER=0
      ISO_KERNEL_SERIAL_ARGS="console=$ISO_SERIALPORT0,$ISO_SERIALPORTSPEED0 console=$ISO_SERIAL_PORT1,$ISO_SERIAL_PORT_SPEED1"
      for ISO_DISK in $ISO_DISK; do
        for ISO_VOLMGR in $ISO_VOLMGRS; do
          echo "label $COUNTER" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
          if [[ "$ISO_VOLMGR" =~ "custom" ]]; then
            echo "  menu label ^$ISO_VOLID:$ISO_VOLMGR: ($ISO_KERNEL_SERIAL_ARGS)" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
            echo "  kernel /casper/vmlinuz" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
            echo "  append  initrd=/casper/initrd $ISO_KERNEL_SERIAL_ARGS quiet autoinstall fsck.mode=skip ds=nocloud;s=$ISO_INSTALLMOUNT/$ISO_AUTOINSTALLDIR/configs/$ISO_VOLMGR/$ISO_DISK/  ---" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
          else
            echo "  menu label ^$ISO_VOLID:$ISO_VOLMGR:$ISO_DISK:$ISO_NIC ($ISO_KERNELARGS)" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
            echo "  kernel /casper/vmlinuz" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
            echo "  append  initrd=/casper/initrd $ISO_KERNELARGS quiet autoinstall fsck.mode=skip ds=nocloud;s=$ISO_INSTALLMOUNT/$ISO_AUTOINSTALLDIR/configs/$ISO_VOLMGR/$ISO_DISK/  ---" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
          fi
          COUNTER=$(( COUNTER+1 ))
        done
      done
      echo "label memtest" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      echo "  menu label Test ^Memory" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      echo "  kernel /install/mt86plus" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      echo "label hd" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      echo "  menu label ^Boot from first hard drive" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      echo "  localboot 0x80" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      print_file "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      echo "set timeout=$ISO_GRUBTIMEOUT" > "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "default=$ISO_GRUBMENU" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "loadfont unicode" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      for ISO_DISK in $ISO_DISK; do
        for ISO_VOLMGR in $ISO_VOLMGRS; do
          if [[ "$ISO_VOLMGR" =~ "custom" ]]; then
            echo "menuentry '$ISO_VOLID:$ISO_VOLMGR:defaults ($ISO_KERNEL_SERIAL_ARGS)' {" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
            echo "  set gfxpayload=keep" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
#            echo "  linux   /casper/vmlinuz $ISO_KERNEL_SERIAL_ARGS quiet autoinstall fsck.mode=skip ds=nocloud\;s=$ISO_INSTALLMOUNT/$ISO_AUTOINSTALLDIR/configs/$ISO_VOLMGR/$ISO_DISK/  ---" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
            echo "  linux   /casper/vmlinuz autoinstall fsck.mode=skip ds=nocloud\;s=$ISO_INSTALLMOUNT/$ISO_AUTOINSTALLDIR/configs/$ISO_VOLMGR/$ISO_DISK/  ---" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
          else
            echo "menuentry '$ISO_VOLID:$ISO_VOLMGR:$ISO_DISK:$ISO_NIC ($ISO_KERNEL_SERIAL_ARGS)' {" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
            echo "  set gfxpayload=keep" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
            echo "  linux   /casper/vmlinuz $ISO_KERNELARGS quiet autoinstall fsck.mode=skip ds=nocloud\;s=$ISO_INSTALLMOUNT/$ISO_AUTOINSTALLDIR/configs/$ISO_VOLMGR/$ISO_DISK/  ---" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
          fi
          echo "  initrd  /casper/initrd" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
          echo "}" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
        done
      done
      echo "menuentry 'Try or Install $ISO_VOLID ($ISO_KERNEL_SERIAL_ARGS)' {" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "  set gfxpayload=keep" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "  linux /casper/vmlinuz $ISO_KERNEL_SERIAL_ARGS fsck.mode=skip quiet ---" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "  initrd  /casper/initrd" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "}" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "menuentry 'Boot from next volume' {" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "  exit 1" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "}" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      if [[ "$ISO_BOOT_TYPE" =~ "efi" ]]; then
        echo "menuentry 'UEFI Firmware Settings' {" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
        echo "  fwsetup" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
        echo "}" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      fi
      print_file "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
    fi
  fi
  for ISO_DISK in $ISO_DISK; do
    for ISO_VOLMGR in $ISO_VOLMGRS; do
      if [ -e "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data" ]; then
        rm "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
      fi
      if [ "$TEST_MODE" = "false" ]; then
        if [ "$ISO_VOLMGR" = "custom" ]; then
          if [ -f "$ISO_WORKDIR/files/user-data" ]; then
            sudo_chown "$ISO_WORKDIR/files/user-data" $OS_USER $OS_GROUP
            chmod +w "$ISO_WORKDIR/files/user-data"
          fi
          cp "$ISO_WORKDIR/files/user-data" "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          print_file "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
        else
          echo "#cloud-config" > "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          echo "autoinstall:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          echo "  version: 1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          echo "  identity:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          echo "    hostname: $ISO_HOSTNAME" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          echo "    password: \"$ISO_PASSWORD_CRYPT\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          echo "    realname: $ISO_REALNAME" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          echo "    username: $ISO_USERNAME" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          if [ ! "$ISO_BUILDTYPE" = "desktop" ]; then
            echo "  apt:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    preserve_sources_list: $DO_ISO_PRESERVE_SOURCES" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    preferences:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "      - package: \"*\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "        pin: \"release a=$ISO_CODENAME-security\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "        pin-priority: 200" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
  #          echo "    disable_components: []" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
  #          echo "    mirror-selection:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    primary:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    - arches:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "      - $ISO_ARCH" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "      uri: http://archive.ubuntu.com/ubuntu" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    - arches:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "      - default" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "      uri: http://ports.ubuntu.com/ubuntu-ports" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    fallback: $ISO_FALLBACK" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    geoip: $DO_GEOIP" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    security:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    - arches:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "      - $ISO_ARCH" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "      uri: http://security.ubuntu.com/ubuntu/" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    - arches:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "      - $ISO_ARCH" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "      uri: http://ports.ubuntu.com/ubuntu-ports" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    package_update: $DO_INSTALL_ISO_UPDATE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    package_upgrade: $DO_INSTALL_ISO_UPGRADE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "  codecs:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    install: $DO_INSTALL_ISO_CODECS" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "  drivers:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    install: $DO_INSTALL_ISO_DRIVERS" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "  kernel:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    package: $ISO_KERNEL" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "  keyboard:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    layout: $ISO_LAYOUT" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "  locale: $ISO_LOCALE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
  #          echo "  user-data:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
  #          echo "    timezone: $ISO_TIMEZONE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "  network:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    ethernets:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "      $ISO_NIC:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            if [ "$DO_ISO_DHCP" = "true" ]; then
              echo "        critical: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "        dhcp-identifier: mac" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "        dhcp4: $DO_ISO_DHCP" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            else
              echo "        addresses:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "        - $ISO_IP/$ISO_CIDR" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "        gateway4: $ISO_GATEWAY" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "        nameservers:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "          addresses:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "          - $ISO_DNS" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            fi
            echo "    version: 2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
#          echo "  refresh-installer:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
#          echo "    update: $DO_REFRESH_INSTALLER" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
#          echo "  oem:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
#          echo "    install: $ISO_OEMINSTALL" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
#          echo "  source:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
#          echo "    id: $ISO_SOURCEID" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
#          echo "    search_drivers: $DO_ISO_SEARCH_DRIVERS" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "  ssh:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    allow-pw: $ISO_ALLOWPASSWORD" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            if [ ! "$ISO_SSHKEY" = "" ]; then
              echo "    authorized-keys: [ \"$ISO_SSHKEY\" ]" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            fi
            echo "    install-server: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          fi
          echo "  storage:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          if [[ "$ISO_VOLMGR" =~ "auto" ]]; then
            echo "    layout:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            if [ "$ISO_VOLMGR" = "auto" ]; then
              echo "      name: lvm" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            fi
          else
            echo "    config:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            if [ "$ISO_VOLMGR" = "zfs" ]; then
              # Creates rpool/ROOT/zfsroot
              echo "    - id: $ISO_DISK" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: disk" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      ptable: gpt" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      path: /dev/$ISO_DISK" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      name: main_disk" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      grub_device: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - id: efi" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      size: 2G" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      number: 1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      device: $ISO_DISK" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      flag: boot" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      grub_device: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - id: ${ISO_DISK}1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      number: 2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      size: -1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      device: $ISO_DISK" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - id: efi_format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      fstype: fat32" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      volume: efi" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      label: efi" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - id: ${ISO_DISK}1_root" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      fstype: zfsroot" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      volume: ${ISO_DISK}1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      label: 'rootfs'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - id: ${ISO_DISK}1_mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      path: /" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      device: ${ISO_DISK}1_root" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - id: efi_mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      device: efi_format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      path: /boot/efi" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              if [ "$DO_ISO_ZFSFILESYSTEMS" = "true" ]; then
                ZFSFS_COUNTER=0
                for ZFSFILESYSTEM in $ISO_ZFSFILESYSTEMS; do
                  echo "    - pool: rpool" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
                  echo "      volume: rpool$ZFSFILESYSTEM" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
                  echo "      properties:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
                  echo "        canmount: 'on'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
                  echo "      id: zfs-$ZFSFS_COUNTER" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
                  echo "      type: zfs" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
                  ZFSFS_COUNTER=$(( ZFSFS_COUNTER+1 ))
                done
              fi
            else
              echo "    - ptable: gpt" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      path: /dev/$ISO_DISK" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      wipe: superblock-recursive" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      name: ''" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      grub_device: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      id: disk-$ISO_DISK" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: disk" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - device: disk-$ISO_DISK" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      size: 1127219200" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      flag: boot" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      number: 1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      grub_device: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      offset: 1048576" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      path: /dev/${ISO_DISK}1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      id: partition-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - fstype: fat32" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      volume: partition-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      id: format-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - device: disk-$ISO_DISK" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      size: 2147483648" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      number: 2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      grub_device: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      offset: 1128267776" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      path: /dev/${ISO_DISK}2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      id: partition-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - fstype: ext4" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      volume: partition-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      id: format-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - device: disk-$ISO_DISK" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      size: 23566745600" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      number: 3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      grub_device: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      offset: 3275751424" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      path: /dev/${ISO_DISK}3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      id: partition-2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - name: $ISO_VGNAME" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      devices:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      - partition-2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      id: lvm_volgroup-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: lvm_volgroup" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - name: $ISO_LVNAME" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      volgroup: lvm_volgroup-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      size: -1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      path: /dev/$ISO_VGNAME/$ISO_LVNAME" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      id: lvm_partition-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: lvm_partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - fstype: $ISO_VOLMGR" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      volume: lvm_partition-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      id: format-3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - path: /" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      device: format-3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      id: mount-3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - path: /boot" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      device: format-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      id: mount-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - path: /boot/$ISO_BOOT_TYPE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      device: format-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      id: mount-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            fi
          fi
          if [ "$DO_REORDER_UEFI" = "true" ]; then
            echo "    grub:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "      reorder_uefi: $DO_REORDER_UEFI" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          fi
          echo "  early-commands:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          if [ "$ISO_MAJOR_RELEASE" -gt 23 ] && [ "$DO_NVME" = "true" ]; then
            echo "    - \"sed -i \\\"s/first-wwn/\$(lsblk -x TYPE -o NAME,WWN,TYPE |grep disk |sort |head -1 |awk '{print \$2}')/g\\\" /autoinstall.yaml\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    - \"sed -i \\\"s/first-serial/\$(udevadm info --query=all --name=\`lsblk -x TYPE |grep disk |sort |head -1 |awk '{print \$1}'\` |grep ID_SERIAL= |cut -f2 -d=)/g\\\" /autoinstall.yaml\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          fi
          if ! [ "$ISO_ALLOWLIST" = "" ]; then
            if [[ "$ISO_ALLOWLIST" =~ "," ]]; then
              for MODULE in $(${ISO_ALLOWLIST//,/ }); do
                echo "    - \"echo '$MODULE' > /etc/modules-load.d/$MODULE.conf\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
                echo "    - \"modprobe $MODULE\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              done
            else
              echo "    - \"echo '$ISO_ALLOWLIST' > /etc/modules-load.d/$ISO_BLOCKLIST.conf\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"modprobe $ISO_ALLOWLIST\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            fi
          fi
          if [ "$ISO_DISK" = "first-disk" ]; then
            if [ ! "$ISO_VOLMGR" = "auto" ]; then
              echo "    - \"sed -i \\\"s/first-disk/\$(lsblk -x TYPE|grep disk |sort |head -1 |awk '{print \$1}')/g\\\" /autoinstall.yaml\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            fi
          fi
          if [ "$ISO_NIC" = "first-nic" ]; then
            echo "    - \"sed -i \\\"s/first-nic/\$(lshw -class network -short |awk '{print \$2}' |grep ^e |head -1)/g\\\" /autoinstall.yaml\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    - \"sed -i \\\"s/nvme\\\([0-9]\\\)n\\\([0-9]\\\)\\\([0-9]\\\)/nvme\\\1n\\\2p\\\3/g\\\" /autoinstall.yaml\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          fi
          NO_DEBS=$( find "$PACKAGE_DIR" "*.deb" |wc -l)
          if [ ! "$NO_DEBS" = "0" ] && [ "$DO_ISO_EARLY_PACKAGES" = "true" ]; then
            echo "    - \"export DEBIAN_FRONTEND=\\\"noninteractive\\\" && dpkg $ISO_DPKG_CONF $ISO_DPKG_OVERWRITE --auto-deconfigure $ISO_DPKG_DEPENDS -i $ISO_INSTALLMOUNT/$ISO_AUTOINSTALLDIR/packages/*.deb\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          fi
          echo "    - \"rm /etc/resolv.conf\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          echo "    - \"echo \\\"nameserver $ISO_DNS\\\" >> /etc/resolv.conf\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          if ! [ "$ISO_BLOCKLIST" = "" ]; then
            if [[ "$ISO_BLOCKLIST" =~ "," ]]; then
              for MODULE in $(${ISO_BLOCKLIST//,/ }); do
                echo "    - \"echo 'blacklist $MODULE' > /etc/modprobe.d/$MODULE.conf\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
                echo "    - \"modprobe -r $MODULE --remove-dependencies\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              done
            else
              echo "    - \"echo 'blacklist $ISO_BLOCKLIST' > /etc/modprobe.d/$ISO_BLOCKLIST.conf\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"modprobe -r $ISO_BLOCKLIST --remove-dependencies\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            fi
          fi
          echo "  late-commands:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          if [ ! "$NO_DEBS" = "0" ]; then
            if [ "$DO_ISO_LATE_PACKAGES" = "true" ]; then
              echo "    - \"mkdir -p $ISO_TARGETMOUNT/var/postinstall/packages\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"cp $ISO_INSTALLMOUNT/$ISO_AUTOINSTALLDIR/packages/*.deb $ISO_TARGETMOUNT/var/postinstall/packages/\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"echo '#!/bin/bash' > $ISO_TARGETMOUNT/tmp/post.sh\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"echo 'export DEBIAN_FRONTEND=\\\"noninteractive\\\" && dpkg $ISO_DPKG_CONF $ISO_DPKG_OVERWRITE --auto-deconfigure $ISO_DPKG_DEPENDS -i /var/postinstall/packages/*.deb' >> $ISO_TARGETMOUNT/tmp/post.sh\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"chmod +x $ISO_TARGETMOUNT/tmp/post.sh\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            fi
            if [ "$ISO_VOLMGR" = "btrfs" ] && [ "$DO_ISO_COMPRESSION" = "true" ]; then
              echo "    - \"mount -o remount,compress=$ISO_COMPRESSION,ssd /\`mount |grep $ISO_VOLMGR |awk '{ print \$1 }'\` /target -t $ISO_VOLMGR\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"sed -i \\\"s/$ISO_VOLMGR defaults/$ISO_VOLMGR compress=$ISO_COMPRESSION,ssd/g\\\" $ISO_TARGETMOUNT/etc/fstab\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"echo '#!/bin/bash' > $ISO_TARGETMOUNT/tmp/post.sh\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"echo '$ISO_VOLMGR filesystem defragment -rc$ISO_COMPRESSION /' > $ISO_TARGETMOUNT/tmp/post.sh\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"chmod +x $ISO_TARGETMOUNT/tmp/post.sh\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            fi
          fi
          echo "    - \"echo '$ISO_TIMEZONE' > $ISO_TARGETMOUNT/etc/timezone\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          echo "    - \"rm $ISO_TARGETMOUNT/etc/localtime\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- ln -s /usr/share/zoneinfo/$ISO_TIMEZONE /etc/localtime\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          if [ ! "$ISO_COUNTRY" = "us" ]; then
            echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- sed -i \\\"s/\\\/archive/\\\/$ISO_COUNTRY.archive/g\\\" /etc/apt/sources.list\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          fi
          if [ ! "$NO_DEBS" = "0" ]; then
            if [ "$DO_ISO_LATE_PACKAGES" = "true" ]; then
              if [ ! "$ISO_VOLMGR" = "btrfs" ] && [ ! "$ISO_VOLMGR" = "xfs" ]; then
                echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- /tmp/post.sh\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              else
                if [ "$ISO_VOLMGR" = "btrfs" ] && [ "$DO_ISO_COMPRESSION" = "true" ]; then
                  echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- /tmp/post.sh\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
                fi
              fi
            fi
          fi
          if [ ! "$ISO_BUILDTYPE" = "desktop" ]; then
            if [ "$DO_SERIAL" = "true" ]; then
              echo "    - \"echo 'GRUB_TERMINAL=\\\"serial console\\\"' >> $ISO_TARGETMOUNT/etc/default/grub\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"echo 'GRUB_SERIAL_COMMAND=\\\"serial --speed=$ISO_SERIALPORTSPEED0 --port=$ISO_SERIALPORTADDRESS0\\\"' >> $ISO_TARGETMOUNT/etc/default/grub\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            else
              echo "    - \"echo 'GRUB_TERMINAL=\\\"console\\\"' >> $ISO_TARGETMOUNT/etc/default/grub\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            fi
            echo "    - \"echo 'GRUB_CMDLINE_LINUX=\\\"console=tty0 $ISO_KERNELARGS\\\"' >> $ISO_TARGETMOUNT/etc/default/grub\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    - \"echo 'GRUB_TIMEOUT=\\\"$ISO_GRUBTIMEOUT\\\"' >> $ISO_TARGETMOUNT/etc/default/grub\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            echo "    - \"echo '$ISO_USERNAME ALL=(ALL) NOPASSWD: ALL' >> $ISO_TARGETMOUNT/etc/sudoers.d/$ISO_USERNAME\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            if [ "$DO_ISO_AUTO_UPGRADES" = "false" ]; then
              echo "    - \"echo 'APT::Periodic::Update-Package-Lists \\\"0\\\";' > $ISO_TARGETMOUNT/etc/apt/apt.conf.d/20auto-upgrades\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"echo 'APT::Periodic::Download-Upgradeable-Packages \\\"0\\\";' >> $ISO_TARGETMOUNT/etc/apt/apt.conf.d/20auto-upgrades\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"echo 'APT::Periodic::AutocleanInterval \\\"0\\\";' >> $ISO_TARGETMOUNT/etc/apt/apt.conf.d/20auto-upgrades\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"echo 'APT::Periodic::Unattended-Upgrade \\\"0\\\";' >> $ISO_TARGETMOUNT/etc/apt/apt.conf.d/20auto-upgrades\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            fi
            if [ "$DO_SERIAL" = "true" ]; then
              echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- systemctl enable serial-getty@ttyS0.service\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- systemctl start serial-getty@ttyS0.service\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- systemctl enable serial-getty@ttyS1.service\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- systemctl start serial-getty@ttyS1.service\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- systemctl enable serial-getty@ttyS4.service\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- systemctl start serial-getty@ttyS4.service\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            fi
            echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- update-grub\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
            if [ "$DO_INSTALL_ISO_NETWORK_UPDATES" = "true" ]; then
              if [ "$DO_INSTALL_ISO_UPDATE" = "true" ] || [ "$DO_INSTALL_ISO_DIST_UPGRADE" = "true" ]; then
                echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- apt update\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              fi
              if [ "$DO_INSTALL_ISO_UPGRADE" = "true" ]; then
                echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- apt upgrade -y\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              fi
              if [ "$DO_INSTALL_ISO_DIST_UPGRADE" = "true" ]; then
                echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- apt dist-upgrade -y\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              fi
              if [ "$DO_INSTALL_ISO_PACKAGES" = "true" ]; then
                echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- apt install -y $ISO_PACKAGES\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
              fi
              if [ "$ISO_MAJOR_RELEASE" = "22" ]; then
                if [ "$DO_ISO_APT_NEWS" = "false" ]; then
                  echo "    - \"curtin in-target --target=$ISO_TARGETMOUNT -- pro config set apt_news=false\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
                fi
              fi
            fi
          fi
#          echo "  updates: $ISO_UPDATES" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
          print_file "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DISK/user-data"
        fi
      fi
    done
  done
}

# Function: handle_ubuntu_pro
#
# Handle Ubuntu Pro Apt News etc

handle_ubuntu_pro () {
  if [ "$ISO_REALNAME" = "Ubuntu" ]; then
    if [ "$ISO_MAJOR_RELEASE" -ge 22 ]; then
      ISO_PACKAGES="$ISO_PACKAGES ubuntu-advantage-tools"
      ISO_CHROOTPACKAGES="$ISO_CHROOTPACKAGES ubuntu-advantage-tools"
    fi
  fi
}

# Function: copy_custom_user_data
#
# Copy the custome user-data file to a place we can get to it whne running in docker

copy_custom_user_data () {
  if [ "$DO_ISO_AUTOINSTALL" = "true" ]; then
    if [ ! -f "/.dockerenv" ]; then
      cp "$ISO_AUTOINSTALLFILE" "$ISO_WORKDIR/files/user-data"
    fi
  fi
}
