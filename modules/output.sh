#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2001

# Function: execute_command
#
# Execute a command

execute_command () {
  COMMAND="$1"
  execute_message "$COMMAND"
  if [ "$DO_ISO_TESTMODE" = "false" ]; then
    eval "$COMMAND"
  fi
}

# Function: print_file
#
# Print contents of file

print_file () {
  FILE_NAME="$1"
  echo ""
  handle_output "# Contents of file $FILE_NAME" "TEXT"
  echo ""
  if [ "$DO_ISO_TESTMODE" = "false" ]; then
    cat "$FILE_NAME"
  fi
}

# Function: execute_message
#
#  Print command

execute_message () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="COMMAND"
  handle_output "$OUTPUT_TEXT" "$OUTPUT_TYPE"
}

# Function: information_message
#
# Print informational message

information_message () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="TEXT"
  handle_output "# Information: $OUTPUT_TEXT" "$OUTPUT_TYPE"
}

# Function: verbose_message
#
# Print verbose message

verbose_message () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="TEXT"
  TEMP_DO_ISO_VERBOSEMODE="true"
  handle_output "$OUTPUT_TEXT" "$OUTPUT_TYPE"
  TEMP_DO_ISO_VERBOSEMODE="false"
}

# Function: warning_message
#
# Print warning message

warning_message () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="TEXT"
  TEMP_DO_ISO_VERBOSEMODE="true"
  handle_output "# Warning: $OUTPUT_TEXT" "$OUTPUT_TYPE"
  TEMP_DO_ISO_VERBOSEMODE="false"
}

# Function: handle_output
#
# Handle text output

handle_output () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="$2"
  if [ "$DO_ISO_VERBOSEMODE" = "true" ] || [ "$TEMP_DO_ISO_VERBOSEMODE" = "true" ]; then
    if [ "$DO_ISO_TESTMODE" = "true" ]; then
      echo "$OUTPUT_TEXT"
    else
      if [ "$OUTPUT_TYPE" = "TEXT" ]; then
        echo "$OUTPUT_TEXT"
      else
        echo "# Executing: $OUTPUT_TEXT"
      fi
    fi
  fi
}

# Function: sudo_chown
#
# Change ownership

sudo_chown () {
  OBJECT="$1"
  USER=$2
  GROUP=$3
  handle_output "# Checking ownership of $OBJECT is $USER:$GROUP" "TEXT"
  if [ "$DO_ISO_TESTMODE" = "false" ]; then
    if [ ! -f "/.dockerenv" ]; then
      sudo chown $USER:$GROUP $OBJECT
    fi
  fi
}

# Function: create_dir
#
# Create directory

create_dir () {
  CREATE_DIR="$1"
  handle_output "# Checking directory $CREATE_DIR exists" "TEXT"
  if [ ! -d "$CREATE_DIR" ]; then
    if [ "$DO_ISO_TESTMODE" = "false" ]; then
      mkdir -p "$CREATE_DIR"
    fi
  fi
}

# Function: sudo_create_dir
#
# Create directory

sudo_create_dir () {
  CREATE_DIR="$1"
  handle_output "# Checking directory $CREATE_DIR exists" "TEXT"
  if [ ! -d "$CREATE_DIR" ]; then
    if [ "$DO_ISO_TESTMODE" = "false" ]; then
      if [ -f "/.dockerenv" ]; then
        mkdir -p "$CREATE_DIR"
      else
        sudo mkdir -p "$CREATE_DIR"
      fi
    fi
  fi
}

# Function: remove_dir
#
# Remove directory

remove_dir () {
  REMOVE_DIR="$1"
  handle_output "# Checking directory $REMOVE_DIR exists" "TEXT"
  if [ ! "$REMOVE_DIR" = "/" ]; then
    if [[ $REMOVE_DIR =~ [0-9a-zA-Z] ]]; then
      if [ -d "$REMOVE_DIR" ]; then
        if [ "$DO_ISO_TESTMODE" = "false" ]; then
          sudo rm -f "$REMOVE_DIR"
        fi
      fi
    fi
  fi
}

# Function: check_ISO_WORKDIR
#
# Check work directories exist
#
# Example:
# mkdir -p ./isomount ./isonew/squashfs ./isonew/cd ./isonew/custom

check_ISO_WORKDIR () {
  handle_output "# Check work directories" "TEXT"
  for ISO_DIR in $ISO_MOUNTDIR $ISO_NEW_DIR/squashfs $ISO_NEW_DIR/mksquash $ISO_NEW_DIR/cd $ISO_NEW_DIR/custom $ISO_WORKDIR/bin $ISO_WORKDIR/files; do
    handle_output "# Check directory $ISO_DIR exists" "TEXT"
    if [ "$DO_ISO_FORCEMODE" = "true" ]; then
      remove_dir "$ISO_DIR"
    fi
    create_dir "$ISO_DIR"
  done
}

