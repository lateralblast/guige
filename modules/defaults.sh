# Function: set_defaults 
# 
# Set defaults

set_defaults () {
  CURRENT_ISO_RELEASE_1404="14.04.6"
  CURRENT_ISO_RELEASE_1604="16.04.7"
  CURRENT_ISO_RELEASE_1804="18.04.6"
  CURRENT_ISO_RELEASE_2004="20.04.6"
  CURRENT_ISO_RELEASE_2204="22.04.3"
  CURRENT_ISO_RELEASE_2210="22.10"
  CURRENT_ISO_RELEASE_2304="23.04"
  CURRENT_ISO_RELEASE_2310="23.10.1"
  CURRENT_ISO_RELEASE_2404="24.04"
  CURRENT_ISO_RELEASE="22.04.3"
  CURRENT_OLD_ISO_RELEASE="23.04"
  CURRENT_ISO_DEV_RELEASE="24.04"
  CURRENT_ISO_OS_NAME="ubuntu"
  CURRENT_DOCKER_UBUNTU_RELEASE="22.04"
  CURRENT_ISO_CODENAME="jammy"
  CURRENT_ISO_ARCH="amd64"
  DEFAULT_ISO_INSTALL_SOURCE="cdrom"
  DEFAULT_ISO_SOURCE_ID="ubuntu-server"
  DEFAULT_ISO_HOSTNAME="ubuntu"
  DEFAULT_ISO_REALNAME="Ubuntu"
  DEFAULT_ISO_USERNAME="ubuntu"
  DEFAULT_ISO_TIMEZONE="Australia/Melbourne"
  DEFAULT_ISO_PASSWORD="ubuntu"
  DEFAULT_ISO_KERNEL="linux-generic"
  DEFAULT_ISO_NIC="first-net"
  DEFAULT_ISO_IP="192.168.1.2"
  DEFAULT_ISO_DNS="8.8.8.8"
  DEFAULT_ISO_CIDR="24"
  DEFAULT_ISO_BLOCKLIST=""
  DEFAULT_ISO_ALLOWLIST=""
  DEFAULT_ISO_GATEWAY="192.168.1.254"
  DEFAULT_ISO_SWAPSIZE="2G"
  DEFAULT_ISO_DEVICES="first-disk"
  DEFAULT_ISO_VOLMGRS="zfs lvm xfs btrfs"
  DEFAULT_ISO_GRUB_MENU="0"
  DEFAULT_ISO_GRUB_TIMEOUT="10"
  DEFAULT_ISO_LOCALE="en_US.UTF-8"
  DEFAULT_ISO_LC_ALL="en_US"
  DEFAULT_ISO_LAYOUT="us"
  DEFAULT_ISO_COUNTRY="us"
  DEFAULT_ISO_BUILD_TYPE="live-server"
  DEFAULT_ISO_BOOT_TYPE="efi"
  DEFAULT_ISO_SERIAL_PORT0="ttyS0"
  DEFAULT_ISO_SERIAL_PORT_ADDRESS0="0x03f8"
  DEFAULT_ISO_SERIAL_PORT_SPEED0="115200"
  DEFAULT_ISO_SERIAL_PORT1="ttyS1"
  DEFAULT_ISO_SERIAL_PORT_ADDRESS1="0x02f8"
  DEFAULT_ISO_SERIAL_PORT_SPEED1="115200"
  DEFAULT_ISO_INSTALL_MODE="text"
  DEFAULT_ISO_INSTALL_PACKAGES="zfsutils-linux zfs-initramfs net-tools curl lftp wget sudo file rsync dialog setserial ansible apt-utils whois squashfs-tools duperemove jq"
  REQUIRED_PACKAGES="p7zip-full lftp wget xorriso whois squashfs-tools sudo file rsync net-tools nfs-kernel-server ansible dialog apt-utils jq"
  DEFAULT_DOCKER_ARCH="amd64 arm64"
  DEFAULT_ISO_SSH_KEY_FILE="$HOME/.ssh/id_rsa.pub"
  MASKED_DEFAULT_ISO_SSH_KEY_FILE="$HOME/.ssh/id_rsa.pub"
  DEFAULT_ISO_SSH_KEY=""
  DEFAULT_ISO_ALLOW_PASSWORD="false"
  DEFAULT_BMC_USERNAME="root"
  DEFAULT_BMC_PASSWORD="calvin"
  DEFAULT_BMC_IP="192.168.1.3"
  DEFAULT_ISO_KERNEL_ARGS="console=tty0 console=vt0"
  DEFAULT_ISO_SEARCH=""
  DEFAULT_ISO_ONBOOT="on"
  DEFAULT_ISO_ENABLE_SERVICE="sshd"
  DEFAULT_ISO_DISABLE_SERVICE="cupsd"
  DEFAULT_ISO_DPKG_CONF="--force-confnew"
  DEFAULT_ISO_DPKG_OVERWRITE="--force-overwrite"
  DEFAULT_ISO_DPKG_DEPENDS="--force-depends"
  DEFAULT_VM_TYPE="kvm"
  DEFAULT_VM_RAM="2048000"
  DEFAULT_VM_CPUS="2"
  DEFAULT_VM_SIZE="20G"
  DEFAULT_VM_NIC="default"
  DEFAULT_ISO_GECOS="Administrator"
  DEFAULT_ISO_GROUPS="dialout,kvm,libvirt,qemu,wheel"
  DEFAULT_ISO_BOOT_PROTO="dhcp"
  DEFAULT_ISO_ALLOW_SERVICE="ssh"
  DEFAULT_ISO_FIREWALL="enabled"
  DEFAULT_ISO_PASSWORD_ALGORITHM="sha512"
  DEFAULT_ISO_BOOT_LOADER_LOCATION="mbr"
  DEFAULT_ISO_OEM_INSTALL="auto"
  DEFAULT_ZFS_FILESYSTEMS="/var /var/lib /var/lib/AccountsService /var/lib/apt /var/lib/dpkg /var/lib/NetworkManager /srv /usr /usr/local /var/games /var/log /var/mail /var/snap /var/spool /var/www"
  VM_EXISTS="false"
  ISO_DHCP="true"
  TEST_MODE="false"
  FORCE_MODE="false"
  FULL_FORCE_MODE="false"
  VERBOSE_MODE="false"
  TEMP_VERBOSE_MODE="false"
  INTERACTIVE_MODE="false"
  ISO_USE_BIOSDEVNAME="false"
  ISO_PREFIX=""
  ISO_SUFFIX=""
  BMC_PORT="443"
  BMC_EXPOSE_DURATION="180"
}

