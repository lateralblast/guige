#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: check_value
## check value (make sure that command line arguments that take values have values)

check_value () {
  param="$1"
  value="$2"
  if [[ "${value}" =~ "--" ]]; then
    verbose_message "Value '${value}' for parameter '${param}' looks like a parameter" "verbose"
    echo ""
    if [ "${do_force}" = "false" ]; then
      do_exit
    fi
  else
    if [ "${value}" = "" ]; then
      verbose_message "No value given for parameter ${param}" "verbose"
      echo ""
      if [[ "${param}" =~ option ]]; then
        print_options
      else
        if [[ "${param}" =~ action ]]; then
          print_actions
        else
          print_help
        fi
      fi
      exit
    fi
  fi
}

# Function: get_password_crypt
#
# Get password crypt
#
# echo test |mkpasswd --method=SHA-512 --stdin

get_password_crypt () {
  iso['password']="$1"
  if [ "${os['name']}" = "Darwin" ]; then
    if [ "${options['testmode']}" = "false" ]; then
      iso['passwordcrypt']=$( echo -n "${iso['password']}" |openssl sha512 | awk '{ print $2 }' )
    fi
  else
    if [ ! -f "/usr/bin/mkpasswd" ]; then
      install_required_packages "${iso['requiredpackages']}"
    fi
    if [ "${options['testmode']}" = "false" ]; then
      iso['passwordcrypt']=$( echo "${iso['password']}" |mkpasswd --method=SHA-512 --stdin )
    fi
  fi
  if [ "${iso['passwordcrypt']}" = "" ]; then
    warning_message "No Password Hash/Crypt created"
    exit
  fi
  echo "${iso['passwordcrypt']}"
}

# Function: get_os_ip
#
# Get my IP

get_os_ip () {
  if [ "${os['name']}" = "Darwin" ]; then
    os['ip']=$(ifconfig | grep "inet " | grep -v 127.0.0.1 |head -1 |awk '{print $2}')
  else
    if [[ "${iso['release']}" =~ "Arch" ]] || [[ "${iso['release']}" =~ "Endeavour" ]]; then
      os['ip']=$(ip addr |grep 'inet ' |grep -v 127 |head -1 |awk '{print $2}' |cut -f1 -d/)
    else
      os['ip']=$(hostname -I |awk '{print $1}')
    fi
  fi
}

# Function: get_current_release
#
# Get current release

get_current_release () {
  case "${iso['release']}" in
    "25.10")
      iso['release']="${current['release2510']}"
      ;;
    "25.04")
      iso['release']="${current['release2504']}"
      ;;
    "24.10")
      iso['release']="${current['release2410']}"
      ;;
    "24.04")
      iso['release']="${current['release2404']}"
      ;;
    "23.10")
      iso['release']="${current['release2310']}"
      ;;
    "23.04")
      iso['release']="${current['release2304']}"
      ;;
    "22.04")
      iso['release']="${current['release2204']}"
      ;;
    "20.04")
      iso['release']="${current['release2004']}"
      ;;
    "18.04")
      iso['release']="${current['release1804']}"
      ;;
    "16.04")
      iso['release']="${current['release1604']}"
      ;;
    "14.04")
      iso['release']="${current['release1404']}"
      ;;
    *)
      iso['release']="${current['release']}"
      ;;
  esac
}

# Function: get_codename
#
# Get Ubuntu relase codename

get_code_name () {
  rel_num="${iso['majorrelease']}.${iso['minorrelease']}"
  if [ "${rel_num}" = "." ]; then
    rel_num="${iso['release']}"
  fi
  case "${rel_num}" in
    "20.04")
      defaults['codename']="focal"
      iso['codename']="focal"
      ;;
    "20.10")
      defaults['codename']="groovy"
      iso['codename']="groovy"
      ;;
    "21.04")
      defaults['codename']="hirsute"
      iso['codename']="hirsute"
      ;;
    "21.10")
      defaults['codename']="impish"
      iso['codename']="impish"
      ;;
    "22.04")
      defaults['codename']="jammy"
      iso['codename']="jammy"
      ;;
    "22.10")
      defaults['codename']="kinetic"
      iso['codename']="kinetic"
      ;;
    "23.04")
      defaults['codename']="lunar"
      iso['codename']="lunar"
      ;;
    "23.10")
      defaults['codename']="mantic"
      iso['codename']="mantic"
      ;;
    "24.04")
      defaults['codename']="noble"
      iso['codename']="noble"
      ;;
    "24.10")
      defaults['codename']="oracular"
      iso['codename']="oracular"
      ;;
    "25.04")
      defaults['codename']="plucky"
      iso['codename']="plucky"
      ;;
    "25.10")
      defaults['codename']="questing"
      iso['codename']="questing"
      ;;
  esac
}