# Function: check_old_ISO_WORKDIR
#
# Check old release work directory
# Used when copying files from old release to a new release

check_old_ISO_WORKDIR () {
  handle_output "# Check old release work directories exist" "TEXT"
  for ISO_DIR in $OLD_ISO_MOUNTDIR $OLD_ISO_WORKDIR/files; do
    if [ "$DO_ISO_FORCEMODE" = "true" ]; then
      remove_dir "$ISO_DIR"
    fi
    create_dir "$ISO_DIR"
  done
}

# Function: check_file_perms
#
# Check file permissions of file

check_file_perms () {
  CHECK_FILE="$1"
  handle_output "# Checking file permissions for $CHECK_FILE" "TEXT"
  if [ -f "$CHECK_FILE" ]; then
    MY_USER="$OS_USER"
    MY_GROUP=$(groups |awk '{print $1}')
    FILE_USER=$(find "$ISO_OUTPUTFILE" -ls |awk '{print $5}')
    if [ ! "$FILE_USER" = "$MY_USER" ]; then
      sudo chown "$MY_USER" "$CHECK_FILE"
      sudo chgrp "$MY_GROUP" "$CHECK_FILE"
    fi
  fi
}

# Function: create_export
#
# Setup NFS server to export ISO

create_export () {
  NFS_DIR="$ISO_WORKDIR/files"
  EXPORTS_FILE="/etc/exports"
  handle_output "# Check NFS export is enabled" "TEXT"
  if [ -f "$EXPORTS_FILE" ]; then
    EXPORT_CHECK=$( grep -v "^#" < "$EXPORTS_FILE" |grep "$NFS_DIR" |grep "$ISO_BMCIP" |awk '{print $1}' | head -1 )
  else
    EXPORT_CHECK=""
  fi
  if [ -z "$EXPORT_CHECK" ]; then
    if [ "$OS_NAME" = "Darwin" ]; then
      echo "$NFS_DIR --mapall=$OS_USER $ISO_BMCIP" |sudo tee -a "$EXPORTS_FILE"
      sudo nfsd enable
      sudo nfsd restart
    else
      echo "$NFS_DIR $ISO_BMCIP(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)" |sudo tee -a "$EXPORTS_FILE"
      sudo exportfs -a
    fi
    print_file "$EXPORTS_FILE"
  fi
}

# Function: update_output_file_name
#
# Update output file name based on switched and options