# Function: reset_defaults 
# 
# Reset defaults

reset_defaults () {
  if [[ "$ISO_OS_NAME" =~ "rocky" ]]; then
    DEFAULT_ISO_NIC="link"
    DEFAULT_ISO_ARCH="x86_64"
    CURRENT_ISO_RELEASE="9.3"
    CURRENT_ISO_RELEASE_9="9.3"
    DEFAULT_ISO_RELEASE="$CURRENT_ISO_RELEASE"
    DEFAULT_ISO_MAJOR_RELEASE=$(echo "$DEFAULT_ISO_RELEASE" |cut -f1 -d.)
    DEFAULT_ISO_MINOR_RELEASE=$(echo "$DEFAULT_ISO_RELEASE" |cut -f2 -d.)
    DEFAULT_ISO_OS_NAME="rocky"
    DEFAULT_ISO_HOSTNAME="rocky"
    DEFAULT_ISO_REALNAME="Rocky"
    DEFAULT_ISO_USERNAME="rocky"
    DEFAULT_ISO_PASSWORD="rocky"
    DEFAULT_ISO_BUILD_TYPE="dvd"
    DEFAULT_WORK_DIR="$HOME/$SCRIPT_NAME/$DEFAULT_ISO_OS_NAME/$DEFAULT_ISO_RELEASE"
    DEFAULT_ISO_MOUNT_DIR="$DEFAULT_WORK_DIR/isomount"
    DEFAULT_INPUT_FILE="$DEFAULT_WORK_DIR/$DEFAULT_ISO_REALNAME-$DEFAULT_ISO_RELEASE-$DEFAULT_ISO_ARCH-dvd.iso"
    DEFAULT_INPUT_FILE_BASE=$( basename "$DEFAULT_INPUT_FILE" )
    DEFAULT_OUTPUT_FILE_BASE=$( basename "$DEFAULT_OUTPUT_FILE" )
    DEFAULT_ISO_URL="https://download.rockylinux.org/pub/rocky/$DEFAULT_ISO_MAJOR_RELEASE/isos/$DEFAULT_ISO_ARCH/$DEFAULT_INPUT_FILE_BASE"
  fi
}

# Function: set_default_flags
#
# Set default flags 

