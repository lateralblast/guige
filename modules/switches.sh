# Function: process_switches
#
# Process switches

process_switches () {
  if [ "$ISO_INSTALL_USERNAME" = "" ]; then
    ISO_INSTALL_USERNAME="$DEFAULT_ISO_INSTALL_USERNAME"
  fi
  if [ "$ISO_INSTALL_PASSWORD" = "" ]; then
    ISO_INSTALL_PASSWORD="$DEFAULT_ISO_INSTALL_PASSWORD"
  fi
  if [ "$ISO_VG_NAME" = "" ]; then
    ISO_VG_NAME="$DEFAULT_ISO_VG_NAME"
  fi
  if [ "$ISO_PE_SIZE" = "" ]; then
    ISO_PE_SIZE="$DEFAULT_ISO_PE_SIZE"
  fi
  if [ "$ISO_BOOT_SIZE" = "" ]; then
    ISO_BOOT_SIZE="$DEFAULT_ISO_BOOT_SIZE"
  fi
  if [ "$ISO_ROOT_SIZE" = "" ]; then
    ISO_ROOT_SIZE="$DEFAULT_ISO_ROOT_SIZE"
  fi
  if [ "$ISO_SELINUX" = "" ]; then
    ISO_SELINUX="$DEFAULT_ISO_SELINUX"
  fi
  if [ "$ISO_INSTALL_SOURCE" = "" ]; then
    ISO_INSTALL_SOURCE="$DEFAULT_ISO_INSTALL_SOURCE"
  fi
  if [ "$ISO_GROUPS" = "" ]; then
    ISO_GROUPS="$DEFAULT_ISO_GROUPS"
  fi
  if [ "$ISO_GECOS" = "" ]; then
    ISO_GECOS="$DEFAULT_ISO_GECOS"
  fi
  if [ "$ISO_ENABLE_SERVICE" = "" ]; then
    ISO_ENABLE_SERVICE="$DEFAULT_ISO_ENABLE_SERVICE"
  fi
  if [ "$ISO_DISABLE_SERVICE" = "" ]; then
    ISO_DISABLE_SERVICE="$DEFAULT_ISO_DISABLE_SERVICE"
  fi
  if [ "$ISO_ONBOOT" = "" ]; then
    ISO_ONBOOT="$DEFAULT_ISO_ONBOOT"
  fi
  if [ "$ISO_ALLOW_SERVICE" = "" ]; then
    ISO_ALLOW_SERVICE="$DEFAULT_ISO_ALLOW_SERVICE"
  fi
  if [ "$ISO_FIREWALL" = "" ]; then
    ISO_FIREWALL="$DEFAULT_ISO_FIREWALL"
  fi
  if [ "$ISO_SELINUX" = "" ]; then
    ISO_SELINUX="$DEFAULT_ISO_SELINUX"
  fi
  if [ "$ISO_BOOT_LOADER_LOCATION" = "" ]; then
    ISO_BOOT_LOADER_LOCATION="$DEFAULT_ISO_BOOT_LOADER_LOCATION"
  fi
  if [ "$ISO_PASSWORD_ALGORITHM" = "" ]; then
    ISO_PASSWORD_ALGORITHM="$DEFAULT_ISO_PASSWORD_ALGORITHM"
  fi
  if [ "$ISO_INSTALL_MODE" = "" ]; then
    ISO_INSTALL_MODE="$DEFAULT_ISO_INSTALL_MODE"
  fi
  if [ "$DO_CUSTOM_AUTO_INSTALL" = "true" ]; then
    if [ ! -f "$AUTO_INSTALL_FILE" ]; then
      if [ ! -f "/.dockerenv" ]; then
        echo "File $AUTO_INSTALL_FILE does not exist"
        exit
      fi
    fi
  fi
  if [ "$ISO_SOURCE_ID" = "" ]; then
    ISO_SOURCE_ID="$DEFAULT_ISO_SOURCE_ID"
  fi
  if [ "$ISO_OEM_INSTALL" = "" ]; then
    ISO_OEM_INSTALL="$DEFAULT_ISO_OEM_INSTALL"
  fi
  if [ "$ZFS_FILESYSTEMS" = "" ]; then
    ZFS_FILESYSTEMS="$DEFAULT_ZFS_FILESYSTEMS"
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
  if [[ "$ISO_SERIAL_PORT0" =~ "," ]]; then
      ISO_SERIAL_PORT0=$(echo "$ISO_SERIAL_PORT0" |cut -f1 -d,)
      ISO_SERIAL_PORT1=$(echo "$ISO_SERIAL_PORT1" |cut -f2 -d,)
  else
    if [ "$ISO_SERIAL_PORT0" = "" ]; then
      ISO_SERIAL_PORT0="$DEFAULT_ISO_SERIAL_PORT0"
      ISO_SERIAL_PORT1="$DEFAULT_ISO_SERIAL_PORT1"
    fi
  fi
  if [[ "$ISO_SERIAL_PORT_ADDRESS0" =~ "," ]]; then
    ISO_SERIAL_PORT_ADDRESS0=$(echo "$ISO_SERIAL_PORT_ADDRESS0" |cut -f1 -d,)
    ISO_SERIAL_PORT_ADDRESS1=$(echo "$ISO_SERIAL_PORT_ADDRESS1" |cut -f2 -d,)
  else
    if [ "$ISO_SERIAL_PORT_ADDRESS0" = "" ]; then
      ISO_SERIAL_PORT_ADDRESS0="$DEFAULT_ISO_SERIAL_PORT_ADDRESS0"
      ISO_SERIAL_PORT_ADDRESS1="$DEFAULT_ISO_SERIAL_PORT_ADDRESS1"
    fi
  fi
  if [ "$ISO_SERIAL_PORT_SPEED0" = "" ]; then
    ISO_SERIAL_PORT_SPEED0=$(echo "$DEFAULT_ISO_SERIAL_PORT_SPEED0" |cut -f1 -d,)
    ISO_SERIAL_PORT_SPEED1=$(echo "$DEFAULT_ISO_SERIAL_PORT_SPEED1" |cut -f2 -d,)
  else
    if [ "$ISO_SERIAL_PORT_SPEED0" = "" ]; then
      ISO_SERIAL_PORT_SPEED0="$DEFAULT_ISO_SERIAL_PORT_SPEED0"
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
  if [ "$ISO_SSH_KEY_FILE" = "" ]; then
    ISO_SSH_KEY_FILE="$DEFAULT_ISO_SSH_KEY_FILE"
  else
    ISO_SSH_KEY="$DEFAULT_ISO_SSH_KEY"
  fi
  if [ "$BOOT_SERVER_IP" = "" ]; then
    BOOT_SERVER_IP="$DEFAULT_BOOT_SERVER_IP"
  fi
  if [ "$BOOT_SERVER_FILE" = "" ]; then
    BOOT_SERVER_FILE="$DEFAULT_BOOT_SERVER_FILE"
  fi
  if [ "$BMC_USERNAME" = "" ]; then
    BMC_USERNAME="$DEFAULT_BMC_USERNAME"
  fi
  if [ "$BMC_PASSWORD" = "" ]; then
    BMC_PASSWORD="$DEFAULT_BMC_PASSWORD"
  fi
  if [ "$BMC_IP" = "" ]; then
    BMC_IP="$DEFAULT_BMC_IP"
  fi
  if [ "$ISO_CIDR" = "" ]; then
    ISO_CIDR="$DEFAULT_ISO_CIDR"
  fi
  if [ "$ISO_OS_NAME" = "" ]; then
    ISO_OS_NAME="$DEFAULT_ISO_OS_NAME"
  fi
  if [ "$ISO_RELEASE" = "" ]; then
    ISO_RELEASE="$DEFAULT_ISO_RELEASE"
  else
    if [ "$ISO_OS_NAME" = "ubuntu" ]; then
      case "$ISO_RELEASE" in
        "22.04")
          ISO_RELEASE="$CURRENT_ISO_RELEASE_2204"
          ;;
        "20.04")
          ISO_RELEASE="$CURRENT_ISO_RELEASE_2004"
          ;;
        "18.04")
          ISO_RELEASE="$CURRENT_ISO_RELEASE_1804"
          ;;
        "16.04")
          ISO_RELEASE="$CURRENT_ISO_RELEASE_1604"
          ;;
        "14.04")
          ISO_RELEASE="$CURRENT_ISO_RELEASE_1404"
          ;;
        *)
          ISO_RELEASE="$CURRENT_ISO_RELEASE"
          ;;
      esac
    else
      if [ "$ISO_OS_NAME" = "rocky" ]; then
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
  ISO_MAJOR_RELEASE=$(echo "$ISO_RELEASE" |cut -f1 -d.)
  ISO_MINOR_RELEASE=$(echo "$ISO_RELEASE" |cut -f2 -d.)
  ISO_POINT_RELEASE=$(echo "$ISO_RELEASE" |cut -f3 -d.)
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
    DO_DHCP="true"
  else
    DO_DHCP="false"
    ISO_BOOT_PROTO="static"
  fi
  if [ "$ISO_ALLOW_PASSWORD" = "" ]; then
    ISO_ALLOW_PASSWORD="$DEFAULT_ISO_ALLOW_PASSWORD"
  fi
  if [ "$ISO_PASSWORD" = "" ]; then
    ISO_PASSWORD="$DEFAULT_ISO_PASSWORD"
  fi
  if [ "$ISO_CHROOT_PACKAGES" = "" ]; then
    ISO_CHROOT_PACKAGES="$DEFAULT_ISO_INSTALL_PACKAGES"
  fi
  if [ "$ISO_INSTALL_PACKAGES" = "" ]; then
    ISO_INSTALL_PACKAGES="$DEFAULT_ISO_INSTALL_PACKAGES"
  fi
  if [ "$ISO_TIMEZONE" = "" ]; then
    ISO_TIMEZONE="$DEFAULT_ISO_TIMEZONE"
  fi
  if [ "$OUTPUT_FILE" = "" ]; then
    OUTPUT_FILE="$DEFAULT_OUTPUT_FILE"
  fi
  if [ "$ISO_NIC" = "" ]; then
    ISO_NIC="$DEFAULT_ISO_NIC"
  fi
  if [ "$SWAPSIZE" = "" ]; then
    ISO_SWAP_SIZE="$DEFAULT_ISO_SWAP_SIZE"
  fi
  if [ "$ISO_DISK" = "" ]; then
    ISO_DISK="$DEFAULT_ISO_DISK"
  fi
  if [ "$ISO_BOOT_TYPE" = "bios" ]; then
    if [[ "$OPTIONS" =~ "fs" ]]; then
      DEFAULT_ISO_VOLMGRS="lvm zfs xfs btrfs"
    else
      DEFAULT_ISO_VOLMGRS="lvm"
    fi
  fi
  if [ "$DO_CUSTOM_AUTO_INSTALL" = "true" ]; then
    DEFAULT_ISO_VOLMGRS="custom $DEFAULT_ISO_VOLMGRS"
  fi
  if [ "$ISO_VOLMGRS" = "" ]; then
    ISO_VOLMGRS="$DEFAULT_ISO_VOLMGRS"
  fi
  if [ "$GRUB_MENU" = "" ]; then
    ISO_GRUB_MENU="$DEFAULT_ISO_GRUB_MENU"
  fi
  if [ "$GRUB_TIMEOUT" = "" ]; then
    ISO_GRUB_TIMEOUT="$DEFAULT_ISO_GRUB_TIMEOUT"
  fi
  if [ "$ISO_KERNEL_ARGS" = "" ]; then
    ISO_KERNEL_ARGS="$DEFAULT_ISO_KERNEL_ARGS"
  fi
  if [ "$ISO_KERNEL" = "" ]; then
    if [ "$DO_CREATE_VM" = "true" ]; then
      ISO_KERNEL="$DEFAULT_VM_TYPE"
    else
      ISO_KERNEL="$DEFAULT_ISO_KERNEL"
    fi
  fi
  if [[ "$ACTION" =~ "iso" ]]; then
    if [ "$CODENAME" = "" ]; then
      get_code_name
    fi
  fi
  if [ "$ISO_LOCALE" = "" ]; then
    ISO_LOCALE="$DEFAULT_ISO_LOCALE"
  fi
  if [ "$ISO_LC_ALL" = "" ]; then
    ISO_LC_ALL="$DEFAULT_ISO_LC_ALL"
  fi
  if [ "$ISO_LAYOUT" = "" ]; then
    ISO_LAYOUT="$DEFAULT_ISO_LAYOUT"
  fi
  if [ "$ISO_INSTALL_MOUNT" = "" ]; then
    ISO_INSTALL_MOUNT="$DEFAULT_ISO_INSTALL_MOUNT"
  fi
  if [ "$ISO_TARGET_MOUNT" = "" ]; then
    ISO_TARGET_MOUNT="$DEFAULT_ISO_TARGET_MOUNT"
  fi
  if [ "$ISO_AUTOINSTALL_DIR" = "" ]; then
    ISO_AUTOINSTALL_DIR="$DEFAULT_ISO_AUTOINSTALL_DIR"
  fi
  if [ "$WORK_DIR" = "" ]; then
    if [ "$DO_DAILY_ISO" = "true" ]; then
      WORK_DIR="$HOME/$SCRIPT_NAME/$ISO_OS_NAME/$ISO_CODENAME"
      DOCKER_WORK_DIR="/root/$SCRIPT_NAME/$ISO_OS_NAME/$ISO_CODENAME"
    else
      WORK_DIR="$HOME/$SCRIPT_NAME/$ISO_OS_NAME/$ISO_RELEASE"
      DOCKER_WORK_DIR="/root/$SCRIPT_NAME/$ISO_OS_NAME/$ISO_RELEASE"
    fi
  else
    if [ "$DO_DAILY_ISO" = "true" ]; then
      WORK_DIR="$HOME/$SCRIPT_NAME/$ISO_OS_NAME/$ISO_CODENAME"
      DOCKER_WORK_DIR="/root/$SCRIPT_NAME/$ISO_OS_NAME/$ISO_CODENAME"
    fi
  fi
  if [ "$ISO_BUILD_TYPE" = "" ]; then
    ISO_BUILD_TYPE="$DEFAULT_ISO_BUILD_TYPE"
  fi
  if [ "$ISO_VOLID" = "" ]; then
    case $ISO_BUILD_TYPE in
      "daily-desktop"|"desktop")
        ISO_VOLID="$ISO_REALNAME $ISO_RELEASE Desktop"
        ;;
      *)
        ISO_VOLID="$ISO_REALNAME $ISO_RELEASE Server"
        ;;
    esac
  fi
  if [ "$INPUT_FILE" = "" ]; then
    INPUT_FILE="$DEFAULT_INPUT_FILE"
  fi
  if [ "$DO_ISO_QUERY" = "true" ]; then
    get_info_from_iso
  else
    if [ "$DO_CUSTOM_BOOT_SERVER_FILE" = "false" ]; then
      if [ "$ISO_OS_NAME" = "ubuntu" ]; then
        case $ISO_BUILD_TYPE in
          "daily-live"|"daily-live-server")
            INPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-live-server-$ISO_ARCH.iso"
            OUTPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-live-server-$ISO_ARCH-$ISO_BOOT_TYPE-autoinstall.iso"
            BOOT_SERVER_FILE="$OUTPUT_FILE"
            ;;
          "daily-desktop")
            INPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-desktop-$ISO_ARCH.iso"
            OUTPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-desktop-$ISO_ARCH-$ISO_BOOT_TYPE-autoinstall.iso"
            BOOT_SERVER_FILE="$OUTPUT_FILE"
            ;;
         "desktop")
            INPUT_FILE="$WORK_DIR/files/$ISO_OS_NAME-$ISO_RELEASE-desktop-$ISO_ARCH.iso"
            OUTPUT_FILE="$WORK_DIR/files/$ISO_OS_NAME-$ISO_RELEASE-desktop-$ISO_ARCH-$ISO_BOOT_TYPE-autoinstall.iso"
            BOOT_SERVER_FILE="$OUTPUT_FILE"
            ;;
          *)
            INPUT_FILE="$WORK_DIR/files/$ISO_OS_NAME-$ISO_RELEASE-live-server-$ISO_ARCH.iso"
            OUTPUT_FILE="$WORK_DIR/files/$$ISO_OS_NAME-$ISO_RELEASE-live-server-$ISO_ARCH-$ISO_BOOT_TYPE-autoinstall.iso"
            BOOT_SERVER_FILE="$OUTPUT_FILE"
            ;;
        esac
      else
        case $ISO_BUILD_TYPE in
          *)
            INPUT_FILE="$WORK_DIR/files/$ISO_REALNAME-$ISO_RELEASE-$ISO_ARCH-$ISO_BUILD_TYPE.iso"
            OUTPUT_FILE="$WORK_DIR/files/$$ISO_REALNAME-$ISO_RELEASE-$ISO_ARCH-$ISO_BOOT_TYPE-$ISO_BUILD_TYPE-kickstart.iso"
            BOOT_SERVER_FILE="$OUTPUT_FILE"
          ;;
        esac
      fi
    fi
  fi
  if [ "$ISO_SQUASHFS_FILE" = "" ]; then
    ISO_SQUASHFS_FILE="$DEFAULT_ISO_SQUASHFS_FILE"
  fi
  if [ "$ISO_GRUB_FILE" = "" ]; then
    ISO_GRUB_FILE="$DEFAULT_ISO_GRUB_FILE"
  fi
  if [ "$ISO_USE_BIOSDEVNAME" = "true" ]; then
    ISO_KERNEL_ARGS="$ISO_KERNEL_ARGS net.ifnames=0 biosdevname=0"
  fi
  if [ "$OLD_INPUT_FILE" = "" ]; then
    OLD_INPUT_FILE="$DEFAULT_OLD_INPUT_FILE"
  fi
}
