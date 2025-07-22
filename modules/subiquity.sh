#!/usr/bin/env bash

# shellcheck disable=SC2004
# shellcheck disable=SC2028
# shellcheck disable=SC2129
# shellcheck disable=SC2153
# shellcheck disable=SC2154

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
    install_required_packages
  fi
  handle_output "# Preparing autoinstall server ISO" "TEXT"
  iso['packagedir']="${iso['sourcedir']}/${iso['autoinstalldir']}/packages"
  iso['casperdir']="${iso['sourcedir']}/casper"
  iso['postscriptdir']="${iso['sourcedir']}/${iso['autoinstalldir']}/scripts"
  iso['configdir']="${iso['sourcedir']}/${iso['autoinstalldir']}/configs"
  iso['installfilesdir']="${iso['sourcedir']}/${iso['autoinstalldir']}/files"
  iso['inputfilebase']=$( basename "${iso['inputfile']}" )
  if [ "${options['testmode']}" = "false" ]; then
    7z -y x "${iso['workdir']}/files/${iso['inputfilebase']}" -o"${iso['sourcedir']}"
    create_dir "${iso['packagedir']}"
    create_dir "${iso['postscriptdir']}"
    create_dir "${iso['installfilesdir']}"
    iso_volmgrs="${iso['volumemanager']//,/ }"
    for iso_volmgr in ${iso_volmgrs}; do
      handle_output "# Creating directory ${iso['configdir']}/${iso_volmgr}/${iso['disk']}" "TEXT"
      create_dir "${iso['configdir']}/${iso_volmgr}/${iso['disk']}"
      handle_output "# Creating ${iso['configdir']}/${iso_volmgr}/${iso['disk']}/meta-data" "TEXT"
      touch "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/meta-data"
    done
    if [ -f "${iso['packagedir']}" ]; then
      if [ ! "${iso['packagedir']}" = "" ]; then
        sudo rm -rf "${iso['packagedir']}"
        sudo mkdir -p "${iso['packagedir']}"
      fi
    fi
    if [ "${options['earlypackages']}" = "true" ] || [ "${options['latepackages']}" = "true" ]; then
      handle_output "# Copying packages to ${iso['packagedir']}" "TEXT"
      if [ "${options['verbose']}" = "true" ]; then
        sudo cp -v "${iso['newdir']}"/custom/var/cache/apt/archives/*.deb "${iso['packagedir']}"
      else
        sudo cp "${iso['newdir']}"/custom/var/cache/apt/archives/*.deb "${iso['packagedir']}"
      fi
      if [ "${options['oldinstaller']}" = "true" ]; then
        handle_output "# Copying old installer files from ${old['mountdir']}/casper/ to ${iso['casperdir']}" "TEXT"
        mount_old
        sudo cp "${old['mountdir']}"/casper/*installer* "${iso['casperdir']}/"
        umount_old
      fi
    fi
  fi
  if [ -d "${iso['sourcedir']}/[BOOT]" ]; then
    handle_output "# Moving ${iso['sourcedir']}/[BOOT] to ${iso['workdir']}/BOOT" "TEXT"
    if [ ! -d "${iso['workdir']}/BOOT" ]; then
      create_dir "/${iso['workdir']}/BOOT"
    fi
    if [ "${options['testmode']}" = "false" ]; then
      cp -r "${iso['sourcedir']}/[BOOT]"/* "${iso['workdir']}/BOOT/"
      rm -rf "${iso['sourcedir']}/[BOOT]"
    fi
  fi
  if [ -f "${iso['workdir']}/grub.cfg" ]; then
    handle_output "cp \"${iso['workdir']}/grub.cfg\" \"${iso['sourcedir']}/boot/grub/grub.cfg\"" "TEXT"
    if [ "${options['testmode']}" = "false" ]; then
      cp "${iso['workdir']}/grub.cfg" "${iso['sourcedir']}/boot/grub/grub.cfg"
    fi
  else
    if [ "${options['testmode']}" = "false" ]; then
      sudo_create_dir "${iso['sourcedir']}/isolinux"
      sudo_chown "${iso['sourcedir']}/isolinux" "${os['user']}" "${os['group']}"
      echo "default ${iso['grubmenu']}" > "${iso['sourcedir']}/isolinux/txt.cfg"
      counter=0
      kernel_args="${iso['kernelargs']}" 
#      iso['kernelserialargs']="console=${iso['serialporta']},${iso['serialportspeeda']} console=${iso['serialportb']},${iso['serialportspeedb']}"
      iso_volmgrs="${iso['volumemanager']//,/ }"
      for iso_volmgr in ${iso_volmgrs}; do
        echo "label ${counter}" >> "${iso['sourcedir']}/isolinux/txt.cfg"
        if [ "${iso_volmgr}" = "custom" ]; then
          echo "  menu label ^${iso['volid']}:${iso_volmgr}: (${iso['kernelserialargs']})" >> "${iso['sourcedir']}/isolinux/txt.cfg"
          echo "  kernel /casper/vmlinuz" >> "${iso['sourcedir']}/isolinux/txt.cfg"
          echo "  append  initrd=/casper/initrd ${kernel_args} quiet autoinstall fsck.mode=skip ds=nocloud;s=${iso['installmount']}/${iso['autoinstalldir']}/configs/${iso_volmgr}/${iso['disk']}/  ---" >> "${iso['sourcedir']}/isolinux/txt.cfg"
        else
          echo "  menu label ^${iso['volid']}:${iso_volmgr}:${iso['disk']}:${iso['nic']} (${iso['kernelargs']}" >> "${iso['sourcedir']}/isolinux/txt.cfg"
          echo "  kernel /casper/vmlinuz" >> "${iso['sourcedir']}/isolinux/txt.cfg"
          echo "  append  initrd=/casper/initrd ${kernel_args} quiet autoinstall fsck.mode=skip ds=nocloud;s=${iso['installmount']}/${iso['autoinstalldir']}/configs/${iso_volmgr}/${iso['disk']}/  ---" >> "${iso['sourcedir']}/isolinux/txt.cfg"
        fi
        counter=$(( counter+1 ))
      done
      echo "label memtest" >> "${iso['sourcedir']}/isolinux/txt.cfg"
      echo "  menu label Test ^Memory" >> "${iso['sourcedir']}/isolinux/txt.cfg"
      echo "  kernel /install/mt86plus" >> "${iso['sourcedir']}/isolinux/txt.cfg"
      echo "label hd" >> "${iso['sourcedir']}/isolinux/txt.cfg"
      echo "  menu label ^Boot from first hard drive" >> "${iso['sourcedir']}/isolinux/txt.cfg"
      echo "  localboot 0x80" >> "${iso['sourcedir']}/isolinux/txt.cfg"
      print_file "${iso['sourcedir']}/isolinux/txt.cfg"
      echo "set timeout=${iso['grubtimeout']}" > "${iso['sourcedir']}/boot/grub/grub.cfg"
      echo "default=${iso['grubmenu']}" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
      echo "loadfont unicode" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
      iso_volmgrs="${iso['volumemanager']//,/ }"
      for iso_volmgr in ${iso_volmgrs}; do
        if [ "${iso_volmgr}" = "custom" ]; then
          echo "menuentry '${iso['volid']}:${iso_volmgr}:defaults (${kernel_args})' {" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
          echo "  set gfxpayload=keep" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
          echo "  linux   /casper/vmlinuz ${kernel_args} autoinstall fsck.mode=skip ds=nocloud\;s=${iso['installmount']}/${iso['autoinstalldir']}/configs/${iso_volmgr}/${iso['disk']}/  ---" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
        else
          echo "menuentry '${iso['volid']}:${iso_volmgr}:${iso['disk']}:${iso['nic']} (${kernel_args})' {" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
          echo "  set gfxpayload=keep" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
          grub_string="linux   /casper/vmlinuz ${kernel_args} quiet autoinstall fsck.mode=skip ds=nocloud\;s=${iso['installmount']}/${iso['autoinstalldir']}/configs/${iso_volmgr}/${iso['disk']}/"
          if [ "${options['grubparse']}" = "true" ] || [ "${options['grubparseall']}" = "true" ]; then
            for param in ${iso['grubparams']}; do
              grub_param="grub${param}"
              if [ ! "${iso[${grub_param}]}" = "" ]; then
                grub_string="${grub_string} ${param}=${iso[${grub_param}]}" 
              fi
            done
          fi
        fi
        echo "  ${grub_string} ---" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
        echo "  initrd  /casper/initrd" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
        echo "}" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
      done
      echo "menuentry 'Try or Install ${iso['volid']} (${kernel_args})' {" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
      echo "  set gfxpayload=keep" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
      echo "  linux /casper/vmlinuz ${kernel_args} fsck.mode=skip quiet ---" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
      echo "  initrd  /casper/initrd" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
      echo "}" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
      echo "menuentry 'Boot from next volume' {" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
      echo "  exit 1" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
      echo "}" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
      if [[ "${iso['boottype']}" =~ "efi" ]]; then
        echo "menuentry 'UEFI Firmware Settings' {" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
        echo "  fwsetup" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
        echo "}" >> "${iso['sourcedir']}/boot/grub/grub.cfg"
      fi
      print_file "${iso['sourcedir']}/boot/grub/grub.cfg"
    fi
  fi
  iso_volmgrs="${iso['volumemanager']//,/ }"
  for iso_volmgr in ${iso_volmgrs}; do
    if [ -e "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data" ]; then
      rm "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
    fi
    if [ ! -d "${iso['configdir']}/${iso_volmgr}/${iso['disk']}" ]; then
      sudo_create_dir "${iso['configdir']}/${iso_volmgr}/${iso['disk']}"
    fi
    if [ "${options['testmode']}" = "false" ]; then
      if [ "${iso_volmgr}" = "custom" ]; then
        if [ -f "/.dockerenv" ]; then
          if [ -f "${iso['workdir']}/files/user-data" ]; then
            execute_command "cp ${iso['workdir']}/files/user-data ${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
        else
          if [ -f "${iso['workdir']}/files/user-data" ]; then
            sudo_chown "${iso['workdir']}/files/user-data" "${os['user']}" "${os['group']}"
            chmod +w "${iso['workdir']}/files/user-data"
          fi
          execute_command "cp ${iso['workdir']}/files/user-data ${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        fi
        execute_command "touch ${iso['configdir']}/${iso_volmgr}/${iso['disk']}/meta-data"
        print_file "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
      else
        echo "#cloud-config" > "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        echo "autoinstall:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        echo "  version: 1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        echo "  identity:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        if [ "${iso['grubhostname']}" = "" ]; then
          echo "    hostname: ${iso['hostname']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        else
          echo "    hostname: grubhostname" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        fi
        if [ "${iso['grubrealname']}" = "" ]; then
          echo "    realname: ${iso['realname']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        else
          echo "    realname: grubrealname" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        fi
        if [ "${iso['grubusername']}" = "" ]; then
          echo "    username: ${iso['username']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        else
          echo "    username: grubusername" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        fi
        if [ "${iso['grubpassword']}" = "" ]; then
          echo "    password: \"${iso['passwordcrypt']}\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        else
          echo "    password: \"grubpassword\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        fi
        if [ ! "${iso['build']}" = "desktop" ]; then
          echo "  apt:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    preserve_sources_list: ${options['preservesources']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    preferences:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "      - package: \"*\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "        pin: \"release a=${iso['codename']}-security\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "        pin-priority: 200" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
#          echo "    disable_components: []" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
#          echo "    mirror-selection:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    primary:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    - arches:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "      - ${iso['arch']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "      uri: http://archive.ubuntu.com/ubuntu" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    - arches:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "      - default" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "      uri: http://ports.ubuntu.com/ubuntu-ports" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    fallback: ${iso['fallback']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    geoip: ${options['geoip']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    security:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    - arches:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "      - ${iso['arch']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "      uri: http://security.ubuntu.com/ubuntu/" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    - arches:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "      - ${iso['arch']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "      uri: http://ports.ubuntu.com/ubuntu-ports" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    package_update: ${options['packageupdates']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    package_upgrade: ${options['packageupgrades']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "  codecs:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    install: ${options['installcodecs']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "  drivers:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    install: ${options['installdrivers']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "  kernel:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          if [ "${iso['grubkernel']}" = "" ]; then
            echo "    package: ${iso['kernel']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          else
            echo "    package: grubkernel" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
          echo "  keyboard:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          if [ "${iso['grublayout']}" = "" ]; then
            echo "    layout: ${iso['layout']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          else
            echo "    package: grublayout" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
          if [ "${iso['grublocale']}" = "" ]; then
            echo "  locale: ${iso['locale']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          else
            echo "  locale: grublocale" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
          echo "  network:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          if [ "${iso['nics']}" = "" ]; then
            echo "    ethernets:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            if [ "${iso['grubnic']}" = "" ]; then
              echo "      ${iso['nic']}:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            else
              echo "      grubnic:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            fi
            if [ "${options['dhcp']}" = "true" ]; then
              echo "        critical: true" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        dhcp-identifier: mac" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        dhcp4: true" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        dhcp6: true" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            else
              echo "        dhcp4: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        dhcp6: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              if [ "${options['bridge']}" = "true" ]; then
                echo "    bridges:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "      ${iso['bridge']}:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "        interfaces:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                if [ "${iso['grubnic']}" = "" ]; then
                   echo "          - ${iso['nic']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                else
                  echo "          - grubnic" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                fi
                echo "        addresses:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                if [ "${iso['grubip']}" = "" ]; then
                  echo "        - ${iso['ip']}/${iso['cidr']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                else
                  echo "        - grubip/grubcidr" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                fi
              else
                echo "        addresses:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                if [ "${iso['grubip']}" = "" ]; then
                  echo "          - ${iso['ip']}/${iso['cidr']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                else
                  echo "          - grubip/grubcidr" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                fi
              fi
              if [ "${iso['majorrelease']}" -lt 22 ]; then
                if [ "${iso['grubgateway']}" = "" ]; then
                  echo "        gateway4: ${iso['gateway']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                else
                  echo "        gateway4: grubgateway" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                fi
              else
                echo "        routes:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "          - to: default" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                if [ "${iso['grubgateway']}" = "" ]; then
                  echo "            via: ${iso['gateway']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                else
                  echo "            via: grubgateway" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                fi
              fi
              echo "        nameservers:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "          addresses:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              if [ "${iso['grubdns']}" = "" ]; then
                echo "            - ${iso['dns']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              else
                echo "            - grubdns" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              fi
            fi
          else
            IFS=',' read -r -a nics <<< "${iso['nics']}"            
            if [ "${options['bridge']}" = "true" ]; then
              if [ "${iso['bridges']}" = "" ]; then
                declare -a bridges
                for index in "${!nics[@]}"; do
                  bridges[${index}]="br${index}"
                done
              else
                IFS=',' read -r -a bridges <<< "${iso['bridges']}"            
              fi
            fi
            if [ "${iso['cidrs']}" = "" ]; then
              declare -a cidrs
              for index in "${!nics[@]}"; do
                cidrs[${index}]="${iso['cidr']}"
              done
            else
              IFS=',' read -r -a cidrs <<< "${iso['cidrs']}"            
            fi
            IFS=',' read -r -a ips <<< "${iso['ips']}"            
            if [ "${options['bridge']}" = "false" ]; then
              echo "    ethernets:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              for index in "${!nics[@]}"; do
                echo "      ${nics[${index}]}:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "        dhcp4: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "        dhcp6: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "        addresses:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "          - ${ips[${index}]}/${cidrs[${index}]}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                if [ "${index}" -eq 0 ]; then
                  echo "        routes:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                  echo "          - to: default" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                  echo "            via: ${iso['gateway']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                  echo "        nameservers:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                  echo "          addresses:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                  echo "            - ${iso['dns']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                fi
              done
            else
              echo "    ethernets:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              for index in "${!nics[@]}"; do
                echo "      ${nics[${index}]}:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "        dhcp4: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "        dhcp6: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              done
              echo "    bridges:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              for index in "${!bridges[@]}"; do
                echo "      ${bridges[${index}]}:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "        interfaces:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "          - ${nics[${index}]}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "        addresses:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "          - ${ips[${index}]}/${cidrs[${index}]}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                if [ "${index}" -eq 0 ]; then
                  echo "        routes:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                  echo "          - to: default" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                  echo "            via: ${iso['gateway']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                  echo "        nameservers:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                  echo "          addresses:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                  echo "            - ${iso['dns']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                fi
              done
            fi
          fi
          echo "    version: 2" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
#          echo "  refresh-installer:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
#          echo "    update: ${options['refreshinstaller']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
#          echo "  oem:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
#          echo "    install: ${iso['oeminstall']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
#          echo "  source:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
#          echo "    id: ${iso['sourceid']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
#          echo "    search_drivers: ${options['searchdrivers']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "  ssh:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    allow-pw: ${iso['allowpassword']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          if [ ! "${iso['sshkey']}" = "" ]; then
            echo "    authorized-keys: [ \"${iso['sshkey']}\" ]" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
          echo "    install-server: true" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        fi
        echo "  storage:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        if [[ "${iso_volmgr}" =~ "auto" ]]; then
          echo "    layout:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          if [ "${iso_volmgr}" = "auto" ]; then
            echo "      name: lvm" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
        else
          echo "    config:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          if [ "${iso_volmgr}" = "zfs" ]; then
            if [ "${options['zfsfilesystems']}" = "true" ]; then
              part_num=0
              echo "    - ptable: gpt" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      path: /dev/${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      wipe: superblock-recursive" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      name: ''" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      grub_device: true" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: disk-${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: disk" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - device: disk-${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      size: 1127219200" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      wipe: superblock" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      flag: boot" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      number: 1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      grub_device: true" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      path: /dev/${iso['disk']}1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: partition-0" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: partition" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - fstype: vfat" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      volume: partition-0" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: format-0" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: format" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - device: disk-${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      size: 2G" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      number: 2" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      path: /dev/${iso['disk']}2" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: partition-1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: partition" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - device: disk-${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      size: ${iso['swapsize']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      wipe: superblock" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      flag: swap" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      number: 3" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      path: /dev/${iso['disk']}3" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: partition-2" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: partition" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - fstype: swap" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      volume: partition-${part_num}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: format-1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: format" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - path: ''" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      device: format-1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: mount-1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: mount" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - device: disk-${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      size: -1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      number: 4" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      path: /dev/${iso['disk']}4" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: partition-3" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: partition" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - vdevs:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      - partition-1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      pool: bpool" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      mountpoint: /boot" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      pool_properties:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        ashift: 12" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        autotrim: 'on'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        feature@async_destroy: enabled" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        feature@bookmarks: enabled" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        feature@embedded_data: enabled" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        feature@empty_bpobj: enabled" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        feature@enabled_txg: enabled" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        feature@extensible_dataset: enabled" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        feature@filesystem_limits: enabled" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        feature@hole_birth: enabled" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        feature@large_blocks: enabled" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        feature@lz4_compress: enabled" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        feature@spacemap_histogram: enabled" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        version: null" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      fs_properties:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        acltype: posixacl" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        atime: null" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        canmount: 'off'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        compression: lz4" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        devices: 'off'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        normalization: formD" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        relatime: 'on'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        sync: standard" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        xattr: sa" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      default_features: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: zpool-0" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: zpool" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - pool: zpool-0" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      volume: BOOT" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      properties:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        canmount: 'off'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        mountpoint: none" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: zfs-0" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: zfs" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - vdevs:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      - partition-3" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      pool: rpool" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      mountpoint: /" >>  "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      pool_properties:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        ashift: 12" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        autotrim: 'on'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        version: null" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      fs_properties:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        acltype: posixacl" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        atime: null" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        canmount: 'off'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        compression: lz4" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        devices: 'off'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        dnodesize: auto" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        normalization: formD" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        relatime: 'on'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        sync: standard" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        xattr: sa" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      default_features: true" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: zpool-1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: zpool" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              zfs_num=2 
              echo "    - pool: zpool-1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      volume: ROOT" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      properties:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        canmount: 'off'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        mountpoint: none" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: zfs-${zfs_num}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: zfs" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              zfs_num=$(( zfs_num+1 ))
              echo "    - pool: zpool-1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      volume: ROOT/${iso['zfsroot']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      properties:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        canmount: 'on'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        mountpoint: /" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: zfs-${zfs_num}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: zfs" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              for zfs_filesystem in ${iso['zfsfilesystems']}; do
                hash_num="${zfs_filesystem//[^\/]}"
                if [ "${#hash_num}" = "1" ]; then
                  can_mount="off"
                else
                  can_mount="on"
                fi
                zfs_num=$(( zfs_num+1 ))
                echo "    - pool: zpool-1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "      volume: ROOT/${iso['zfsroot']}${zfs_filesystem}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "      properties:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "        canmount: '${can_mount}'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "      id: zfs-${zfs_num}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "      type: zfs" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              done

              zfs_num=$(( zfs_num+1 ))
              echo "    - pool: zpool-1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      volume: USERDATA" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      properties:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        canmount: 'off'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        mountpoint: none" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: zfs-${zfs_num}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: zfs" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              for user_fs in /root /home; do
                zfs_num=$(( zfs_num+1 ))
                echo "    - pool: zpool-1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "      volume: USERDATA${user_fs}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "      properties:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "        canmount: 'on'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "        mountpoint: ${user_fs}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "      id: zfs-${zfs_num}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
                echo "      type: zfs" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              done

              echo "    - pool: zpool-0" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      volume: BOOT/${iso['zfsroot']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      properties:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        canmount: 'on'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "        mountpoint: /boot" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: zfs-1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: zfs" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - path: /boot/efi" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      device: format-0" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: mount-0" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: mount" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"


              echo "    swap:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      size: 0" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

            else
              # Creates rpool/ROOT/zfsroot
              echo "    - id: ${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: disk" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      ptable: gpt" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      path: /dev/${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      name: main_disk" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      wipe: superblock" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      grub_device: true" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - id: efi" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: partition" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      size: 2G" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      number: 1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      device: ${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      flag: boot" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      grub_device: true" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - id: ${iso['disk']}1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: partition" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      number: 2" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      size: -1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      device: ${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - id: efi_format" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: format" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      fstype: fat32" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      volume: efi" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      label: efi" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - id: ${iso['disk']}1_root" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: format" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      fstype: zfsroot" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      volume: ${iso['disk']}1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      label: 'rootfs'" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - id: ${iso['disk']}1_mount" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: mount" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      path: /" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      device: ${iso['disk']}1_root" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - id: efi_mount" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      device: efi_format" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      path: /boot/efi" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: mount" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            fi
          else

            echo "    - ptable: gpt" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      path: /dev/${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      wipe: superblock-recursive" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      grub_device: true" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      type: disk" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      id: disk-${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

            # EFI System Partition (512MB) - Required for UEFI

            echo "    - device: disk-${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      size: 1127219200" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      wipe: superblock" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      flag: boot" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      grub_device: true" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      type: partition" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      id: partition-efi" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

            echo "    - fstype: vfat" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      volume: partition-efi" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      type: format" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      id: format-efi" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

            echo "    - path: /boot/efi" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      device: format-efi" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      type: mount" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      id: mount-efi" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

            # Boot Partition (2GB)

            echo "    - device: disk-${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      size: 2147483648" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      wipe: superblock" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      grub_device: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      type: partition" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      id: partition-boot" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

            echo "    - fstype: ext4" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      volume: partition-boot" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      id: format-boot" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      type: format" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

            echo "    - path: /boot" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      device: format-boot" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      type: mount" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      id: mount-boot" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

            # Root Partition (LVM)

            echo "    - device: disk-${iso['disk']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      size: -1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      wipe: superblock" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      grub_device: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      type: partition" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      id: partition-root" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

            # LVM Volume Group

            echo "    - volume: partition-root" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      type: lvm_volgroup" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      id: ${iso['vgname']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      name: ${iso['vgname']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      devices:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      - partition-root" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

            # Logical Volume for Swap

            if [ "${options['swap']}" = "true" ]; then
              echo "    - volgroup: ${iso['vgname']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      name: ${iso['lvname']}-swap" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      size: ${iso['swapsize']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: lvm_partition" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: ${iso['lvname']}-swap" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            fi

            # Logical Volume for Root

            echo "    - volgroup: ${iso['vgname']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      name: ${iso['lvname']}-root" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      size: -1" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      type: lvm_partition" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      id: ${iso['lvname']}-root" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

            # Format and Mount Root Filesystem

            echo "    - fstype: ${iso_volmgr}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      volume: ${iso['lvname']}-root" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      type: format" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      id: format-root" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

            echo "    - path: /" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      device: format-root" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      type: mount" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "      id: mount-root" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

            # Format and Mount Swap

            if [ "${options['swap']}" = "true" ]; then
              echo "    - fstype: swap" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      volume: ${iso['lvname']}-swap" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      preserve: false" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: format" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: format-swap" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"

              echo "    - path: ''" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      device: format-swap" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      type: mount" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "      id: mount-swap" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            fi

          fi
        fi
        if [ "${options['reorderuefi']}" = "true" ]; then
          echo "    grub:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "      reorder_uefi: ${options['reorderuefi']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        fi
        echo "  early-commands:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        if [ "${options['grubparse']}" = "true" ] || [ "${options['grubparseall']}" = "true" ]; then
          for param in ${iso['grubparams']}; do
            grub_param="grub${param}"
            if [ ! "${iso[${grub_param}]}" = "" ]; then
              if [ "${param}" = "password" ]; then
                echo "    - \"sed -i \\\"s/${grub_param}/\$(cat /proc/cmdline |awk -F'${param}=' '{print \$2}' |awk '{print \$1}' |/usr/bin/openssl passwd -1 -stdin)/g\\\" /autoinstall.yaml\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              else
                echo "    - \"sed -i \\\"s/${grub_param}/\$(cat /proc/cmdline |awk -F'${param}=' '{print \$2}' |awk '{print \$1}')/g\\\" /autoinstall.yaml\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              fi
            fi
          done
        fi
        if [ "${iso['majorrelease']}" -gt 23 ] && [ "${options['nvme']}" = "true" ]; then
          echo "    - \"sed -i \\\"s/first-wwn/\$(lsblk -x TYPE -o NAME,WWN,TYPE |grep disk |sort |head -1 |awk '{print \$2}')/g\\\" /autoinstall.yaml\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    - \"sed -i \\\"s/first-serial/\$(udevadm info --query=all --name=\`lsblk -x TYPE |grep disk |sort |head -1 |awk '{print \$1}'\` |grep ID_SERIAL= |cut -f2 -d=)/g\\\" /autoinstall.yaml\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        fi
        if ! [ "${iso['allowlist']}" = "" ]; then
          if [[ "${iso['allowlist']}" =~ , ]]; then
            module_list=$(eval echo "${iso['allowlist']//,/ }")
            for module in ${module_list}; do
              echo "    - \"echo '${module}' > /etc/modules-load.d/${module}.conf\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "    - \"modprobe ${module}\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            done
          else
            echo "    - \"echo '${iso['allowlist']}' > /etc/modules-load.d/${iso['blocklist']}.conf\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"modprobe ${iso['allowlist']}\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
        fi
        if [ "${iso['disk']}" = "first-disk" ]; then
          if [ ! "${iso_volmgr}" = "auto" ]; then
            echo "    - \"sed -i \\\"s/first-disk/\$(lsblk -x TYPE|grep disk |sort |head -1 |awk '{print \$1}')/g\\\" /autoinstall.yaml\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
        fi
        if [ "${iso['nic']}" = "first-nic" ]; then
          echo "    - \"sed -i \\\"s/first-nic/\$(lshw -class network -short |awk '{print \$2}' |grep ^e |head -1)/g\\\" /autoinstall.yaml\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    - \"sed -i \\\"s/nvme\\\([0-9]\\\)n\\\([0-9]\\\)\\\([0-9]\\\)/nvme\\\1n\\\2p\\\3/g\\\" /autoinstall.yaml\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        fi
        num_debs=$( find "${iso['packagedir']}" -name "*.deb" |wc -l)
        if [ ! "${num_debs}" = "0" ] && [ "${options['earlypackages']}" = "true" ]; then
          echo "    - \"export DEBIAN_FRONTEND=\\\"noninteractive\\\" && dpkg ${iso['dpkgconf']} ${iso['dpkgoverwrite']} --auto-deconfigure ${iso['dpkgdepends']} -i ${iso['installmount']}/${iso['autoinstalldir']}/packages/*.deb\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        fi
        echo "    - \"rm /etc/resolv.conf\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        echo "    - \"echo \\\"nameserver ${iso['dns']}\\\" >> /etc/resolv.conf\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        if ! [ "${iso['blocklist']}" = "" ]; then
          if [[ "${iso['blocklist']}" =~ , ]]; then
            module_list=$(eval echo "${iso['blocklist']//,/ }")
            for module in ${module_list}; do
              echo "    - \"echo 'blacklist ${module}' > /etc/modprobe.d/${module}.conf\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              echo "    - \"modprobe -r ${module} --remove-dependencies\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            done
          else
            echo "    - \"echo 'blacklist ${iso['blocklist']}' > /etc/modprobe.d/${iso['blocklist']}.conf\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"modprobe -r ${iso['blocklist']} --remove-dependencies\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
        fi
        echo "  late-commands:" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        echo "    - \"echo \\\"DNS=${iso['dns']}\\\" >> ${iso['targetmount']}/etc/systemd/resolved.conf\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        echo "    - \"rm ${iso['targetmount']}/etc/resolv.conf\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        echo "    - \"echo \\\"nameserver ${iso['dns']}\\\" > ${iso['targetmount']}/etc/resolv.conf\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        echo "    - \"echo \\\"options ${iso['dnsoptions']}\\\" >> ${iso['targetmount']}/etc/resolv.conf\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        echo "    - \"echo \\\"search ${iso['searchdomain']}\\\" >> ${iso['targetmount']}/etc/resolv.conf\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        if [ ! "${num_debs}" = "0" ]; then
          if [ "${options['latepackages']}" = "true" ]; then
            echo "    - \"mkdir -p ${iso['targetmount']}/var/postinstall/packages\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"cp ${iso['installmount']}/${iso['autoinstalldir']}/packages/*.deb ${iso['targetmount']}/var/postinstall/packages/\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"echo '#!/bin/bash' > ${iso['targetmount']}/tmp/post.sh\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"echo 'export DEBIAN_FRONTEND=\\\"noninteractive\\\" && dpkg ${iso['dpkgconf']} ${iso['dpkgoverwrite']} --auto-deconfigure ${iso['dpkgdepends']} -i /var/postinstall/packages/*.deb' >> ${iso['targetmount']}/tmp/post.sh\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"chmod +x ${iso['targetmount']}/tmp/post.sh\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
          if [ "${iso_volmgr}" = "btrfs" ] && [ "${options['compression']}" = "true" ]; then
            echo "    - \"mount -o remount,compress=${iso['compression']},ssd /\`mount |grep ${iso_volmgr} |awk '{ print \$1 }'\` /target -t ${iso_volmgr}\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"sed -i \\\"s/${iso_volmgr} defaults/${iso_volmgr} compress=${iso['compression']},ssd/g\\\" ${iso['targetmount']}/etc/fstab\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"echo '#!/bin/bash' > ${iso['targetmount']}/tmp/post.sh\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"echo '${iso_volmgr} filesystem defragment -rc${iso['compression']} /' > ${iso['targetmount']}/tmp/post.sh\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"chmod +x ${iso['targetmount']}/tmp/post.sh\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
        fi
        echo "    - \"echo '${iso['timezone']}' > ${iso['targetmount']}/etc/timezone\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        echo "    - \"rm ${iso['targetmount']}/etc/localtime\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        echo "    - \"curtin in-target --target=${iso['targetmount']} -- ln -s /usr/share/zoneinfo/${iso['timezone']} /etc/localtime\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        if [ ! "${iso['country']}" = "us" ]; then
          echo "    - \"curtin in-target --target=${iso['targetmount']} -- sed -i \\\"s/\\\/archive/\\\/${iso['country']}.archive/g\\\" /etc/apt/sources.list\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        fi
        if [ ! "${num_debs}" = "0" ]; then
          if [ "${options['latepackages']}" = "true" ]; then
            if [ ! "${iso_volmgr}" = "btrfs" ] && [ ! "${iso_volmgr}" = "xfs" ]; then
              echo "    - \"curtin in-target --target=${iso['targetmount']} -- /tmp/post.sh\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            else
              if [ "${iso_volmgr}" = "btrfs" ] && [ "${options['compression']}" = "true" ]; then
                echo "    - \"curtin in-target --target=${iso['targetmount']} -- /tmp/post.sh\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              fi
            fi
          fi
        fi
        if [ ! "${iso['build']}" = "desktop" ]; then
          if [ "${options['serial']}" = "true" ]; then
            echo "    - \"echo 'GRUB_TERMINAL=\\\"serial console\\\"' >> ${iso['targetmount']}/etc/default/grub\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"echo 'GRUB_SERIAL_COMMAND=\\\"serial --speed=${iso['serialportspeeda']} --port=${iso['serialportaddressa']}\\\"' >> ${iso['targetmount']}/etc/default/grub\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          else
            echo "    - \"echo 'GRUB_TERMINAL=\\\"console\\\"' >> ${iso['targetmount']}/etc/default/grub\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
          echo "    - \"echo 'GRUB_CMDLINE_LINUX=\\\"console=tty0 ${iso['kernelargs']}\\\"' >> ${iso['targetmount']}/etc/default/grub\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    - \"echo 'GRUB_TIMEOUT=\\\"${iso['grubtimeout']}\\\"' >> ${iso['targetmount']}/etc/default/grub\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    - \"echo '${iso['username']} ALL=(ALL) NOPASSWD: ALL' >> ${iso['targetmount']}/etc/sudoers.d/${iso['username']}\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          if [ "${options['autoupgrade']}" = "false" ]; then
            echo "    - \"echo 'APT::Periodic::Update-Package-Lists \\\"0\\\";' > ${iso['targetmount']}/etc/apt/apt.conf.d/20auto-upgrades\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"echo 'APT::Periodic::Download-Upgradeable-Packages \\\"0\\\";' >> ${iso['targetmount']}/etc/apt/apt.conf.d/20auto-upgrades\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"echo 'APT::Periodic::AutocleanInterval \\\"0\\\";' >> ${iso['targetmount']}/etc/apt/apt.conf.d/20auto-upgrades\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"echo 'APT::Periodic::Unattended-Upgrade \\\"0\\\";' >> ${iso['targetmount']}/etc/apt/apt.conf.d/20auto-upgrades\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
          if [ "${options['serial']}" = "true" ]; then
            echo "    - \"curtin in-target --target=${iso['targetmount']} -- systemctl enable serial-getty@ttyS0.service\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"curtin in-target --target=${iso['targetmount']} -- systemctl start serial-getty@ttyS0.service\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"curtin in-target --target=${iso['targetmount']} -- systemctl enable serial-getty@ttyS1.service\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"curtin in-target --target=${iso['targetmount']} -- systemctl start serial-getty@ttyS1.service\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"curtin in-target --target=${iso['targetmount']} -- systemctl enable serial-getty@ttyS4.service\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            echo "    - \"curtin in-target --target=${iso['targetmount']} -- systemctl start serial-getty@ttyS4.service\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          fi
          echo "    - \"curtin in-target --target=${iso['targetmount']} -- systemctl enable ssh\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    - \"curtin in-target --target=${iso['targetmount']} -- systemctl start ssh\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          echo "    - \"curtin in-target --target=${iso['targetmount']} -- update-grub\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
          if [ "${options['networkupdates']}" = "true" ]; then
            if [ "${options['packageupdates']}" = "true" ] || [ "${options['distupgrade']}" = "true" ]; then
              echo "    - \"curtin in-target --target=${iso['targetmount']} -- apt update\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            fi
            if [ "${options['packageupgrades']}" = "true" ]; then
              echo "    - \"curtin in-target --target=${iso['targetmount']} -- apt upgrade -y\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            fi
            if [ "${options['distupgrade']}" = "true" ]; then
              echo "    - \"curtin in-target --target=${iso['targetmount']} -- apt dist-upgrade -y\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            fi
            if [ "${options['installpackages']}" = "true" ]; then
              echo "    - \"curtin in-target --target=${iso['targetmount']} -- apt install -y ${iso['packages']}\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
            fi
            if [ "${iso['majorrelease']}" = "22" ]; then
              if [ "${options['aptnews']}" = "false" ]; then
                echo "    - \"curtin in-target --target=${iso['targetmount']} -- pro config set apt_news=false\"" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
              fi
            fi
          fi
        fi
#        echo "  updates: ${iso['updates']}" >> "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
        print_file "${iso['configdir']}/${iso_volmgr}/${iso['disk']}/user-data"
      fi
    fi
  done
}

# Function: handle_ubuntu_pro
#
# Handle Ubuntu Pro Apt News etc

handle_ubuntu_pro () {
  if [ "${iso['realname']}" = "Ubuntu" ]; then
    if [ "${iso['majorrelease']}" -ge 22 ]; then
      iso['packages']="${iso['packages']} ubuntu-advantage-tools"
      iso['chrootpackages']="${iso['chrootpackages']} ubuntu-advantage-tools"
    fi
  fi
}

# Function: copy_custom_user_data
#
# Copy the custome user-data file to a place we can get to it whne running in docker

copy_custom_user_data () {
  if [ "${options['autoinstall']}" = "true" ]; then
    if [ ! -f "/.dockerenv" ]; then
      if [ ! -d "${iso['workdir']}/files" ]; then
        execute_command "mkdir -p ${iso['workdir']}/files"
      fi
      cp "${iso['autoinstallfile']}" "${iso['workdir']}/files/user-data"
    fi
  fi
}
