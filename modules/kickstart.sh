# Function: create_kickstart_iso
#
# Create kickstart ISO (e.g. Rocky Linux)

create_kickstart_iso () {
  # insert code here 
  echo "" 
}

# Function: create_kickstart_file
#
# Create kickstart files (e.g. Rocky Linux)

prepare_kickstart_files () {
  for ISO_VOLMGR in $ISO_VOLMGRS; do
    KS_FILE="$WORK_DIR/files/$ISO_VOLMGR.ks"
    DATE=$( date )
    echo "# Kistart file generated by $SCRIPT_NAME on $DATE" > "$KS_FILE"
    if [ "$DO_MEDIA_CHECK" = "true" ]; then
      echo "mediacheck" >> "$KS_FILE"
    fi
    echo "$ISO_INSTALL_MODE" >> "$KS_FILE"
    echo "$ISO_INSTALL_SOURCE" >> "$KS_FILE"
    echo "%pre" >> "$KS_FILE"
    if [ "$ISO_DISK" = "first-disk" ]; then
      echo "FIRST_DISK=\$(lsblk -x TYPE|grep disk |sort |head -1 |awk '{print \$1}')" >> "$KS_FILE"
      echo "export \$FIRST_DISK" >> "$KS_FILE"
    fi
    if [ "$ISO_NIC" = "first-nic" ]; then
      echo "FIRST_NIC=\$(lshw -class network -short |awk '{print \$2}' |grep ^e |head -1)" >> "$KS_FILE"
      echo "export \$FIRST_NIC" >> "$KS_FILE"
    fi
    echo "%end" >> "$KS_FILE"
    echo "lang $ISO_LOCALE" >> "$KS_FILE"
    echo "keyboard $ISO_COUNTRY" >> "$KS_FILE"
    echo "timezone --utc $ISO_TIMEZONE" >> "$KS_FILE"
    if [ "$ISO_DISK" = "first-disk" ]; then
      echo "bootloader --timeout=$ISO_GRUB_TIMEOUT --location=$ISO_BOOT_LOADER_LOCATION --append=\"\" --boot-drive=\$FIRST_DISK" >> "$KS_FILE"
      echo "clearpart --all --drives=\$FIRST_DISK" >> "$KS_FILE"
    else
      echo "bootloader --timeout=$ISO_GRUB_TIMEOUT --location=$ISO_BOOT_LOADER_LOCATION --append=\"\" --boot-drive=$ISO_DISK" >> "$KS_FILE"
      echo "clearpart --all --drives=$ISO_DISK" >> "$KS_FILE"
    fi
    if [ "$ISO_VOLMGR" = "lvm" ]; then
      echo "autopart --type=lvm" >> "$KS_FILE"
    else
      if [ "$ISO_DISK" = "first-disk" ]; then
        echo "part /boot --size $ISO_BOOT_SIZE --asprimary --fstype ext4 --ondrive=\$FIRST_DISK" >> "$KS_FILE"
        echo "part pv.1 --size 1 --grow --fstype=ext4 --ondrive=\$FIRST_DISK" >> "$KS_FILE"
      else
        echo "part /boot --size $ISO_BOOT_SIZE --asprimary --fstype ext4 --ondrive=$ISO_DISK" >> "$KS_FILE"
        echo "part pv.1 --size 1 --grow --fstype=ext4 --ondrive=$ISO_DISK" >> "$KS_FILE"
      fi
      echo "logvol / --fstype $ISO_VOLMGR --vgname $ISO_VG_NAME --size=$ISO_ROOT_SIZE --name=root" >> "$KS_FILE"
      echo "logvol swap --vgname $ISO_VG_NAME --size=$ISO_SWAP_SIZE --name=swap" >> "$KS_FILE"
      echo "" >> "$KS_FILE"
    fi
    echo "auth --enableshadow --passalgo=$ISO_PASSWORD_ALGORITHM" >> "$KS_FILE"
    echo "selinux --$ISO_SELINUX" >> "$KS_FILE"
    if [ "$ISO_FIREWALL" = "enabled" ]; then
      echo "firewall --$ISO_FIREWALL --service=$ISO_ALLOW_SERVICE" >> "$KS_FILE"
    else
      echo "firewall --$ISO_FIREWALL" >> "$KS_FILE"
    fi
    if [ "$ISO_NIC" = "first-nic" ]; then
      NETWORK="network --hostname=$ISO_HOSTNAME --bootproto=$ISO_BOOT_PROTO --device=\$FIRST_NIC --onboot=$ISO_ONBOOT"
    else
      NETWORK="network --hostname=$ISO_HOSTNAME --bootproto=$ISO_BOOT_PROTO --device=$ISO_NIC --onboot=$ISO_ONBOOT"
    fi
    if [ "$DO_IPV4" = "false" ]; then
      NETWORK="$NETWORK --noipv4"
    fi
    if [ "$DO_IPV6" = "false" ]; then
      NETWORK="$NETWORK --noipv6"
    fi
    if [ "$DO_ACTIVATE" = "true" ]; then
      NETWORK="$NETWORK --activate"
    else
      NETWORK="$NETWORK --no-activate"
    fi
    if [ "$DO_DEFROUTE" = "false" ]; then
      NETWORK="$NETWORK --nodefroute"
    fi
    if [ "$DO_DHCP" = "false" ]; then
      NETWORK="$NETWORK --ip=$ISO_IP --netmask=$ISO_NETMASK --gateway=$ISO_GATEWAY --nameserver=$ISO_DNS"
    fi
    echo "$NETWORK" >> $KS_FILE 
    echo "services --enabled=$ISO_ENABLE_SERVICE --disabled=$ISO_DISABLE_SERVICE" >> "$KS_FILE"
    if [ "$DO_PLAIN_TEXT_PASSWORD" = "true" ]; then
      ROOT_PW="rootpw --plaintext $ISO_PASSWORD"
      USER_PW="user --name=$ISO_USERNAME --group=$ISO_GROUPS --password=$ISO_PASSWORD --plaintext --gecos=\"$ISO_GECOS\"" >> "$KS_FILE"
      SSH_PW="sshpw --username=$ISO_INSTALL_USERNAME $ISO_INSTALL_PASSWORD"
    else
      ROOT_PW="rootpw --iscrypted $ISO_PASSWORD_CRYPT" >> "$KS_FILE"
      USER_PW="user --name=$ISO_USERNAME --group=$ISO_GROUPS --password=$ISO_PASSWORD_CRYPT --iscrypted --gecos=\"$ISO_GECOS\"" >> "$KS_FILE"
      SSH_PW="sshpw --username=$ISO_INSTALL_USERNAME --iscrypted --password=$ISO_INSTALL_PASSWORD_CRYPT"
    fi
    echo "$ROOT_PW" >> "$KS_FILE"
    if [ "$DO_LOCK_ROOT" = "true" ]; then
      ROOT_PW="$ROOT_PW --lock"
    fi
    echo "$ROOT_PW" >> "$KS_FILE"
    echo "$USER_PW" >> "$KS_FILE"
    if [ "$DO_INSTALL_USER" = "true" ]; then
      echo "$SSH_PW" >> "$KS_FILE"
    fi
    echo "%packages" >> "$KS_FILE"
    for PACKAGE in $ISO_INSTALL_PACKAGES; do
      echo "$PACKAGE" >> "$KS_FILE"
    done
    echo "%end" >> "$KS_FILE"
    echo "" >> "$KS_FILE"
    echo "" >> "$KS_FILE"
    echo "" >> "$KS_FILE"
    print_file "$KS_FILE"
    if ! [ -z "$( command -v ksvalidator )" ]; then
      ksvalidator "$KS_FILE"
    fi
  done
}

# Function: prepare_kickstart_iso
#
# Prepare kickstart ISO (e.g. Rocky Linux)

prepare_kickstart_iso () {
  create_kickstart_files
}
