#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034

# Function: get_password_crypt
#
# Get password crypt
#
# echo test |mkpasswd --method=SHA-512 --stdin

get_password_crypt () {
  ISO_PASSWORD="$1"
  if [ "$OS_NAME" = "Darwin" ]; then
    if [ "$DO_ISO_TESTMODE" = "false" ]; then
      ISO_PASSWORD_CRYPT=$( echo -n "$ISO_PASSWORD" |openssl sha512 | awk '{ print $2 }' )
    fi
  else
    if [ ! -f "/usr/bin/mkpasswd" ]; then
      install_required_packages "$REQUIRED_PACKAGES"
    fi
    if [ "$DO_ISO_TESTMODE" = "false" ]; then
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
    "25.10")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2510"
      ;;
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
  RELEASE_NO="$ISO_MAJORRELEASE.$ISO_MINORRELEASE"
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
    "plucky")
      DEFAULT_ISO_BUILDTYPE="daily-live"
      ISO_BUILDTYPE="daily-live"
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
      read -r -p "Enter Bootserver IP [$ISO_BOOTSERVERIP]: " NEW_ISO_BOOTSERVERIP
      ISO_BOOTSERVERIP=${NEW_ISO_BOOTSERVERIP:-$ISO_BOOTSERVERIP}
      # Get bootserver file
      read -r -p "Enter Bootserver file [$ISO_BOOTSERVERFILE]: " NEW_ISO_BOOTSERVERFILE
      ISO_BOOTSERVERFILE=${NEW_ISO_BOOTSERVERFILE:-$ISO_BOOTSERVERFILE}
    fi
    if [ "$DO_CREATE_ANSIBLE" = "true" ]; then
      # Get BMC IP
      read -r -p "Enter BMC/iDRAC IP [$ISO_BMCIP]: " NEW_ISO_BMCIP
      ISO_BMCIP=${NEW_ISO_BMCIP:-$ISO_BMCIP}
      # Get BMC Username
      read -r -p "Enter BMC/iDRAC Username [$ISO_BMCUSERNAME]: " NEW_ISO_BMCUSERNAME
      ISO_BMCUSERNAME=${NEW_ISO_BMCUSERNAME:-$ISO_BMCUSERNAME}
      # Get BMC Password
      read -r -p "Enter BMC/iDRAC Password [$ISO_BMCPASSWORD]: " NEW_ISO_BMCPASSWORD
      ISO_BMCPASSWORD=${NEW_ISO_BMCPASSWORD:-$ISO_BMCPASSWORD}
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
    read -r -p "Enter Work directory [$ISO_WORKDIR]: " NEW_ISO_WORKDIR
    ISO_WORKDIR=${NEW_ISO_WORKDIR:-$ISO_WORKDIR}
    # Get ISO input file
    read -r -p "Enter ISO input file [$ISO_INPUTFILE]: " NEW_ISO_INPUTFILE
    ISO_INPUTFILE=${NEW_ISO_INPUTFILE:-$ISO_INPUTFILE}
    # Get CI input file
    read -r -p "Enter CI input file [$ISO_INPUTCI]: " NEW_ISO_INPUTCI
    ISO_INPUTCI=${NEW_ISO_INPUTCI:-$ISO_INPUTCI}
    # Get ISO output file
    read -r -p "Enter ISO output file [$ISO_OUTPUTFILE]: " NEW_ISO_OUTPUTFILE
    ISO_OUTPUTFILE=${NEW_ISO_OUTPUTFILE:-$ISO_OUTPUTFILE}
    # Get CI output file
    read -r -p "Enter CI output file [$ISO_OUTPUTCI]: " NEW_ISO_OUTPUTCI
    ISO_OUTPUTCI=${NEW_ISO_OUTPUTCI:-$ISO_OUTPUTCI}
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
    read -r -s -p "Allow SSH access with password [$ISO_ALLOWPASSWORD]: " NEW_ISO_ALLOWPASSWORD
    ISO_ALLOWPASSWORD=${NEW_ISO_ALLOWPASSWORD:-$ISO_ALLOWPASSWORD}
    # Get Timezone
    read -r -p "Enter Timezone: " NEW_ISO_TIMEZONE
    ISO_TIMEZONE=${NEW_ISO_TIMEZONE:-$ISO_TIMEZONE}
    # Get NIC
    read -r -p "Enter NIC [$ISO_NIC]: " NEW_ISO_NIC
    ISO_NIC=${NEW_ISO_NIC:-$ISO_NIC}
    # Get DHCP
    read -r -p "Use DHCP? [$DO_ISO_DHCP]: " NEW_DO_ISO_DHCP
    DO_ISO_DHCP=${NEW_DO_ISO_DHCP:-$DO_ISO_DHCP}
    # Get Static IP information if no DHCP
    if [ "$DO_ISO_DHCP" = "false" ]; then
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
    read -r -p "Install Mode [$ISO_INSTALLMODE]: " NEW_ISO_INSTALLMODE
    ISO_INSTALLMODE=${NEW_ISO_INSTALLMODE:-$ISO_INSTALLMODE}
    # Get Kernel
    read -r -p "Enter Kernel [$ISO_KERNEL]: " NEW_ISO_KERNEL
    ISO_KERNEL=${NEW_ISO_KERNEL:-$ISO_KERNEL}
    # Get Kernel Arguments
    read -r -p "Enter Kernel Arguments [$ISO_KERNELARGS]: " NEW_ISO_KERNELARGS
    ISO_KERNELARGS=${NEW_ISO_KERNELARGS:-$ISO_KERNELARGS}
    # Get Keyboard Layout
    read -r -p "Enter IP [$ISO_LAYOUT]: " NEW_ISO_LAYOUT
    ISO_LAYOUT=${NEW_ISO_LAYOUT:-$ISO_LAYOUT}
    # Get Locale
    read -r -p "Enter IP [$ISO_LOCALE]: " NEW_ISO_LOCALE
    ISO_LOCALE=${NEW_ISO_LOCALE:-$ISO_LOCALE}
    # Get LC _ALL
    read -r -p "Enter LC_ALL [$ISO_LCALL]: " NEW_ISO_LCALL
    ISO_LCALL=${NEW_ISO_LCALL:-$ISO_LCALL}
    # Get Root Disk(s)
    read -r -p "Enter Root Disk(s) [$ISO_DISK]: " NEW_ISO_DISK
    ISO_DISK=${NEW_ISO_DISK:-$ISO_DISK}
    # Get Volume Managers
    read -r -p "Enter Volume Manager(s) [$ISO_VOLMGRS]: " NEW_ISO_VOLMGRS
    ISO_VOLMGRS=${NEW_ISO_VOLMGRS:-$ISO_VOLMGRS}
    # Get Default Grub Menu selection
    read -r -p "Enter Default Grub Menu [$ISO_GRUBMENU]: " NEW_ISO_GRUBMENU
    ISO_GRUBMENU=${NEW_ISO_GRUBMENU:-$ISO_GRUBMENU}
    # Get Grub Timeout
    read -r -p "Enter Grub Timeout [$ISO_GRUBTIMEOUT]: " NEW_ISO_GRUBTIMEOUT
    ISO_GRUBTIMEOUT=${NEW_ISO_GRUBTIMEOUT:-$ISO_GRUBTIMEOUT}
    # Get Autoinstall directory
    read -r -p "Enter Auttoinstall Directory [$ISO_AUTOINSTALLDIR]: " NEW_ISO_AUTOINSTALLDIR
    ISO_AUTOINSTALLDIR=${NEW_ISO_AUTOINSTALLDIR:-$ISO_AUTOINSTALLDIR}
    # Get Install Mount
    read -r -p "Enter Install Mount [$ISO_INSTALLMOUNT]: " NEW_ISO_INSTALLMOUNT
    ISO_INSTALLMOUNT=${NEW_ISO_INSTALLMOUNT:-$ISO_INSTALLMOUNT}
    # Get Install Target
    read -r -p "Enter Install Target [$ISO_TARGETMOUNT]: " NEW_ISO_TARGETMOUNT
    ISO_TARGETMOUNT=${NEW_ISO_TARGETMOUNT:-$ISO_TARGETMOUNT}
    # Get whether to do squashfs
    read -r -p "Recreate squashfs? [$DO_ISO_SQUASHFS_UPDATE]: " NEW_DO_ISO_SQUASHFS_UPDATE
    DO_ISO_SQUASHFS_UPDATE=${NEW_DO_ISO_SQUASHFS_UPDATE:-$DO_ISO_SQUASHFS_UPDATE}
    if  [ "$DO_ISO_SQUASHFS_UPDATE" = "true" ]; then
      # Get squashfs packages
      read -r -p "Enter Squashfs Packages [$ISO_CHROOTPACKAGES]: " NEW_ISO_CHROOTPACKAGES
      ISO_CHROOTPACKAGES=${NEW_ISO_CHROOTPACKAGES:-$ISO_CHROOTPACKAGES}
    fi
    # Get whether to install packages as part of install
    read -r -p "Install additional packages [$DO_INSTALL_ISO_PACKAGES]: " NEW_DO_INSTALL_ISO_PACKAGES
    DO_INSTALL_ISO_PACKAGES=${NEW_DO_INSTALL_ISO_PACKAGES:-$DO_INSTALL_ISO_PACKAGES}
    if [ "$DO_INSTALL_ISO_PACKAGES" = "true" ]; then
      # Get IP
      read -r -p "Enter Additional Packages to install[$ISO_PACKAGES]: " NEW_ISO_PACKAGES
      ISO_PACKAGES=${NEW_ISO_PACKAGES:-$ISO_PACKAGES}
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
    read -r -p "Enter Swap Size [$ISO_SWAPSIZE]: " NEW_ISO_SWAPSIZE
    ISO_SWAPSIZE=${NEW_ISO_SWAPSIZE:-$ISO_SWAPSIZE}
    # Determine wether we use an SSH key
    read -r -p "Use SSH keys? [$DO_ISO_SSHKEY]: " NEW_DO_ISO_SSHKEY
    DO_ISO_SSHKEY=${NEW_DO_ISO_SSHKEY:-$DO_ISO_SSHKEY}
    if [ "$DO_ISO_SSHKEY" = "true" ]; then
      # Determine wether we use an SSH key
      read -r -p "SSH keys file [$ISO_SSHKEYFILE]: " NEW_ISO_SSHKEYFILE
      ISO_SSHKEYFILE=${NEW_ISO_SSHKEYFILE:-$ISO_SSHKEYFILE}
    fi
    if [ "$ISO_CODENAME" = "rocky" ]; then
      # Get type of OEM install
      read -r -p "OEM Install? [$ISO_OEMINSTALL]: " NEW_ISO_OEMINSTALL
      ISO_OEMINSTALL=${NEW_ISO_OEMINSTALL:-$ISO_OEMINSTALL}
      # Install Source
      read -r -p "Install Source? [$ISO_INSTALLSOURCE]: " NEW_ISO_INSTALLSOURCE
      ISO_INSTALLSOURCE=${NEW_ISO_INSTALLSOURCE:-$ISO_INSTALLSOURCE}
      # Install Mode
      read -r -p "Install Mode? [$ISO_INSTALLMODE]: " NEW_ISO_INSTALLMODE
      ISO_INSTALLMODE=${NEW_ISO_INSTALLMODE:-$ISO_INSTALLMODE}
      # Install Username
      read -r -p "SSH Install Username? [$ISO_INSTALLUSERNAME]: " NEW_ISO_INSTALLUSERNAME
      ISO_INSTALLUSERNAME=${NEW_ISO_INSTALLUSERNAME:-$ISO_INSTALLUSERNAME}
      # Install Username
      read -r -p "SSH Install Password? [$ISO_INSTALLPASSWORD]: " NEW_ISO_INSTALLPASSWORD
      ISO_INSTALLPASSWORD=${NEW_ISO_INSTALLPASSWORD:-$ISO_INSTALLPASSWORD}
      # Get Password Algorithm
      read -r -p "Password Algorithm? [$ISO_PASSWORDALGORITHM]: " NEW_ISO_PASSWORDALGORITHM
      ISO_PASSWORDALGORITHM=${NEW_ISO_PASSWORDALGORITHM:-$ISO_PASSWORDALGORITHM}
      # Get Bootloader Location
      read -r -p "Bootloader Location? [$ISO_BOOTLOADER]: " NEW_ISO_BOOTLOADER_LOCATION
      ISO_BOOTLOADER=${NEW_ISO_BOOTLOADER_LOCATION:-$ISO_BOOTLOADER}
      # Get SELinux mode
      read -r -p "SELinux Mode? [$ISO_SELINUX]: " NEW_ISO_SELINUX
      ISO_SELINUX=${NEW_ISO_SELINUX:-$ISO_SELINUX}
      # Firewall
      read -r -p "Firewall? [$ISO_FIREWALL]: " NEW_ISO_FIREWALL
      ISO_FIREWALL=${NEW_ISO_FIREWALL:-$ISO_FIREWALL}
      # Allow services
      read -r -p "Allow Services? [$ISO_ALLOWSERVICE]: " NEW_ISO_ALLOWSERVICE
      ISO_ALLOWSERVICE=${NEW_ISO_ALLOWSERVICE:-$ISO_ALLOWSERVICE}
      # Network boot protocol
      read -r -p "Network Boot Protocol? [$ISO_BOOTPROTO]: " NEW_ISO_BOOTPROTO
      ISO_BOOTPROTO=${NEW_ISO_BOOTPROTO:-$ISO_BOOTPROTO}
      # Enable Network on boot
      read -r -p "Enable Network on boot? [$ISO_ONBOOT]: " NEW_ISO_ONBOOT
      ISO_ONBOOT=${NEW_ISO_ONBOOT:-$ISO_ONBOOT}
      # User GECOS field
      read -r -p "User GECOS? [$ISO_GECOS]: " NEW_ISO_GECOS
      ISO_GECOS=${NEW_ISO_GECOS:-$ISO_GECOS}
      # User Groups
      read -r -p "User Groups? [$ISO_GROUPS]: " NEW_ISO_GROUPS
      ISO_GROUPS=${NEW_ISO_GROUPS:-$ISO_GROUPS}
      # PE Size
      read -r -p "PE Size? [$ISO_PESIZE]: " NEW_ISO_PESIZE
      ISO_PESIZE=${NEW_ISO_PESIZE:-$ISO_PESIZE}
      # Boot Partition Size
      read -r -p "Boot Partition Size? [$ISO_BOOTSIZE]: " NEW_ISO_BOOTSIZE
      ISO_BOOTSIZE=${NEW_ISO_BOOTSIZE:-$ISO_BOOTSIZE}
    fi
    # VG Name
    read -r -p "Disk Name? [$ISO_DISK_NAME]: " NEW_ISO_DISK_NAME
    ISO_DISK_NAME=${NEW_ISO_DISK_NAME:-$ISO_DISK_NAME}
    if [[ ! "$ISO_VOLMGRS" =~ "zfs" ]]; then
      # VG Name
      read -r -p "Volume Group Name? [$ISO_VGNAME]: " NEW_ISO_VGNAME
      ISO_VGNAME=${NEW_ISO_VGNAME:-$ISO_VGNAME}
      # LV Name
      read -r -p "Logic Volume Name? [$ISO_LVNAME]: " NEW_ISO_LVNAME
      ISO_LVNAME=${NEW_ISO_LVNAME:-$ISO_LVNAME}
      # LV Name
      read -r -p "Physical Volume Name? [$ISO_PVNAME]: " NEW_ISO_PVNAME
      ISO_PVNAME=${NEW_ISO_PVNAME:-$ISO_PVNAME}
    fi
    # Get whether to install drivers
    read -r -p "Install Drivers? [$DO_INSTALL_ISO_DRIVERS]: " NEW_INSTALL_ISO_DRIVERS
    DO_INSTALL_ISO_DRIVERS=${NEW_INSTALL_ISO_DRIVERS:-$DO_INSTALL_ISO_DRIVERS}
    # Get whether to install codecs
    read -r -p "Install Codecs? [$DO_INSTALL_ISO_CODECS]: " NEW_INSTALL_ISO_CODECS
    DO_INSTALL_ISO_CODECS=${NEW_INSTALL_ISO_CODECS:-$DO_INSTALL_ISO_CODECS}
    # Get Serial Port 0
    read -r -p "First Serial Port? [$ISO_SERIALPORT0]: " NEW_ISO_SERIALPORT0
    ISO_SERIALPORT0=${NEW_ISO_SERIALPORT0:-$ISO_SERIALPORT0}
    # Get Serial Port 1
    read -r -p "Second Serial Port? [$ISO_SERIAL_PORT1]: " NEW_ISO_SERIAL_PORT1
    ISO_SERIAL_PORT1=${NEW_ISO_SERIAL_PORT1:-$ISO_SERIAL_PORT1}
    # Get Serial Port Address 0
    read -r -p "First Serial Port Address? [$ISO_SERIALPORTADDRESS0]: " NEW_ISO_SERIALPORTADDRESS0
    ISO_SERIALPORTADDRESS0=${NEW_ISO_SERIALPORTADDRESS0:-$ISO_SERIALPORTADDRESS0}
    # Get Serial Port Address 1
    read -r -p "Second Serial Port Address? [$ISO_SERIAL_PORT_ADDRESS1]: " NEW_ISO_SERIAL_PORT_ADDRESS1
    ISO_SERIAL_PORT_ADDRESS1=${NEW_ISO_SERIAL_PORT_ADDRESS1:-$ISO_SERIAL_PORT_ADDRESS1}
    # Get Serial Port Speed 0
    read -r -p "First Serial Port Speed? [$ISO_SERIALPORTSPEED0]: " NEW_ISO_SERIALPORTSPEED0
    ISO_SERIALPORTSPEED0=${NEW_ISO_SERIALPORTSPEED0:-$ISO_SERIALPORTSPEED0}
    # Get Serial Port Speed 1
    read -r -p "Second Serial Port Speed? [$ISO_SERIAL_PORT_SPEED1]: " NEW_ISO_SERIAL_PORT_SPEED1
    ISO_SERIAL_PORT_SPEED1=${NEW_ISO_SERIAL_PORT_SPEED1:-$ISO_SERIAL_PORT_SPEED1}
  fi
}
