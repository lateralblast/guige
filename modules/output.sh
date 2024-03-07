# Function: execute_command
#
# Execute a command

execute_command () {
  COMMAND="$1"
  execution_message "$COMMAND"
  if [ "$TEST_MODE" = "false" ]; then
    $COMMAND
  fi
}

# Function: print_file
#
# Print contents of file

print_file () {
  FILE_NAME="$1"
  handle_output "# Contents of file $FILE_NAME"
  if [ "$TEST_MODE" = "false" ]; then
    cat "$FILE_NAME"
  fi
}

# Function: execution_message
#
#  Print command

execution_message () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="COMMAND"
  handle_output "$OUTPUT_TEXT" $OUTPUT_TYPE
}

# Function: information_message
#
# Print informational message

information_message () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="TEXT"
  handle_output "# Information: $OUTPUT_TEXT" $OUTPUT_TYPE
}

# Function: verbose_message
#
# Print verbose message

verbose_message () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="TEXT"
  TEMP_VERBOSE_MODE="true"
  handle_output "$OUTPUT_TEXT" $OUTPUT_TYPE
  TEMP_VERBOSE_MODE="false"
}

# Function: warning_message
#
# Print warning message

warning_message () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="TEXT"
  TEMP_VERBOSE_MODE="true"
  handle_output "# Warning: $OUTPUT_TEXT" $OUTPUT_TYPE
  TEMP_VERBOSE_MODE="false"
}

# Function: handle_output
#
# Handle text output

handle_output () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="$2"
  if [ "$VERBOSE_MODE" = "true" ] || [ "$TEMP_VERBOSE_MODE" = "true" ]; then
    if [ "$TEST_MODE" = "true" ]; then
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

# Function: create_dir
#
# Create directory

