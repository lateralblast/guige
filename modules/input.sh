#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034

# Function: get_ssh_key
#
# Get SSH key if option set

get_ssh_key () {
  if [ "$DO_ISO_SSH_KEY" = "true" ]; then
    if ! [ -f "$ISO_SSH_KEY_FILE" ]; then
      warning_message "SSH Key file ($ISO_SSH_KEY_FILE) does not exist"
    else
      ISO_SSH_KEY=$(<"$ISO_SSH_KEY_FILE")
    fi
  fi
}

# Function: get_password_crypt
#
# Get password crypt
#
# echo test |mkpasswd --method=SHA-512 --stdin

get_password_crypt () {
  ISO_PASSWORD="$1"
  if [ "$OS_NAME" = "Darwin" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      ISO_PASSWORD_CRYPT=$( echo -n "$ISO_PASSWORD" |openssl sha512 | awk '{ print $2 }' )
    fi
  else
    if [ ! -f "/usr/bin/mkpasswd" ]; then
      install_required_packages "$REQUIRED_PACKAGES"
    fi
    if [ "$TEST_MODE" = "false" ]; then
      ISO_PASSWORD_CRYPT=$( echo "$ISO_PASSWORD" |mkpasswd --method=SHA-512 --stdin )
    fi
  fi
  if [ "$ISO_PASSWORD_CRYPT" = "" ]; then
    warning_message "No Password Hash/Crypt created"
    exit
  fi
  echo "$ISO_PASSWORD_CRYPT"
}

# Function: get_my_ip
#
# Get my IP

get_my_ip () {
  if [ "$OS_NAME" = "Darwin" ]; then
    MY_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 |head -1 |awk '{print $2}')
  else
    if [[ "$LSB_RELEASE" =~ "Arch" ]] || [[ "$LSB_RELEASE" =~ "Endeavour" ]]; then
      MY_IP=$(ip addr |grep 'inet ' |grep -v 127 |head -1 |awk '{print $2}' |cut -f1 -d/)
    else
      MY_IP=$(hostname -I |awk '{print $1}')
    fi
  fi
}

# Function: get_current_release
#
# Get current release

get_current_release () {
  case "$ISO_RELEASE" in
    "25.04")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2504"
      ;;
    "24.10")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2410"
      ;;
    "24.04")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2404"
      ;;
    "23.10")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2310"
      ;;
    "23.04")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2304"
      ;;
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
}

# Function: get_codename
#
# Get Ubuntu relase codename

get_code_name () {
  RELEASE_NO="$ISO_MAJOR_RELEASE.$ISO_MINOR_RELEASE"
  if [ "$RELEASE_NO" = "." ]; then
    RELEASE_NO="$ISO_RELEASE"
  fi
  case $RELEASE_NO in
    "20.04")
      DEFAULT_ISO_CODENAME="focal"
      ISO_CODENAME="focal"
      ;;
    "20.10")
      DEFAULT_ISO_CODENAME="groovy"
      ISO_CODENAME="groovy"
      ;;
    "21.04")
      DEFAULT_ISO_CODENAME="hirsute"
      ISO_CODENAME="hirsute"
      ;;
    "21.10")
      DEFAULT_ISO_CODENAME="impish"
      ISO_CODENAME="impish"
      ;;
    "22.04")
      DEFAULT_ISO_CODENAME="jammy"
      ISO_CODENAME="jammy"
      ;;
    "22.10")
      DEFAULT_ISO_CODENAME="kinetic"
      ISO_CODENAME="kinetic"
      ;;
    "23.04")
      DEFAULT_ISO_CODENAME="lunar"
      ISO_CODENAME="lunar"
      ;;
    "23.10")
      DEFAULT_ISO_CODENAME="mantic"
      ISO_CODENAME="mantic"
      ;;
    "24.04")
      DEFAULT_ISO_CODENAME="noble"
      ISO_CODENAME="noble"
      ;;
    "24.10")
      DEFAULT_ISO_CODENAME="oracular"
      ISO_CODENAME="oracular"
      ;;
    "25.04")
      DEFAULT_ISO_CODENAME="plucky"
      ISO_CODENAME="plucky"
      ;;
  esac
}

