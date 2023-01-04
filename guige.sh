
#!/bin/bash

# Name:         guige (Generic Ubuntu ISO Generation Engine)
# Version:      0.0.4
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: Ubuntu Linux
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Shell script designed to simplify creation of custom Ubuntu

# Defaults

args=$@
default_release=$(lsb_release -cs)
default_hostname="ubuntu"
default_realname="Ubuntu"
default_username="ubuntu"
default_timezome="Australia/Melbourne"
default_password="P455w0rD"
release=""
hostname=""
realname=""
username=""
timezome=""
password=""
arch="amd64"
test_mode="1"
verbose_mode="1"
default_mode="0"
interactve_mode="0"
verbose_switch=""
grub_timeout="10"
chroot_packages=""
default_packages="zfsutils-linux grub-efi zfs-initramfs net-tools curl wget"
required_packages="p7zip-full wget xorriso whois"

# Default work directories

work_dir=$HOME/ubuntu-iso
iso_mount_dir="$work_dir/isomount"
iso_new_dir="$work_dir/isonew"
iso_source_dir="$work_dir/source-files"
install_dir="autoinstall"
install_mount="/cdrom"

# Default file names/locations

iso_file="$work_dir/$release-live-server-$arch.iso"
squashfs_file="$iso_mount_dir/casper/ubuntu-server-minimal.squashfs"
grub_fule="$work_dir/grub.cfg"
sda_user_file="$work_dir/sda-user-data"
vda_user_file="$work_dir/vda-user-data"

# Get the path the script starts from

start_path=$( pwd )

# Get the version of the script from the script itself

script_version=$( cd $start_path ; cat $0 | grep '^# Version' | awk '{print $3}' )

# Function: Print help