create_dir () {
  CREATE_DIR="$1"
  handle_output "# Checking directory $CREATE_DIR exists"
  if [ ! -d "$CREATE_DIR" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      mkdir -p "$CREATE_DIR"
    fi
  fi
}

# Function: sudo_create_dir
#
# Create directory

sudo_create_dir () {
  CREATE_DIR="$1"
  handle_output "# Checking directory $CREATE_DIR exists"
  if [ ! -d "$CREATE_DIR" ]; then
    if [ "$TEST_MODE" = "false" ]; then
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
  handle_output "# Checking directory $REMOVE_DIR exists"
  if [ ! "$REMOVE_DIR" = "/" ]; then
    if [[ $REMOVE_DIR =~ [0-9a-zA-Z] ]]; then
      if [ -d "$REMOVE_DIR" ]; then
        if [ "$TEST_MODE" = "false" ]; then
          sudo rm -f "$REMOVE_DIR"
        fi
      fi
    fi
  fi
}

# Function: check_work_dir
#
# Check work directories exist
#
# Example:
# mkdir -p ./isomount ./isonew/squashfs ./isonew/cd ./isonew/custom

check_work_dir () {
  handle_output "# Check work directories" TEXT
  for ISO_DIR in $ISO_MOUNT_DIR $ISO_NEW_DIR/squashfs $ISO_NEW_DIR/mksquash $ISO_NEW_DIR/cd $ISO_NEW_DIR/custom $WORK_DIR/bin $WORK_DIR/files; do
    handle_output "# Check directory $ISO_DIR exists" TEXT
    if [ "$FORCE_MODE" = "true" ]; then
      remove_dir "$ISO_DIR"
    fi
    create_dir "$ISO_DIR"
  done
}

# Function: check_old_work_dir
#
# Check old release work directory
# Used when copying files from old release to a new release

check_old_work_dir () {
  handle_output "# Check old release work directories exist" TEXT
  for ISO_DIR in $OLD_ISO_MOUNT_DIR $OLD_WORK_DIR/files; do
    if [ "$FORCE_MODE" = "true" ]; then
      remove_dir "$ISO_DIR"
    fi
    create_dir "$ISO_DIR"
  done
}

# Function: check_file_perms
#
# Check file permissions of file

check_file_perms () {
  handle_output "# Checking file permissions for $CHECK_FILE" TEXT
  CHECK_FILE="$1"
  if [ -f "$CHECK_FILE" ]; then
    MY_USER="$USER"
    MY_GROUP=$(groups |awk '{print $1}')
    FILE_USER=$(find "$OUTPUT_FILE" -ls |awk '{print $5}')
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
  NFS_DIR="$WORK_DIR/files"
  EXPORTS_FILE="/etc/exports"
  handle_output "# Check NFS export is enabled" TEXT
  if [ -f "$EXPORTS_FILE" ]; then
    EXPORT_CHECK=$( grep -v "^#" < "$EXPORTS_FILE" |grep "$NFS_DIR" |grep "$BMC_IP" |awk '{print $1}' | head -1 )
  else
    EXPORT_CHECK=""
  fi
  if [ -z "$EXPORT_CHECK" ]; then
    if [ "$OS_NAME" = "Darwin" ]; then
      echo "$NFS_DIR --mapall=$OS_USER $BMC_IP" |sudo tee -a "$EXPORTS_FILE"
      sudo nfsd enable
      sudo nfsd restart
    else
      echo "$NFS_DIR $BMC_IP(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)" |sudo tee -a "$EXPORTS_FILE"
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
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_HOSTNAME.iso"
  fi
  if ! [ "$ISO_NIC" = "$DEFAULT_ISO_NIC" ]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_NIC.iso"
  fi
  if [ "$ISO_DHCP" = "false" ]; then
    if ! [ "$ISO_IP" = "$DEFAULT_ISO_IP" ]; then
      TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
      TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
      OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_IP.iso"
    fi
    if ! [ "$ISO_GATEWAY" = "$DEFAULT_ISO_GATEWAY" ]; then
      TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
      TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
      OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_GATEWAY.iso"
    fi
    if ! [ "$ISO_DNS" = "$DEFAULT_ISO_DNS" ]; then
      TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
      TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
      OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_DNS.iso"
    fi
  fi
  if ! [ "$ISO_USERNAME" = "$DEFAULT_ISO_USERNAME" ]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_USERNAME.iso"
  fi
  if ! [ "$ISO_DEVICES" = "$DEFAULT_ISO_DEVICES" ]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_DEVICES.iso"
  fi
  if ! [ "$ISO_PREFIX" = "" ]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$ISO_PREFIX-$TEMP_FILE_NAME.iso"
  fi
  if ! [ "$ISO_SUFFIX" = "" ]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_SUFFIX.iso"
  fi
  if [[ "$OPTIONS" =~ "cluster" ]]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-cluster.iso"
  fi
  if [[ "$OPTIONS" =~ "kvm" ]]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-kvm.iso"
  fi
  if [[ "$OPTIONS" =~ "biosdevname" ]]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-biosdevname.iso"
  fi
  if [[ "$OPTIONS" =~ "sshkey" ]]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-sshkey.iso"
  fi
  if [ "$ISO_DHCP" = "true" ]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-dhcp.iso"
  fi
  if [ "$DO_CREATE_VM" = "true" ]; then
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
  if [[ "$ACTION" =~ "vm" ]]; then
    if [[ "$ACTION" =~ "create" ]]; then
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
      VM_NAME="$SCRIPT_NAME-ubuntu-$ISO_RELEASE-$ISO_BOOT_TYPE"
    fi
    if [[ "$ACTION" =~ "create" ]]; then
      if ! [ "$VM_ISO" = "" ]; then
        if ! [ -f "$VM_ISO" ]; then
          warning_message "ISO $VM_ISO does not exist"
          exit
        fi
      fi
    fi
  fi
  if [ "$DO_SERIAL" = "true" ]; then
    ISO_KERNEL_ARGS="$ISO_KERNEL_ARGS console=$ISO_SERIAL_PORT0,$ISO_SERIAL_PORT_SPEED0"
    if ! [ "$ISO_SERIAL_PORT1" = "" ]; then
      ISO_KERNEL_ARGS="$ISO_KERNEL_ARGS console=$ISO_SERIAL_PORT1,$ISO_SERIAL_PORT_SPEED1"
    fi
  fi
  if [ "$OLD_INSTALL_SQUASHFS_FILE" = "" ]; then
    OLD_INSTALL_SQUASHFS_FILE="$DEFAULT_OLD_INSTALL_SQUASHFS_FILE"
  fi
  if [ "$OLD_WORK_DIR" = "" ]; then
    OLD_WORK_DIR="$DEFAULT_OLD_WORK_DIR"
  fi
  if [ "$VM_ISO" = "" ]; then
    VM_ISO="$OUTPUT_FILE"
  fi
}
