#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034
# shellcheck disable=SC2153

# Function: create_kickstart_iso
#
# Create kickstart ISO (e.g. Rocky Linux)

create_kickstart_iso () {
  if [ ! -f "/usr/bin/xorriso" ]; then
    install_required_packages "$REQUIRED_PACKAGES"
  fi
  if [ "$DO_ISO_TESTMODE" = "false" ]; then
    handle_output "# Creating ISO" "TEXT"
    check_file_perms "$ISO_OUTPUTFILE"
    cd "$ISO_NEW_DIR/cd" || exit
    sudo mkisofs -o "$ISO_OUTPUTFILE" -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -boot-load-size 4 -boot-info-table -no-emul-boot -eltorito-alt-boot \
    -eltorito-boot images/efiboot.img -no-emul-boot -R -J -V "$ISO_LABEL" -T .
    check_file_perms "$ISO_OUTPUTFILE"
  fi
}

# Function: create_kickstart_file
#
# Create kickstart files (e.g. Rocky Linux)

prepare_kickstart_files () {
  KS_DIR="$ISO_NEW_DIR/cd/"
  INCLUDE_DISK_FILE="/tmp/first-disk.cfg"
  INCLUDE_NIC_FILE="/tmp/first-nic.cfg"
  if [ "$DO_ISO_ISOLINUXFILE" = "true" ] && [ "$DO_ISO_AUTOINSTALL" = "true" ]; then
    print_file "$ISO_AUTOINSTALLFILE"
    ksvalidator "$ISO_AUTOINSTALLFILE"
    sudo cp "$ISO_AUTOINSTALLFILE" "$KS_DIR"
  else
    for ISO_VOLMGR in $ISO_VOLMGRS; do
      KS_FILE="$ISO_WORKDIR/files/$ISO_VOLMGR.cfg"
      DATE=$( date )
      echo "# Kistart file generated by $SCRIPT_NAME on $DATE" > "$KS_FILE"
      if [ "$DO_ISO_MEDIACHECK" = "true" ]; then
        echo "mediacheck" >> "$KS_FILE"
      fi
  #    echo "$ISO_INSTALLMODE" >> "$KS_FILE"
      echo "$ISO_INSTALLSOURCE" >> "$KS_FILE"
      echo "%pre" >> "$KS_FILE"
      if [ "$ISO_DISK" = "first-disk" ]; then
        if [ ! "$ISO_VOLMGR" = "lvm" ]; then
          echo "FIRST_DISK=\$( /bin/lsblk -x TYPE |grep disk |grep -v SWAP |sort |head -1 |awk '{print \$1}' )" > "$KS_FILE"
          echo "echo \"# First Disk\" > $INCLUDE_DISK_FILE" >> "$KS_FILE"
          echo "echo \"bootloader --timeout=$ISO_GRUBTIMEOUT --location=$ISO_BOOTLOADER --append=\\\"$ISO_KERNELARGS\\\" --boot-drive=/dev/\\$FIRST_DISK\" >> $INCLUDE_DISK_FILE" >> "$KS_FILE"
          echo "echo \"clearpart --all --drives=/dev/\\$FIRST_DISK\" >> $INCLUDE_DISK_FILE" >> "$KS_FILE"
          echo "echo \"part /boot --size=$ISO_BOOTSIZE --fstype=\\\"$ISO_VOLMGR\\\" --ondisk=/dev/\\$FIRST_DISK\" >> $INCLUDE_DISK_FILE" >> "$KS_FILE"
          echo "echo \"part $ISO_LVNAME --size=-1 --grow --fstype=\\\"lvmpv\\\" --ondisk=/dev/\\$FIRST_DISK\" >> $INCLUDE_DISK_FILE" >> "$KS_FILE"
          echo "echo \"part /boot/efi --size=$ISO_BOOTSIZE --asprimary --fstype=\\\"efi\\\" --ondisk=/dev/\\$FIRST_DISK\" >> $INCLUDE_DISK_FILE" >> "$KS_FILE"
        fi
      fi
      if [ "$ISO_NIC" = "first-nic" ]; then
        echo "echo\"# First NIC\" > $INCLUDE_NIC_FILE" >> "$KS_FILE"
        echo "FIRST_NIC=\$(lshw -class network -short |awk '{print \$2}' |grep ^e |head -1)\" >> $INCLUDE_NIC_FILE" >> "$KS_FILE"
      fi
      echo "%end" >> "$KS_FILE"
      echo "lang $ISO_LOCALE" >> "$KS_FILE"
      echo "keyboard $ISO_COUNTRY" >> "$KS_FILE"
      echo "timezone --utc $ISO_TIMEZONE" >> "$KS_FILE"
      echo "firstboot --$DO_ISO_FIRSTBOOT" >> "$KS_FILE"
      if [ "$ISO_VOLMGR" = "lvm" ]; then
        echo "autopart --type=lvm" >> "$KS_FILE"
      else
        if [ "$ISO_DISK" = "first-disk" ]; then
          echo "%include $INCLUDE_DISK_FILE" >> "$KS_FILE"
        else
          echo "bootloader --timeout=$ISO_GRUBTIMEOUT --location=$ISO_BOOTLOADER --append=\"$ISO_KERNELARGS\" --boot-drive=$ISO_DISK" >> "$KS_FILE"
          echo "clearpart --all --drives=$ISO_DISK" >> "$KS_FILE"
          echo "part /boot --size=$ISO_BOOTSIZE --fstype=\"$ISO_VOLMGR\" --ondisk=$ISO_DISK" >> "$KS_FILE"
          echo "part $ISO_LVNAME --size=-1 --grow --fstype=\"$ISO_VOLMGR\" --ondisk=$ISO_DISK" >> "$KS_FILE"
          echo "part /boot/efi --size=$ISO_BOOTSIZE --asprimary --fstype=\"efi\" --ondisk=$ISO_DISK" >> "$KS_FILE"
        fi
        echo "volgroup $ISO_VGNAME --pesize=$ISO_PESIZE $ISO_LVNAME" >> "$KS_FILE"
        echo "logvol / --fstype $ISO_VOLMGR --vgname $ISO_VGNAME --size=$ISO_ROOTSIZE --name=root" >> "$KS_FILE"
        echo "logvol swap --vgname $ISO_VGNAME --size=$ISO_SWAPSIZE --name=swap" >> "$KS_FILE"
      fi
  #    echo "auth --enableshadow --passalgo=$ISO_PASSWORDALGORITHM" >> "$KS_FILE"
      echo "selinux --$ISO_SELINUX" >> "$KS_FILE"
      if [ "$ISO_FIREWALL" = "enabled" ]; then
        echo "firewall --$ISO_FIREWALL --service=$ISO_ALLOWSERVICE" >> "$KS_FILE"
      else
        echo "firewall --$ISO_FIREWALL" >> "$KS_FILE"
      fi
      if [ "$ISO_NIC" = "first-nic" ]; then
        NETWORK="network --hostname=$ISO_HOSTNAME --bootproto=$ISO_BOOTPROTO --device=\$FIRST_NIC --onboot=$ISO_ONBOOT"
      else
        NETWORK="network --hostname=$ISO_HOSTNAME --bootproto=$ISO_BOOTPROTO --device=$ISO_NIC --onboot=$ISO_ONBOOT"
      fi
      if [ "$DO_ISO_IPV4" = "false" ]; then
        NETWORK="$NETWORK --noipv4"
      fi
      if [ "$DO_ISO_IPV6" = "false" ]; then
        NETWORK="$NETWORK --noipv6"
      fi
      if [ "$DO_ISO_ACTIVATE" = "true" ]; then
        NETWORK="$NETWORK --activate"
      else
        NETWORK="$NETWORK --no-activate"
      fi
      if [ "$DO_ISO_DEFAULTROUTE" = "false" ]; then
        NETWORK="$NETWORK --nodefroute"
      fi
      if [ "$DO_ISO_DHCP" = "false" ]; then
        NETWORK="$NETWORK --ip=$ISO_IP --netmask=$ISO_NETMASK --gateway=$ISO_GATEWAY --nameserver=$ISO_DNS"
      fi
      if [ "$ISO_NIC" = "first-nic" ]; then
        echo "%include $INCLUDE_NIC_FILE" >> "$KS_FILE"
        echo "echo \"$NETWORK\" >> $INCLUDE_NIC_FILE" >> "$KS_FILE"
      else
        echo "$NETWORK" >> "$KS_FILE"
      fi
      echo "services --enabled=$ISO_ENABLESERVICE --disabled=$ISO_DISABLESERVICE" >> "$KS_FILE"
      if [ "$DO_ISO_PLAINTEXTPASSWORD" = "true" ]; then
        ROOT_PW="rootpw --plaintext $ISO_PASSWORD"
        USER_PW="user --name=$ISO_USERNAME --group=$ISO_GROUPS --password=$ISO_PASSWORD --plaintext --gecos=\"$ISO_GECOS\"" >> "$KS_FILE"
        SSH_PW="sshpw --username=$ISO_INSTALLUSERNAME $ISO_INSTALLPASSWORD"
      else
        ROOT_PW="rootpw --iscrypted $ISO_PASSWORD_CRYPT" >> "$KS_FILE"
        USER_PW="user --name=$ISO_USERNAME --group=$ISO_GROUPS --password=$ISO_PASSWORD_CRYPT --iscrypted --gecos=\"$ISO_GECOS\"" >> "$KS_FILE"
        SSH_PW="sshpw --username=$ISO_INSTALLUSERNAME --iscrypted --password=$ISO_INSTALLPASSWORD_CRYPT"
      fi
      if [ "$DO_ISO_LOCKROOT" = "true" ]; then
        ROOT_PW="$ROOT_PW --lock"
      fi
      echo "$ROOT_PW" >> "$KS_FILE"
      echo "$USER_PW" >> "$KS_FILE"
      if [ "$DO_ISO_INSTALLUSER" = "true" ]; then
        echo "$SSH_PW" >> "$KS_FILE"
      fi
      echo "%packages" >> "$KS_FILE"
      for PACKAGE in $ISO_PACKAGES; do
        echo "$PACKAGE" >> "$KS_FILE"
      done
      echo "%end" >> "$KS_FILE"
      print_file "$KS_FILE"
      if [ -n "$( command -v ksvalidator )" ]; then
        ksvalidator "$KS_FILE"
      fi
      if [ "$DO_ISO_TESTMODE" = "false" ]; then
        sudo cp "$KS_FILE" "$KS_DIR"
      fi
    done
    if [ "$DO_ISO_AUTOINSTALL" = "true" ]; then
      if [ -n "$( command -v ksvalidator )" ]; then
        ksvalidator "$ISO_AUTOINSTALLFILE"
      fi
      print_file "$ISO_AUTOINSTALLFILE"
      if [ "$DO_ISO_TESTMODE" = "false" ]; then
        sudo cp "$ISO_AUTOINSTALLFILE" "$KS_DIR/custom.cfg"
      fi
    fi
  fi
}

