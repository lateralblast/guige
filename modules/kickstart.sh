# Function: create_kickstart_iso
#
# Create kickstart ISO (e.g. Rocky Linux)

create_kickstart_iso () {
  # insert code here 
  echo "" 
}

# Function: prepare_kickstart_iso
#
# Prepare kickstart ISO (e.g. Rocky Linux)

prepare_kickstart_iso () {
  for ISO_VOLMGR in $ISO_VOLMGRS; do
    KS_FILE="$WORK_DIR/files/$ISO_VOLMGR.ks"
    echo "# Kistart file generate $SCRIPT_NAME" > "$KS_FILE"
    echo "$ISO_INSTALL_MODE" >> "$KS_FILE"
    echo "$ISO_INSTALL_SOURCE" >> "$KS_FILE"
    echo "lang $ISO_LOCALE" >> "$KS_FILE"
    echo "keyboard $ISO_COUNTRY" >> "$KS_FILE"
    echo "timezone --utc $ISO_TIMEZONE" >> "$KS_FILE"
    echo "bootloader --timeout=$ISO_GRUB_TIMEOUT --location=$ISO_BOOT_LOADER_LOCATION --append=\"\" --boot-drive=$ISO_DEVICE" >> "$KS_FILE"
    echo "clearpart --all --drives=$ISO_DEVICE" >> "$KS_FILE"
    if [ "$ISO_VOLMGR" = "lvm" ]; then
      echo "autopart --type=lvm" >> "$KS_FILE"
    else
      echo "part / " >> "$KS_FILE"
      echo "part /boot --fstype \"$ISO_VOLMGR\" --ondisk" >> "$KS_FILE"
      echo "" >> "$KS_FILE"
    fi
    echo "auth --enableshadow --passalgo=$ISO_PASSWORD_ALGORITHM" >> "$KS_FILE"
    echo "selinux --$ISO_SELINUX" >> "$KS_FILE"
    echo "firewall --$ISO_FIREWALL --service=$ISO_ALLOW_SERVICE" >> "$KS_FILE"
    echo "network --hostname=$ISO_HOSTNAME --bootproto=$ISO_BOOT_PROTO --device=$ISO_NIC --activate --onboot=$ISO_ONBOOT" >> "$KS_FILE"
    echo "services --enabled=$ISO_ENABLE_SERVICE --disabled=$ISO_DISABLE_SERVICE" >> "$KS_FILE"
    if [ "$DO_PLAIN_TEXT_PASSWORD" = "true" ]; then
      echo "rootpw --plaintext $ISO_PASSWORD" >> "$KS_FILE"
      echo "user --name=$ISO_USERNAME --group=$ISO_GROUPS --password=$ISO_PASSWORD --plaintext --gecos=\"$ISO_GECOS\"" >> "$KS_FILE"
    else
      echo "rootpw --iscrypted $ISO_PASSWORD_CRYPT" >> "$KS_FILE"
      echo "user --name=$ISO_USERNAME --group=$ISO_GROUPS --password=$ISO_PASSWORD_CRYPT --iscrypted --gecos=\"$ISO_GECOS\"" >> "$KS_FILE"
    fi
    echo "%packages" >> "$KS_FILE"
    for PACKAGE in $ISO_INSTALL_PACKAGES; do
      echo "$PACKAGE" >> "$KS_FILE"
    done
    echo "%end" >> "$KS_FILE"
    echo "" >> "$KS_FILE"
    echo "" >> "$KS_FILE"
    echo "" >> "$KS_FILE"
  done
}
