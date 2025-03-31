#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034

# Function: process_switches
#
# Process switches

process_switches () {
  if [ "$ISO_COMPRESSION" = "" ]; then
    ISO_COMPRESSION="$DEFAULT_ISO_COMPRESSION"
  fi
  if [ "$ISO_DISKSERIAL" = "" ]; then
    ISO_DISKSERIAL="$DEFAULT_ISO_DISKSERIAL"
  fi
  if [ "$ISO_DISK_WWN" = "" ]; then
    ISO_DISK_WWN="$DEFAULT_ISO_DISK_WWN"
  fi
  if [ "$ISO_UPDATES" = "" ]; then
    ISO_UPDATES="$DEFAULT_ISO_UPDATES"
  fi
  if [ "$ISO_FALLBACK" = "" ]; then
    ISO_FALLBACK="$DEFAULT_ISO_FALLBACK"
  fi
  if [ "$ISO_VGNAME" = "" ]; then
    ISO_VGNAME="$DEFAULT_ISO_VGNAME"
  else
    if [ "$ISO_PVNAME" = "" ]; then
      ISO_PVNAME="${ISO_VGNAME}-pv"
    fi
    if [ "$ISO_LVNAME" = "" ]; then
      ISO_LVNAME="${ISO_VGNAME}-lv"
    fi
  fi
  if [ "$ISO_PVNAME" = "" ]; then
    ISO_PVNAME="$DEFAULT_ISO_PVNAME"
  fi
  if [ "$ISO_LVNAME" = "" ]; then
    ISO_LVNAME="$DEFAULT_ISO_LVNAME"
  fi
  if [ "$ISO_DISK_NAME" = "" ]; then
    ISO_DISK_NAME="$DEFAULT_ISO_DISK_NAME"
  fi
  if [ "$ISO_INSTALLUSERNAME" = "" ]; then
    ISO_INSTALLUSERNAME="$DEFAULT_ISO_INSTALLUSERNAME"
  fi
  if [ "$ISO_INSTALLPASSWORD" = "" ]; then
    ISO_INSTALLPASSWORD="$DEFAULT_ISO_INSTALLPASSWORD"
  fi
  if [ "$ISO_PESIZE" = "" ]; then
    ISO_PESIZE="$DEFAULT_ISO_PESIZE"
  fi
  if [ "$ISO_BOOTSIZE" = "" ]; then
    ISO_BOOTSIZE="$DEFAULT_ISO_BOOTSIZE"
  fi
  if [ "$ISO_ROOTSIZE" = "" ]; then
    ISO_ROOTSIZE="$DEFAULT_ISO_ROOTSIZE"
  fi
  if [ "$ISO_SELINUX" = "" ]; then
    ISO_SELINUX="$DEFAULT_ISO_SELINUX"
  fi
  if [ "$ISO_INSTALLSOURCE" = "" ]; then
    ISO_INSTALLSOURCE="$DEFAULT_ISO_INSTALLSOURCE"
  fi
  if [ "$ISO_GROUPS" = "" ]; then
    ISO_GROUPS="$DEFAULT_ISO_GROUPS"
  fi
  if [ "$ISO_GECOS" = "" ]; then
    ISO_GECOS="$DEFAULT_ISO_GECOS"
  fi
  if [ "$ISO_ENABLESERVICE" = "" ]; then
    ISO_ENABLESERVICE="$DEFAULT_ISO_ENABLESERVICE"
  fi
  if [ "$ISO_DISABLESERVICE" = "" ]; then
    ISO_DISABLESERVICE="$DEFAULT_ISO_DISABLESERVICE"
  fi
  if [ "$ISO_ONBOOT" = "" ]; then
    ISO_ONBOOT="$DEFAULT_ISO_ONBOOT"
  fi
  if [ "$ISO_ALLOWSERVICE" = "" ]; then
    ISO_ALLOWSERVICE="$DEFAULT_ISO_ALLOWSERVICE"
  fi
  if [ "$ISO_FIREWALL" = "" ]; then
    ISO_FIREWALL="$DEFAULT_ISO_FIREWALL"
  fi
  if [ "$ISO_SELINUX" = "" ]; then
    ISO_SELINUX="$DEFAULT_ISO_SELINUX"
  fi
  if [ "$ISO_BOOTLOADER" = "" ]; then
    ISO_BOOTLOADER="$DEFAULT_ISO_BOOTLOADER"
  fi
  if [ "$ISO_PASSWORDALGORITHM" = "" ]; then
    ISO_PASSWORDALGORITHM="$DEFAULT_ISO_PASSWORDALGORITHM"
  fi
  if [ "$ISO_INSTALLMODE" = "" ]; then
    ISO_INSTALLMODE="$DEFAULT_ISO_INSTALLMODE"
  fi
  if [ "$DO_ISO_AUTOINSTALL" = "true" ]; then
    if [ ! -f "$ISO_AUTOINSTALLFILE" ]; then
      if [ ! -f "/.dockerenv" ]; then
        echo "File $ISO_AUTOINSTALLFILE does not exist"
        exit
      fi
    fi
  fi
  if [ "$ISO_SOURCEID" = "" ]; then
    ISO_SOURCEID="$DEFAULT_ISO_SOURCEID"
  fi
  if [ "$ISO_OEMINSTALL" = "" ]; then
    ISO_OEMINSTALL="$DEFAULT_ISO_OEMINSTALL"
  fi
  if [ "$ISO_ZFSFILESYSTEMS" = "" ]; then
    ISO_ZFSFILESYSTEMS="$DEFAULT_ISO_ZFSFILESYSTEMS"
  fi
  if [ "$ISO_SEARCH" = "" ]; then
    ISO_SEARCH="$DEFAULT_ISO_SEARCH"
  fi
  if [ "$ISO_BLOCKLIST" = "" ]; then
    ISO_BLOCKLIST="$DEFAULT_ISO_BLOCKLIST"
  fi
  if [ "$ISO_ALLOWLIST" = "" ]; then
    ISO_ALLOWLIST="$DEFAULT_ISO_ALLOWLIST"
  fi
  if [ "$ISO_COUNTRY" = "" ]; then
    ISO_COUNTRY="$DEFAULT_ISO_COUNTRY"
  fi
  if [[ "$ISO_SERIALPORT0" =~ "," ]]; then
      ISO_SERIALPORT0=$(echo "$ISO_SERIALPORT0" |cut -f1 -d,)
      ISO_SERIAL_PORT1=$(echo "$ISO_SERIAL_PORT1" |cut -f2 -d,)
  else
    if [ "$ISO_SERIALPORT0" = "" ]; then
      ISO_SERIALPORT0="$DEFAULT_ISO_SERIALPORT0"
      ISO_SERIAL_PORT1="$DEFAULT_ISO_SERIAL_PORT1"
    fi
  fi
  if [[ "$ISO_SERIALPORTADDRESS0" =~ "," ]]; then
    ISO_SERIALPORTADDRESS0=$(echo "$ISO_SERIALPORTADDRESS0" |cut -f1 -d,)
    ISO_SERIAL_PORT_ADDRESS1=$(echo "$ISO_SERIAL_PORT_ADDRESS1" |cut -f2 -d,)
  else
    if [ "$ISO_SERIALPORTADDRESS0" = "" ]; then
      ISO_SERIALPORTADDRESS0="$DEFAULT_ISO_SERIALPORTADDRESS0"
      ISO_SERIAL_PORT_ADDRESS1="$DEFAULT_ISO_SERIAL_PORT_ADDRESS1"
    fi
  fi
  if [ "$ISO_SERIALPORTSPEED0" = "" ]; then
    ISO_SERIALPORTSPEED0=$(echo "$DEFAULT_ISO_SERIALPORTSPEED0" |cut -f1 -d,)
    ISO_SERIAL_PORT_SPEED1=$(echo "$DEFAULT_ISO_SERIAL_PORT_SPEED1" |cut -f2 -d,)
  else
    if [ "$ISO_SERIALPORTSPEED0" = "" ]; then
      ISO_SERIALPORTSPEED0="$DEFAULT_ISO_SERIALPORTSPEED0"
      ISO_SERIAL_PORT_SPEED1="$DEFAULT_ISO_SERIAL_PORT_SPEED1"
    fi
  fi
  if [ "$ISO_ARCH" = "" ]; then
    ISO_ARCH="$DEFAULT_ISO_ARCH"
    DOCKER_ARCH="$DEFAULT_DOCKER_ARCH"
  else
    DOCKER_ARCH="$ISO_ARCH"
  fi
  if [ "$ISO_BOOT_TYPE" = "" ]; then
    ISO_BOOT_TYPE="$DEFAULT_ISO_BOOT_TYPE"
  fi
  if [ "$ISO_SSHKEYFILE" = "" ]; then
    ISO_SSHKEYFILE="$DEFAULT_ISO_SSHKEYFILE"
  else
    ISO_SSHKEY="$DEFAULT_ISO_SSHKEY"
  fi
  if [ "$ISO_BOOTSERVERIP" = "" ]; then
    ISO_BOOTSERVERIP="$DEFAULT_ISO_BOOTSERVERIP"
  fi
  if [ "$ISO_BOOTSERVERFILE" = "" ]; then
    ISO_BOOTSERVERFILE="$DEFAULT_ISO_BOOTSERVERFILE"
  fi
  if [ "$ISO_BMCUSERNAME" = "" ]; then
    ISO_BMCUSERNAME="$DEFAULT_ISO_BMCUSERNAME"
  fi
  if [ "$ISO_BMCPASSWORD" = "" ]; then
    ISO_BMCPASSWORD="$DEFAULT_ISO_BMCPASSWORD"
  fi
  if [ "$ISO_BMCIP" = "" ]; then
    ISO_BMCIP="$DEFAULT_ISO_BMCIP"
  fi
  if [ "$ISO_CIDR" = "" ]; then
    ISO_CIDR="$DEFAULT_ISO_CIDR"
  fi
  if [ "$ISO_CODENAME" = "" ]; then
    ISO_CODENAME="$DEFAULT_ISO_CODENAME"
  fi
  if [ "$ISO_RELEASE" = "" ]; then
    ISO_RELEASE="$DEFAULT_ISO_RELEASE"
  else
    ISO_MINOR_RELEASE=$( echo "$ISO_RELEASE" |cut -f2 -d. )
    ISO_DOT_RELEASE=$( echo "$ISO_RELEASE" |cut -f3 -d. )
    if [ "$ISO_CODENAME" = "ubuntu" ]; then
      if [ "$ISO_DOT_RELEASE" = "" ]; then
        get_current_release
      fi
    else
      if [ "$ISO_CODENAME" = "rocky" ]; then
        case "$ISO_RELEASE" in
          "9")
            ISO_RELEASE="$CURRENT_ISO_RELEASE_9"
            ;;
          *)
            ISO_RELEASE="$CURRENT_ISO_RELEASE"
            ;;
        esac
      fi
    fi
  fi
  if [ "$OLD_ISO_RELEASE" = "" ]; then
    OLD_ISO_RELEASE="$CURRENT_OLD_ISO_RELEASE"
  fi
  get_release_info
  if [ "$ISO_CODENAME" = "" ]; then
    get_code_name
  fi
  if [ "$ISO_USERNAME" = "" ]; then
    ISO_USERNAME="$DEFAULT_ISO_USERNAME"
  fi
  if [ "$ISO_REALNAME" = "" ]; then
    ISO_REALNAME="$DEFAULT_ISO_REALNAME"
  fi
  if [ "$ISO_HOSTNAME" = "" ]; then
    ISO_HOSTNAME="$DEFAULT_ISO_HOSTNAME"
  fi
  if [ "$ISO_GATEWAY" = "" ]; then
    ISO_GATEWAY="$DEFAULT_ISO_GATEWAY"
  fi
  if [ "$ISO_DNS" = "" ]; then
    ISO_DNS="$DEFAULT_ISO_DNS"
  fi
  if [ "$ISO_IP" = "" ]; then
    ISO_BOOT_PROTO="dhcp"
    DO_ISO_DHCP="true"
  else
    DO_ISO_DHCP="false"
    ISO_BOOT_PROTO="static"
  fi
  if [ "$ISO_ALLOWPASSWORD" = "" ]; then
    ISO_ALLOWPASSWORD="$DEFAULT_ISO_ALLOWPASSWORD"
  fi
  if [ "$ISO_PASSWORD" = "" ]; then
    ISO_PASSWORD="$DEFAULT_ISO_PASSWORD"
  fi
  if [ "$ISO_CHROOTPACKAGES" = "" ]; then
    ISO_CHROOTPACKAGES="$DEFAULT_ISO_PACKAGES"
  fi
  if [ "$ISO_PACKAGES" = "" ]; then
    ISO_PACKAGES="$DEFAULT_ISO_PACKAGES"
  fi
  if [ "$ISO_TIMEZONE" = "" ]; then
    ISO_TIMEZONE="$DEFAULT_ISO_TIMEZONE"
  fi
  if [ "$ISO_OUTPUTFILE" = "" ]; then
    ISO_OUTPUTFILE="$DEFAULT_ISO_OUTPUTFILE"
  fi
  if [ "$ISO_OUTPUTCI" = "" ]; then
    ISO_OUTPUTCI="$DEFAULT_ISO_OUTPUTCI"
  fi
  if [ "$ISO_NIC" = "" ]; then
    ISO_NIC="$DEFAULT_ISO_NIC"
  fi
  if [ "$SWAPSIZE" = "" ]; then
    ISO_SWAPSIZE="$DEFAULT_ISO_SWAPSIZE"
  fi
  if [ "$ISO_DISK" = "" ]; then
    ISO_DISK="$DEFAULT_ISO_DISK"
  fi
  if [ "$ISO_BOOT_TYPE" = "bios" ]; then
    if [[ "$ISO_OPTIONS" =~ "fs" ]]; then
      DEFAULT_ISO_VOLMGRS="lvm zfs xfs btrfs"
    else
      DEFAULT_ISO_VOLMGRS="lvm"
    fi
  fi
  if [ "$DO_ISO_AUTOINSTALL" = "true" ]; then
    DEFAULT_ISO_VOLMGRS="custom $DEFAULT_ISO_VOLMGRS"
  fi
  reset_volmgrs
  if [ "$GRUB_MENU" = "" ]; then
    ISO_GRUBMENU="$DEFAULT_ISO_GRUBMENU"
  fi
  if [ "$GRUB_TIMEOUT" = "" ]; then
    ISO_GRUBTIMEOUT="$DEFAULT_ISO_GRUBTIMEOUT"
  fi
  if [ "$ISO_KERNELARGS" = "" ]; then
    ISO_KERNELARGS="$DEFAULT_ISO_KERNELARGS"
  fi
  if [ "$ISO_KERNEL" = "" ]; then
    if [ "$DO_CREATE_ISO_VM" = "true" ]; then
      ISO_KERNEL="$DEFAULT_VM_TYPE"
    else
      ISO_KERNEL="$DEFAULT_ISO_KERNEL"
    fi
  fi
  if [[ "$ISO_ACTION" =~ "iso" ]]; then
    if [ "$CODENAME" = "" ]; then
      get_code_name
    fi
  fi
  if [ "$ISO_LOCALE" = "" ]; then
    ISO_LOCALE="$DEFAULT_ISO_LOCALE"
  fi
  if [ "$ISO_LCALL" = "" ]; then
    ISO_LCALL="$DEFAULT_ISO_LCALL"
  fi
  if [ "$ISO_LAYOUT" = "" ]; then
    ISO_LAYOUT="$DEFAULT_ISO_LAYOUT"
  fi
  if [ "$ISO_INSTALLMOUNT" = "" ]; then
    ISO_INSTALLMOUNT="$DEFAULT_ISO_INSTALLMOUNT"
  fi
  if [ "$ISO_TARGETMOUNT" = "" ]; then
    ISO_TARGETMOUNT="$DEFAULT_ISO_TARGETMOUNT"
  fi
  if [ "$ISO_AUTOINSTALLDIR" = "" ]; then
    ISO_AUTOINSTALLDIR="$DEFAULT_ISO_AUTOINSTALLDIR"
  fi
  if [ "$ISO_BUILDTYPE" = "" ]; then
    ISO_BUILDTYPE="$DEFAULT_ISO_BUILDTYPE"
  fi
  if [ "$ISO_WORKDIR" = "" ]; then
    if [ "$DO_ISO_DAILY" = "true" ]; then
      ISO_WORKDIR="$HOME/$SCRIPT_NAME/$ISO_CODENAME/$ISO_BUILDTYPE/$ISO_CODENAME"
      DOCKER_ISO_WORKDIR="/root/$SCRIPT_NAME/$ISO_CODENAME/$ISO_BUILDTYPE/$ISO_CODENAME"
    else
      ISO_WORKDIR="$HOME/$SCRIPT_NAME/$ISO_CODENAME/$ISO_BUILDTYPE/$ISO_RELEASE"
      DOCKER_ISO_WORKDIR="/root/$SCRIPT_NAME/$ISO_CODENAME/$ISO_BUILDTYPE/$ISO_RELEASE"
    fi
  else
    if [ "$DO_ISO_DAILY" = "true" ]; then
      ISO_WORKDIR="$HOME/$SCRIPT_NAME/$ISO_CODENAME/$ISO_BUILDTYPE/$ISO_CODENAME"
      DOCKER_ISO_WORKDIR="/root/$SCRIPT_NAME/$ISO_CODENAME/$ISO_BUILDTYPE/$ISO_CODENAME"
    fi
  fi
  if [ "$ISO_VOLID" = "" ]; then
    case $ISO_BUILDTYPE in
      "daily-desktop"|"desktop")
        ISO_VOLID="$ISO_REALNAME $ISO_RELEASE Desktop"
        ;;
      *)
        ISO_VOLID="$ISO_REALNAME $ISO_RELEASE Server"
        ;;
    esac
  fi
  if [ "$ISO_INPUTFILE" = "" ]; then
    ISO_INPUTFILE="$DEFAULT_ISO_INPUTFILE"
  fi
  if [ "$ISO_INPUTCI" = "" ]; then
    ISO_INPUTCI="$DEFAULT_ISO_INPUTCI"
  fi
  if [ "$DO_ISO_QUERY" = "true" ]; then
    get_info_from_iso
  else
    if [ "$DO_ISO_BOOTSERVERFILE" = "false" ]; then
      if [ "$ISO_CODENAME" = "ubuntu" ]; then
        case $ISO_BUILDTYPE in
          "daily-live"|"daily-live-server")
            ISO_INPUTFILE="$ISO_WORKDIR/files/$ISO_CODENAME-live-server-$ISO_ARCH.iso"
            ISO_OUTPUTFILE="$ISO_WORKDIR/files/$ISO_CODENAME-live-server-$ISO_ARCH-$ISO_BOOT_TYPE-autoinstall.iso"
            ISO_INPUTCI="$ISO_WORKDIR/files/$ISO_CODENAME-server-cloudimg-$ISO_ARCH.img"
            ISO_OUTPUTCI="$ISO_WORKDIR/files/$ISO_CODENAME-server-cloudimg-$ISO_ARCH.img"
            ISO_BOOTSERVERFILE="$ISO_OUTPUTFILE"
            ;;
          "daily-desktop")
            ISO_INPUTFILE="$ISO_WORKDIR/files/$ISO_CODENAME-desktop-$ISO_ARCH.iso"
            ISO_OUTPUTFILE="$ISO_WORKDIR/files/$ISO_CODENAME-desktop-$ISO_ARCH-$ISO_BOOT_TYPE-autoinstall.iso"
            ISO_BOOTSERVERFILE="$ISO_OUTPUTFILE"
            ;;
         "desktop")
            ISO_INPUTFILE="$ISO_WORKDIR/files/$ISO_CODENAME-$ISO_RELEASE-desktop-$ISO_ARCH.iso"
            ISO_OUTPUTFILE="$ISO_WORKDIR/files/$ISO_CODENAME-$ISO_RELEASE-desktop-$ISO_ARCH-$ISO_BOOT_TYPE-autoinstall.iso"
            ISO_BOOTSERVERFILE="$ISO_OUTPUTFILE"
            ;;
          *)
            ISO_INPUTFILE="$ISO_WORKDIR/files/$ISO_CODENAME-$ISO_RELEASE-live-server-$ISO_ARCH.iso"
            ISO_OUTPUTFILE="$ISO_WORKDIR/files/$ISO_CODENAME-$ISO_RELEASE-live-server-$ISO_ARCH-$ISO_BOOT_TYPE-autoinstall.iso"
            ISO_BOOTSERVERFILE="$ISO_OUTPUTFILE"
            ;;
        esac
      else
        case $ISO_BUILDTYPE in
          *)
            ISO_INPUTFILE="$ISO_WORKDIR/files/$ISO_REALNAME-$ISO_RELEASE-$ISO_ARCH-$ISO_BUILDTYPE.iso"
            ISO_OUTPUTFILE="$ISO_WORKDIR/files/$ISO_REALNAME-$ISO_RELEASE-$ISO_ARCH-$ISO_BOOT_TYPE-$ISO_BUILDTYPE-kickstart.iso"
            ISO_INPUTCI="$ISO_WORKDIR/files/ubuntu-$ISO_RELEASE-server-cloudimg-$ISO_ARCH.img"
            ISO_OUTPUTCI="$ISO_WORKDIR/files/ubuntu-$ISO_RELEASE-server-cloudimg-$ISO_ARCH.img"
            ISO_BOOTSERVERFILE="$ISO_OUTPUTFILE"
          ;;
        esac
      fi
    fi
  fi
  if [ "$ISO_SQUASHFSFILE" = "" ]; then
    ISO_SQUASHFSFILE="$DEFAULT_ISO_SQUASHFSFILE"
  fi
  if [ "$ISO_GRUBFILE" = "" ]; then
    ISO_GRUBFILE="$DEFAULT_ISO_GRUBFILE"
  fi
  if [ "$ISO_USE_BIOSDEVNAME" = "true" ]; then
    ISO_KERNELARGS="$ISO_KERNELARGS net.ifnames=0 biosdevname=0"
  fi
  if [ "$OLD_ISO_INPUTFILE" = "" ]; then
    OLD_ISO_INPUTFILE="$DEFAULT_OLD_ISO_INPUTFILE"
  fi
  if [ "$VM_RAM" = "" ]; then
    VM_RAM="$DEFAULT_VM_RAM"
  fi
  if [ ! "$ISO_NETMASK" = "" ]; then
    if [ "$ISO_CIDR" = "" ]; then
      get_cidr_from_netmask "$ISO_NETMASK"
    fi
  fi
  if [ ! "$ISO_CIDR" = "" ]; then
    if [ "$ISO_NETMASK" = "" ]; then
      get_netmask_from_cidr "$ISO_CIDR"
    fi
  fi
  if [ "$ISO_VOLMGRS" = "" ]; then
    ISO_VOLMGRS="$DEFAULT_ISO_VOLMGRS"
  fi
  if [[ "$ISO_VOLMGRS" =~ "fs" ]] || [[ "$ISO_VOLMGRS" =~ "custom" ]]; then
    DO_CHROOT="true"
    DO_ISO_SQUASHFS_UNPACK="true"
    DO_ISO_EARLY_PACKAGES="true"
    DO_ISO_LATE_PACKAGES="true"
  else
    DO_CHROOT="false"
    DO_ISO_SQUASHFS_UNPACK="false"
    DO_ISO_EARLY_PACKAGES="false"
    DO_ISO_LATE_PACKAGES="false"
  fi
}