print_help () {
  cat <<-HELP
  Usage: ${0##*/} [OPTIONS...]
    -h  Help/Usage Information
    -V  Script Version
    -v  Verbose output
    -t  Test mode
    -D  Use defaultd
    -I  Interactive mode (will ask for input rather than using command line options or defaults)
    -p  Packages to add to ISO
    -P  Password
    -U  Username
    -R  Realname
    -H  Hostname
    -T  Timezone
HELP
}

# If given no command line arguments print usage information

if [ $( expr "$args" : "\-" ) != 1 ]; then
  print_help
  exit
fi

# Function: Handle output

handle_output () {
  output_text=$1
  verbose_mode=$2
  test_mode=$3
  if [ "$verbose_mode" = "1" ]; then
    if [ "$test_mode" = "1" ]; then
      echo '$output_text'
    else
      echo 'Executing: $output_text'
    fi
  fi
}

# Function: Execute command and enable debug or script writing mode

execute_command () {
  command=$1
  verbose_mode=$2
  test_mode=$3
  handle_output $command $verbose_mode $test_mode
  if [ "$test_mode" = "0" ]; then
    $commmand
  fi
}


# Function: Check work directories exist
#
# mkdir -p ./isomount ./isonew/squashfs ./isonew/cd ./isonew/custom

check_work_dir_exists () {
  verbose_mode=$1
  test_mode=$2
  for iso_dir in $iso_mount_dir $iso_new_dir new_dir/cd $iso_new_dir/custom; do
    if ! [ -d "$iso_dir" ]; then
      execute_command "mkdir -p $iso_dir"
    fi
  done
}

# Function: Install required packages
#
# sudo apt install -y p7zip-full wget xorriso

install_required_packages () {
  verbose_mode=$1
  test_mode=$2
  for package in $required_packages; do
    version=$(apt show $package 2>&1 |grep Version)
    if ! [ -x "$version" ]; then
      execute_command "sudo apt install -y $package"
    fi
  done
}

# Grab ISO from Ubuntu
# 
# https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/jammy-live-server-amd64.iso
# wget https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.1-live-server-amd64.iso

get_base_iso () {
  verbose_mode=$1
  test_mode=$2
  release=$2
  iso_file=$4
  base_iso_file=$(basename $iso_file)
  iso_url="https://cdimage.ubuntu.com/ubuntu-server/$release/daily-live/$base_iso_file"
  if ! [ -f "$work_dir/$iso_file" ]; then
    execute_command "cd $work_dir ; wget $iso_url"
  fi
}

# Mount base ISO as loopback device so contents can be copy
#
# sudo mount -o loop ./ubuntu-22.04.1-live-server-arm64.iso ./isomount
# sudo mount -o loop ./ubuntu-22.04.1-live-server-amd64.iso ./isomount

mount_iso () {
  release=$1
  iso_file=$2
  iso_mount_dir=$3
  get_base_iso $release $iso_file
  execute_command "sudo mount -o loop $work_dir/$iso_file $iso_mount_dir"
}

# Copy contents of ISO to a RW location so we can work with them
#
# rsync --exclude=/casper/ubuntu-server-minimal.squashfs -av ./isomount/ ./isonew/cd
# rsync -av ./isomount/ ./isonew/cd

copy_iso () {
  iso_mount_dir=$1
  iso_new_dir=$2
  verbose_switch=$3
  execute_command "cd $work_dir ; rsync -a$verbose_switch $iso_mount_dir/ $iso_new_dir/cd"
}

# Mount squashfs and copy giles into it
#
# sudo mount -t squashfs -o loop ./isomount/casper/ubuntu-server-minimal.squashfs ./isonew/squashfs/
# sudo rsync -av ./isonew/squashfs/ ./isonew/custom
# sudo cp /etc/resolv.conf /etc/hosts ./isonew/custom/etc/
# sudo cp /etc/apt/sources.list ./isonew/custom/etc/apt/

copy_squashfs () {
  iso_mount_dir=$1
  iso_new_dir=$2
  squashfs_file=$3
  verbose_switch=$4
  execute_command "sudo mount -t squashfs -o loop $squashfs_file $iso_new_dir/squashfs/"
  execute_command "sudo rsync -a$verbose_switch . $iso_new_dir/squashfs/ $iso_new_dir/custom"
  execute_command "sudo cp /etc/resolv.conf /etc/hosts $iso_new_dir/custom/etc/"
  execute_command "sudo cp /etc/apt/sources.list $iso_new_dir/etc/apt/"
}

# Chroot into environment and run script on chrooted environmnet
#
# sudo chroot ./isonew/custom

execute_chroot_script () {
  iso_new_dir=$1
  execute_command "sudo chroot $iso_new_dir/custom /tmp/modify_chroot.sh"
}

# Create script to drop into chrooted environment
# Inside chrooted environment, mount filesystems and packages
# 
# mount -t proc none /proc/
# mount -t sysfs none /sys/
# mount -t devpts none /dev/pts
# export HOME=/root
# sudo apt update
# sudo apt install -y --download-only zfsutils-linux grub-efi zfs-initramfs net-tools curl wget
# sudo apt install -y zfsutils-linux grub-efi zfs-initramfs net-tools curl wget
# umount /proc/
# umount /sys/
# umount /dev/pts/
# exit

create_chroot_script () {
  iso_new_dir=$1
  orig_script="$work_dir/modify_chroot.sh"
  chroot_script="$iso_new_dir/custom/tmp/modify_chroot.sh"
  if ! [ -f "$orig_script" ]; then
    execute_command 'echo "#!/usr/bin/bash" > $orig_script'
    execute_command 'echo "mount -t proc none /proc/" >> $orig_script'
    execute_command 'echo "mount -t sysfs none /sys/" >> $orig_script'
    execute_command 'echo "mount -t devpts none /dev/pts" >> $orig_script'
    execute_command 'echo "export HOME=/root" >> $orig_script'
    execute_command 'echo "sudo apt update" >> $orig_script'
    execute_command 'echo "sudo apt install -y --download-only $chroot_packages" >> $orig_script'
    execute_command 'echo "sudo apt install -y $chroot_packages" >> $orig_script'
    execute_command 'echo "umount /proc/" >> $orig_script'
    execute_command 'echo "umount /sys/" >> $orig_script'
    execute_command 'echo "umount /dev/pts/" >> $orig_script'
    execute_command 'echo "exit" >> $orig_script'
  fi
  if ! [ -f "$chroot_script" ]; then
    execute_command "sudo cp $orig_script $chroot_script"
    execute_command "sudo chmod +x $chroot_script"
  fi
}

# Get password crypt
#
# echo test |mkpasswd --method=SHA-512 --stdin

get_password_crypt () {
  password=$1
  password_crypt=$(echo $password |mkpasswd --method=SHA-512 --stdin)
}

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
# export append_partition=$(xorriso -indev ubuntu-22.04.1-live-server-amd64.iso -report_el_torito as_mkisofs |grep append_partition |tail -1 |awk '{print $3}' 2>&1)
# export iso_mbr_part_type=$(xorriso -indev ubuntu-22.04.1-live-server-amd64.iso -report_el_torito as_mkisofs |grep iso_mbr_part_type |tail -1 |awk '{print $2}' 2>&1)
# xorriso -as mkisofs -r -V 'Ubuntu-Server 22.04.1 LTS arm64' -o ../ubuntu-22.04-autoinstall-arm64.iso --grub2-mbr \
# ../BOOT/Boot-NoEmul.img -partition_offset 16 --mbr-force-bootable -append_partition 2 $append_partition ../BOOT/Boot-NoEmul.img \
# -appended_part_as_gpt -iso_mbr_part_type $iso_mbr_part_type -c '/boot/boot.cat' -e '--interval:appended_partition_2:::' -no-emul-boot

prepare_autoinstall_iso () {
  iso_source_dir=$1
  iso_custom_dir=$2
  install_dir=$3
  install_mount=$4
  iso_file=$5
  grub_timeout=$6
  password=$7
  output_file="autoinstall-$iso_file"
  get_password_crypt $password
  package_dir="$iso_source_dir/$install_dir/packages/"
  config_dir="$iso_source_dir/$install_dir/configs/"
  execute_command "cd $work_dir ; mv $iso_source_dir/\[BOOT\] ./BOOT"
  execute_command "mkdir -p $package_dir"
  cd $work_dir ; 7z -y x $work_dir/$iso_file -o$iso_source_dir
  for sub_dir in sda vda; do
    execute_command "mkdir -p $config_dir/$sub_dir"
    execute_command "touch $config_dir/$sub_dir/meta-data"
  done
  execute_command "cp $iso_custom_dir/var/cache/apt/archives/*.dev $package_dir"
  if [ -f "$work_dir/grub.cfg" ]; then
    execute_command "cp $work_dir/grub.cfg $iso_source_dir/boot/grub/grub.cfg"
  else
    echo "set timeout=$grub_timeout" > $iso_source_dir/boot/grub/grub.cfg
    echo "loadfont unicode" >> $iso_source_dir/boot/grub/grub.cfg
    echo "menuentry "Autoinstall Ubuntu Server - Physical" {" >> $iso_source_dir/boot/grub/grub.cfg
    echo "  set gfxpayload=keep" >> $iso_source_dir/boot/grub/grub.cfg
    echo "  linux   /casper/vmlinuz quiet autoinstall ds=nocloud\;s=/$install_mount/$install_dirs/configs/sda/  ---" >> $iso_source_dir/boot/grub/grub.cfg
    echo "  initrd  /casper/initrd" >> $iso_source_dir/boot/grub/grub.cfg
    echo "}" >> $iso_source_dir/boot/grub/grub.cfg
    echo "  menuentry "Autoinstall Ubuntu Server - Virtual - KVM" {" >> $iso_source_dir/boot/grub/grub.cfg
    echo "  set gfxpayload=keep" >> $iso_source_dir/boot/grub/grub.cfg
    echo "  linux   /casper/vmlinuz quiet autoinstall ds=nocloud\;s=/$install_mount/$install_dirs/configs/vda/  ---" >> $iso_source_dir/boot/grub/grub.cfg
    echo "  initrd  /casper/initrd" >> $iso_source_dir/boot/grub/grub.cfg
    echo "}" >> $iso_source_dir/boot/grub/grub.cfg
    echo "menuentry "Try or Install Ubuntu Server" {" >> $iso_source_dir/boot/grub/grub.cfg
    echo "  set gfxpayload=keep" >> $iso_source_dir/boot/grub/grub.cfg
    echo "  linux /casper/vmlinuz quiet ---" >> $iso_source_dir/boot/grub/grub.cfg
    echo "  initrd  /casper/initrd" >> $iso_source_dir/boot/grub/grub.cfg
    echo "}" >> $iso_source_dir/boot/grub/grub.cfg
    echo "menuentry 'Boot from next volume' {" >> $iso_source_dir/boot/grub/grub.cfg
    echo "  exit 1" >> $iso_source_dir/boot/grub/grub.cfg
    echo "}" >> $iso_source_dir/boot/grub/grub.cfg
    echo "menuentry 'UEFI Firmware Settings' {" >> $iso_source_dir/boot/grub/grub.cfg
    echo "  fwsetup" >> $iso_source_dir/boot/grub/grub.cfg
    echo "}" >> $iso_source_dir/boot/grub/grub.cfg
  fi
  for device in sda vda; do 
    if [ -f "$device-user-data" ]; then
      execute_command "cp $device-user-data $config_dir/$device/user-data"
    else
      echo "#cloud-config" > $config_dir/$device/user-data
      echo "autoinstall:" >> $config_dir/$device/user-data
      echo "  apt:" >> $config_dir/$device/user-data
      echo "    preferences:" >> $config_dir/$device/user-data
      echo "      - package: \"*\"" >> $config_dir/$device/user-data
      echo "        pin: \"release a=$release-security\"" >> $config_dir/$device/user-data
      echo "        pin-priority: 200" >> $config_dir/$device/user-data
      echo "    disable_components: []" >> $config_dir/$device/user-data
      echo "    geoip: true" >> $config_dir/$device/user-data
      echo "    preserve_sources_list: false" >> $config_dir/$device/user-data
      echo "    primary:" >> $config_dir/$device/user-data
      echo "    - arches:" >> $config_dir/$device/user-data
      echo "      - $arch" >> $config_dir/$device/user-data
      echo "      uri: http://archive.ubuntu.com/ubuntu" >> $config_dir/$device/user-data
      echo "    - arches:" >> $config_dir/$device/user-data
      echo "      - default" >> $config_dir/$device/user-data
      echo "      uri: http://ports.ubuntu.com/ubuntu-ports" >> $config_dir/$device/user-data
      echo "  package_update: false" >> $config_dir/$device/user-data
      echo "  package_upgrade: false" >> $config_dir/$device/user-data
      echo "  drivers:" >> $config_dir/$device/user-data
      echo "    install: false" >> $config_dir/$device/user-data
      echo "  user-data:" >> $config_dir/$device/user-data
      echo "    timezone: $timezome" >> $config_dir/$device/user-data
      echo "  identity:" >> $config_dir/$device/user-data
      echo "    hostname: $hostname" >> $config_dir/$device/user-data
      echo "    password: \"$password_crypt\"" >> $config_dir/$device/user-data
      echo "    realname: $realname" >> $config_dir/$device/user-data
      echo "    username: $username" >> $config_dir/$device/user-data
      echo "  kernel:" >> $config_dir/$device/user-data
      echo "    package: linux-generic" >> $config_dir/$device/user-data
      echo "  keyboard:" >> $config_dir/$device/user-data
      echo "    layout: us" >> $config_dir/$device/user-data
      echo "  locale: en_US.UTF-8" >> $config_dir/$device/user-data
      echo "  network:" >> $config_dir/$device/user-data
      echo "    ethernets:" >> $config_dir/$device/user-data
      echo "      ens33:" >> $config_dir/$device/user-data
      echo "        critical: true" >> $config_dir/$device/user-data
      echo "        dhcp-identifier: mac" >> $config_dir/$device/user-data
      echo "        dhcp4: true" >> $config_dir/$device/user-data
      echo "    version: 2" >> $config_dir/$device/user-data
      echo "  ssh:" >> $config_dir/$device/user-data
      echo "    allow-pw: true" >> $config_dir/$device/user-data
      echo "    authorized-keys: []" >> $config_dir/$device/user-data
      echo "    install-server: true" >> $config_dir/$device/user-data
      echo "  storage:" >> $config_dir/$device/user-data
      echo "    config:" >> $config_dir/$device/user-data
      echo "    - ptable: gpt" >> $config_dir/$device/user-data
      echo "      path: /dev/$device" >> $config_dir/$device/user-data
      echo "      wipe: superblock-recursive" >> $config_dir/$device/user-data
      echo "      preserve: false" >> $config_dir/$device/user-data
      echo "      name: ''" >> $config_dir/$device/user-data
      echo "      grub_device: true" >> $config_dir/$device/user-data
      echo "      type: disk" >> $config_dir/$device/user-data
      echo "      id: disk1" >> $config_dir/$device/user-data
      echo "    - device: disk1" >> $config_dir/$device/user-data
      echo "      size: 1127219200" >> $config_dir/$device/user-data
      echo "      wipe: superblock-recursive" >> $config_dir/$device/user-data
      echo "      flag: boot" >> $config_dir/$device/user-data
      echo "      number: 1" >> $config_dir/$device/user-data
      echo "      preserve: false" >> $config_dir/$device/user-data
      echo "      grub_device: true" >> $config_dir/$device/user-data
      echo "      type: partition" >> $config_dir/$device/user-data
      echo "      ptable: gpt" >> $config_dir/$device/user-data
      echo "      id: disk1p1" >> $config_dir/$device/user-data
      echo "    - fstype: fat32" >> $config_dir/$device/user-data
      echo "      volume: disk1p1" >> $config_dir/$device/user-data
      echo "      preserve: false" >> $config_dir/$device/user-data
      echo "      type: format" >> $config_dir/$device/user-data
      echo "      id: disk1p1fs1" >> $config_dir/$device/user-data
      echo "    - path: /boot/efi" >> $config_dir/$device/user-data
      echo "      device: disk1p1fs1" >> $config_dir/$device/user-data
      echo "      type: mount" >> $config_dir/$device/user-data
      echo "      id: mount-2" >> $config_dir/$device/user-data
      echo "    - device: disk1" >> $config_dir/$device/user-data
      echo "      size: -1" >> $config_dir/$device/user-data
      echo "      wipe: superblock-recursive" >> $config_dir/$device/user-data
      echo "      flag: root" >> $config_dir/$device/user-data
      echo "      number: 2" >> $config_dir/$device/user-data
      echo "      preserve: false" >> $config_dir/$device/user-data
      echo "      grub_device: false" >> $config_dir/$device/user-data
      echo "      type: partition" >> $config_dir/$device/user-data
      echo "      id: disk1p2" >> $config_dir/$device/user-data
      echo "    - id: disk1p2fs1" >> $config_dir/$device/user-data
      echo "      type: format" >> $config_dir/$device/user-data
      echo "      fstype: zfsroot" >> $config_dir/$device/user-data
      echo "      volume: disk1p2" >> $config_dir/$device/user-data
      echo "      preserve: false" >> $config_dir/$device/user-data
      echo "    - id: disk1p2f1_rootpool" >> $config_dir/$device/user-data
      echo "      mountpoint: /" >> $config_dir/$device/user-data
      echo "      pool: rpool" >> $config_dir/$device/user-data
      echo "      type: zpool" >> $config_dir/$device/user-data
      echo "      device: disk1p2fs1" >> $config_dir/$device/user-data
      echo "      preserve: false" >> $config_dir/$device/user-data
      echo "      vdevs:" >> $config_dir/$device/user-data
      echo "        - disk1p2fs1" >> $config_dir/$device/user-data
      echo "    - id: disk1_rootpool_container" >> $config_dir/$device/user-data
      echo "      pool: disk1p2f1_rootpool" >> $config_dir/$device/user-data
      echo "      preserve: false" >> $config_dir/$device/user-data
      echo "      properties:" >> $config_dir/$device/user-data
      echo "        canmount: "off"" >> $config_dir/$device/user-data
      echo "        mountpoint: "none"" >> $config_dir/$device/user-data
      echo "      type: zfs" >> $config_dir/$device/user-data
      echo "      volume: /ROOT" >> $config_dir/$device/user-data
      echo "    - id: disk1_rootpool_rootfs" >> $config_dir/$device/user-data
      echo "      pool: disk1p2f1_rootpool" >> $config_dir/$device/user-data
      echo "      preserve: false" >> $config_dir/$device/user-data
      echo "      properties:" >> $config_dir/$device/user-data
      echo "        canmount: noauto" >> $config_dir/$device/user-data
      echo "        mountpoint: /" >> $config_dir/$device/user-data
      echo "      type: zfs" >> $config_dir/$device/user-data
      echo "      volume: /ROOT/zfsroot" >> $config_dir/$device/user-data
      echo "    - path: /" >> $config_dir/$device/user-data
      echo "      device: disk1p2fs1" >> $config_dir/$device/user-data
      echo "      type: mount" >> $config_dir/$device/user-data
      echo "      id: mount-disk1p2" >> $config_dir/$device/user-data
      echo "    swap:" >> $config_dir/$device/user-data
      echo "      swap: 0" >> $config_dir/$device/user-data
      echo "  early-commands:" >> $config_dir/$device/user-data
      echo "    - \"sudo dpkg --auto-deconfigure --force-depends -i /$install_mount/$install_dir/packages/*.deb\"" >> $config_dir/$device/user-data
      echo "  version: 1" >> $config_dir/$device/user-data
    fi
  done
  cd $work_dir ; export append_part=$(xorriso -indev $iso_file -report_el_torito as_mkisofs |grep append_partition |tail -1 |awk '{print $3}' 2>&1)
  cd $work_dir ; export iso_mbr_part_type=$(xorriso -indev $iso_file -report_el_torito as_mkisofs |grep iso_mbr_part_type |tail -1 |awk '{print $2}' 2>&1)
  execute_command "cd $iso_source_dir ; xorriso -as mkisofs -r -V 'Ubuntu 22.04 LTS AUTO (EFIBIOS)' -o ../$output_file \
  --grub2-mbr ../BOOT/1-Boot-NoEmul.img -partition_offset 16 --mbr-force-bootable \
  -append_partition 2 $append_part ../BOOT/2-Boot-NoEmul.img -appended_part_as_gpt \
  -iso_mbr_part_type $iso_mbr_part_type -c /boot.catalog -b /boot/grub/i386-pc/eltorito.img \
  -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info -eltorito-alt-boot \
  -e '--interval:appended_partition_2:::' -no-emul-boot ."
}

# Set function variables

do_required_packages="0"
do_check_work_dir="0"

# Handle command line arguments

while getopts ":dhH:hIi:P:p:U:u:Vv" args; do
  case $args in
    V)
      echo $script_version
      exit
      ;;
    h)
      print_help
      exit
      ;;
    v)
      verbose_mode="1"
      ;;
    t)
      test_mode="1"
      ;;
    d)
      function="download"
      ;;
    D)
      default_mode="1"
      ;;
    i)
      iso_file="$OPTARG"
      ;;
    I)
      interactive_mode="I"
      ;;
    p)
      chroot_packages="$OPTARG"
      ;;
    P)
      password="$OPTARG"
      ;;
    r)
      install_required_packages $verbose_mode $test_mode
      ;;
    R)
      realname="$OPTARG"
      ;;
    T)
      timezome="$OPTARG"
      ;;
    U)
      username="$OPTARG"
      ;;
    W)
      work_dir="$OPTARG"
      ;;
    w)
      check_work_dir_exists $verbose_mode $test_mode 
      ;;
  esac
