#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034

# Function: set_defaults
#
# Set defaults

set_defaults () {
  CURRENT_ISO_RELEASE_1404="14.04.6"
  CURRENT_ISO_RELEASE_1604="16.04.7"
  CURRENT_ISO_RELEASE_1804="18.04.6"
  CURRENT_ISO_RELEASE_2004="20.04.6"
  CURRENT_ISO_RELEASE_2204="22.04.5"
  CURRENT_ISO_RELEASE_2210="22.10"
  CURRENT_ISO_RELEASE_2304="23.04"
  CURRENT_ISO_RELEASE_2310="23.10.1"
  CURRENT_ISO_RELEASE_2404="24.04.2"
  CURRENT_ISO_RELEASE_2410="24.10"
  CURRENT_ISO_RELEASE_2504="25.04"
  CURRENT_ISO_RELEASE="24.04.2"
  CURRENT_ISO_OSNAME="ubuntu"
  DEFAULT_ISO_RELEASE="$CURRENT_ISO_RELEASE"
  DEFAULT_ISO_MAJORRELEASE=$( echo "$DEFAULT_ISO_RELEASE" |cut -f1 -d. )
  DEFAULT_ISO_MINORRELEASE=$( echo "$DEFAULT_ISO_RELEASE" |cut -f2 -d. )
  DEFAULT_ISO_DOTRELEASE=$( echo "$DEFAULT_ISO_RELEASE" |cut -f3 -d. )
  CURRENT_OLD_ISO_RELEASE="23.04"
  CURRENT_ISO_DEVRELEASE="25.04"
  CURRENT_DOCKER_UBUNTU_RELEASE="24.04"
  DEFAULT_ISO_CODENAME="jammy"
  CURRENT_ISO_CODENAME="jammy"
  CURRENT_ISO_ARCH="amd64"
  DEFAULT_ISO_ARCH=$( uname -m |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" |sed "s/x86/amd64/g" )
  DEFAULT_ISO_INSTALLSOURCE="cdrom"
  DEFAULT_ISO_SOURCEID="ubuntu-server"
  DEFAULT_ISO_FALLBACK="continue-anyway"
  DEFAULT_ISO_HOSTNAME="ubuntu"
  DEFAULT_ISO_REALNAME="Ubuntu"
  DEFAULT_ISO_USERNAME="ubuntu"
  DEFAULT_ISO_TIMEZONE="Australia/Melbourne"
  DEFAULT_ISO_PASSWORD="ubuntu"
  DEFAULT_ISO_KERNEL="linux-generic"
  DEFAULT_ISO_NIC="first-nic"
  DEFAULT_ISO_IP="192.168.1.2"
  DEFAULT_ISO_DNS="8.8.8.8"
  DEFAULT_ISO_CIDR="24"
  DEFAULT_ISO_BLOCKLIST=""
  DEFAULT_ISO_ALLOWLIST=""
  DEFAULT_ISO_GATEWAY="192.168.1.254"
  DEFAULT_ISO_SWAPSIZE="2G"
  DEFAULT_ISO_DISK="first-disk"
  DEFAULT_ISO_VOLMGRS="zfs auto ext4 xfs btrfs"
  DEFAULT_ISO_GRUBMENU="0"
  DEFAULT_ISO_GRUBTIMEOUT="10"
  DEFAULT_ISO_LOCALE="en_US.UTF-8"
  DEFAULT_ISO_LCALL="en_US"
  DEFAULT_ISO_LAYOUT="us"
  DEFAULT_ISO_COUNTRY="us"
  DEFAULT_ISO_UPDATES="security"
  DEFAULT_ISO_BUILDTYPE="live-server"
  DEFAULT_ISO_BOOTTYPE="efi"
  DEFAULT_ISO_SERIALPORT0="ttyS0"
  DEFAULT_ISO_SERIALPORTADDRESS0="0x03f8"
  DEFAULT_ISO_SERIALPORTSPEED0="115200"
  DEFAULT_ISO_SERIAL_PORT1="ttyS1"
  DEFAULT_ISO_SERIAL_PORT_ADDRESS1="0x02f8"
  DEFAULT_ISO_SERIAL_PORT_SPEED1="115200"
  DEFAULT_ISO_INSTALLMODE="text"
  DEFAULT_ISO_PACKAGES="zfsutils-linux zfs-initramfs xfsprogs btrfs-progs net-tools curl lftp wget sudo file rsync dialog setserial ansible apt-utils whois squashfs-tools duperemove jq btrfs-compsize"
  REQUIRED_PACKAGES="binwalk casper genisoimage live-boot live-boot-initramfs-tools p7zip-full lftp wget xorriso whois squashfs-tools sudo file rsync net-tools nfs-kernel-server ansible dialog apt-utils jq"
  DEFAULT_DOCKER_ARCH="amd64 arm64"
  DEFAULT_ISO_SSHKEYFILE="$HOME/.ssh/id_rsa.pub"
  MASKED_DEFAULT_ISO_SSHKEYFILE="$HOME/.ssh/id_rsa.pub"
  DEFAULT_ISO_SSHKEY=""
  DEFAULT_ISO_ALLOWPASSWORD="false"
  DEFAULT_ISO_BMCUSERNAME="root"
  DEFAULT_ISO_BMCPASSWORD="calvin"
  DEFAULT_ISO_BMCIP="192.168.1.3"
  DEFAULT_ISO_KERNELARGS="console=tty0 console=vt0"
  DEFAULT_ISO_SEARCH=""
  DEFAULT_ISO_SELINUX="enforcing"
  DEFAULT_ISO_ONBOOT="on"
  DEFAULT_ISO_ENABLESERVICE="sshd"
  DEFAULT_ISO_DISABLESERVICE="cupsd"
  DEFAULT_ISO_ISO_DPKGCONF="--force-confnew"
  DEFAULT_ISO_DPKGOVERWRITE="--force-overwrite"
  DEFAULT_ISO_DPKGDEPENDS="--force-depends"
  DEFAULT_VM_TYPE="kvm"
  DEFAULT_VM_RAM="2048000"
  DEFAULT_VM_CPUS="2"
  DEFAULT_VM_SIZE="20G"
  DEFAULT_VM_NIC="default"
  DEFAULT_ISO_GECOS="Administrator"
  DEFAULT_ISO_GROUPS="dialout,kvm,libvirt,qemu,wheel"
  DEFAULT_ISO_BOOTPROTO="dhcp"
  DEFAULT_ISO_ALLOWSERVICE="ssh"
  DEFAULT_ISO_FIREWALL="enabled"
  DEFAULT_ISO_PASSWORDALGORITHM="sha512"
  DEFAULT_ISO_BOOTLOADER="mbr"
  DEFAULT_ISO_OEMINSTALL="auto"
  DEFAULT_ISO_ZFSFILESYSTEMS="/var /var/lib /var/lib/AccountsService /var/lib/apt /var/lib/dpkg /var/lib/NetworkManager /srv /usr /usr/local /var/games /var/log /var/mail /var/snap /var/spool /var/www"
  DEFAULT_ISO_BOOTSIZE="2048"
  DEFAULT_ISO_ROOTSIZE="-1"
  DEFAULT_ISO_PESIZE="32768"
  DEFAULT_ISO_INSTALLUSERNAME="install"
  DEFAULT_ISO_INSTALLPASSWORD="install"
  DEFAULT_ISO_VG_BASE="ubuntu"
  DEFAULT_ISO_VGNAME="${DEFAULT_ISO_VG_BASE}-vg"
  DEFAULT_ISO_LVNAME="${DEFAULT_ISO_VG_BASE}-lv"
  DEFAULT_ISO_PVNAME="${DEFAULT_ISO_VG_BASE}-pv"
  DEFAULT_ISO_DISK_NAME="boot"
  DEFAULT_ISO_DISKSERIAL="first-serial"
  DEFAULT_ISO_DISK_WWN="first-wwn"
  DEFAULT_ISO_COMPRESSION="lzo"
  DEFAULT_ISO_OPTION="btrfs"
  DEFAULT_ISO_NETMASK=""
  VM_EXISTS="false"
  DO_ISO_TESTMODE="false"
  DO_ISO_FORCEMODE="false"
  DO_ISO_FULLFORCEMODE="false"
  DO_ISO_VERBOSEMODE="false"
  TEMP_DO_ISO_VERBOSEMODE="false"
  DO_ISO_INTERACTIVEMODE="false"
  ISO_BIOSDEVNAME="false"
  ISO_PREFIX=""
  ISO_SUFFIX=""
  ISO_SSHKEY=""
  ISO_VGNAME=""
  ISO_LVNAME=""
  ISO_PVNAME=""
  ISO_DISK_NAME=""
  BMC_PORT="443"
  BMC_EXPOSE_DURATION="180"
  VM_NAME=""
  XML_FILE=""
  ISO_MAJORRELEASE=""
  ISO_MINORRELEASE=""
  ISO_DOTRELEASE=""
  ISO_NETMASK=""
  ISO_POSTINSTALL="none"
  BREW_DIR=""
  BIN_DIR=""
  VIRT_DIR=""
  DEFAULT_VM_NAME="$SCRIPT_NAME"
  if [ "$OS_NAME" = "Linux" ]; then
    REQUIRED_KVM_PACKAGES="libvirt-clients libvirt-daemon-system libguestfs-tools qemu-kvm virt-manager"
  else
    REQUIRED_KVM_PACKAGES="libvirt-glib libvirt qemu qemu-kvm virt-manager"
  fi
  set_default_cidr
}

# Function: reset_defaults
#
# Reset defaults

reset_defaults () {
  get_ssh_key
  get_release_info
  if [[ "$ISO_BUILDTYPE" =~ "desktop" ]]; then
    DO_ISO_CHROOT="false"
  fi
  if [ "$ISO_OSNAME" = "" ]; then
    ISO_OSNAME="$DEFAULT_ISO_OSNAME"
  fi
  if [[ "$ISO_OSNAME" =~ "rocky" ]]; then
    DEFAULT_ISO_VOLMGRS="auto ext4 xfs btrfs"
    DEFAULT_ISO_ARCH="x86_64"
    CURRENT_ISO_RELEASE="9.3"
    CURRENT_ISO_RELEASE_9="9.3"
    DEFAULT_ISO_OSNAME="rocky"
    DEFAULT_ISO_HOSTNAME="rocky"
    DEFAULT_ISO_REALNAME="Rocky"
    DEFAULT_ISO_USERNAME="rocky"
    DEFAULT_ISO_PASSWORD="rocky"
    DEFAULT_ISO_BUILDTYPE="dvd"
    DEFAULT_ISO_SWAPSIZE="2048"
    DEFAULT_ISO_WORKDIR="$HOME/$SCRIPT_NAME/$DEFAULT_ISO_OSNAME/$DEFAULT_ISO_BUILDTYPE/$DEFAULT_ISO_RELEASE"
    DEFAULT_ISO_MOUNTDIR="$DEFAULT_ISO_WORKDIR/isomount"
    DEFAULT_ISO_INPUTFILE="$DEFAULT_ISO_WORKDIR/$DEFAULT_ISO_REALNAME-$DEFAULT_ISO_RELEASE-$DEFAULT_ISO_ARCH-dvd.iso"
    DEFAULT_ISO_INPUTFILE_BASE=$( basename "$DEFAULT_ISO_INPUTFILE" )
    DEFAULT_ISO_OUTPUTFILE_BASE=$( basename "$DEFAULT_ISO_OUTPUTFILE" )
    DEFAULT_ISO_URL="https://download.rockylinux.org/pub/rocky/$DEFAULT_ISO_MAJORRELEASE/isos/$DEFAULT_ISO_ARCH/$DEFAULT_ISO_INPUTFILE_BASE"
    DEFAULT_ISO_PACKAGES="net-tools curl lftp wget sudo file rsync dialog setserial whois squashfs-tools jq"
    REQUIRED_PACKAGES="apt-utils $REQUIRED_PACKAGES"
  fi
  if [[ "$ISO_ACTION" =~ "ci" ]]; then
    DEFAULT_ISO_RELEASE=$( echo "$DEFAULT_ISO_RELEASE" |awk -F"." '{ print $1"."$2 }' )
    DEFAULT_ISO_WORKDIR="$HOME/$SCRIPT_NAME/$DEFAULT_ISO_OSNAME/$DEFAULT_ISO_RELEASE"
    DEFAULT_ISO_INPUTCI="$DEFAULT_ISO_WORKDIR/files/ubuntu-$DEFAULT_ISO_RELEASE-server-cloudimg-$DEFAULT_ISO_ARCH.img"
    DEFAULT_ISO_INPUTCI_BASE=$( basename "$DEFAULT_ISO_INPUTCI" )
    DEFAULT_ISO_OUTPUTCI="$DEFAULT_ISO_WORKDIR/files/ubuntu-$DEFAULT_ISO_RELEASE-server-cloudimg-$DEFAULT_ISO_ARCH-$DEFAULT_ISO_BOOTTYPE-autoinstall.img"
    DEFAULT_ISO_OUTPUTCI_BASE=$( basename "$DEFAULT_ISO_OUTPUTCI" )
  fi
  if [[ "$ISO_BUILDTYPE" =~ "server" ]]; then
    DO_ISO_SQUASHFS_UNPACK="true"
    if [[ "$ISO_VOLMGRS" =~ "zfs" ]]; then
      DO_ISO_EARLYPACKAGES="true"
      DO_ISO_LATEPACKAGES="true"
    fi
  fi
}

# Function: set_default_flags
#
# Set default flags

set_default_flags () {
  DO_ZFS="false"
  DO_ISO_IPV4="true"
  DO_ISO_IPV6="true"
  DO_ISO_NOMULTIPATH="false"
  DO_KVM_PACKAGES="false"
  DO_ISO_HWEKERNEL="true"
  DO_ISO_CLUSTERPACKAGES="false"
  DO_ISO_DAILY="false"
  DO_ISO_CHECKDOCKER="false"
  DO_ISO_LATEST="false"
  DO_CHECK_CI="false"
  DO_ISO_CREATECIVM="false"
  DO_ISO_DELETECIVM="false"
  DO_ISO_CREATEISOVM="false"
  DO_ISO_DELETEISOVM="false"
  DO_ISO_LISTVM="false"
  DO_ISO_OLDINSTALLER="false"
  DO_ISO_BOOTSERVERFILE="false"
  DO_ISO_INSTALLREQUIREDPACKAGES="false"
  DO_INSTALL_ISO_NETWORK_UPDATES="false"
  DO_INSTALL_ISO_PACKAGES="false"
  DO_INSTALL_ISO_DRIVERS="false"
  DO_INSTALL_ISO_CODECS="false"
  DO_ISO_AUTOUPGRADES="false"
  DO_ISO_APTNEWS="false"
  DO_ISO_GETISO="false"
  DO_ISO_CHECKWORKDIR="false"
  DO_ISO_CREATEAUTOINSTALL="false"
  DO_ISO_FULLISO="false"
  DO_ISO_JUSTISO="false"
  DO_ISO_RUNCHROOTSCRIPT="false"
  DO_PRINT_HELP="true"
  DO_ISO_UNMOUNT="true"
  DO_ISO_NOUNMOUNT="false"
  DO_INSTALL_ISO_UPDATE="false"
  DO_INSTALL_ISO_UPGRADE="false"
  DO_INSTALL_ISO_DIST_UPGRADE="false"
  DO_ISO_SQUASHFS_UPDATE="false"
  DO_ISO_QUERY="false"
  DO_ISO_DOCKER="false"
  DO_PRINT_ENV="false"
  DO_INSTALL_SERVER="false"
  DO_CREATE_EXPORT="false"
  DO_CREATE_ANSIBLE="false"
  DO_ISO_CHECKRACADM="false"
  DO_ISO_EXECUTERACADM="false"
  DO_ISO_LIST="false"
  DO_ISO_SCPHEADER="false"
  DO_ISO_SERIAL="true"
  DO_ISO_AUTOINSTALL="false"
  DO_ISO_SEARCHDRIVERS="false"
  DO_ISO_PRESERVESOURCES="false"
  DO_ISO_PLAINTEXTPASSWORD="false"
  DO_ISO_ACTIVATE="true"
  DO_ISO_DEFAULTROUTE="true"
  DO_ISO_LOCKROOT="true"
  DO_ISO_KSTEST="false"
  DO_ISO_MEDIACHECK="false"
  DO_ISO_INSTALLUSER="false"
  DO_ISO_SSHKEY="true"
  DO_ISO_FIRSTBOOT="disabled"
  DO_ISO_SECUREBOOT="true"
  DO_ISO_ISOLINUXFILE="false"
  DO_ISO_GRUBFILE="false"
  DO_ISO_KSQUIET="false"
  DO_ISO_KSTEXT="false"
  DO_ISO_ZFSFILESYSTEMS="false"
  DO_ISO_CREATEISO="true"
  DO_ISO_REORDERUEFI="false"
  DO_DELETE_VM="false"
  DO_ISO_DHCP="true"
  DO_ISO_GEOIP="true"
  DO_ISO_CHROOT="true"
  DO_ISO_NVME="false"
  DO_ISO_COMPRESSION="true"
  DO_REFRESH_INSTALL="false"
  DO_ISO_EARLYPACKAGES="false"
  DO_ISO_LATEPACKAGES="false"
  DO_ISO_REFRESHINSTALLER="false"
  DO_MULTIPATH="false"
  DO_ISO_DEBUG="false"
  DO_ISO_STRICT="false"
}

# Function: set_default_os_name
#
# Set default OS name

set_default_os_name () {
  if [ -f "/usr/bin/lsb_release" ]; then
    LSB_RELEASE=$( lsb_release -s -a )
    if [[ "$LSB_RELEASE" =~ "Ubuntu" ]]; then
      DEFAULT_ISO_OSNAME=$( lsb_release -d |awk '{print $2}' |tr '[:upper:]' '[:lower:]' )
    else
      DEFAULT_ISO_OSNAME="$CURRENT_ISO_OSNAME"
      if [[ "$LSB_RELEASE" =~ "Arch" ]] || [[ "$LSB_RELEASE" =~ "Endeavour" ]]; then
        REQUIRED_PACKAGES="p7zip lftp wget xorriso whois squashfs-tools sudo file rsync ansible dialog"
      fi
    fi
  else
    DEFAULT_ISO_OSNAME="$CURRENT_ISO_OSNAME"
  fi
}

# Function: set_default_arch
#
# Set default zrchitecture

set_default_arch () {
  if [ -f "/usr/bin/uname" ]; then
    if [ "$OS_NAME" = "Linux" ]; then
      if [ "$( command -v ifconfig )" ]; then
        DEFAULT_ISO_BOOTSERVERIP=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
      else
        DEFAULT_ISO_BOOTSERVERIP=$( ip addr | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' |cut -f1 -d/ )
      fi
      if [ "$ISO_OSNAME" = "rocky" ]; then
        DEFAULT_ISO_ARCH=$( uname -m)
      else
        DEFAULT_ISO_ARCH=$( uname -m | sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" )
        if [ "$DEFAULT_ISO_ARCH" = "x86_64" ] || [ "$DEFAULT_ISO_ARCH" = "amd64" ]; then
          DEFAULT_ISO_ARCH="amd64"
        fi
        if [ "$DEFAULT_ISO_ARCH" = "aarch64" ] || [ "$DEFAULT_ISO_ARCH" = "arm64" ]; then
          DEFAULT_ISO_ARCH="arm64"
        fi
      fi
    else
      if [ "$( command -v ifconfig )" ]; then
        DEFAULT_ISO_BOOTSERVERIP=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
      else
        DEFAULT_ISO_BOOTSERVERIP=$( ip add | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' |cut -f1 -d/ )
      fi
    fi
  else
    DEFAULT_ISO_ARCH="$CURRENT_ISO_ARCH"
    DEFAULT_ISO_BOOTSERVERIP=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
  fi
}

# Function: set_default_release
#
# Set default release

set_default_release () {
  if [ -f "/usr/bin/lsb_release" ]; then
    if [ "$OS_DISTRO" = "Ubuntu" ]; then
      if [ "$DEFAULT_ISO_RELEASE" = "" ]; then
        DEFAULT_ISO_RELEASE=$( lsb_release -ds |awk '{print $2}' )
      else
        DEFAULT_ISO_RELEASE="$CURRENT_ISO_RELEASE"
      fi
    fi
  else
    DEFAULT_ISO_RELEASE="$CURRENT_ISO_RELEASE"
  fi
  DEFAULT_OLD_ISO_RELEASE="$CURRENT_OLD_ISO_RELEASE"
}

# Funtion: set_default_codename
#
# Set default codename

set_default_codename () {
  if [ -f "/usr/bin/lsb_release" ]; then
    if [ "$OS_NAME" = "Ubuntu" ]; then
      DEFAULT_ISO_CODENAME=$( lsb_release -cs 2> /dev/null)
    else
      DEFAULT_ISO_CODENAME="$CURRENT_ISO_CODENAME"
    fi
  else
    DEFAULT_ISO_CODENAME="$CURRENT_ISO_CODENAME"
  fi
}

# Function: set_default_old_url
#
# Set default old ISO URL

set_default_old_url () {
  DEFAULT_OLD_ISO_URL="https://old-releases.ubuntu.com/releases/$DEFAULT_OLD_ISO_RELEASE/ubuntu-$DEFAULT_OLD_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH.iso"
}

# Function: set_default_docker_arch
#
# Set default arches for Docker

set_default_docker_arch () {
  if [ "$OS_NAME" = "Darwin" ]; then
    if [ "$OS_ARCH" = "arm64" ]; then
      DEFAULT_DOCKER_ARCH="amd64 arm64"
    else
      DEFAULT_DOCKER_ARCH="amd64"
    fi
  else
    DEFAULT_DOCKER_ARCH="amd64"
  fi
}

# Function: set_default_dirs
#
# Set default work directories

set_default_dirs () {
  DEFAULT_ISO_WORKDIR="$HOME/$SCRIPT_NAME/$DEFAULT_ISO_OSNAME/$DEFAULT_ISO_BUILDTYPE/$DEFAULT_ISO_RELEASE"
  DEFAULT_OLD_ISO_WORKDIR="$HOME/$SCRIPT_NAME/$DEFAULT_ISO_OSNAME/$DEFAULT_ISO_BUILDTYPE/$DEFAULT_OLD_ISO_RELEASE"
  MASKED_DEFAULT_ISO_WORKDIR="$HOME/$SCRIPT_NAME/$DEFAULT_ISO_OSNAME/$DEFAULT_ISO_BUILDTYPE/$DEFAULT_ISO_RELEASE"
  DEFAULT_ISO_MOUNTDIR="$DEFAULT_ISO_WORKDIR/isomount"
  DEFAULT_OLD_ISO_MOUNTDIR="$DEFAULT_OLD_ISO_WORKDIR/isomount"
  DEFAULT_ISO_AUTOINSTALLDIR="autoinstall"
  DEFAULT_ISO_TARGETMOUNT="/target"
  DEFAULT_ISO_INSTALLMOUNT="/cdrom"
}

# Function: reset_default_dirs
#
# Update Default work directories

reset_default_dirs () {
  ISO_MOUNTDIR="$ISO_WORKDIR/isomount"
  OLD_ISO_MOUNTDIR="$OLD_ISO_WORKDIR/isomount"
  ISO_NEW_DIR="$ISO_WORKDIR/isonew"
  ISO_SOURCE_DIR="$ISO_WORKDIR/source-files"
}

# Function: set_default_files
#
# Set default file names/locations

set_default_files () {
  DEFAULT_ISO_INPUTFILE="$DEFAULT_ISO_WORKDIR/files/ubuntu-$DEFAULT_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH.iso"
  DEFAULT_ISO_INPUTCI="$DEFAULT_ISO_WORKDIR/files/ubuntu-$DEFAULT_ISO_RELEASE-server-cloudimg-$DEFAULT_ISO_ARCH.img"
  DEFAULT_OLD_ISO_INPUTFILE="$DEFAULT_OLD_ISO_WORKDIR/files/ubuntu-$DEFAULT_OLD_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH.iso"
  DEFAULT_ISO_OUTPUTFILE="$DEFAULT_ISO_WORKDIR/files/ubuntu-$DEFAULT_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH-$DEFAULT_ISO_BOOTTYPE-autoinstall.iso"
  DEFAULT_ISO_OUTPUTCI="$DEFAULT_ISO_WORKDIR/files/ubuntu-$DEFAULT_ISO_RELEASE-server-cloudimg-$DEFAULT_ISO_ARCH-$DEFAULT_ISO_BOOTTYPE-autoinstall.img"
  DEFAULT_ISO_BOOTSERVERFILE="$DEFAULT_ISO_OUTPUTFILE"
  DEFAULT_ISO_SQUASHFSFILE="$DEFAULT_ISO_MOUNTDIR/casper/ubuntu-server-minimal.squashfs"
  DEFAULT_OLD_ISO_INSTALLSQUASHFSFILE="$DEFAULT_OLD_ISO_MOUNTDIR/casper/ubuntu-server-minimal.ubuntu-server.installer.squashfs"
  DEFAULT_ISO_GRUBFILE="$DEFAULT_ISO_WORKDIR/grub.cfg"
  DEFAULT_ISO_VOLID="$DEFAULT_ISO_REALNAME $DEFAULT_ISO_RELEASE Server"
  DEFAULT_ISO_INPUTFILE_BASE=$( basename "$DEFAULT_ISO_INPUTFILE" )
  DEFAULT_ISO_INPUTCI_BASE=$( basename "$DEFAULT_ISO_INPUTCI" )
  DEFAULT_ISO_OUTPUTFILE_BASE=$( basename "$DEFAULT_ISO_OUTPUTFILE" )
  DEFAULT_ISO_OUTPUTCI_BASE=$( basename "$DEFAULT_ISO_OUTPUTCI" )
  DEFAULT_ISO_BOOTSERVERFILE_BASE=$(basename "$DEFAULT_ISO_BOOTSERVERFILE")
  DEFAULT_ISO_SQUASHFSFILE_BASE=$( basename "$DEFAULT_ISO_SQUASHFSFILE" )
  DEFAULT_ISO_GRUBFILE_BASE=$( basename "$DEFAULT_ISO_GRUBFILE" )
}

# Function: reset_default_files
#
# Update default files

reset_default_files () {
  ISO_VOLID="$ISO_VOLID $ISO_ARCH"
  ISO_GRUBFILE="$ISO_WORKDIR/grub.cfg"
  if [[ "$ISO_BUILDTYPE" =~ "desktop" ]]; then
    ISO_SQUASHFSFILE="$ISO_MOUNTDIR/casper/minimal.squashfs"
    NEW_SQUASHFS_FILE="$ISO_SOURCE_DIR/casper/minimal.squashfs"
  else
    if [ "$ISO_MAJORRELEASE" -ge "22" ]; then
      ISO_SQUASHFSFILE="$ISO_MOUNTDIR/casper/ubuntu-server-minimal.squashfs"
      NEW_SQUASHFS_FILE="$ISO_SOURCE_DIR/casper/ubuntu-server-minimal.squashfs"
    else
      ISO_SQUASHFSFILE="$ISO_MOUNTDIR/casper/filesystem.squashfs"
      NEW_SQUASHFS_FILE="$ISO_SOURCE_DIR/casper/filesystem.squashfs"
    fi
  fi
}

# Function: reset_volmgrs
#
# Update order of volmgrs based on --firstoption switch

reset_volmgrs () {
  if [ ! "$ISO_OPTION" = "" ]; then
    TEMP_VOLMGRS=$(echo "$ISO_VOLMGRS" |sed "s/$ISO_OPTION//g" |sed "s/^ //g" |sed "s/ $//g" )
    ISO_VOLMGRS="$ISO_OPTION $TEMP_VOLMGRS"
  fi
}

# Function: set_default_cidr
#
# Set default CIDR

set_default_cidr () {
  BIN_TEST=$( command -v ipcalc | grep -c ipcalc )
  if [ "$OS_NAME" = "Darwin" ]; then
    if [ ! "$BIN_TEST" = "0" ]; then
      DEFAULT_INTERFACE=$( route -n get default |grep interface |awk '{print $2}' )
      DEFAULT_ISO_NETMASK=$( ifconfig "$DEFAULT_INTERFACE" |grep mask |awk '{print $4}' )
      DEFAULT_ISO_CIDR=$( ipcalc "1.1.1.1" "$DEFAULT_ISO_NETMASK" | grep ^Netmask |awk '{print $4}' )
      if [[ "$DEFAULT_ISO_NETMASK" =~ "0x" ]]; then
        OCTETS=$( eval echo '$(((DEFAULT_ISO_CIDR<<32)-1<<32-$DEFAULT_ISO_CIDR>>'{3..0}'*8&255))' )
        DEFAULT_ISO_NETMASK=$( echo "${OCTETS// /.}" )
      fi
    else
      verbose_message "Tool ipcalc not found" "warn"
      DEFAULT_ISO_CIDR="24"
    fi
  else
    DEFAULT_INTERFACE=$( ip -4 route show default |grep -v linkdown|awk '{ print $5 }' )
    DEFAULT_ISO_CIDR=$( ip r |grep link |grep "$DEFAULT_INTERFACE" |awk '{print $1}' |cut -f2 -d/ |head -1 )
    if [[ "$DEFAULT_ISO_CIDR" =~ "." ]] || [ "$DEFAULT_ISO_CIDR" = "" ]; then
      if [ ! "$BIN_TEST" = "0" ]; then
        DEFAULT_ISO_NETMASK=$( route -n |awk '{print $3}' |grep "^255" )
        DEFAULT_ISO_CIDR=$( ipcalc "1.1.1.1" "$DEFAULT_ISO_NETMASK" | grep ^Netmask |awk '{print $4}' )
      else
        verbose_message "Tool ipcalc not found" "warn"
        DEFAULT_ISO_CIDR="24"
      fi
    fi
  fi
  DEFAULT_VM_BRIDE="$DEFAULT_INTERFACE"
}

# Function: get_cidr_from_netmask
#
# Get CIDR from netmask

get_cidr_from_netmask () {
  BINARY=$( eval eval echo "'\$((('{"${1//./,}"}'>>'{7..0}')%2))'" )
  ISO_CIDR=$( eval echo '$(('"${BINARY// /+}"'))' )
}


# Function:: get_netmask_from_cidr
#
# Get netmask from CIDR

get_netmask_from_cidr () {
  OCTETS=$( eval echo '$(((1<<32)-1<<32-$1>>'{3..0}'*8&255))' )
  ISO_NETMASK=$( echo "${OCTETS// /.}" )
}