set_default_flags () {
  DO_NO_MULTIPATH="false"
  DO_KVM_PACKAGES="false"
  DO_NO_HWE_KERNEL="false"
  DO_CLUSTER_PACKAGES="false"
  DO_DAILY_ISO="false"
  DO_CHECK_DOCKER="false"
  DO_CHECK_ISO="false"
  DO_CREATE_VM="false"
  DO_DELETE_VM="false"
  DO_LIST_VM="false"
  DO_OLD_INSTALLER="false"
  DO_CUSTOM_BOOT_SERVER_FILE="false"
  DO_INSTALL_REQUIRED_PACKAGES="false"
  DO_INSTALL_ISO_NETWORK_UPDATES="false"
  DO_INSTALL_ISO_PACKAGES="false"
  DO_INSTALL_ISO_DRIVERS="false"
  DO_INSTALL_ISO_CODECS="false"
  DO_ISO_AUTO_UPGRADES="false"
  DO_ISO_APT_NEWS="false"
  DO_GET_BASE_ISO="false"
  DO_CHECK_WORK_DIR="false"
  DO_PREPARE_AUTOINSTALL_ISO_ONLY="false"
  DO_CREATE_AUTOINSTALL_ISO_FULL="false"
  DO_CREATE_AUTOINSTALL_ISO_ONLY="false"
  DO_EXECUTE_ISO_CHROOT_SCRIPT="false"
  DO_PRINT_HELP="true"
  DO_NO_UNMOUNT_ISO="false"
  DO_INSTALL_ISO_UPDATE="false"
  DO_INSTALL_ISO_UPGRADE="false"
  DO_INSTALL_ISO_DIST_UPGRADE="false"
  DO_ISO_SQUASHFS_UPDATE="false"
  DO_ISO_QUERY="false"
  DO_DOCKER="false"
  DO_PRINT_ENV="false"
  DO_INSTALL_SERVER="false"
  DO_CREATE_EXPORT="false"
  DO_CREATE_ANSIBLE="false"
  DO_CHECK_RACADM="false"
  DO_EXECUTE_RACADM="false"
  DO_LIST_ISOS="false"
  DO_SCP_HEADER="false"
  DO_SERIAL="true"
  DO_CUSTOM_AUTO_INSTALL="false"
  DO_ISO_SEARCH_DRIVERS="false"
  DO_ISO_PRESERVE_SOURCES="false"
  DO_PLAIN_TEXT_PASSWORD="false"
}

# Function: set_default_os_name
#
# Set default OS name

set_default_os_name () {
  if [ -f "/usr/bin/lsb_release" ]; then
    LSB_RELEASE=$( lsb_release -s -a )
    if [[ "$LSB_RELEASE" =~ "Ubuntu" ]]; then
      DEFAULT_ISO_OS_NAME=$( lsb_release -d |awk '{print $2}' |tr '[:upper:]' '[:lower:]' )
    else
      DEFAULT_ISO_OS_NAME="$CURRENT_ISO_OS_NAME"
      if [[ "$LSB_RELEASE" =~ "Arch" ]] || [[ "$LSB_RELEASE" =~ "Endeavour" ]]; then
        REQUIRED_PACKAGES="p7zip lftp wget xorriso whois squashfs-tools sudo file rsync ansible dialog"
      fi
    fi
  else
    DEFAULT_ISO_OS_NAME="$CURRENT_ISO_OS_NAME"
  fi
}

# Function: set_default_arch
#
# Set default zrchitecture