# Function: get_build_type
#
# Get build type based on release

get_build_type () {
  :
#  case "${iso['codename']}" in
#    "plucky")
#      defaults['build']="daily-live"
#      iso['build']="daily-live"
#      ;;
#  esac
}

# Function: get_interactive_input
#
# Get values for script interactively

get_interactive_input () {
  # Get codename
  read -r -p "Enter OS Name [${iso['osname']}]: " new['osname']
  iso['osname']=${new['osname']}:-${iso['osname']}
  if [ "${options['createexport']}" = "true" ] || [ "${options['createansible']}" = "true" ]; then
    if [ "${options['createexport']}" = "true" ] || [ "${options['createansible']}" = "true" ]; then
      # Get bootserver IP
      read -r -p "Enter Bootserver IP [${iso['bootserverip']}]: " new['bootserverip']
      iso['bootserverip']=${new['bootserverip']}:-${iso['bootserverip']}
      # Get bootserver file
      read -r -p "Enter Bootserver file [${iso['bootserverfile']}]: " new['bootserverfile']
      iso['bootserverfile']=${new['bootserverfile']}:-${iso['bootserverfile']}
    fi
    if [ "${options['createansible']}" = "true" ]; then
      # Get BMC IP
      read -r -p "Enter BMC/iDRAC IP [${iso['bmcip']}]: " new['bmcip']
      iso['bmcip']=${new['bmcip']}:-${iso['bmcip']}
      # Get BMC Username
      read -r -p "Enter BMC/iDRAC Username [${iso['bmcusername']}]: " new['bmcusername']
      iso['bmcusername']=${new['bmcusername']}:-${iso['bmcusername']}
      # Get BMC Password
      read -r -p "Enter BMC/iDRAC Password [${iso['bmcpassword']}]: " new['bmcpassword']
      iso['bmcpassword']=${new['bmcpassword']}:-${iso['bmcpassword']}
    fi
  else
    # Get release
    read -r -p "Enter Release [${iso['release']}]: " new['release']
    iso['release']=${new['release']}:-${iso['release']}
    # Get codename
    read -r -p "Enter Codename [${iso['codename']}: " new['codename']
    iso['codename']=${new['codename']}:-${iso['codename']}
    # Get Architecture
    read -r -p "Architecture [${iso['arch']}]: "
    iso['arch']=${new['arch']}:-${iso['arch']}
    # Get Work directory
    read -r -p "Enter Work directory [${iso['workdir']}]: " new['workdir']
    iso['workdir']=${new['workdir']}:-${iso['workdir']}
    # Get ISO input file
    read -r -p "Enter ISO input file [${iso['inputfile']}]: " new['inputfile']
    iso['inputfile']=${new['inputfile']}:-${iso['inputfile']}
    # Get CI input file
    read -r -p "Enter CI input file [${iso['inputci']}]: " new['inputci']
    iso['inputci']=${new['inputci']}:-${iso['inputci']}
    # Get ISO output file
    read -r -p "Enter ISO output file [${iso['outputfile']}]: " new['outputfile']
    iso['outputfile']=${new['outputfile']}:-${iso['outputfile']}
    # Get CI output file
    read -r -p "Enter CI output file [${iso['outputci']}]: " new['outputci']
    iso['outputci']=${new['outputci']}:-${iso['outputci']}
    # Get ISO URL
    read -r -p "Enter ISO URL [${iso['url']}]: " new['url']
    iso['url']=${new['url']}:-${iso['url']}
    # Get CI URL
    read -r -p "Enter ISO URL [${iso['ciurl']}]: " new['ciurl']
    iso['ciurl']=${new['ciurl']}:-${iso['ciurl']}
    # Get ISO Volume ID
    read -r -p "Enter ISO Volume ID [${iso['volid']}]: " new['volid']
    iso['volid']=${new['volid']}:-${iso['volid']}
    # Get Hostname
    read -r -p "Enter Hostname[${iso['hostname']}]: " new['hostname']
    iso['hostname']=${new['hostname']}:-${iso['hostname']}
    # Get Username
    read -r -p "Enter Username [${iso['username']}]: " new['username']
    iso['username']=${new['username']}:-${iso['username']}
    # Get User Real NAme
    read -r -p "Enter User Realname [${iso['realname']}]: " new['realname']
    iso['realname']=${new['realname']}:-${iso['realname']}
    # Get Password
    read -r -s -p "Enter password [${iso['password']}]: " new['password']
    iso['password']=${new['password']}:-${iso['password']}
    # Get wether to allow SSH Password
    read -r -s -p "Allow SSH access with password [${iso['allowpassword']}]: " new['allowpassword']
    iso['allowpassword']=${new['allowpassword']}:-${iso['allowpassword']}
    # Get Timezone
    read -r -p "Enter Timezone: " new['timezone']
    iso['timezone']=${new['timezone']}:-${iso['timezone']}
    # Get NIC
    read -r -p "Enter NIC [${iso['nic']}]: " new['nic']
    iso['nic']=${new['nic']}:-${iso['nic']}
    # Get DHCP
    read -r -p "Use DHCP? [${options['dhcp']}]: " NEW_options['dhcp']
    options['dhcp']=${NEW_options['dhcp']}:-${options['dhcp']}
    # Get Static IP information if no DHCP
    if [ "${options['dhcp']}" = "false" ]; then
      # Get IP
      read -r -p "Enter IP [${iso['ip']}]: " new['ip']
      iso['ip']=${new['ip']}:-${iso['ip']}
      # Get CIDR
      read -r -p "Enter CIDR [${iso['cidr']}]: " new['cidr']
      iso['cidr']=${new['cidr']}:-${iso['cidr']}
      # Get Geteway
      read -r -p "Enter Gateway [${iso['gateway']}]: " new['gateway']
      iso['gateway']=${new['gateway']}:-${iso['gateway']}
      # Get DNS
      read -r -p "Enter DNS [${iso['dns']}]: " new['dns']
      iso['dns']=${new['dns']}:-${iso['dns']}
    fi
    # Get Install Mode
    read -r -p "Install Mode [${iso['installmode']}]: " new['installmode']
    iso['installmode']=${new['installmode']}:-${iso['installmode']}
    # Get Kernel
    read -r -p "Enter Kernel [${iso['kernel']}]: " new['kernel']
    iso['kernel']=${new['kernel']}:-${iso['kernel']}
    # Get Kernel Arguments
    read -r -p "Enter Kernel Arguments [${iso['kernelargs']}]: " new['kernelargs']
    iso['kernelargs']=${new['kernelargs']}:-${iso['kernel']}
    # Get Disk Size
    read -r -p "Enter IP [${iso['disksize']}]: " new['disksize']
    iso['disksize']=${new['disksize']}:-${iso['disksize']}
    # Get Keyboard Layout
    read -r -p "Enter IP [${iso['layout']}]: " new['layout']
    iso['layout']=${new['layout']}:-${iso['layout']}
    # Get Locale
    read -r -p "Enter IP [${iso['locale']}]: " new['locale']
    iso['locale']=${new['locale']}:-${iso['locale']}
    # Get LC _ALL
    read -r -p "Enter LC_ALL [${iso['lcall']}]: " new['lcall']
    iso['lcall']=${new['lcall']}:-${iso['lcall']}
    # Get Root Disk(s)
    read -r -p "Enter Root Disk(s) [${iso['disk']}]: " new['disk']
    iso['disk']=${new['disk']}:-${iso['disk']}
    # Get Volume Managers
    read -r -p "Enter Volume Manager(s) [${iso['volumemanager']}]: " new['volumemanager']
    iso['volumemanager']=${new['volumemanager']}:-${iso['volumemanager']}
    # Get Default Grub Menu selection
    read -r -p "Enter Default Grub Menu [${iso['grubmenu']}]: " new['grubmenu']
    iso['grubmenu']=${new['grubmenu']}:-${iso['grubmenu']}
    # Get Grub Timeout
    read -r -p "Enter Grub Timeout [${iso['grubtimeout']}]: " new['grubtimeout']
    iso['grubtimeout']=${new['grubtimeout']}:-${iso['grubtimeout']}
    # Get Autoinstall directory
    read -r -p "Enter Auttoinstall Directory [${iso['autoinstalldir']}]: " new['autoinstalldir']
    iso['autoinstalldir']=${new['autoinstalldir']}:-${iso['autoinstalldir']}
    # Get Install Mount
    read -r -p "Enter Install Mount [${iso['installmount']}]: " new['installmount']
    iso['installmount']=${new['installmount']}:-${iso['installmount']}
    # Get Install Target
    read -r -p "Enter Install Target [${iso['targetmount']}]: " new['targetmount']
    iso['targetmount']=${new['targetmount']}:-${iso['targetmount']}
    # Get whether to do squashfs
    read -r -p "Recreate squashfs? [${options['updatesquashfs']}]: " NEW_options['updatesquashfs']
    options['updatesquashfs']=${NEW_options['updatesquashfs']}:-${options['updatesquashfs']}
    if  [ "${options['updatesquashfs']}" = "true" ]; then
      # Get squashfs packages
      read -r -p "Enter Squashfs Packages [${iso['chrootpackages']}]: " new['chrootpackages']
      iso['chrootpackages']=${new['chrootpackages']}:-${iso['chrootpackages']}
    fi
    # Get whether to install packages as part of install
    read -r -p "Install additional packages [${options['installpackages']}]: " NEW_options['installpackages']
    options['installpackages']=${NEW_options['installpackages']}:-${options['installpackages']}
    if [ "${options['installpackages']}" = "true" ]; then
      # Get IP
      read -r -p "Enter Additional Packages to install[${iso['packages']}]: " new['packages']
      iso['packages']=${new['packages']}:-${iso['packages']}
    fi
    # Get wether to install network updates
    read -r -p "Install Network Updates? [${options['networkupdates']}]: " NEW_options['networkupdates']
    options['networkupdates']=${NEW_options['networkupdates']}:-${options['networkupdates']}
    # Get whether to install updates
    if [ "${options['networkupdates']}" = "true" ]; then
      read -r -p "Install updates? [${options['packageupdates']}]: " NEW_options['packageupdates']
      options['packageupdates']=${NEW_options['packageupdates']}:-${options['packageupdates']}
      if [ "${options['packageupdates']}" = "true" ]; then
        # Get wether to install upgrades
        read -r -p "Upgrade packages? [${options['packageupgrades']}]: " NEW_options['packageupgrades']
        options['packageupgrades']=${NEW_options['packageupgrades']}:-${options['packageupgrades']}
        # Get whether to do a dist-updrage
        read -r -p "Install Distribution Upgrade if available (e.g. 20.04.4 -> 20.04.5)? [${options['distupgrade']}]: " NEW_options['distupgrade']
        options['distupgrade']=${NEW_options['distupgrade']}:-${options['distupgrade']}
      fi
    fi
    # Get swap device
    read -r -p "Enter Swap Size [${iso['swap']}]: " new['swap']
    iso['swap']=${new['swap']}:-${iso['swap']}
    # Get swap size
    read -r -p "Enter Swap Size [${iso['swapsize']}]: " new['swapsize']
    iso['swap']=${new['swapsize']}:-${iso['swapsize']}
    # Determine wether we use an SSH key
    read -r -p "Use SSH keys? [${options['sshkey']}]: " NEW_options['sshkey']
    options['sshkey']=${NEW_options['sshkey']}:-${options['sshkey']}
    if [ "${options['sshkey']}" = "true" ]; then
      # Determine wether we use an SSH key
      read -r -p "SSH keys file [${iso['sshkeyfile']}]: " new['sshkeyfile']
      iso['sshkeyfile']=${new['sshkeyfile']}:-${iso['sshkeyfile']}
    fi
    if [ "${iso['osname']}" = "rocky" ]; then
      # Get type of OEM install
      read -r -p "OEM Install? [${iso['oeminstall']}]: " new['oeminstall']
      iso['oeminstall']=${new['oeminstall']}:-${iso['oeminstall']}
      # Install Source
      read -r -p "Install Source? [${iso['installsource']}]: " new['installsource']
      iso['installsource']=${new['installsource']}:-${iso['installsource']}
      # Install Mode
      read -r -p "Install Mode? [${iso['installmode']}]: " new['installmode']
      iso['installmode']=${new['installmode']}:-${iso['installmode']}
      # Install Username
      read -r -p "SSH Install Username? [${iso['installusername']}]: " new['installusername']
      iso['installusername']=${new['installusername']}:-${iso['installusername']}
      # Install Username
      read -r -p "SSH Install Password? [${iso['installpassword']}]: " new['installpassword']
      iso['installpassword']=${new['installpassword']}:-${iso['installpassword']}
      # Get Password Algorithm
      read -r -p "Password Algorithm? [${iso['passwordalgorithm']}]: " new['passwordalgorithm']
      iso['passwordalgorithm']=${new['passwordalgorithm']}:-${iso['passwordalgorithm']}
      # Get Bootloader Location
      read -r -p "Bootloader Location? [${iso['bootloader']}]: " new['bootloader']
      iso['bootloader']=${new['bootloader']}:-${iso['bootloader']}
      # Get SELinux mode
      read -r -p "SELinux Mode? [${iso['selinux']}]: " new['selinux']
      iso['selinux']=${new['selinux']}:-${iso['selinux']}
      # Firewall
      read -r -p "Firewall? [${iso['firewall']}]: " new['firewall']
      iso['firewall']=${new['firewall']}:-${iso['firewall']}
      # Allow services
      read -r -p "Allow Services? [${iso['allowservice']}]: " new['allowservice']
      iso['allowservice']=${new['allowservice']}:-${iso['allowservice']}
      # Network boot protocol
      read -r -p "Network Boot Protocol? [${iso['bootproto']}]: " new['bootproto']
      iso['bootproto']=${new['bootproto']}:-${iso['bootproto']}
      # Enable Network on boot
      read -r -p "Enable Network on boot? [${iso['onboot']}]: " new['onboot']
      iso['onboot']=${new['onboot']}:-${iso['onboot']}
      # User GECOS field
      read -r -p "User GECOS? [${iso['gecos']}]: " new['gecos']
      iso['gecos']=${new['gecos']}:-${iso['gecos']}
      # User Groups
      read -r -p "User Groups? [${iso['groups']}]: " new['groups']
      iso['groups']=${new['groups']}:-${iso['groups']}
      # PE Size
      read -r -p "PE Size? [${iso['pesize']}]: " new['pesize']
      iso['pesize']=${new['pesize']}:-${iso['pesize']}
      # Boot Partition Size
      read -r -p "Boot Partition Size? [${iso['bootsize']}]: " new['bootsize']
      iso['bootsize']=${new['bootsize']}:-${iso['bootsize']}
    fi
    # VG Name
    read -r -p "Disk Name? [${iso['diskname']}]: " new['diskname']
    iso['diskname']=${new['diskname']}:-${iso['diskname']}
    if [[ ! "${iso['volumemanager']}" =~ "zfs" ]]; then
      # VG Name
      read -r -p "Volume Group Name? [${iso['vgname']}]: " new['vgname']
      iso['vgname']=${new['vgname']}:-${iso['vgname']}
      # LV Name
      read -r -p "Logic Volume Name? [${iso['lvname']}]: " new['lvname']
      iso['lvname']=${new['lvname']}:-${iso['lvname']}
      # LV Name
      read -r -p "Physical Volume Name? [${iso['pvname']}]: " new['pvname']
      iso['pvname']=${new['pvname']}:-${iso['pvname']}
    fi
    # Get whether to install drivers
    read -r -p "Install Drivers? [${options['installdrivers']}]: " new['installdrivers']
    options['installdrivers']=${new['installdrivers']}:-${options['installdrivers']}
    # Get whether to install codecs
    read -r -p "Install Codecs? [${options['installcodecs']}]: " new['installcodecs'] 
    options['installcodecs']=${new['installcodecs']}:-${options['installcodecs']}
    # Get Serial Port 0 
    read -r -p "First Serial Port? [${iso['serialporta']}]: " new['serialporta']
    iso['serialporta']=${new['serialporta']}:-${iso['serialporta']}
    # Get Serial Port 1
    read -r -p "Second Serial Port? [${iso['serialportb']}]: " new['serialportb']
    iso['serialportb']=${new['serialportb']}:-${iso['serialportb']}
    # Get Serial Port Address 0
    read -r -p "First Serial Port Address? [${iso['serialportaddressa']}]: " new['serialportaddressa']
    iso['serialportaddressa']=${new['serialportaddressa']}:-${iso['serialportaddressa']}
    # Get Serial Port Address 1
    read -r -p "Second Serial Port Address? [${iso['serialportaddressb']}]: " new['serialportaddressb']
    iso['serialportaddressb']=${new['serialportaddressb']}:-${iso['serialportaddressb']}
    # Get Serial Port Speed 0
    read -r -p "First Serial Port Speed? [${iso['serialportspeeda']}]: " new['serialportspeeda']
    iso['serialportspeeda']=${new['serialportspeeda']}:-${iso['serialportspeeda']}
    # Get Serial Port Speed 1
    read -r -p "Second Serial Port Speed? [${iso['serialportspeedb']}]: " new['serialportspeedb']
    iso['serialportspeedb']=${new['serialportspeedb']}:-${iso['serialportspeedb']}
  fi
}