done

# Set any unset values to defaults

if [ "$interactve_mode" == "1" ]; then
  echo "Enter hostname:"
  read hostname
  echo "Enter timezome"
  read timezome
  echo "Enter username:"
  read username
  echo "Enter user real name"
  enter realname
  echo "Enter password:"
  read -s password
  echo "Additional packages:"
  read chroot_packages
else
  if [ "$username" = "" ] || [ "$default_mode" = "1" ]; then
    username=$default_username
  fi
  if [ "$realname" = "" ] || [ "$default_mode" = "1" ]; then
    realname=$default_realname
  fi
  if [ "$hostname" = "" ] || [ "$default_mode" = "1" ]; then
    hostname = $default_hostname
  fi
  if [ "$password" = "" ] || [ "$default_mode" = "1" ]; then
    password = $default_password
  fi
  if [ "$chroot_packages" = "" ] || [ "$default_mode" = "1" ]; then
    chroot_packages = $default_packages
  fi
  if [ "$timezome" = "" ] || [ "$default_mode" = "1" ]; then
    timezome = $default_timezome
  fi
fi

# Check work directories
# Check required packages are installed
# Check we have a base iso to work with

check_work_dir_exists $verbose_mode $test_mode
if [ "$function" = "required" ]; then
  install_required_packages $verbose_mode $test_mode
fi
if [ "$function" = "download" ]; then
  get_base_iso $verbose_mode $test_mode $release $iso_file
  exit
else
  get_base_iso $verbose_mode $test_mode $release $iso_file
fi

# Handle specific functions