set_default_arch () {
  if [ -f "/usr/bin/uname" ]; then
    if [ "$OS_NAME" = "Linux" ]; then
      if [ "$( command -v ifconfig )" ]; then
        DEFAULT_BOOT_SERVER_IP=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
      else
        DEFAULT_BOOT_SERVER_IP=$( ip addr | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' |cut -f1 -d/ )
      fi
      if [ "$ISO_OS_NAME" = "rocky" ]; then
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
        DEFAULT_BOOT_SERVER_IP=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
      else
        DEFAULT_BOOT_SERVER_IP=$( ip add | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' |cut -f1 -d/ )
      fi
    fi
  else
    DEFAULT_ISO_ARCH="$CURRENT_ISO_ARCH"
    DEFAULT_BOOT_SERVER_IP=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
  fi
}

# Function: set_default_release
#
# Set default release

set_default_release () {
  if [ -f "/usr/bin/lsb_release" ]; then
    if [ "$DEFAULT_ISO_OS_NAME" = "Ubuntu" ]; then
      DEFAULT_ISO_RELEASE=$( lsb_release -d |awk '{print $3}' )
    else
      DEFAULT_ISO_RELEASE="$CURRENT_ISO_RELEASE"
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
    if [ "$DEFAULT_ISO_OS_NAME" = "Ubuntu" ]; then
      DEFAULT_ISO_CODENAME=$( lsb_release -cs )
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
  DEFAULT_WORK_DIR="$HOME/$SCRIPT_NAME/$DEFAULT_ISO_OS_NAME/$DEFAULT_ISO_RELEASE"
  DEFAULT_OLD_WORK_DIR="$HOME/$SCRIPT_NAME/$DEFAULT_ISO_OS_NAME/$DEFAULT_OLD_ISO_RELEASE"
  MASKED_DEFAULT_WORK_DIR="$HOME/$SCRIPT_NAME/$DEFAULT_ISO_OS_NAME/$DEFAULT_ISO_RELEASE"
  DEFAULT_ISO_MOUNT_DIR="$DEFAULT_WORK_DIR/isomount"
  DEFAULT_OLD_ISO_MOUNT_DIR="$DEFAULT_OLD_WORK_DIR/isomount"
  DEFAULT_ISO_AUTOINSTALL_DIR="autoinstall"
  DEFAULT_ISO_TARGET_MOUNT="/target"
  DEFAULT_ISO_INSTALL_MOUNT="/cdrom"
}

# Function: reset_default_dirs
#
# Update Default work directories

reset_default_dirs () {
  ISO_MOUNT_DIR="$WORK_DIR/isomount"
  OLD_ISO_MOUNT_DIR="$OLD_WORK_DIR/isomount"
  ISO_NEW_DIR="$WORK_DIR/isonew"
  ISO_SOURCE_DIR="$WORK_DIR/source-files"
}

# Function: set_default_files
#
# Set default file names/locations

set_default_files () {
  DEFAULT_INPUT_FILE="$DEFAULT_WORK_DIR/files/ubuntu-$DEFAULT_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH.iso"
  DEFAULT_OLD_INPUT_FILE="$DEFAULT_OLD_WORK_DIR/files/ubuntu-$DEFAULT_OLD_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH.iso"
  DEFAULT_OUTPUT_FILE="$DEFAULT_WORK_DIR/files/ubuntu-$DEFAULT_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH-$DEFAULT_ISO_BOOT_TYPE-autoinstall.iso"
  DEFAULT_BOOT_SERVER_FILE="$DEFAULT_OUTPUT_FILE"
  DEFAULT_ISO_SQUASHFS_FILE="$DEFAULT_ISO_MOUNT_DIR/casper/ubuntu-server-minimal.squashfs"
  DEFAULT_OLD_INSTALL_SQUASHFS_FILE="$DEFAULT_OLD_ISO_MOUNT_DIR/casper/ubuntu-server-minimal.ubuntu-server.installer.squashfs"
  DEFAULT_ISO_GRUB_FILE="$DEFAULT_WORK_DIR/grub.cfg"
  DEFAULT_ISO_VOLID="$DEFAULT_ISO_REALNAME $DEFAULT_ISO_RELEASE Server"
  DEFAULT_INPUT_FILE_BASE=$( basename "$DEFAULT_INPUT_FILE" )
  DEFAULT_OUTPUT_FILE_BASE=$( basename "$DEFAULT_OUTPUT_FILE" )
  DEFAULT_BOOT_SERVER_FILE_BASE=$(basename "$DEFAULT_BOOT_SERVER_FILE")
  DEFAULT_ISO_SQUASHFS_FILE_BASE=$( basename "$DEFAULT_ISO_SQUASHFS_FILE" )
  DEFAULT_ISO_GRUB_FILE_BASE=$( basename "$DEFAULT_ISO_GRUB_FILE" )
}

# Function: reset_default_files
#
# Update default files

reset_default_files () {
  ISO_GRUB_FILE="$WORK_DIR/grub.cfg"
  if [ "$ISO_MAJOR_RELEASE" -ge "22" ]; then
    ISO_SQUASHFS_FILE="$ISO_MOUNT_DIR/casper/ubuntu-server-minimal.squashfs"
    NEW_SQUASHFS_FILE="$ISO_SOURCE_DIR/casper/ubuntu-server-minimal.squashfs"
  else
    ISO_SQUASHFS_FILE="$ISO_MOUNT_DIR/casper/filesystem.squashfs"
    NEW_SQUASHFS_FILE="$ISO_SOURCE_DIR/casper/filesystem.squashfs"
  fi
}