# Function: get_build_type
#
# Get build type based on release

get_build_type () {
  case $ISO_CODENAME in
    "oracular")
      DEFAULT_ISO_BUILD_TYPE="daily-live"
      ISO_BUILD_TYPE="daily-live"
      ;;
  esac
}

# Function: get_interactive_input
#
# Get values for script interactively

get_interactive_input () {
  if [ "$DO_CREATE_EXPORT" = "true" ] || [ "$DO_CREATE_ANSIBLE" = "true" ]; then
    if [ "$DO_CREATE_EXPORT" = "true" ] || [ "$DO_CREATE_ANSIBLE" = "true" ]; then
      # Get bootserver IP
      read -r -p "Enter Bootserver IP [$BOOT_SERVER_IP]: " NEW_BOOT_SERVER_IP
      BOOT_SERVER_IP=${NEW_BOOT_SERVER_IP:-$BOOT_SERVER_IP}
      # Get bootserver file
      read -r -p "Enter Bootserver file [$BOOT_SERVER_FILE]: " NEW_BOOT_SERVER_FILE
      BOOT_SERVER_FILE=${NEW_BOOT_SERVER_FILE:-$BOOT_SERVER_FILE}
    fi
    if [ "$DO_CREATE_ANSIBLE" = "true" ]; then
      # Get BMC IP
      read -r -p "Enter BMC/iDRAC IP [$BMC_IP]: " NEW_BMC_IP
      BMC_IP=${NEW_BMC_IP:-$BMC_IP}
      # Get BMC Username
      read -r -p "Enter BMC/iDRAC Username [$BMC_USERNAME]: " NEW_BMC_USERNAME
      BMC_USERNAME=${NEW_BMC_USERNAME:-$BMC_USERNAME}
      # Get BMC Password
      read -r -p "Enter BMC/iDRAC Password [$BMC_PASSWORD]: " NEW_BMC_PASSWORD
      BMC_PASSWORD=${NEW_BMC_PASSWORD:-$BMC_PASSWORD}
    fi
  else
    # Get release
    read -r -p "Enter Release [$ISO_RELEASE]: " NEW_ISO_RELEASE
    ISO_RELEASE=${NEW_ISO_RELEASE:-$ISO_RELEASE}
    # Get codename
    read -r -p "Enter Codename [$ISO_CODENAME: " NEW_ISO_CODENAME
    ISO_CODENAME=${NEW_ISO_CODENAME:-$ISO_CODENAME}
    # Get Architecture
    read -r -p "Architecture [$ISO_ARCH]: "
    ISO_ARCH=${NEW_ISO_ARCH:-$ISO_ARCH}
    # Get Work directory
    read -r -p "Enter Work directory [$WORK_DIR]: " NEW_WORK_DIR
    WORK_DIR=${NEW_WORK_DIR:-$WORK_DIR}
    # Get ISO input file
    read -r -p "Enter ISO input file [$ISO_INPUT_FILE]: " NEW_ISO_INPUT_FILE
    ISO_INPUT_FILE=${NEW_ISO_INPUT_FILE:-$ISO_INPUT_FILE}
    # Get CI input file
    read -r -p "Enter CI input file [$CI_INPUT_FILE]: " NEW_CI_INPUT_FILE
    CI_INPUT_FILE=${NEW_CI_INPUT_FILE:-$CI_INPUT_FILE}
    # Get ISO output file
    read -r -p "Enter ISO output file [$ISO_OUTPUT_FILE]: " NEW_ISO_OUTPUT_FILE
    ISO_OUTPUT_FILE=${NEW_ISO_OUTPUT_FILE:-$ISO_OUTPUT_FILE}
    # Get CI output file
    read -r -p "Enter CI output file [$CI_OUTPUT_FILE]: " NEW_CI_OUTPUT_FILE
    CI_OUTPUT_FILE=${NEW_CI_OUTPUT_FILE:-$CI_OUTPUT_FILE}
    # Get ISO URL
    read -r -p "Enter ISO URL [$ISO_URL]: " NEW_ISO_URL
    ISO_URL=${NEW_ISO_URL:-$ISO_URL}
    # Get CI URL
    read -r -p "Enter ISO URL [$CI_URL]: " NEW_CI_URL
    CI_URL=${NEW_CI_URL:-$CI_URL}
    # Get ISO Volume ID
    read -r -p "Enter ISO Volume ID [$ISO_VOLID]: " NEW_ISO_VOLID
    ISO_VOLID=${NEW_ISO_VOLID:-$ISO_VOLID}
    # Get Hostname
    read -r -p "Enter Hostname[$ISO_HOSTNAME]: " NEW_ISO_HOSTNAME
    ISO_HOSTNAME=${NEW_ISO_HOSTNAME:-$ISO_HOSTNAME}
    # Get Username
    read -r -p "Enter Username [$ISO_USERNAME]: " NEW_ISO_USERNAME
    ISO_USERNAME=${NEW_ISO_USERNAME:-$ISO_USERNAME}
    # Get User Real NAme
    read -r -p "Enter User Realname [$ISO_REALNAME]: " NEW_ISO_REALNAME
    ISO_REALNAME=${NEW_ISO_REALNAME:-$ISO_REALNAME}
    # Get Password
    read -r -s -p "Enter password [$ISO_PASSWORD]: " NEW_ISO_PASSWORD
    ISO_PASSWORD=${NEW_ISO_PASSWORD:-$ISO_PASSWORD}
    # Get wether to allow SSH Password
    read -r -s -p "Allow SSH access with password [$ISO_ALLOW_PASSWORD]: " NEW_ISO_ALLOW_PASSWORD
    ISO_ALLOW_PASSWORD=${NEW_ISO_ALLOW_PASSWORD:-$ISO_ALLOW_PASSWORD}
    # Get Timezone
    read -r -p "Enter Timezone: " NEW_ISO_TIMEZONE
    ISO_TIMEZONE=${NEW_ISO_TIMEZONE:-$ISO_TIMEZONE}
    # Get NIC
    read -r -p "Enter NIC [$ISO_NIC]: " NEW_ISO_NIC
    ISO_NIC=${NEW_ISO_NIC:-$ISO_NIC}
    # Get DHCP
    read -r -p "Use DHCP? [$DO_DHCP]: " NEW_DO_DHCP
    DO_DHCP=${NEW_DO_DHCP:-$DO_DHCP}
    # Get Static IP information if no DHCP
    if [ "$DO_DHCP" = "false" ]; then
      # Get IP
      read -r -p "Enter IP [$ISO_IP]: " NEW_ISO_IP
      ISO_IP=${NEW_ISO_IP:-$ISO_IP}
      # Get CIDR
      read -r -p "Enter CIDR [$ISO_CIDR]: " NEW_ISO_CIDR
      ISO_CIDR=${NEW_ISO_CIDR:-$ISO_CIDR}
      # Get Geteway
      read -r -p "Enter Gateway [$ISO_GATEWAY]: " NEW_ISO_GATEWAY
      ISO_GATEWAY=${NEW_ISO_GATEWAY:-$ISO_GATEWAY}
      # Get DNS
      read -r -p "Enter DNS [$ISO_DNS]: " NEW_ISO_DNS
      ISO_DNS=${NEW_ISO_DNS:-$ISO_DNS}
    fi
    # Get Install Mode
    read -r -p "Install Mode [$ISO_INSTALL_MODE]: " NEW_ISO_INSTALL_MODE
    ISO_INSTALL_MODE=${NEW_ISO_INSTALL_MODE:-$ISO_INSTALL_MODE}
    # Get Kernel
    read -r -p "Enter Kernel [$ISO_KERNEL]: " NEW_ISO_KERNEL
    ISO_KERNEL=${NEW_ISO_KERNEL:-$ISO_KERNEL}
    # Get Kernel Arguments
    read -r -p "Enter Kernel Arguments [$ISO_KERNEL_ARGS]: " NEW_ISO_KERNEL_ARGS
    ISO_KERNEL_ARGS=${NEW_ISO_KERNEL_ARGS:-$ISO_KERNEL_ARGS}
    # Get Keyboard Layout
    read -r -p "Enter IP [$ISO_LAYOUT]: " NEW_ISO_LAYOUT
    ISO_LAYOUT=${NEW_ISO_LAYOUT:-$ISO_LAYOUT}
    # Get Locale
    read -r -p "Enter IP [$ISO_LOCALE]: " NEW_ISO_LOCALE
    ISO_LOCALE=${NEW_ISO_LOCALE:-$ISO_LOCALE}
    # Get LC _ALL
    read -r -p "Enter LC_ALL [$ISO_LC_ALL]: " NEW_ISO_LC_ALL
    ISO_LC_ALL=${NEW_ISO_LC_ALL:-$ISO_LC_ALL}
    # Get Root Disk(s)
    read -r -p "Enter Root Disk(s) [$ISO_DISK]: " NEW_ISO_DISK
    ISO_DISK=${NEW_ISO_DISK:-$ISO_DISK}
    # Get Volume Managers
    read -r -p "Enter Volume Manager(s) [$ISO_VOLMGRS]: " NEW_ISO_VOLMGRS
    ISO_VOLMGRS=${NEW_ISO_VOLMGRS:-$ISO_VOLMGRS}
    # Get Default Grub Menu selection
    read -r -p "Enter Default Grub Menu [$ISO_GRUB_MENU]: " NEW_ISO_GRUB_MENU
    ISO_GRUB_MENU=${NEW_ISO_GRUB_MENU:-$ISO_GRUB_MENU}
    # Get Grub Timeout
    read -r -p "Enter Grub Timeout [$ISO_GRUB_TIMEOUT]: " NEW_ISO_GRUB_TIMEOUT
    ISO_GRUB_TIMEOUT=${NEW_ISO_GRUB_TIMEOUT:-$ISO_GRUB_TIMEOUT}
    # Get Autoinstall directory
    read -r -p "Enter Auttoinstall Directory [$ISO_AUTOINSTALL_DIR]: " NEW_ISO_AUTOINSTALL_DIR
    ISO_AUTOINSTALL_DIR=${NEW_ISO_AUTOINSTALL_DIR:-$ISO_AUTOINSTALL_DIR}
    # Get Install Mount
    read -r -p "Enter Install Mount [$ISO_INSTALL_MOUNT]: " NEW_ISO_INSTALL_MOUNT
    ISO_INSTALL_MOUNT=${NEW_ISO_INSTALL_MOUNT:-$ISO_INSTALL_MOUNT}
    # Get Install Target
    read -r -p "Enter Install Target [$ISO_TARGET_MOUNT]: " NEW_ISO_TARGET_MOUNT
    ISO_TARGET_MOUNT=${NEW_ISO_TARGET_MOUNT:-$ISO_TARGET_MOUNT}
    # Get whether to do squashfs
    read -r -p "Recreate squashfs? [$DO_ISO_SQUASHFS_UPDATE]: " NEW_DO_ISO_SQUASHFS_UPDATE
    DO_ISO_SQUASHFS_UPDATE=${NEW_DO_ISO_SQUASHFS_UPDATE:-$DO_ISO_SQUASHFS_UPDATE}
    if  [ "$DO_ISO_SQUASHFS_UPDATE" = "true" ]; then
      # Get squashfs packages
      read -r -p "Enter Squashfs Packages [$ISO_CHROOT_PACKAGES]: " NEW_ISO_CHROOT_PACKAGES
      ISO_CHROOT_PACKAGES=${NEW_ISO_CHROOT_PACKAGES:-$ISO_CHROOT_PACKAGES}
    fi
    # Get whether to install packages as part of install
    read -r -p "Install additional packages [$DO_INSTALL_ISO_PACKAGES]: " NEW_DO_INSTALL_ISO_PACKAGES
    DO_INSTALL_ISO_PACKAGES=${NEW_DO_INSTALL_ISO_PACKAGES:-$DO_INSTALL_ISO_PACKAGES}
    if [ "$DO_INSTALL_ISO_PACKAGES" = "true" ]; then
      # Get IP
      read -r -p "Enter Additional Packages to install[$ISO_INSTALL_PACKAGES]: " NEW_ISO_INSTALL_PACKAGES
      ISO_INSTALL_PACKAGES=${NEW_ISO_INSTALL_PACKAGES:-$ISO_INSTALL_PACKAGES}
    fi
    # Get wether to install network updates
    read -r -p "Install Network Updates? [$DO_INSTALL_ISO_NETWORK_UPDATES]: " NEW_DO_INSTALL_ISO_NETWORK_UPDATES
    DO_INSTALL_ISO_NETWORK_UPDATES=${NEW_DO_INSTALL_ISO_NETWORK_UPDATES:-$DO_INSTALL_ISO_NETWORK_UPDATES}
    # Get whether to install updates
    if [ "$DO_INSTALL_ISO_NETWORK_UPDATES" = "true" ]; then
      read -r -p "Install updates? [$DO_INSTALL_ISO_UPDATE]: " NEW_DO_INSTALL_ISO_UPDATE
      DO_INSTALL_ISO_UPDATE=${NEW_DO_INSTALL_ISO_UPDATE:-$DO_INSTALL_ISO_UPDATE}
      if [ "$DO_INSTALL_ISO_UPDATE" = "true" ]; then
        # Get wether to install upgrades
        read -r -p "Upgrade packages? [$DO_INSTALL_ISO_UPGRADE]: " NEW_DO_INSTALL_ISO_UPGRADE
        DO_INSTALL_ISO_UPGRADE=${NEW_DO_INSTALL_ISO_UPGRADE:-$DO_INSTALL_ISO_UPGRADE}
        # Get whether to do a dist-updrage
        read -r -p "Install Distribution Upgrade if available (e.g. 20.04.4 -> 20.04.5)? [$DO_INSTALL_ISO_DIST_UPGRADE]: " NEW_DO_INSTALL_ISO_DIST_UPGRADE
        DO_INSTALL_ISO_DIST_UPGRADE=${NEW_DO_INSTALL_ISO_DIST_UPGRADE:-$DO_INSTALL_ISO_DIST_UPGRADE}
      fi
    fi
    # Get swap size
    read -r -p "Enter Swap Size [$ISO_SWAP_SIZE]: " NEW_ISO_SWAP_SIZE
    ISO_SWAP_SIZE=${NEW_ISO_SWAP_SIZE:-$ISO_SWAP_SIZE}
    # Determine wether we use an SSH key
    read -r -p "Use SSH keys? [$DO_ISO_SSH_KEY]: " NEW_DO_ISO_SSH_KEY
    DO_ISO_SSH_KEY=${NEW_DO_ISO_SSH_KEY:-$DO_ISO_SSH_KEY}
    if [ "$DO_ISO_SSH_KEY" = "true" ]; then
      # Determine wether we use an SSH key
      read -r -p "SSH keys file [$ISO_SSH_KEY_FILE]: " NEW_ISO_SSH_KEY_FILE
      ISO_SSH_KEY_FILE=${NEW_ISO_SSH_KEY_FILE:-$ISO_SSH_KEY_FILE}
    fi
    if [ "$ISO_OS_NAME" = "rocky" ]; then
      # Get type of OEM install
      read -r -p "OEM Install? [$ISO_OEM_INSTALL]: " NEW_ISO_OEM_INSTALL
      ISO_OEM_INSTALL=${NEW_ISO_OEM_INSTALL:-$ISO_OEM_INSTALL}
      # Install Source
      read -r -p "Install Source? [$ISO_INSTALL_SOURCE]: " NEW_ISO_INSTALL_SOURCE
      ISO_INSTALL_SOURCE=${NEW_ISO_INSTALL_SOURCE:-$ISO_INSTALL_SOURCE}
      # Install Mode
      read -r -p "Install Mode? [$ISO_INSTALL_MODE]: " NEW_ISO_INSTALL_MODE
      ISO_INSTALL_MODE=${NEW_ISO_INSTALL_MODE:-$ISO_INSTALL_MODE}
      # Install Username
      read -r -p "SSH Install Username? [$ISO_INSTALL_USERNAME]: " NEW_ISO_INSTALL_USERNAME
      ISO_INSTALL_USERNAME=${NEW_ISO_INSTALL_USERNAME:-$ISO_INSTALL_USERNAME}
      # Install Username
      read -r -p "SSH Install Password? [$ISO_INSTALL_PASSWORD]: " NEW_ISO_INSTALL_PASSWORD
      ISO_INSTALL_PASSWORD=${NEW_ISO_INSTALL_PASSWORD:-$ISO_INSTALL_PASSWORD}
      # Get Password Algorithm
      read -r -p "Password Algorithm? [$ISO_PASSWORD_ALGORITHM]: " NEW_ISO_PASSWORD_ALGORITHM
      ISO_PASSWORD_ALGORITHM=${NEW_ISO_PASSWORD_ALGORITHM:-$ISO_PASSWORD_ALGORITHM}
      # Get Bootloader Location
      read -r -p "Bootloader Location? [$ISO_BOOT_LOADER_LOCATION]: " NEW_ISO_BOOTLOADER_LOCATION
      ISO_BOOT_LOADER_LOCATION=${NEW_ISO_BOOTLOADER_LOCATION:-$ISO_BOOT_LOADER_LOCATION}
      # Get SELinux mode
      read -r -p "SELinux Mode? [$ISO_SELINUX]: " NEW_ISO_SELINUX
      ISO_SELINUX=${NEW_ISO_SELINUX:-$ISO_SELINUX}
      # Firewall
      read -r -p "Firewall? [$ISO_FIREWALL]: " NEW_ISO_FIREWALL
      ISO_FIREWALL=${NEW_ISO_FIREWALL:-$ISO_FIREWALL}
      # Allow services
      read -r -p "Allow Services? [$ISO_ALLOW_SERVICE]: " NEW_ISO_ALLOW_SERVICE
      ISO_ALLOW_SERVICE=${NEW_ISO_ALLOW_SERVICE:-$ISO_ALLOW_SERVICE}
      # Network boot protocol
      read -r -p "Network Boot Protocol? [$ISO_BOOT_PROTO]: " NEW_ISO_BOOT_PROTO
      ISO_BOOT_PROTO=${NEW_ISO_BOOT_PROTO:-$ISO_BOOT_PROTO}
      # Enable Network on boot
      read -r -p "Enable Network on boot? [$ISO_ONBOOT]: " NEW_ISO_ONBOOT
      ISO_ONBOOT=${NEW_ISO_ONBOOT:-$ISO_ONBOOT}
      # User GECOS field
      read -r -p "User GECOS? [$ISO_GECOS]: " NEW_ISO_GECOS
      ISO_GECOS=${NEW_ISO_GECOS:-$ISO_GECOS}
      # User Groups
      read -r -p "User Groups? [$ISO_GROUPS]: " NEW_ISO_GROUPS
      ISO_GROUPS=${NEW_ISO_GROUPS:-$ISO_GROUPS}
      # VG Name
      read -r -p "Volume Group Name? [$ISO_VG_NAME]: " NEW_ISO_VG_NAME
      ISO_VG_NAME=${NEW_ISO_VG_NAME:-$ISO_VG_NAME}
      # LV Name
      read -r -p "Logic Volume Name? [$ISO_LV_NAME]: " NEW_ISO_LV_NAME
      ISO_LV_NAME=${NEW_ISO_LV_NAME:-$ISO_LV_NAME}
      # Boot Partition Size
      read -r -p "Boot Partition Size? [$ISO_BOOT_SIZE]: " NEW_ISO_BOOT_SIZE
      ISO_BOOT_SIZE=${NEW_ISO_BOOT_SIZE:-$ISO_BOOT_SIZE}
      # PE Size
      read -r -p "PE Size? [$ISO_PE_SIZE]: " NEW_ISO_PE_SIZE
      ISO_PE_SIZE=${NEW_ISO_PE_SIZE:-$ISO_PE_SIZE}
    fi
    # Get whether to install drivers
    read -r -p "Install Drivers? [$DO_INSTALL_ISO_DRIVERS]: " NEW_INSTALL_ISO_DRIVERS
    DO_INSTALL_ISO_DRIVERS=${NEW_INSTALL_ISO_DRIVERS:-$DO_INSTALL_ISO_DRIVERS}
    # Get whether to install codecs
    read -r -p "Install Codecs? [$DO_INSTALL_ISO_CODECS]: " NEW_INSTALL_ISO_CODECS
    DO_INSTALL_ISO_CODECS=${NEW_INSTALL_ISO_CODECS:-$DO_INSTALL_ISO_CODECS}
    # Get Serial Port 0
    read -r -p "First Serial Port? [$ISO_SERIAL_PORT0]: " NEW_ISO_SERIAL_PORT0
    ISO_SERIAL_PORT0=${NEW_ISO_SERIAL_PORT0:-$ISO_SERIAL_PORT0}
    # Get Serial Port 1
    read -r -p "Second Serial Port? [$ISO_SERIAL_PORT1]: " NEW_ISO_SERIAL_PORT1
    ISO_SERIAL_PORT1=${NEW_ISO_SERIAL_PORT1:-$ISO_SERIAL_PORT1}
    # Get Serial Port Address 0
    read -r -p "First Serial Port Address? [$ISO_SERIAL_PORT_ADDRESS0]: " NEW_ISO_SERIAL_PORT_ADDRESS0
    ISO_SERIAL_PORT_ADDRESS0=${NEW_ISO_SERIAL_PORT_ADDRESS0:-$ISO_SERIAL_PORT_ADDRESS0}
    # Get Serial Port Address 1
    read -r -p "Second Serial Port Address? [$ISO_SERIAL_PORT_ADDRESS1]: " NEW_ISO_SERIAL_PORT_ADDRESS1
    ISO_SERIAL_PORT_ADDRESS1=${NEW_ISO_SERIAL_PORT_ADDRESS1:-$ISO_SERIAL_PORT_ADDRESS1}
    # Get Serial Port Speed 0
    read -r -p "First Serial Port Speed? [$ISO_SERIAL_PORT_SPEED0]: " NEW_ISO_SERIAL_PORT_SPEED0
    ISO_SERIAL_PORT_SPEED0=${NEW_ISO_SERIAL_PORT_SPEED0:-$ISO_SERIAL_PORT_SPEED0}
    # Get Serial Port Speed 1
    read -r -p "Second Serial Port Speed? [$ISO_SERIAL_PORT_SPEED1]: " NEW_ISO_SERIAL_PORT_SPEED1
    ISO_SERIAL_PORT_SPEED1=${NEW_ISO_SERIAL_PORT_SPEED1:-$ISO_SERIAL_PORT_SPEED1}
  fi
}