update_output_file_name () {
  if ! [ "$ISO_HOSTNAME" = "$DEFAULT_ISO_HOSTNAME" ]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_HOSTNAME.iso"
  fi
  if ! [ "$ISO_NIC" = "$DEFAULT_ISO_NIC" ]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_NIC.iso"
  fi
  if [ "$DO_ISO_DHCP" = "false" ]; then
    if ! [ "$ISO_IP" = "$DEFAULT_ISO_IP" ]; then
      TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
      TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
      ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_IP.iso"
    fi
    if ! [ "$ISO_GATEWAY" = "$DEFAULT_ISO_GATEWAY" ]; then
      TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
      TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
      ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_GATEWAY.iso"
    fi
    if ! [ "$ISO_DNS" = "$DEFAULT_ISO_DNS" ]; then
      TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
      TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
      ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_DNS.iso"
    fi
  fi
  if ! [ "$ISO_USERNAME" = "$DEFAULT_ISO_USERNAME" ]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_USERNAME.iso"
  fi
  if ! [ "$ISO_DISK" = "$DEFAULT_ISO_DISK" ]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_DISK.iso"
  fi
  if ! [ "$ISO_PREFIX" = "" ]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$ISO_PREFIX-$TEMP_FILE_NAME.iso"
  fi
  if ! [ "$ISO_SUFFIX" = "" ]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_SUFFIX.iso"
  fi
  if [[ "$ISO_OPTIONS" =~ "cluster" ]]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-cluster.iso"
  fi
  if [[ "$ISO_OPTIONS" =~ "kvm" ]]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-kvm.iso"
  fi
  if [[ "$ISO_OPTIONS" =~ "biosdevname" ]]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-biosdevname.iso"
  fi
  if [ "$DO_ISO_SSHKEY" = "true" ]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-sshkey.iso"
  fi
  if [ "$DO_ISO_NVME" = "true" ]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-nvme.iso"
  fi
  if [ "$DO_ISO_DHCP" = "true" ]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-dhcp.iso"
  fi
  if [ "$DO_ISO_AUTOINSTALL" = "true" ]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-custom-user-data.iso"
  fi
  if [ "$DO_ISO_GRUBFILE" = "true" ]; then
    TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
    TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
    ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-custom-grub.iso"
  fi
  for VOLMGR in $ISO_VOLMGRS; do
    if [ ! "$VOLMGR" = "custom" ]; then
      TEMP_DIR_NAME=$( dirname "$ISO_OUTPUTFILE" )
      TEMP_FILE_NAME=$( basename "$ISO_OUTPUTFILE" .iso )
      ISO_OUTPUTFILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$VOLMGR.iso"
    fi
  done
  if [ "$DO_ISO_CREATEISOVM" = "true" ] || [ "$DO_ISO_CREATECIVM" = "true" ]; then
    if [ "$VM_TYPE" = "kvm" ]; then
      if [ "$OS_NAME" = "Darwin" ]; then
        REQUIRED_PACKAGES="$REQUIRED_PACKAGES qemu libvirt dnsmasq libosinfo virt-manager"
      else
        REQUIRED_PACKAGES="$REQUIRED_PACKAGES qemu-full virt-manager virt-viewer dnsmasq bridge-utils libguestfs ebtables vde2 openbsd-netcat cloud-image-utils libosinfo"
      fi
    fi
  fi
  if [ "$VM_TYPE" = "" ]; then
    VM_TYPE="$DEFAULT_VM_TYPE"
  fi
  if [ "$VM_NIC" = "" ]; then
    VM_NIC="$DEFAULT_VM_NIC"
  fi
  if [ "$VM_SIZE" = "" ]; then
    VM_SIZE="$DEFAULT_VM_SIZE"
  fi
  if [ "$VM_CPUS" = "" ]; then
    VM_CPUS="$DEFAULT_VM_CPUS"
  fi
  if [[ "$ISO_ACTION" =~ "vm" ]]; then
    if [[ "$ISO_ACTION" =~ "create" ]]; then
      if [ "$VM_RAM" = "" ]; then
        VM_RAM="$DEFAULT_VM_RAM"
      else
        if [[ "$VM_RAM" =~ "G" ]] || [[ "$VM_RAM" =~ "g" ]]; then
          VM_RAM=$(echo "$VM_RAM" |sed "s/[G,g]//g")
          VM_RAM=$(echo "$VM_RAM*1024*1024" |bc -l)
        fi
        if [ "$VM_RAM" -lt 1024000 ]; then
          warning_message "Insufficient RAM specified for VM"
          exit
        fi
      fi
    fi
    if [ "$VM_NAME" = "" ]; then
      if [ "$ISO_BUILDTYPE" = "" ]; then
        if [[ "$ISO_ACTION" =~ "ci" ]]; then
          VM_NAME="$SCRIPT_NAME-ci-$ISO_OSNAME-$ISO_RELEASE-$ISO_BOOTTYPE-$ISO_ARCH"
        else
          VM_NAME="$SCRIPT_NAME-iso-$ISO_OSNAME-$ISO_RELEASE-$ISO_BOOTTYPE-$ISO_ARCH"
        fi
      else
        if [[ "$ISO_ACTION" =~ "ci" ]]; then
          VM_NAME="$SCRIPT_NAME-ci-$ISO_OSNAME-$ISO_BUILDTYPE-$ISO_RELEASE-$ISO_BOOTTYPE-$ISO_ARCH"
        else
          VM_NAME="$SCRIPT_NAME-iso-$ISO_OSNAME-$ISO_BUILDTYPE-$ISO_RELEASE-$ISO_BOOTTYPE-$ISO_ARCH"
        fi
      fi
    fi
    if [[ "$ISO_ACTION" =~ "create" ]]; then
      if ! [ "$VM_ISO" = "" ]; then
        if ! [ -f "$VM_ISO" ]; then
          warning_message "ISO $VM_ISO does not exist"
          exit
        fi
      fi
    fi
  fi
  if [ "$DO_ISO_SERIAL" = "true" ]; then
    ISO_KERNELARGS="$ISO_KERNELARGS console=$ISO_SERIALPORT0,$ISO_SERIALPORTSPEED0"
    if ! [ "$ISO_SERIAL_PORT1" = "" ]; then
      ISO_KERNELARGS="$ISO_KERNELARGS console=$ISO_SERIAL_PORT1,$ISO_SERIAL_PORT_SPEED1"
    fi
  fi
  if [ "$OLD_ISO_INSTALLSQUASHFSFILE" = "" ]; then
    OLD_ISO_INSTALLSQUASHFSFILE="$DEFAULT_OLD_ISO_INSTALLSQUASHFSFILE"
  fi
  if [ "$OLD_ISO_WORKDIR" = "" ]; then
    OLD_ISO_WORKDIR="$DEFAULT_OLD_ISO_WORKDIR"
  fi
  if [ "$VM_ISO" = "" ]; then
    VM_ISO="$ISO_OUTPUTFILE"
  fi
}