# Function: prepare_kickstart_grub_menu
#
# Prepare kickstart grub, isolinux, etc files

prepare_kickstart_grub_menu () {
  TMP_LINUX_CFG="$ISO_WORKDIR/files/isolinux.cfg"
  TMP_GRUB_CFG="$ISO_WORKDIR/files/grub.cfg"
  ISO_LINUX_CFG="$ISO_NEW_DIR/cd/isolinux/isolinux.cfg"
  ISO_GRUB_CFG="$ISO_NEW_DIR/cd/EFI/BOOT/grub.cfg"
  ISO_LABEL="$ISO_REALNAME-$ISO_MAJORRELEASE-$ISO_MINORRELEASE-$ISO_ARCH-$ISO_TYPE"
  ISO_REPO_DIR="/run/install/repo"
  echo "default $ISO_GRUBMENU" > "$TMP_LINUX_CFG"
  COUNTER=0
  ISO_KERNEL_SERIAL_ARGS="console=$ISO_SERIALPORT0,$ISO_SERIALPORTSPEED0 console=$ISO_SERIAL_PORT1,$ISO_SERIAL_PORT_SPEED1"
  if [ "$DO_ISO_KSQUIET" = "true" ]; then
    ISO_KERNELARGS="$ISO_KERNELARGS quiet"
  fi
  if [ "$DO_ISO_KSTEXT" = "true" ]; then
    ISO_KERNELARGS="$ISO_KERNELARGS inst.text"
  fi
  if [ "$DO_ISO_ISOLINUXFILE" = "true" ]; then
    print_file "$ISO_ISOLINUXFILE"
    print_file "$ISO_GRUBFILE"
    if [ "$DO_ISO_TESTMODE" = "false" ]; then
      sudo cp "$ISO_ISOLINUXFILE" "$ISO_LINUX_CFG"
      sudo cp "$ISO_GRUBFILE" "$ISO_GRUB_CFG"
    fi
  else
    for ISO_DISK in $ISO_DISK; do
      for ISO_VOLMGR in $ISO_VOLMGRS; do
        if ! [ "$ISO_VOLMGR" = "custom" ]; then
          echo "label $COUNTER" >> "$TMP_LINUX_CFG"
          echo "  menu label ^$ISO_VOLID:$ISO_VOLMGR:$ISO_DISK:$ISO_NIC ($ISO_KERNELARGS)" >> "$TMP_LINUX_CFG"
          echo "  kernel vmlinuz" >> "$TMP_LINUX_CFG"
          echo "  append initrd=initrd.img inst.stage2=hd:LABEL=$ISO_LABEL $ISO_KERNELARGS inst.ks=hd:LABEL=$ISO_LABEL:/$ISO_VOLMGR.cfg" >> "$TMP_LINUX_CFG"
          COUNTER=$(( COUNTER+1 ))
        fi
      done
    done
    if [ "$DO_ISO_AUTOINSTALL" = "true" ]; then
      echo "label custom" >> "$TMP_LINUX_CFG"
      echo "  menu label ^$ISO_VOLID:custom ($ISO_KERNELARGS)" >> "$TMP_LINUX_CFG"
      echo "  kernel vmlinuz" >> "$TMP_LINUX_CFG"
      echo "  append initrd=initrd.img inst.stage2=hd:LABEL=$ISO_LABEL $ISO_KERNELARGS inst.ks=hd:LABEL=$ISO_LABEL:/custom.cfg" >> "$TMP_LINUX_CFG"
    fi
    echo "label install" >> "$TMP_LINUX_CFG"
    echo "  menu label ^Install a Rocky Linux system" >> "$TMP_LINUX_CFG"
    echo "  kernel vmlinuz" >> "$TMP_LINUX_CFG"
    echo "  append initrd=initrd.img inst.stage2=hd:LABEL=$ISO_LABEL $ISO_KERNELARGS" >> "$TMP_LINUX_CFG"
    echo "label rescue" >> "$TMP_LINUX_CFG"
    echo "  menu label ^Rescue a Rocky Linux system" >> "$TMP_LINUX_CFG"
    echo "  kernel vmlinuz" >> "$TMP_LINUX_CFG"
    echo "  append initrd=initrd.img inst.stage2=hd:LABEL=$ISO_LABEL $ISO_KERNELARGS" >> "$TMP_LINUX_CFG"
    echo "label memtest" >> "$TMP_LINUX_CFG"
    echo "  menu label Test ^Memory" >> "$TMP_LINUX_CFG"
    echo "  kernel memtest" >> "$TMP_LINUX_CFG"
    echo "label hd" >> "$TMP_LINUX_CFG"
    echo "  menu label ^Boot from first hard drive" >> "$TMP_LINUX_CFG"
    echo "  localboot 0x80" >> "$TMP_LINUX_CFG"
    print_file "$TMP_LINUX_CFG"
    if [ "$DO_ISO_TESTMODE" = "false" ]; then
      sudo cp "$TMP_LINUX_CFG" "$ISO_LINUX_CFG"
    fi
    echo "set timeout=$ISO_GRUBTIMEOUT" > "$TMP_GRUB_CFG"
    echo "set default=$ISO_GRUBMENU" >> "$TMP_GRUB_CFG"
    echo "" >> "$TMP_GRUB_CFG"
    echo "function load_video {" >> "$TMP_GRUB_CFG"
    echo "  insmod efi_gop" >> "$TMP_GRUB_CFG"
    echo "  insmod efi_uga" >> "$TMP_GRUB_CFG"
    echo "  insmod video_bochs" >> "$TMP_GRUB_CFG"
    echo "  insmod video_cirrus" >> "$TMP_GRUB_CFG"
    echo "}" >> "$TMP_GRUB_CFG"
    echo "" >> "$TMP_GRUB_CFG"
    echo "load_video" >> "$TMP_GRUB_CFG"
    echo "set gfxpayload=keep" >> "$TMP_GRUB_CFG"
    echo "insmod gzio" >> "$TMP_GRUB_CFG"
    echo "insmod part_gpt" >> "$TMP_GRUB_CFG"
    echo "insmod ext2" >> "$TMP_GRUB_CFG"
    echo "" >> "$TMP_GRUB_CFG"
    echo "search --no-floppy --set=root -l '$ISO_LABEL'" >> "$TMP_GRUB_CFG"
    echo "" >> "$TMP_GRUB_CFG"
    if [ "$DO_ISO_AUTOINSTALL" = "true" ]; then
      echo "menuentry '$ISO_VOLID:custom ($ISO_KERNEL_SERIAL_ARGS)' {" >> "$TMP_GRUB_CFG"
      echo "  linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=$ISO_LABEL $ISO_KERNELARGS inst.ks=hd:LABEL=$ISO_LABEL:/custom.cfg" >> "$TMP_GRUB_CFG"
      echo "  initrdefi /images/pxeboot/initrd.img" >> "$TMP_GRUB_CFG"
      echo "}" >> "$TMP_GRUB_CFG"
    fi
    for ISO_DISK in $ISO_DISK; do
      for ISO_VOLMGR in $ISO_VOLMGRS; do
        if ! [ "$ISO_VOLMGR" = "custom" ]; then
          echo "menuentry '$ISO_VOLID:$ISO_VOLMGR:$ISO_DISK:$ISO_NIC ($ISO_KERNEL_SERIAL_ARGS)' {" >> "$TMP_GRUB_CFG"
          echo "  linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=$ISO_LABEL $ISO_KERNELARGS inst.ks=hd:LABEL=$ISO_LABEL:/$ISO_VOLMGR.cfg" >> "$TMP_GRUB_CFG"
          echo "  initrdefi /images/pxeboot/initrd.img" >> "$TMP_GRUB_CFG"
          echo "}" >> "$TMP_GRUB_CFG"
        fi
      done
    done
    echo "menuentry 'Install $ISO_VOLID ($ISO_KERNEL_SERIAL_ARGS)' {" >> "$TMP_GRUB_CFG"
    echo "  linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=$ISO_LABEL $ISO_KERNEL_SERIAL_ARGS" >> "$TMP_GRUB_CFG"
    echo "  initrdefi /images/pxeboot/initrd.img" >> "$TMP_GRUB_CFG"
    echo "}" >> "$TMP_GRUB_CFG"
    echo "menuentry 'Rescue $ISO_VOLID ($ISO_KERNEL_SERIAL_ARGS)' {" >> "$TMP_GRUB_CFG"
    echo "  linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=$ISO_LABEL $ISO_KERNEL_SERIAL_ARGS" >> "$TMP_GRUB_CFG"
    echo "  initrdefi /images/pxeboot/initrd.img" >> "$TMP_GRUB_CFG"
    echo "}" >> "$TMP_GRUB_CFG"
    echo "menuentry 'Boot from next volume' {" >> "$TMP_GRUB_CFG"
    echo "  exit 1" >> "$TMP_GRUB_CFG"
    echo "}" >> "$TMP_GRUB_CFG"
    if [[ "$ISO_BOOTTYPE" =~ "efi" ]]; then
      echo "menuentry 'UEFI Firmware Settings' {" >> "$TMP_GRUB_CFG"
      echo "  fwsetup" >> "$TMP_GRUB_CFG"
      echo "}" >> "$TMP_GRUB_CFG"
    fi
    print_file "$TMP_GRUB_CFG"
    if [ "$DO_ISO_TESTMODE" = "false" ]; then
      sudo cp "$TMP_GRUB_CFG" "$ISO_GRUB_CFG"
    fi
  fi
}

# Function: prepare_kickstart_iso
#
# Prepare kickstart ISO (e.g. Rocky Linux)

prepare_kickstart_iso () {
  prepare_kickstart_files
  prepare_kickstart_grub_menu
}
